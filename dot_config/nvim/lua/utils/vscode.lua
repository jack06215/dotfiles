-- Helpers for code that only runs under vscode-neovim (vim.g.vscode).
--
-- Require this behind a vim.g.vscode check: the `vscode` module it wraps comes
-- from the extension's runtime directory, not from any plugin, so a plain nvim
-- has no such module.
local vscode = require("vscode")

local M = {}

---Transient status-bar message. vim.notify becomes a VS Code toast here, and a
---toast per toggle or per hardtime hint piles up in the corner fast.
---@param msg string may use VS Code's $(codicon) syntax
---@param ms? integer how long it stays up, default 3000
function M.status(msg, ms)
  vscode.eval_async("vscode.window.setStatusBarMessage(args.msg, args.ms)", {
    args = { msg = msg, ms = ms or 3000 },
  })
end

---Flip a VS Code setting between two values, in the user settings.json.
---
---That file is a symlink to ~/.config/vscode/settings.json, the chezmoi target,
---so the flip shows up in `chezmoi diff` and the next `chezmoi apply` reverts
---it -- the same as VS Code's own UI toggles, which write there too.
---@param name string setting key
---@param on any the value that counts as "on"; anything else flips to it
---@param off any
---@param label string shown in the status bar
function M.toggle_config(name, on, off, label)
  local value = vscode.get_config(name) == on and off or on
  vscode.update_config(name, value, "global")
  M.status(("%s: %s"):format(label, tostring(value)), 2000)
end

---Active editor's path relative to its workspace folder.
---
---nvim's own `:.` modifier is no use here: vscode-neovim never sets nvim's cwd,
---so it is wherever the extension host happened to start (often `/`).
---@return string?
function M.relative_path()
  local path = vscode.eval([[
    const editor = vscode.window.activeTextEditor;
    return editor ? vscode.workspace.asRelativePath(editor.document.uri, false) : null;
  ]])
  if path == nil or path == vim.NIL then
    return nil
  end
  return path
end

return M
