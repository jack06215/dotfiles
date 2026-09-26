return {
  {
    "glacambre/firenvim",
    -- Not on WSL2: the browser is a Windows app, and firenvim#install() run
    -- from WSL rewrites %LOCALAPPDATA%\firenvim and the HKCU native-messaging
    -- keys on every build.
    cond = vim.fn.has("wsl") == 0,
    build = ":call firenvim#install(0)",
  },
}
