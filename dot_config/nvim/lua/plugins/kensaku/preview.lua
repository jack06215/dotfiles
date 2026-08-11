-- Live highlight of the Japanese a romaji pattern will match, while you type.
--
-- Conversion happens on `<CR>` (see `cmdline.lua`), so up to that point Vim's
-- own `incsearch` only knows about the literal romaji -- type `nihongo` and
-- 日本語 stays dark until you commit. This fills that gap: on every keystroke
-- the converted pattern goes into `@/` with `hlsearch` forced on, so the real
-- targets light up as you type. `@/` is restored on `CmdlineLeave`, which fires
-- before the command runs, so nothing here changes what actually executes.
--
-- Highlight only, not a full `incsearch`: the cursor does not jump to the first
-- match, and `inccommand` still cannot show the replacement text for `:s`
-- (that would need the converted pattern to be in the command line itself,
-- which is exactly what we are avoiding). What you get is which lines are
-- about to be hit, live.
--
-- `kensaku#query` is a synchronous denops round-trip, measured at 0.2-1.2ms per
-- keystroke once denops is warm, so this runs inline rather than async.

local M = {}

-- Non-nil only while we are overriding, and holds what to put back.
local saved = nil

--- The romaji to preview on this command line, if any.
---@return string?
local function romaji_of()
  local cmdtype = vim.fn.getcmdtype()
  local line = vim.fn.getcmdline()

  if cmdtype == "/" or cmdtype == "?" then
    local romaji = vim.fn.matchstr(line, vim.g["kensaku_search#pattern"])
    return romaji ~= "" and romaji or nil
  elseif cmdtype == ":" then
    return (require("plugins.kensaku.cmdline").ex_split(line))
  end
end

local function restore()
  if not saved then
    return
  end
  vim.fn.setreg("/", saved.search)
  vim.v.hlsearch = saved.hlsearch
  saved = nil
  return true
end

--- Restore on the way out of the command line.
---
--- `<C-c>` fires `CmdlineLeave` but sets the interrupt flag, which aborts the
--- callback partway -- `@/` would keep the preview pattern and poison `n`/`N`.
--- So queue a retry *first*, then try synchronously: the sync path clears
--- `saved` and the retry becomes a no-op, and if it was interrupted the retry
--- runs a tick later with the flag cleared.
local function leave()
  vim.schedule(function()
    -- A new command line already open owns the restore; `saved` still holds the
    -- pre-preview value either way, so its own `CmdlineLeave` puts it back.
    if vim.fn.getcmdtype() == "" then
      restore()
    end
  end)
  restore()
end

local function update()
  local romaji = romaji_of()

  -- Backspacing out of a romaji pattern has to drop the preview too.
  if not romaji then
    if restore() then
      vim.cmd("redraw")
    end
    return
  end

  local pattern = require("plugins.kensaku.query").query(romaji)
  if not pattern then
    return
  end

  saved = saved or { search = vim.fn.getreg("/"), hlsearch = vim.v.hlsearch }
  vim.fn.setreg("/", pattern)
  vim.v.hlsearch = 1
  vim.cmd("redraw")
end

function M.setup()
  local group = vim.api.nvim_create_augroup("kensaku_preview", { clear = true })
  vim.api.nvim_create_autocmd("CmdlineChanged", { group = group, callback = update })
  -- Fires before the command executes, so `:%s//x/g` still sees the real `@/`.
  vim.api.nvim_create_autocmd("CmdlineLeave", { group = group, callback = leave })
end

return M
