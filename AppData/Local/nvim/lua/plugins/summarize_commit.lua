local config_path = vim.fn.stdpath("config")

return {
  dir = config_path .. "/lua/utils",
  keys = {
    {
      "<leader>ail",
      function()
        require("utils.summarize_commit").summarize_commit_ollama()
      end,
      desc = "[Ollama] Summarize commit",
    },
    -- {
    --   "<leader>aio",
    --   function()
    --     require("utils.summarize_commit").summarize_commit_openai()
    --   end,
    --   desc = "[OpenAI] Summarize commit",
    -- },
  },
}