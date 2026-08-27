-- Dictionary completion, ported from linkarzu/dotfiles-latest.
--
-- Plain English words complete while writing prose, ranked below every code
-- source so they never crowd out LSP results. Two inputs feed it: the bulk
-- word list generated at `chezmoi apply` by
-- run_onchange_after_generate-dictionary.sh.tmpl, and the spell file, so
-- anything added with `zg` becomes a completion immediately.

-- Matches the path the generator writes to.
local dict_dir = (vim.env.XDG_DATA_HOME or vim.fn.expand("~/.local/share")) .. "/dict"

local M = {
  "saghen/blink.cmp",
  dependencies = {
    -- https://github.com/Kaiser-Yang/blink-cmp-dictionary
    "Kaiser-Yang/blink-cmp-dictionary",
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
end

return M
