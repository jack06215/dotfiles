local python_env = require("utils.python_env")

return {
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        typeCheckingMode = "basic",       -- or "strict"
      },
      pythonPath = python_env.get_path(), -- custom env detection
    },
  },
}
