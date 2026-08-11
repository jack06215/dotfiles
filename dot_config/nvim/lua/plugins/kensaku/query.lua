-- Shared romaji -> Japanese regex conversion, on top of vim-kensaku.
--
-- `kensaku#query()` returns an `\m`-prefixed Vim regex that matches the romaji
-- input *and* its hiragana / katakana / kanji / full-/half-width readings:
--
--   kensaku#query("nihongo")
--   => \m\%(nihongo\|にほんご\|ニホンゴ\|日本\%(語\|...\)\|ｎｉｈｏｎｇｏ\|ﾆﾎﾝｺﾞ\)
--
-- Every caller needs the same "kensaku isn't answering" handling but a
-- different fallback, so the guard lives here and the fallback stays with the
-- caller.

local M = {}

---@param str string romaji input
---@return string? pattern nil when kensaku cannot answer
function M.query(str)
  if str == "" then
    return nil
  end

  -- `kensaku#query` blocks on `denops#plugin#wait` and returns "" on failure,
  -- so pcall + empty check covers every not-ready case (Deno missing, denops
  -- still booting, plugin not loaded).
  local ok, pattern = pcall(vim.fn["kensaku#query"], str)

  -- "\m" is what an empty/failed conversion degrades to; as a pattern it would
  -- match at every position, so treat it as failure too.
  if not ok or pattern == "" or pattern == "\\m" then
    return nil
  end

  return pattern
end

return M
