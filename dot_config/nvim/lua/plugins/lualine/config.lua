-- Utility for detecting & caching Python env (Poetry, .venv, system)
-- local python_env = require("utils.python_env")

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",

    opts = function(_, opts)
      ------------------------------------------------------------
      -- 📁 Current directory
      ------------------------------------------------------------
      local function current_directory()
        local cwd = vim.fn.getcwd()

        -- current folder
        local current = vim.fn.fnamemodify(cwd, ":t")

        -- parent folder
        local parent_path = vim.fn.fnamemodify(cwd, ":h")
        local parent = vim.fn.fnamemodify(parent_path, ":t")

        -- ~/ special case
        if cwd == vim.loop.os_homedir() then
          return "󰉋 ~"
        end

        -- if parent exists and is not root, show parent/current
        if parent ~= "" and parent ~= "/" and parent ~= "." then
          return "󰉋 " .. parent .. "/" .. current
        end

        return "󰉋 " .. current
      end

      ------------------------------------------------------------
      -- 🔧 Active LSP
      ------------------------------------------------------------
      local function active_lsp()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })

        if #clients == 0 then
          return "󰒋 none"
        end

        local names = {}

        for _, client in ipairs(clients) do
          table.insert(names, client.name)
        end

        return "󰒋 " .. table.concat(names, ",")
      end

      -- ------------------------------------------------------------
      -- --  Git branch
      -- ------------------------------------------------------------
      -- local function git_branch()
      --   local head = vim.b.gitsigns_head
      --   return head and head ~= "" and (" " .. head) or ""
      -- end

      ------------------------------------------------------------
      -- 🐍 Python env
      ------------------------------------------------------------
      local function python_env()
        if vim.bo.filetype ~= "python" then
          return ""
        end

        local env = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_DEFAULT_ENV")

        if not env then
          return ""
        end

        return "󰌠 " .. vim.fn.fnamemodify(env, ":t")
      end

      ------------------------------------------------------------
      -- Section
      ------------------------------------------------------------
      opts.sections.lualine_x = {
        -- git_branch,
        python_env,
        active_lsp,
        current_directory,
      }

      ------------------------------------------------------------
      -- UI
      ------------------------------------------------------------
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        globalstatus = true,
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
      })
    end,
  },
}
