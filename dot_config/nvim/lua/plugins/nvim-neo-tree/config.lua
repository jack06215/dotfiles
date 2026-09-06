local neo_tree = require("neo-tree")
local neo_tree_commands = require("neo-tree.sources.common.commands")
local neo_tree_events = require("neo-tree.events")

---@class neotree.UserCommands
---@field [string] neotree.TreeCommand
local M = {}

---Puts a path in the system clipboard and the unnamed register.
---@param path string The absolute path to copy
M.copy_path = function(path)
  vim.fn.setreg("+", path)
  vim.fn.setreg('"', path)
  vim.notify(path, vim.log.levels.INFO, { title = "Copied path" })
end

---Replaces the popup's "Press <Escape>..." footer with one that documents `cp`.
---@param bufnr integer The popup buffer
local set_popup_footer = function(bufnr)
  for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if line:match("Press <Escape>") then
      pcall(vim.api.nvim_buf_set_lines, bufnr, i - 1, i, false, { " cp copy path  <Esc>/<CR> close" })
      return
    end
  end
end

---Shows neo-tree's File Details popup with `cp` bound to copy the node's path.
---
---`popups.alert()` leaves the popup as the current window when it returns, so the
---mapping can be attached right afterwards. The popup buffer is bufhidden=delete,
---so the mapping is torn down along with it.
---@param state neotree.StateWithTree
M.show_file_details = function(state)
  local node = state.tree:get_node()
  if not node or node.type == "message" then
    return
  end
  neo_tree_commands.show_file_details(state)
  if vim.bo.filetype ~= "neo-tree-popup" then
    return -- popup did not open; don't map into the tree buffer
  end
  set_popup_footer(0)
  vim.keymap.set("n", "cp", function()
    M.copy_path(node.path)
    pcall(vim.api.nvim_win_close, 0, true)
  end, { buffer = 0, nowait = true, desc = "Copy absolute path" })
end

---Copies the current node's path without opening the details popup.
---@param state neotree.StateWithTree
M.copy_path_from_tree = function(state)
  local node = state.tree:get_node()
  if node then
    M.copy_path(node.path)
  end
end

---NOTE: neo-tree forces nonumber/norelativenumber on its own window on every buffer
---enter; re-enable them right after so the tree gets the same hybrid
---number/relativenumber style as the main editor.
M.restore_line_numbers = function()
  vim.wo.number = true
  vim.wo.relativenumber = true
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opt = { log_level = "warn" },
    config = function()
      neo_tree.setup({
        sources = { "filesystem" },
        -- NOTE: Names must not collide with neo-tree's built-ins. Duplicated
        -- name would be silently dropped in favour of the built-in.
        commands = {
          show_file_details_with_copy = M.show_file_details,
          copy_path_to_clipboard = M.copy_path_from_tree,
        },
        window = {
          mappings = {
            ["i"] = "show_file_details_with_copy",
            ["Y"] = "copy_path_to_clipboard",
          },
        },
        filesystem = {
          use_libuv_file_watcher = true,
          filtered_items = {
            hide_gitignored = false,
          },
          follow_current_file = {
            enabled = false,
          },
        },
        git_status = {
          enabled = false, -- 🔥 biggest speedup
        },
        event_handlers = {
          {
            event = neo_tree_events.NEO_TREE_BUFFER_ENTER,
            handler = M.restore_line_numbers,
          },
        },
      })
    end,
  },
  {
    -- NOTE: The commands above take a `neotree.StateWithTree`, whose `tree` field is a
    -- `NuiTree`. lazydev only loads a plugin's annotations when the file requires
    -- it, and this file never requires nui. Pull nui's types in whenever a
    -- file mentions a neo-tree type.
    "folke/lazydev.nvim",
    optional = true,
    opts = function(_, opts)
      -- append; a plain `opts` table would overwrite LazyVim's library entries
      table.insert(opts.library, { path = "nui.nvim", words = { "neotree%." } })
    end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- NOTE: Makes sure that this loads after Neo-tree.
      "nvim-neo-tree/neo-tree.nvim",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    config = function()
      require("window-picker").setup({
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          -- filter using buffer options
          bo = {
            -- if the file type is one of following, the window will be ignored
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            -- if the buffer type is one of following, the window will be ignored
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },
}
