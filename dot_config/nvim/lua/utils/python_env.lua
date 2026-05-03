local util = require("lspconfig.util")
local M = { _path = nil, _name = nil }

-- internal detection
local function detect()
  local cwd = vim.fn.getcwd()

  -- 1) locate project root by .git, pyproject.toml or .venv
  local project_root = util.root_pattern(".git", "pyproject.toml", ".venv")(cwd) or cwd

  local sys = vim.loop.os_uname().sysname
  local is_wsl = sys == "Linux" and vim.fn.has("wsl") == 1

  ------------------------------------------------------------------
  -- 2) Poetry venv (works in WSL)
  ------------------------------------------------------------------
  local poetry_cmd = "cd " .. project_root .. " && poetry env info -p"
  local p = vim.fn.trim(vim.fn.system(poetry_cmd))

  if vim.v.shell_error == 0 and p ~= "" then
    local bin = sys == "Windows_NT" and (p .. "\\Scripts\\python.exe") or (p .. "/bin/python")

    return bin, vim.fn.fnamemodify(p, ":t")
  end

  ------------------------------------------------------------------
  -- 3) .venv in project root
  ------------------------------------------------------------------
  local sep = sys == "Windows_NT" and "\\" or "/"
  local venv_dir = project_root .. sep .. ".venv"

  if vim.fn.isdirectory(venv_dir) == 1 then
    local bin = venv_dir .. sep .. (sys == "Windows_NT" and "Scripts\\python.exe" or "bin/python")

    return bin, vim.fn.fnamemodify(bin, ":t")
  end

  ------------------------------------------------------------------
  -- 4) WSL2 (force Linux python, never Windows shims)
  ------------------------------------------------------------------
  if is_wsl then
    local exe = vim.fn.exepath("python3")
    if exe ~= "" then
      return exe, "wsl-python3"
    end
  end

  ------------------------------------------------------------------
  -- 5) Termux on Android
  ------------------------------------------------------------------
  if sys == "Linux" and vim.fn.has("android") == 1 and vim.fn.executable("termux-setup-storage") == 1 then
    return "/data/data/com.termux/files/usr/bin/python", "termux-python"
  end

  ------------------------------------------------------------------
  -- 6) fallback to python3 → python
  ------------------------------------------------------------------
  local exe = vim.fn.exepath("python3")
  if exe == "" then
    exe = vim.fn.exepath("python")
  end

  return exe ~= "" and exe or "python3", exe ~= "" and vim.fn.fnamemodify(exe, ":t") or "python3"
end

-- public: force re-detect
function M.update()
  M._path, M._name = detect()

  -- make Neovim provider stable (important for Mason/LSP)
  if M._path then
    vim.g.python3_host_prog = M._path
  end
end

-- public: get full path
function M.get_path()
  if not M._path then
    M.update()
  end
  return M._path
end

-- public: get display name
function M.get_name()
  if not M._name then
    M.update()
  end
  return M._name
end

return M
