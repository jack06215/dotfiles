return {
  "yetone/avante.nvim",
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- ⚠️ must add this setting! ! !
  build = function()
    local build_command = "make"
    if vim.fn.has("win32") == 1 then
      build_command = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    end
    return build_command
  end,
  event = "VeryLazy",
  version = false, -- Never set this value to "*"! Never!
  ---@module 'avante'
  ---@type avante.Config
  opts = {
    provider = "copilot", -- Default provider
    providers = {
      ollama = {
        endpoint = "http://127.0.0.1:11434", -- Specify endpoint without trailing /v1
        model = "qwen2.5-coder:latest",    -- Model version
      },
    },
    -- Additional options can be added here for future extensibility
  },
  dependencies = {
    -- Mandatory dependencies
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    
    -- Optional dependencies
    --- For file_selector providers
    "echasnovski/mini.pick",         -- Supports mini.pick
    "nvim-telescope/telescope.nvim", -- Supports telescope
    "ibhagwan/fzf-lua",              -- Supports fzf

    --- For input providers
    "stevearc/dressing.nvim",        -- Supports dressing
    "folke/snacks.nvim",             -- Supports snacks

    --- Others
    "nvim-tree/nvim-web-devicons",   -- Icons support
    "zbirenbaum/copilot.lua",        -- Required for providers='copilot'

    {
      -- Support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true, -- Required for Windows users
        },
      },
    },
    {
      -- Markdown rendering support
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
