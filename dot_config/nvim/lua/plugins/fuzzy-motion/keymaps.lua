return {
  keys = {
    {
      "<CR>",
      -- A global <CR> map replaces the built-in <CR> in special buffers too,
      -- so <CR> in a quickfix, help or command-line window would start
      -- FuzzyMotion instead of opening the entry. Those buffers have a
      -- buftype, so they get the built-in <CR> back.
      function()
        if vim.bo.buftype ~= "" then
          return "<CR>"
        end
        return "<Cmd>FuzzyMotion<CR>"
      end,
      mode = { "n", "v", "x" },
      expr = true,
      desc = "Fuzzy Motion",
    },
  },
}
