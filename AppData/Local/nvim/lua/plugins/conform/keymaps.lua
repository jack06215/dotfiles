return {
  {
    "<leader>mp",
    function()
      require("conform").format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 3000,
      })
    end,
    mode = { "n", "v" },
    desc = "Format file or range (in visual mode)",
  },
}

