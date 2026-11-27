# firenvim

[glacambre/firenvim](https://github.com/glacambre/firenvim) puts Neovim into
text fields in the browser. The folder name is `firevim`, but the plugin is
firenvim.

After an install or an update, lazy.nvim runs `firenvim#install(0)`, which
registers firenvim with the browsers.

The plugin does not load in two cases:

- **WSL2.** The browser is a Windows app. `firenvim#install()` from WSL would
  rewrite `%LOCALAPPDATA%\firenvim` and the native-messaging registry keys at
  each build.
- **vscode-neovim.** The `cond` of this spec replaces the check of the LazyVim
  vscode extra. Without the `not vim.g.vscode` test, the plugin would load in VS
  Code.

The config is in [`config.lua`](config.lua).
