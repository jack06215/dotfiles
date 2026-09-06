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

---@class neotree.FileDetailAction
---@field key string The key to press inside the popup, e.g. "cp"
---@field label string Shown in the popup footer next to the key
---@field handler fun(node: NuiTree.Node) Receives the node the popup describes
---@field keep_open boolean? Leave the popup open afterwards (default: close it)
---@field hint_only boolean? Only render the hint row, do not bind the key

---Extra keys bound inside the File Details popup.
---@type neotree.FileDetailAction[]
M.file_detail_actions = {
  {
    key = "cp",
    label = "copy_path",
    handler = function(node)
      M.copy_path(node.path)
    end,
  },
  -- {
  --   key = "pr",
  --   label = "print('hello')",
  --   handler = function(node)
  --     vim.notify("hello", vim.log.levels.INFO, { title = "Print Hello" })
  --   end,
  --   keep_open = true,
  -- },
  {
    -- NOTE: already handled by neo-tree -- popups.alert() maps <Esc> and <CR> to
    -- close the popup itself
    key = "<Esc>/<CR>",
    label = "close",
    hint_only = true,
    handler = function() end,
  },
}

---Binds `M.file_detail_actions` in the popup and rewrites its footer to match.
---@param bufnr integer The popup buffer
---@param node NuiTree.Node The node the popup describes
local show_file_detail_apply_actions = function(bufnr, node)
  -- pad the key column so every `->` lines up
  local key_width = 0
  for _, action in ipairs(M.file_detail_actions) do
    key_width = math.max(key_width, vim.fn.strdisplaywidth(action.key))
  end
  local function row(key, label)
    local padding = string.rep(" ", key_width - vim.fn.strdisplaywidth(key))
    return " " .. key .. padding .. " -> " .. label
  end

  local hints = { " Custom Actions:" }
  for _, action in ipairs(M.file_detail_actions) do
    hints[#hints + 1] = row(action.key, action.label)
    if not action.hint_only then
      vim.keymap.set("n", action.key, function()
        action.handler(node)
        if not action.keep_open then
          pcall(vim.api.nvim_win_close, 0, true)
        end
      end, { buffer = bufnr, nowait = true, desc = action.label })
    end
  end

  -- swap the single "Press <Escape>..." line for the header plus one line per action
  for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if line:match("Press <Escape>") then
      pcall(vim.api.nvim_buf_set_lines, bufnr, i - 1, i, false, hints)
      break
    end
  end

  -- the popup sized itself around the single footer line it started with, so it is
  -- now both too short and possibly too narrow for the rows we just wrote
  local winid = vim.fn.bufwinid(bufnr)
  if winid ~= -1 then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local width = 0
    for _, line in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    pcall(vim.api.nvim_win_set_width, winid, math.max(vim.api.nvim_win_get_width(winid), width + 2))
    pcall(vim.api.nvim_win_set_height, winid, #lines)
  end
end

---Shows neo-tree's File Details popup with `M.file_detail_actions` bound inside it.
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
  -- Append actions list hints
  show_file_detail_apply_actions(vim.api.nvim_get_current_buf(), node)
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
