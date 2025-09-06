local M = {}

M.create_keymaps = function()
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
end

return M
