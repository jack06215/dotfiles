local M = {}

M.create_keymaps = function()
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
end

return M
