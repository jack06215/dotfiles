-- Prose completion: two sources, both ranked below every code source so they
-- never crowd out LSP results.
--
-- English (`dictionary`), ported from linkarzu/dotfiles-latest, always on.
-- Two inputs feed it: the bulk word list generated at `chezmoi apply` by
-- run_onchange_after_generate-dictionary.sh.tmpl, and the spell file, so
-- anything added with `zg` becomes a completion immediately.
--
-- Japanese (`im`), off until toggled, keyed by romaji. Its table comes from
-- run_onchange_after_generate-jisyo.sh.tmpl. See the block at the bottom.

-- Matches the paths the generators write to. The jisyo gets its own directory
-- rather than a second file under dict/: `dictionary_directories` globs every
-- .txt beneath it, so a jisyo there would be swallowed into English
-- completion.
local data_home = vim.env.XDG_DATA_HOME or vim.fn.expand("~/.local/share")
local dict_dir = data_home .. "/dict"
local jisyo = data_home .. "/dict-ja/skk.txt"

local M = {
  "saghen/blink.cmp",
  dependencies = {
    -- https://github.com/Kaiser-Yang/blink-cmp-dictionary
    "Kaiser-Yang/blink-cmp-dictionary",
    -- https://github.com/yehuohan/blink-cmp-im
    "yehuohan/blink-cmp-im",
  },
}

M.opts = function(_, opts)
  -- Layering onto LazyVim's opts rather than redeclaring every provider, so
  -- mutate in place: vim.tbl_deep_extend replaces list values, which would
  -- silently drop LazyVim's own default sources.
  opts.sources = opts.sources or {}
  opts.sources.default = opts.sources.default or {}
  table.insert(opts.sources.default, "dictionary")

  opts.sources.providers = opts.sources.providers or {}
  opts.sources.providers.dictionary = {
    module = "blink-cmp-dictionary",
    name = "Dict",
    -- blink's own defaults are lsp 0, path 3, snippets -1, buffer -3, so -4
    -- puts dictionary words below every code source. linkarzu's 20 is on a
    -- different scale because he redeclares every provider with an explicit
    -- offset; copying that number here would rank dictionary above the LSP.
    score_offset = -4,
    max_items = 8,
    min_keyword_length = 3,
    opts = {
      -- Every .txt in the directory is concatenated, so the generator only
      -- has to drop a file in for it to be picked up.
      dictionary_directories = { dict_dir },
      dictionary_files = { vim.fn.stdpath("config") .. "/spell/en.utf-8.add" },

      -- Definitions in the docs window come from WordNet. No guard needed:
      -- the plugin probes for `wn` itself and shows nothing when it is
      -- missing. To drop definitions even when it is installed, override
      -- separate_output to return bare { label, insert_text } items.
    },
  }

  -- Japanese: type romaji, insert kana or kanji. The same direction kensaku
  -- already goes for searching -- ASCII in, Japanese out, no OS IME -- only
  -- this end inserts the text instead of building a pattern to match it.
  --
  -- It cannot just be another file handed to the dictionary source above:
  -- blink-cmp-dictionary sets `filterText = leading .. insert_text`, welding
  -- what you type to what you get, so an item inserting 日本語 could only be
  -- found by typing 日本語. blink-cmp-im keeps the two apart -- romaji in
  -- filterText, Japanese in the label -- which is the whole trick.
  --
  -- Both guards matter: the table is absent on a machine that was offline at
  -- apply time, and registering a provider whose module failed to load takes
  -- the whole menu down with it.
  local ok, im = pcall(require, "blink_cmp_im")
  if ok and vim.fn.filereadable(jisyo) == 1 then
    table.insert(opts.sources.default, "im")
    opts.sources.providers.im = {
      module = "blink_cmp_im",
      name = "IM",
      -- Below dictionary's -4: while the IM is on, a word that is both
      -- English and valid romaji should still rank as the English word.
      score_offset = -5,
      max_items = 8,
      -- The generator drops keys shorter than this for the same reason.
      min_keyword_length = 3,
    }

    im.setup({
      -- Off until toggled -- see lua/config/keymaps/blink.lua. Romaji keys
      -- like `no`, `ni` and `to` are ordinary identifiers in every language
      -- here, so an always-on source would offer Japanese while coding.
      enable = false,
      tables = { jisyo },
      maxn = 8,
      -- Japanese first so the menu reads at a glance, romaji after it as a
      -- reminder of what was typed. `%S` is vim's display-width-aware `%s`,
      -- without which the column tears on double-width glyphs.
      format = function(key, text)
        return vim.fn.printf("%-14S %s", text, key)
      end,
    })
  end
end

return M
