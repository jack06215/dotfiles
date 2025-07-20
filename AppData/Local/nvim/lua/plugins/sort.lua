return {
  "sQVe/sort.nvim",
  config = function()
    require("sort").setup({
      delimiters = { ",", "|", ";", " " }, -- customizable
    })
  end,
  keys = {
    {
      "<leader>so",
      ":sort<CR>",
      mode = "v",
      desc = "Sort lines (ascending)",
    },
    {
      "<leader>sO",
      ":sort!<CR>",
      mode = "v",
      desc = "Sort lines (descending)",
    },
    {
      "<leader>SD",
      ":Sort<CR>",
      mode = "v",
      desc = "Smart sort (plugin)",
    },
  },
}
