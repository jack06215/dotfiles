local function map(key)
  return "<Leader>t" .. key
end

-- No [e / ]e: LazyVim binds them to the previous and next diagnostic error.
-- lazy.nvim sets a plugin's keys again when the plugin loads, so a neotest
-- pair here would replace LazyVim's error jumps after the first test run.
return {
  {
    map("r"),
    function()
      require("neotest").run.run()
    end,
    desc = "Run Nearest Test",
  },
  {
    map("f"),
    function()
      require("neotest").run.run(vim.fn.expand("%"))
    end,
    desc = "Run File Tests",
  },
  {
    map("w"),
    function()
      require("neotest").watch.toggle()
    end,
    desc = "Watch Nearest Test",
  },
  {
    map("W"),
    function()
      require("neotest").watch.toggle(vim.fn.expand("%"))
    end,
    desc = "Watch File Tests",
  },
  {
    map("p"),
    function()
      require("neotest").output_panel.toggle()
    end,
    desc = "Toggle Test Output Panel",
  },
  {
    map("o"),
    function()
      require("neotest").output.open({ enter = false })
    end,
    desc = "Show Test Output",
  },
  {
    map("O"),
    function()
      require("neotest").output.open({ enter = true })
    end,
    desc = "Show Test Output (enter)",
  },
  {
    "[E",
    function()
      require("neotest").jump.prev({ status = "failed" })
    end,
    desc = "Prev Failed Test",
  },
  {
    "]E",
    function()
      require("neotest").jump.next({ status = "failed" })
    end,
    desc = "Next Failed Test",
  },
}
