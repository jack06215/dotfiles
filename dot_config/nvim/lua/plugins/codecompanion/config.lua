return {
  "olimorris/codecompanion.nvim",
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  dependencies = {
    "j-hui/fidget.nvim",
    "ravitemer/codecompanion-history.nvim",
    {
      "ravitemer/mcphub.nvim",
      cmd = "MCPHub",
      build = "npm install -g mcp-hub@latest",
      config = true,
    },
    {
      "Davidyz/VectorCode",
      version = "*",
      -- Keeps the vectorcode CLI in step with the plugin. `pip upgrade` is not
      -- a pip command, so the old build step failed on every update; this
      -- upgrades through whichever tool installed it and is a no-op where the
      -- CLI (or both tools) are absent.
      build = function()
        if vim.fn.executable("vectorcode") == 0 then
          return
        end
        if vim.fn.executable("uv") == 1 then
          vim.fn.system({ "uv", "tool", "upgrade", "vectorcode" })
        elseif vim.fn.executable("pipx") == 1 then
          vim.fn.system({ "pipx", "upgrade", "vectorcode" })
        end
      end,
      dependencies = { "nvim-lua/plenary.nvim" },
    },
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      cmd = "PasteImage",
      opts = {
        filetypes = {
          codecompanion = {
            prompt_for_file_name = false,
            template = "[image]($FILE_PATH)",
            use_absolute_path = true,
          },
        },
      },
    },
  },
  opts = {
    extensions = {
      history = {
        enabled = true,
        opts = {
          keymap = "gh",
          save_chat_keymap = "sc",
          auto_save = false,
          auto_generate_title = true,
          continue_last_chat = false,
          delete_on_clearing_chat = false,
          picker = "snacks",
          enable_logging = false,
          dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
        },
      },
      mcphub = {
        callback = "mcphub.extensions.codecompanion",
        opts = {
          make_vars = true,
          make_slash_commands = true,
          show_result_in_chat = true,
        },
      },
      vectorcode = {
        opts = {
          add_tool = true,
        },
      },
    },
    adapters = {
      copilot = function()
        return require("codecompanion.adapters").extend("copilot", {
          -- Ensure copilot is installed and configured externally
        })
      end,
      ollama = function()
        return require("codecompanion.adapters").extend("ollama", {
          schema = {
            model = { default = "qwen3:latest" },
            num_ctx = { default = 20000 },
          },
        })
      end,
    },
    strategies = {
      chat = {
        adapter = {
          name = "copilot",
          model = "claude-sonnet-4", -- Replace if unsupported
        },
        roles = {
          user = "jack06215",
        },
        keymaps = {
          send = {
            modes = {
              i = { "<C-CR>", "<C-s>" },
            },
          },
          completion = {
            modes = {
              i = "<C-x>",
            },
          },
        },
        slash_commands = {
          ["buffer"] = { keymaps = { modes = { i = "<C-b>" } } },
          ["fetch"] = { keymaps = { modes = { i = "<C-f>" } } },
          ["help"] = { opts = { max_lines = 1000 } },
          ["image"] = {
            keymaps = { modes = { i = "<C-i>" } },
            -- Where screenshots land: macOS's own folder, or Windows' on WSL2
            -- ($WIN_HOME comes from ~/.zshenv there).
            opts = {
              dirs = {
                vim.env.WIN_HOME and (vim.env.WIN_HOME .. "/Pictures/Screenshots") or "~/Documents/Screenshots",
              },
            },
          },
        },
      },
      inline = {
        adapter = {
          name = "copilot",
          model = "gpt-4.1",
        },
      },
    },
    display = {
      action_palette = {
        provider = "default",
      },
      diff = {
        provider = "mini_diff",
      },
    },
    opts = {
      log_level = "DEBUG",
    },
  },
  -- Keys have been moved to `keymaps.lua`
  init = function()
    vim.cmd([[cab cc CodeCompanion]])
  end,
}
