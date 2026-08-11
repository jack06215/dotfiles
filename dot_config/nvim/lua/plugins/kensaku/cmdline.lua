-- Romaji -> Japanese regex conversion on the command line.
--
-- `kensaku-search.vim` covers `/` and `?` by rewriting the whole line on
-- `<CR>`. Ex commands need something finer: only the pattern argument may be
-- touched, and only for the handful of commands that take one. Two entry
-- points:
--
--   expand_ex()  automatic, on `<CR>`, for `:s` / `:g` / `:v`
--   expand()     manual, on `<C-x>`, for anything else
--
-- Both rewrite the line in place rather than wrapping `:s` in a custom
-- command, so the substitution stays a real `:s` and `inccommand` keeps
-- previewing it.

local M = {}

-- Ex commands whose first argument is a search pattern, with an optional range
-- in front. Deliberately narrow: `:e /home/user` parses as valid romaji
-- ("ho" + "me"), so a blanket rewrite of `:` lines would mangle paths.
--
-- Captures: 1 = delimiter, 2 = everything after it. The delimiter class is
-- Vim's own rule for `:s` (`:h :s_flags`) -- any character except alphanumerics,
-- whitespace, `\`, `"` and `|`.
local EX_PATTERN_CMD = table.concat({
  [[^\s*\%(%\|\.\|\$\|\d\+\|'.\|\\[/?&]\|[+-]\d*\|,\|;\|\s\)*]], -- range
  [[\%(s\%[ubstitute]\|g\%[lobal]\|v\%[global]\)!\=\s*]], -- command
  [[\([^0-9a-zA-Z \t|"\\]\)]], -- delimiter
  [[\(.*\)$]], -- pattern, then the rest of the command
})

--- Text up to the first unescaped `delim`, i.e. the pattern argument.
---@param rest string
---@param delim string
---@return string
local function pattern_segment(rest, delim)
  local i = 1
  while i <= #rest do
    local c = rest:sub(i, i)
    if c == "\\" then
      i = i + 2 -- an escaped delimiter does not end the pattern
    elseif c == delim then
      return rest:sub(1, i - 1)
    else
      i = i + 1
    end
  end
  return rest -- pattern still being typed, no closing delimiter yet
end

--- Split a `:s` / `:g` / `:v` command line around its pattern argument.
--- Shared with `preview.lua`, which needs the pattern without rewriting.
---@param line string
---@return string? romaji, string? head, string? tail
function M.ex_split(line)
  local m = vim.fn.matchlist(line, EX_PATTERN_CMD)
  if #m == 0 then
    return nil
  end

  local delim, rest = m[2], m[3]
  local segment = pattern_segment(rest, delim)

  -- `g:kensaku_search#pattern` is the guard kensaku-search.vim uses on `/`: it
  -- matches only strings a romaji syllable sequence can produce. So a regex
  -- (`:%s/foo.*bar/`), an already-expanded pattern, and an empty one
  -- (`:%s//x/`, reusing @/) all fall through unconverted. `\zs` in the guard
  -- drops a leading `\v` / `\m`, which kensaku's own output replaces anyway.
  local romaji = vim.fn.matchstr(segment, vim.g["kensaku_search#pattern"])
  if romaji == "" then
    return nil
  end

  return romaji, line:sub(1, #line - #rest), rest:sub(#segment + 1)
end

--- Convert the pattern argument of a `:s` / `:g` / `:v` command, if it is
--- romaji. Bound to `<CR>`, so it runs before every `:` command and must be
--- conservative about what it touches.
function M.expand_ex()
  if vim.fn.getcmdtype() ~= ":" then
    return
  end

  local romaji, head, tail = M.ex_split(vim.fn.getcmdline())
  if not romaji then
    return
  end

  local converted = require("plugins.kensaku.query").query(romaji)
  if not converted then
    return
  end

  vim.fn.setcmdline(head .. converted .. tail)
end

--- Replace the trailing romaji run before the cursor with its kensaku pattern.
--- Bound to `<C-x>`, for the commands `expand_ex` deliberately skips:
---
---   :vimgrep /nihongo<C-x>/ **/*.md
---
--- Explicit, so no guard is needed -- pressing the key *is* the intent.
function M.expand()
  local line = vim.fn.getcmdline()
  local pos = vim.fn.getcmdpos() -- 1-based byte index of the char under cursor
  local before = line:sub(1, pos - 1)

  -- Only the trailing romaji run is converted, so the `:vimgrep /` prefix and
  -- any earlier segment survive. `-` is included for 長音 ("ko-hi-").
  local romaji = before:match("[%a-]+$")
  if not romaji then
    return
  end

  local pattern = require("plugins.kensaku.query").query(romaji)
  if not pattern then
    return
  end

  -- kensaku patterns are pure `\m` / `\%(...\)` regex and contain no delimiter
  -- character, so this drops between `:s` delimiters without re-escaping.
  local head = before:sub(1, #before - #romaji)
  vim.fn.setcmdline(head .. pattern .. line:sub(pos), #head + #pattern + 1)
end

return M
