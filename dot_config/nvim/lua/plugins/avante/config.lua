return {
  {
    "yetone/avante.nvim", -- now avante-corp/avante.nvim; GitHub redirects
    -- A string, not a function: lazy.nvim calls a build function and ignores
    -- what it returns, so returning "make" never builds anything.
    build = vim.fn.has("win32") == 1 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or {
        -- Downloads the release libs. Not `make`, whatever upstream's README
        -- says: the Makefile only compiles from source, which needs cargo.
        -- `:AvanteBuild source=true` is that path.
        ":AvanteBuild",
        -- The v0.4.0 macOS release libs link libiconv from the CI's /nix/store,
        -- so dlopen fails and avante reports "missing avante_templates". Point
        -- them at the system libiconv and re-sign; a no-op once upstream fixes it.
        vim.fn.has("mac") == 1
            and [[for f in lua/avante_*.so; do old=$(otool -L "$f" | awk '/\/nix\/store\/.*libiconv/ {print $1}'); [ -z "$old" ] || { install_name_tool -change "$old" /usr/lib/libiconv.2.dylib "$f" && codesign --force -s - "$f"; }; done]]
          or nil,
      },
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    ---@module 'avante'
    ---@type avante.Config
    opts = {
      mode = "agentic",
      provider = "copilot",
      providers = {
        copilot = {
          -- Avante's default is gpt-4o-2024-11-20. IDs come from Copilot's
          -- /models endpoint, so check what your plan exposes with <leader>a?
          model = "claude-opus-5.5",
        },
      },
      -- Leave inline completion to copilot.lua: Avante warns that using
      -- copilot here floods the API (yetone/avante.nvim#1048).
      auto_suggestions_provider = nil,
      behaviour = {
        auto_suggestions = false,
        -- Default is false; true lets the agent read .env and other ignored files.
        allow_access_to_git_ignored_files = false,
        -- Default (true) runs bash and writes files without asking. Auto-approve
        -- read-only tools and confirm everything else.
        auto_approve_tool_permissions = { "view", "ls", "glob", "grep", "get_diagnostics" },
      },
      -- LazyVim ships snacks; the native selector is broken alongside blink.cmp.
      -- Our own snacks provider: avante's re-reads every matching file per key.
      selector = {
        provider = function(selector)
          require("plugins.avante.selector")(selector)
        end,
      },
      input = { provider = "snacks" },
      -- Avante's own tools stay on; mcphub's overlapping "neovim" server is off
      -- instead (nativeMCPServers.neovim.disabled in ~/.config/mcphub/servers.json).
      disabled_tools = {},
      -- MCP via mcphub.nvim (extensions.avante is already on in plugins/mcphub).
      -- Functions, so the prompt tracks running servers and mcphub loads first.
      system_prompt = function()
        local ok, mcphub = pcall(require, "mcphub")
        local hub = ok and mcphub.get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ""
      end,
      custom_tools = function()
        local ok, ext = pcall(require, "mcphub.extensions.avante")
        return ok and { ext.mcp_tool() } or {}
      end,
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      { "ColinKennedy/mega.cmdparse", dependencies = { "ColinKennedy/mega.logging" } },
      "folke/snacks.nvim", -- selector + input
      "zbirenbaum/copilot.lua", -- provides the OAuth token in ~/.config/github-copilot
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
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
  {
    -- @file / @codebase mentions, /commands and #shortcuts in the Avante input
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "Kaiser-Yang/blink-cmp-avante" },
    opts = {
      sources = {
        per_filetype = {
          AvanteInput = { inherit_defaults = true, "avante" },
        },
        providers = {
          avante = { module = "blink-cmp-avante", name = "Avante" },
        },
      },
    },
  },
}
