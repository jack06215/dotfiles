return {
  { "folke/snacks.nvim", opts = { dashboard = { enabled = false } } },
  {
    dir = vim.fn.stdpath("config") .. "/lua/vendor/pokemon.nvim",
    name = "pokemon.nvim",
    lazy = true,
  },
  {
    "nvimdev/dashboard-nvim",
    lazy = false,

    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },

    opts = function()
      ----------------------------------------------------------------
      -- Shared Footer Info
      ----------------------------------------------------------------
      local function get_footer_text()
        local today = os.date("%Y-%m-%d (%A)")
        local pc_name = vim.loop.os_gethostname()
        local v = vim.version()

        local nvim_version = string.format("NVIM v%d.%d.%d", v.major, v.minor, v.patch)

        return "[ @" .. pc_name .. " with " .. nvim_version .. " | " .. today .. " ]"
      end
      ----------------------------------------------------------------
      -- Neovim Logo Header
      ----------------------------------------------------------------
      local function get_header(text)
        local big_text_convert = require("utils.big_text_convert")

        local lines = {}

        table.insert(lines, "")

        for _, line in ipairs(big_text_convert.big_text(text)) do
          table.insert(lines, line)
        end

        table.insert(lines, "")
        table.insert(lines, get_footer_text())
        table.insert(lines, "")

        return lines
      end

      ----------------------------------------------------------------
      -- Pokemon Header
      -- examples:
      -- get_pokemon("0025")
      -- get_pokemon("0001")
      -- get_pokemon("random")
      ----------------------------------------------------------------
      local function get_pokemon(pokedex)
        local pokemon = require("pokemon")
        pokemon.setup({
          number = pokedex or "random",
          size = "auto",
        })
        local poke = pokemon.header()
        --------------------------------------------------------------
        -- pokemon.setup() already loads metadata into:
        -- pokemon.pokemon
        --------------------------------------------------------------
        local pokemon_name = "Pokemon"
        if pokemon.pokemon and pokemon.pokemon.name then
          pokemon_name = pokemon.pokemon.name
        end

        local big_text_convert = require("utils.big_text_convert")
        table.insert(poke, "")
        for _, line in ipairs(big_text_convert.big_text(pokemon_name)) do
          table.insert(poke, line)
        end
        table.insert(poke, "")
        table.insert(poke, get_footer_text())

        return poke
      end

      ----------------------------------------------------------------
      -- CHANGE THIS ONLY
      ----------------------------------------------------------------
      local header = get_pokemon("random")
      -- local header = get_pokemon("0025")
      -- local header = get_header("neovim")

      local opts = {
        theme = "doom",

        hide = {
          statusline = false,
        },

        config = {
          header = header,

          center = {
            { action = 'lua LazyVim.pick("projects")()', desc = " Projects", icon = " ", key = "p" },
            { action = "lua LazyVim.pick()()", desc = " Find File", icon = " ", key = "f" },
            { action = "ene | startinsert", desc = " New File", icon = " ", key = "n" },
            { action = 'lua LazyVim.pick("oldfiles")()', desc = " Recent Files", icon = " ", key = "r" },
            { action = 'lua LazyVim.pick("live_grep")()', desc = " Find Text", icon = " ", key = "g" },
            { action = "lua LazyVim.pick.config_files()()", desc = " Config", icon = " ", key = "c" },
            { action = 'lua require("persistence").load()', desc = " Restore Session", icon = " ", key = "s" },
            { action = "LazyExtras", desc = " Lazy Extras", icon = " ", key = "x" },
            { action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
            {
              action = function()
                vim.cmd("qa")
              end,
              desc = " Quit",
              icon = " ",
              key = "q",
            },
          },

          footer = function()
            local stats = require("lazy").stats()
            local ms = math.floor(stats.startuptime * 100 + 0.5) / 100

            return {
              "⚡ Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms",
            }
          end,
        },
      }

      for _, button in ipairs(opts.config.center) do
        button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
        button.key_format = "  %s"
      end

      if vim.o.filetype == "lazy" then
        vim.api.nvim_create_autocmd("WinClosed", {
          pattern = tostring(vim.api.nvim_get_current_win()),
          once = true,
          callback = function()
            vim.schedule(function()
              vim.api.nvim_exec_autocmds("UIEnter", {
                group = "dashboard",
              })
            end)
          end,
        })
      end

      return opts
    end,
  },
}
