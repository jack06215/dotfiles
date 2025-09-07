return {
  "sQVe/sort.nvim",
  config = function()
    local sort = require("sort")
    sort.setup({
      delimiters = { ",", "|", ";", " " }, -- customizable
    })
  end,
  keys = require("plugins.sort.keymaps"),
  -- Keys have been moved to `keymaps.lua`
}
