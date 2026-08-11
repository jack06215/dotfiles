-- Romaji -> Japanese search pattern for flash.nvim, via vim-kensaku.
--
-- flash's `search.mode` accepts `fun(input): pattern, skip?` returning a Vim
-- regex, which is exactly what `plugins.kensaku.query` produces: a pattern
-- matching the romaji input *and* its hiragana / katakana / kanji / full-width
-- / half-width readings. Because the raw input stays in the alternation, this
-- is a strict superset of flash's default "exact" mode -- ASCII searches keep
-- working unchanged.

local M = {}

-- flash's built-in "exact" mode, used as the fallback when kensaku is not
-- answering (denops still booting, Deno missing, plugin not loaded).
local function exact(str)
  return "\\V" .. str:gsub("\\", "\\\\")
end

---@param str string
---@return string pattern
function M.mode(str)
  if str == "" then
    return str
  end

  return require("plugins.kensaku.query").query(str) or exact(str)
end

return M
