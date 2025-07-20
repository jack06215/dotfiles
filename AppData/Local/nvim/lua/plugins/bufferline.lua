return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  opts = {
    options = {
      mode = "buffers",
      numbers = function(opts)
        return string.format("[%d]", opts.ordinal)
      end,
      diagnostics = "nvim_lsp",
      separator_style = "slant",
      show_buffer_close_icons = false,
      show_close_icon = false,
      always_show_bufferline = true,
    },
  },
}
