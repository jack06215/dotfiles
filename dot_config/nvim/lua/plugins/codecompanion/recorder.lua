-- Archives every CodeCompanion chat turn and inline request to a local SQLite
-- database: what was asked, the code sent with it, and what came back.
--
-- A local extension, registered in ./config.lua. .chezmoiignore keeps it off
-- company machines, so their code doesn't pile up in a plain-text archive.
--
-- Chat uses the documented `on_completed` callback. Inline has no such hook (its
-- events carry neither the prompt nor the result), so `Inline.done` and
-- `Inline.stop` are wrapped. They're private: if an update renames them this warns
-- once and inline stops being recorded, but inline itself carries on working.

local M = {}

local api, uv = vim.api, vim.uv

local PRIVATE_FILE = tonumber("600", 8)
local BUSY_TIMEOUT_MS = 5000
local WRITE_TIMEOUT_MS = 30000
local FLUSH_TIMEOUT_MS = BUSY_TIMEOUT_MS + 1000

local SCHEMA = [[
PRAGMA journal_mode = WAL;
CREATE TABLE IF NOT EXISTS interactions (
  id            INTEGER PRIMARY KEY,
  created_at    TEXT NOT NULL,  -- UTC
  kind          TEXT NOT NULL,  -- chat | inline
  session_id    TEXT,           -- groups the turns of one chat
  turn          INTEGER,
  adapter       TEXT,
  model         TEXT,
  cwd           TEXT,
  file          TEXT,
  filetype      TEXT,
  request       TEXT,
  code          TEXT,
  result        TEXT,           -- the reply, or a unified diff of an inline edit
  status        TEXT,           -- done | stopped | proposed | accepted | replied | discarded | error
  messages_json TEXT            -- the full messages for this turn, including tool calls
);
CREATE INDEX IF NOT EXISTS interactions_session ON interactions (session_id);
]]

local COLUMNS = {
  "created_at",
  "kind",
  "session_id",
  "turn",
  "adapter",
  "model",
  "cwd",
  "file",
  "filetype",
  "request",
  "code",
  "result",
  "status",
  "messages_json",
}

local CHAT_STATUS = { success = "done", error = "error", cancelling = "stopped" }

-- Hidden messages that steer the model rather than carry the user's code
local NOT_CODE = { compact_summary = true, rules = true, skills = true }

local HEX = {}
for byte = 0, 255 do
  HEX[string.char(byte)] = ("%02X"):format(byte)
end

local db_path
local installed = false
local schema_ready = false
local writing = false
local pending = {} ---@type string[]
local warned = {} ---@type table<string, boolean>
local inline_sessions = {} ---@type table<number, string>
local chat_states = setmetatable({}, { __mode = "k" }) ---@type table<table, table>

---@param key string Warnings sharing a key are shown once
---@param message string
local function warn_once(key, message)
  if not warned[key] then
    warned[key] = true
    vim.notify("[CodeCompanion recorder] " .. message, vim.log.levels.WARN)
  end
end

---Recording must never take a request down with it
---@param fn function
local function guarded(fn, ...)
  local ok, err = xpcall(fn, debug.traceback, ...)
  if not ok then
    warn_once("record", "Could not record a request: " .. tostring(err))
  end
end

---Hex-encoded, so nothing in a prompt or in code can break out of the statement
---@param value string|number|nil
---@return string
local function literal(value)
  if value == nil then
    return "NULL"
  end
  if type(value) == "number" then
    return tostring(value)
  end
  return ("CAST(X'%s' AS TEXT)"):format(tostring(value):gsub(".", HEX))
end

---Run the queued statements one at a time, so they land in the order they were made
local function pump()
  if writing or #pending == 0 then
    return
  end
  writing = true

  local sql = (".timeout %d\n%s%s\n"):format(BUSY_TIMEOUT_MS, schema_ready and "" or SCHEMA, table.remove(pending, 1))
  local ok, err = pcall(
    vim.system,
    { "sqlite3", "-batch", "-bail", db_path },
    { stdin = sql, text = true, timeout = WRITE_TIMEOUT_MS },
    vim.schedule_wrap(function(out)
      writing = false
      if out.code == 0 then
        schema_ready = true
      else
        warn_once("write", ("A write to %s failed: %s"):format(db_path, vim.trim(out.stderr or "")))
      end
      pump()
    end)
  )
  if not ok then
    writing = false
    warn_once("write", ("Could not run sqlite3: %s"):format(err))
  end
end

---@param statement string
local function enqueue(statement)
  table.insert(pending, statement)
  pump()
end

---Wait for queued writes to land
---@return boolean drained
function M.flush()
  return vim.wait(FLUSH_TIMEOUT_MS, function()
    return not writing and #pending == 0
  end, 10)
end

---@param row table<string, string|number|nil>
function M.insert(row)
  row.created_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
  row.cwd = vim.fn.getcwd()
  local values = vim.tbl_map(function(column)
    return literal(row[column])
  end, COLUMNS)
  enqueue(
    ("INSERT INTO interactions (%s) VALUES (%s);"):format(table.concat(COLUMNS, ", "), table.concat(values, ", "))
  )
end

---@param kind "chat"|"inline"
---@param id number The ID CodeCompanion gave it, which is only unique within a session
---@return string
local function new_session_id(kind, id)
  return ("%s-%s-%d-%d"):format(kind, os.date("!%Y%m%dT%H%M%S"), uv.os_getpid(), id)
end

---@param adapter table?
---@return string?
local function model_of(adapter)
  local ok, model = pcall(function()
    return require("codecompanion.adapters.utils").model(adapter)
  end)
  return ok and model or nil
end

---@param messages table[]?
---@return string?
local function to_json(messages)
  local ok, json = pcall(vim.json.encode, messages)
  return ok and messages and json or nil
end

---@param parts string[]
---@return string?
local function join(parts)
  return #parts > 0 and table.concat(parts, "\n\n") or nil
end

---@param message table
---@return boolean
local function is_visible(message)
  return not (message.opts and message.opts.visible == false)
end

---@param message table
---@return boolean
local function is_code(message)
  local tag = message._meta and message._meta.tag
  local is_binary = message.context and message.context.mimetype
  return not is_visible(message) and not is_binary and not NOT_CODE[tag]
end

---@param messages table[]
---@param role string
---@return string?
local function last_visible(messages, role)
  for i = #messages, 1, -1 do
    local message = messages[i]
    if message.role == role and is_visible(message) and type(message.content) == "string" then
      return message.content
    end
  end
end

---@param chat table
---@param state { session_id: string, turn: number, seen: table<table, boolean> }
---@param data { status: string, error?: string }
local function record_chat(chat, state, data)
  local constants = require("codecompanion.config").constants
  local new, request, code, result = {}, {}, {}, {}

  for _, message in ipairs(chat.messages) do
    if not state.seen[message] then
      state.seen[message] = true
      table.insert(new, message)

      if type(message.content) == "string" and message.content ~= "" then
        if message.role == constants.LLM_ROLE then
          table.insert(result, message.content)
        elseif message.role == constants.USER_ROLE and is_visible(message) then
          table.insert(request, message.content)
        elseif message.role == constants.USER_ROLE and is_code(message) then
          table.insert(code, message.content)
        end
      end
    end
  end

  if #new == 0 then
    return
  end

  state.turn = state.turn + 1
  local context = chat.buffer_context or {}
  M.insert({
    kind = "chat",
    session_id = state.session_id,
    turn = state.turn,
    adapter = chat.adapter and chat.adapter.name,
    model = model_of(chat.adapter),
    file = context.filename,
    filetype = context.filetype,
    -- Regenerating a reply re-sends a message that's already been seen
    request = join(request) or last_visible(chat.messages, constants.USER_ROLE),
    code = join(code),
    result = join(result) or data.error,
    status = CHAT_STATUS[data.status] or data.status,
    messages_json = to_json(new),
  })
end

---A restored chat arrives with its history, which was recorded when it happened
---@param chat table
local function skip_history(chat)
  local seen = chat_states[chat].seen
  for _, message in ipairs(chat.messages) do
    seen[message] = true
  end
end

---@param chat table
local function watch_chat(chat)
  local llm_role = require("codecompanion.config").constants.LLM_ROLE
  local state = {
    session_id = new_session_id("chat", chat.id),
    turn = 0,
    seen = setmetatable({}, { __mode = "k" }),
  }
  chat_states[chat] = state

  local is_restored = vim.iter(chat.messages):any(function(message)
    return message.role == llm_role
  end)
  if is_restored then
    skip_history(chat)
  end

  chat:add_callback("on_completed", function(current, data)
    guarded(record_chat, current, state, data)
  end)
end

---@param inline table
---@param result table
---@return string status
---@return string text
local function inline_outcome(inline, result)
  if result.error then
    return "error", result.error
  end
  if result.reply then
    return "replied", result.reply
  end

  local before = table.concat(inline.target.lines, "\n") .. "\n"
  local after = table.concat(result.lines, "\n") .. "\n"
  return api.nvim_buf_is_valid(inline.bufnr) and "proposed" or "discarded", vim.text.diff(before, after, { ctxlen = 3 })
end

---@param inline table
---@param status string
---@param text string?
---@param messages table[]?
local function record_inline(inline, status, text, messages)
  local target, context = inline.target, inline.buffer_context
  local session_id = new_session_id("inline", inline.id)
  if status == "proposed" then
    inline_sessions[inline.id] = session_id
  end

  -- A prompt library entry may not have a prompt of its own to report
  local user_role = require("codecompanion.config").constants.USER_ROLE
  local request = inline.prompt_text or last_visible(messages or inline.prompts or {}, user_role)

  M.insert({
    kind = "inline",
    session_id = session_id,
    turn = 1,
    adapter = inline.adapter and inline.adapter.name,
    model = model_of(inline.adapter),
    file = context.filename,
    filetype = context.filetype,
    request = request,
    code = table.concat(vim.list_slice(target.lines, target.context.first, target.context.last), "\n"),
    result = text,
    status = status,
    messages_json = to_json(messages),
  })
end

---@param id number
local function mark_accepted(id)
  local session_id = inline_sessions[id]
  if session_id then
    inline_sessions[id] = nil
    enqueue(("UPDATE interactions SET status = 'accepted' WHERE session_id = %s;"):format(literal(session_id)))
  end
end

local function hook_inline()
  local ok, Inline = pcall(require, "codecompanion.interactions.inline")
  if not ok or type(Inline.done) ~= "function" or type(Inline.stop) ~= "function" then
    return warn_once("inline", "Inline requests aren't being recorded: this CodeCompanion has no `Inline.done`/`stop`")
  end

  local done, stop = Inline.done, Inline.stop

  Inline.done = function(inline, result)
    guarded(function()
      local status, text = inline_outcome(inline, result)
      record_inline(inline, status, text, result.messages)
    end)
    return done(inline, result)
  end

  -- A stopped request never reaches `done`
  Inline.stop = function(inline)
    if inline.requesting then
      guarded(record_inline, inline, "stopped")
    end
    return stop(inline)
  end
end

---@param opts? { path?: string }
function M.setup(opts)
  if installed then
    return
  end
  if vim.fn.executable("sqlite3") == 0 then
    return warn_once("sqlite3", "Nothing is being recorded: sqlite3 isn't on PATH")
  end

  db_path = opts and opts.path or (vim.fn.stdpath("data") .. "/codecompanion/history.db")
  vim.fn.mkdir(vim.fs.dirname(db_path), "p")
  -- sqlite3 would create it world-readable. Its -wal and -shm files copy this mode.
  local fd, err = uv.fs_open(db_path, "a", PRIVATE_FILE)
  if not fd then
    return warn_once("open", ("Nothing is being recorded: %s"):format(err))
  end
  uv.fs_close(fd)
  uv.fs_chmod(db_path, PRIVATE_FILE)

  installed = true
  hook_inline()

  local group = api.nvim_create_augroup("CodeCompanionRecorder", { clear = true })
  api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeCompanionChatCreated",
    callback = function(event)
      guarded(watch_chat, require("codecompanion").buf_get_chat(event.data.bufnr))
    end,
  })
  api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeCompanionChatSessionRestored",
    callback = function(event)
      -- A saved session swaps in its messages after the chat is created
      guarded(skip_history, require("codecompanion").buf_get_chat(event.data.bufnr))
    end,
  })
  api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeCompanionInlineAccepted",
    callback = function(event)
      guarded(mark_accepted, event.data.id)
    end,
  })
  api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.flush()
    end,
  })
end

return M
