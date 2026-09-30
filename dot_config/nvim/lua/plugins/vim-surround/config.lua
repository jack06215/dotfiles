return {
  {
    "tpope/vim-surround",
    -- Pure text edits, so it works unchanged under vscode-neovim; the LazyVim
    -- vscode extra only loads specs that opt in like this.
    vscode = true,
    keys = {
      { "ys", mode = { "n", "x" }, desc = "Surround text" },
    },
  },
}
