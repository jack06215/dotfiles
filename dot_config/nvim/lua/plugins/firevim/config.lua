return {
  {
    "glacambre/firenvim",
    -- Not on WSL2: the browser is a Windows app, and firenvim#install() run
    -- from WSL rewrites %LOCALAPPDATA%\firenvim and the HKCU native-messaging
    -- keys on every build.
    -- Not under vscode-neovim either: a spec's own `cond` replaces the LazyVim
    -- vscode extra's whitelist check instead of adding to it, so without this
    -- it would load inside VS Code.
    cond = vim.fn.has("wsl") == 0 and not vim.g.vscode,
    build = ":call firenvim#install(0)",
  },
}
