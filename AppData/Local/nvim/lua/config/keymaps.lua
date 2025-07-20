-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- General Keymaps
vim.keymap.set("n", "<leader>ul", function()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Toggle Relative Line Numbers" })

vim.keymap.set("n", "<leader>bo", function()
  vim.cmd("%bd|e#")
end, { desc = "Delete Other Buffers" })

vim.keymap.set("n", "<leader>bx", function()
  local choice = vim.fn.confirm("[WARM] Delete ALL buffers?", "&Yes\n&No", 2)
  if choice == 1 then
    vim.cmd(":%bd")
  end
end, { desc = "Delete All Buffers (Confirm)" })

vim.keymap.set("n", "<leader>bb", function()
  vim.cmd("b#")
end, { desc = "Switch to Last Buffer" })

vim.keymap.set("n", "<leader>b#", function()
  vim.cmd(":echo bufnr('%')")
end, { desc = "Current Buffer Number" })

for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, function()
    local buffers = require("bufferline.state").components
    local bufnr = buffers[i] and buffers[i].id
    if bufnr then
      vim.api.nvim_set_current_buf(bufnr)
    else
      vim.notify("No buffer " .. i, vim.log.levels.WARN)
    end
  end, { desc = "Go to bufferline buffer " .. i })
end

vim.keymap.set("n", "<leader>fp", function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("No file path", vim.log.levels.WARN)
  else
    local rel_path = vim.fn.fnamemodify(path, ":.p")
    vim.fn.setreg("+", rel_path) -- Copy to system clipboard
    print("Copied: " .. rel_path)
  end
end, { desc = "Copy Relative Path to Clipboard" })

vim.keymap.set("n", "<leader>pycm", function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("No file associated with current buffer", vim.log.levels.ERROR)
  else
    local rel_root = vim.fn.fnamemodify(path, ":.:r") -- relative path, no extension
    local dot_path = rel_root:gsub("/", ".")
    vim.fn.setreg("+", dot_path) -- copy to system clipboard
    vim.notify("Copied to clipboard: " .. dot_path, vim.log.levels.INFO)
  end
end, { desc = "Copy Python Module Name" })

-- Delete buffers to the right of current buffer
vim.keymap.set("n", "<leader>br", function()
  local current = vim.api.nvim_get_current_buf()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  local found = false
  for _, buf in ipairs(bufs) do
    if found and buf.bufnr ~= current then
      vim.cmd("bd " .. buf.bufnr)
    end
    if buf.bufnr == current then
      found = true
    end
  end
end, { desc = "Delete Buffers to the Right" })

-- Delete buffers to the left of current buffer
vim.keymap.set("n", "<leader>bl", function()
  local current = vim.api.nvim_get_current_buf()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  for _, buf in ipairs(bufs) do
    if buf.bufnr == current then
      break
    end
    vim.cmd("bd " .. buf.bufnr)
  end
end, { desc = "Delete Buffers to the Left" })

-- LazyVim
vim.keymap.del("n", "<leader>gG")

-- Neogit
vim.keymap.set("n", "<leader>gg", function()
  require("neogit").open()
end, { desc = "Open Neogit" })

-- Package Info
-- Package Info keymaps (only active in JSON files)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function()
    local pkg = require("package-info")
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true, buffer = true }

    map("n", "<leader>ns", pkg.show, vim.tbl_extend("force", opts, { desc = "Show package versions" }))
    map("n", "<leader>nc", pkg.hide, vim.tbl_extend("force", opts, { desc = "Clear package versions" }))
    map("n", "<leader>nu", pkg.update, vim.tbl_extend("force", opts, { desc = "Update dependency" }))
    map("n", "<leader>nd", pkg.delete, vim.tbl_extend("force", opts, { desc = "Delete dependency" }))
    map("n", "<leader>ni", pkg.install, vim.tbl_extend("force", opts, { desc = "Install dependency" }))
    map("n", "<leader>np", pkg.change_version, vim.tbl_extend("force", opts, { desc = "Change dependency version" }))
  end,
})
