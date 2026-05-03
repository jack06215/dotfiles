return {
  filetypes = { "sh", "zsh" }, -- attach to zsh too
  settings = {
    bashIde = {
      -- widen glob so bashls considers zsh-ish filenames
      globPattern = "**/*@(.sh|.bash|.zsh|zshrc|*.zshrc|zsh_*|.zsh_*)",
    },
  },
}
