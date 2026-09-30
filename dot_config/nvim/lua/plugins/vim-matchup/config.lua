return {
  "andymass/vim-matchup",
  event = "BufReadPost",
  -- The motions and text objects (%, g%, [%, ]%, a%, i%) are what carry over;
  -- see matchparen below for the part that does not.
  vscode = true,

  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },

  init = function()
    vim.g.matchup_surround_enabled = 1
    vim.g.matchup_delim_noskips = 1
    -- VS Code draws its own bracket match, and cannot show matchup's
    -- highlights or its offscreen popup anyway.
    vim.g.matchup_matchparen_enabled = vim.g.vscode and 0 or 1
    vim.g.matchup_matchparen_offscreen = { method = "popup" }
    vim.g.matchup_matchparen_deferred = 1
    vim.g.matchup_matchparen_timeout = 300
    vim.g.matchup_matchparen_insert_timeout = 60
  end,
}
