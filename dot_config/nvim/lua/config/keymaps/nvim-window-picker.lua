local M = {}

M.create_keymaps = function()
  vim.keymap.set("n", "<leader>wp", function()
    local ok, picker = pcall(require, "window-picker")
    if not ok then
      vim.notify("window-picker not available", vim.log.levels.ERROR)
      return
    end

    local picked = picker.pick_window()

    if picked then
      vim.api.nvim_set_current_win(picked)
    else
      vim.notify("No window selected", vim.log.levels.INFO)
    end
  end, { desc = "Pick window" })
end

return M
