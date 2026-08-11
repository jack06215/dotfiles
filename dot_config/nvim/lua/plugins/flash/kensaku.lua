-- Romaji -> Japanese search pattern for flash.nvim, via vim-kensaku.
--
-- flash's `search.mode` accepts `fun(input): pattern, skip?` returning a Vim
-- regex. `kensaku#query()` returns exactly that: an `\m`-prefixed pattern that
-- matches the romaji input *and* its hiragana / katakana / kanji / full-width /
-- half-width readings. Because the raw input stays in the alternation, this is
-- a strict superset of flash's default "exact" mode -- ASCII searches keep
-- working unchanged.
--
--   kensaku#query("nihongo")
--   => \m\%(nihongo\|にほんご\|ニホンゴ\|日本\%(語\|...\)\|ｎｉｈｏｎｇｏ\|ﾆﾎﾝｺﾞ\)

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

  -- `kensaku#query` blocks on `denops#plugin#wait` and returns "" on failure,
  -- so pcall + empty check covers every not-ready case.
  local ok, pattern = pcall(vim.fn["kensaku#query"], str)

  -- "\m" is what an empty/failed conversion degrades to; as a pattern it would
  -- match at every position, so treat it as failure too.
  if not ok or pattern == "" or pattern == "\\m" then
    return exact(str)
  end

  return pattern
end

return M
