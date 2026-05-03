return {
  {
    "junegunn/goyo.vim",
    cmd = { "Goyo" },
    init = function()
      vim.g.goyo_width = 100
      vim.g.goyo_height = "80%"
    end,
    config = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "GoyoEnter",
        callback = function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.spell = true
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          -- Optional: start limelight
          vim.cmd("silent! Limelight")
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "GoyoLeave",
        callback = function()
          vim.opt_local.wrap = false
          vim.opt_local.spell = false
          vim.opt_local.number = true
          vim.opt_local.relativenumber = true
          -- Optional: stop limelight
          vim.cmd("silent! Limelight!")
        end,
      })
    end,
  },
}
