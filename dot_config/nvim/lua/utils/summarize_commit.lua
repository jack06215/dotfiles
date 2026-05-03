local M = {}

-- your original prompt header
M.prompt = [[
Read my instruction and follow it carefully.

<<INSTRUCTION START>>
Generate a commit summary using conventional commit format from
the output of a git diff that starts after the word <<DIFF START>>

--------

Only respond with the generated commit text.

--------

Example commit message:

feat: add new feature

- Add new feature
- Update documentation
- Fix bug in existing feature
...

--------

<<INSTRUCTION END>>

<<DIFF START>>
]]

-- get the staged diff, no pager, strip CRLFs, only error on code > 1
local function get_staged_diff()
  local cmd   = { "git", "--no-pager", "diff", "--cached" }
  local lines = vim.fn.systemlist(cmd)
  local code  = vim.v.shell_error

  if code > 1 then
    vim.notify(("git diff failed (exit code %d)"):format(code),
               vim.log.levels.ERROR)
    return nil
  end

  -- if no changes staged, lines == {} → return nil
  if #lines == 0 then
    vim.notify("No staged changes to diff", vim.log.levels.WARN)
    return nil
  end

  return table.concat(lines, "\n")
end

-- insert a list of lines at cursor
local function insert_at_cursor(lines)
  local win    = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  vim.api.nvim_buf_set_lines(0,
    cursor[1] - 1,
    cursor[1] - 1,
    false,
    lines
  )
  vim.api.nvim_win_set_cursor(win, {
    cursor[1] + #lines,
    cursor[2],
  })
end

-- helper to call curl and handle errors
local function curl_json(args)
  local out = vim.fn.systemlist(args)
  if vim.v.shell_error ~= 0 then
    vim.notify("curl failed: " .. table.concat(args, " "),
               vim.log.levels.ERROR)
    return nil
  end
  return table.concat(out, "\n")
end

-- Ollama via local REST API
M.summarize_commit_ollama = function()
  local diff = get_staged_diff(); if not diff then return end

  local payload = vim.json.encode({
    model  = "qwen2.5-coder:latest",
    prompt = M.prompt .. diff,
    stream = false,
  })

  local args = {
    "curl", "-sS", "--fail",
    "-X", "POST",
    "-H", "Content-Type: application/json",
    "http://localhost:11434/api/generate",
    "-d", payload,
  }
  local body = curl_json(args)
  if not body then return end

  local ok, resp = pcall(vim.json.decode, body)
  if not ok then
    vim.notify("Failed to decode Ollama JSON", vim.log.levels.ERROR)
    print(body)
    return
  end

  if type(resp.response) ~= "string" then
    vim.notify("Unexpected Ollama response format", vim.log.levels.ERROR)
    print(body)
    return
  end

  local lines = vim.split(resp.response, "\n", { trimempty = true })
  insert_at_cursor(lines)
end

-- OpenAI Chat Completions
M.summarize_commit_openai = function()
  local diff = get_staged_diff(); if not diff then return end

  local api_key = os.getenv("OPENAI_API_KEY")
  if not (api_key and #api_key > 0) then
    vim.notify("OPENAI_API_KEY not set", vim.log.levels.ERROR)
    return
  end

  local payload = vim.json.encode({
    model    = "gpt-4o-mini",
    messages = {
      {
        role    = "system",
        content = [[
You are a conventional commits summarizer.
You take git diff data and ONLY respond with a concise,
bullet‑listed commit message in conventional‑commit format.
Do not add any extra text or formatting.
        ]],
      },
      {
        role    = "user",
        content = M.prompt .. diff,
      },
    },
    max_tokens = 1024,
    stream     = false,
  })

  local args = {
    "curl", "-sS", "--fail",
    "-X", "POST",
    "https://api.openai.com/v1/chat/completions",
    "-H", "Authorization: Bearer " .. api_key,
    "-H", "Content-Type: application/json",
    "-d", payload,
  }

  local body = curl_json(args)
  if not body then return end

  local ok, resp = pcall(vim.json.decode, body)
  if not ok
     or not resp.choices
     or not resp.choices[1].message
     or not resp.choices[1].message.content
  then
    vim.notify("Unexpected OpenAI response", vim.log.levels.ERROR)
    return
  end

  local lines = vim.split(
    resp.choices[1].message.content,
    "\n",
    { trimempty = true }
  )
  insert_at_cursor(lines)
end

return M
