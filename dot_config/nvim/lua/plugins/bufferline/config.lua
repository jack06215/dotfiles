return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  opts = function()
    --------------------------------------------------------------------------
    -- Safe helpers
    --------------------------------------------------------------------------
    local function name(buf)
      return (buf.name or ""):lower()
    end

    -- plain substring search (safer than Lua patterns for paths)
    local function has(buf, text)
      return name(buf):find(text:lower(), 1, true) ~= nil
    end

    -- lua pattern search (for regex-like matching)
    local function has_pattern(buf, pattern)
      return name(buf):match(pattern) ~= nil
    end

    local function ext(buf, ...)
      local n = name(buf)
      for _, e in ipairs({ ... }) do
        e = e:gsub("%.", "%%.")
        if n:match("%." .. e .. "$") then
          return true
        end
      end
      return false
    end

    --------------------------------------------------------------------------
    -- Group theme (priority + color)
    --------------------------------------------------------------------------
    local GROUP = {
      TESTS = { priority = 9, color = "#83a598" },
      DOCS = { priority = 8, color = "#b8bb26" },
      BUILD = { priority = 7, color = "#fabd2f" },
      KUBERNETES = { priority = 6, color = "#d3869b" },
      NEOVIM = { priority = 5, color = "#458588" },
      BACKEND = { priority = 4, color = "#8ec07c" },
      CONFIG = { priority = 3, color = "#fb4934" },
      WEB = { priority = 2, color = "#fe8019" },
      SQL = { priority = 1, color = "#d79921" },
    }

    local function hl(group)
      return {
        underline = true,
        sp = group.color,
      }
    end

    --------------------------------------------------------------------------
    -- Config
    --------------------------------------------------------------------------
    return {
      options = {
        mode = "buffers",

        numbers = function(opts)
          return string.format("%s·%d", opts.raise(opts.id), opts.ordinal)
        end,

        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,

        diagnostics_indicator = function(count, level)
          local icon = level:match("error") and " " or " "
          return icon .. count
        end,

        separator_style = "slant",
        always_show_bufferline = true,
        show_buffer_close_icons = false,
        show_close_icon = false,

        truncate_names = true,
        max_name_length = 28,
        max_prefix_length = 18,

        sort_by = "insert_after_current",

        hover = {
          enabled = true,
          delay = 200,
          reveal = { "close" },
        },

        indicator = {
          style = "icon",
          icon = "▎",
        },

        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            highlight = "Directory",
            separator = true,
          },
        },

        ----------------------------------------------------------------------
        -- Groups
        ----------------------------------------------------------------------
        groups = {
          options = {
            toggle_hidden_on_enter = true,
          },

          items = {
            ------------------------------------------------------------------
            -- Tests
            ------------------------------------------------------------------
            {
              name = "Tests",
              priority = GROUP.TESTS.priority,
              highlight = hl(GROUP.TESTS),

              matcher = function(buf)
                local n = name(buf)

                return n:match("_test%.[%w]+$")
                  or n:match("%.test%.[%w]+$")
                  or n:match("%.spec%.[%w]+$")
                  or n:match("_spec%.[%w]+$")
                  or n:match("/tests?/")
              end,
            },

            ------------------------------------------------------------------
            -- Docs
            ------------------------------------------------------------------
            {
              name = "Docs",
              priority = GROUP.DOCS.priority,
              highlight = hl(GROUP.DOCS),

              matcher = function(buf)
                return ext(buf, "md", "txt", "rst")
                  or has(buf, "readme")
                  or has(buf, "license")
                  or has(buf, "claude.md")
              end,
            },

            ------------------------------------------------------------------
            -- Build / Bazel
            ------------------------------------------------------------------
            {
              name = "Build",
              priority = GROUP.BUILD.priority,
              highlight = hl(GROUP.BUILD),

              matcher = function(buf)
                return has(buf, "build.bazel")
                  or has(buf, "workspace")
                  or has(buf, "module.bazel")
                  or ext(buf, "bzl")
                  or has(buf, "justfile")
                  or has(buf, "makefile")
              end,
            },

            ------------------------------------------------------------------
            -- Kubernetes / Infra
            ------------------------------------------------------------------
            {
              name = "Kubernetes",
              priority = GROUP.KUBERNETES.priority,
              highlight = hl(GROUP.KUBERNETES),

              matcher = function(buf)
                return ext(buf, "tf", "tfvars", "hcl")
                  or has(buf, "/helm/")
                  or has(buf, "chart.yaml")
                  or has(buf, "values.yaml")
                  or has(buf, "values.yml")
                  or has(buf, "/k8s/")
                  or has(buf, "/kubernetes/")
                  or has(buf, "/clusters/")
                  or has(buf, "deployment.yaml")
                  or has(buf, "deployment.yml")
                  or has(buf, "service.yaml")
                  or has(buf, "service.yml")
                  or has(buf, "ingress.yaml")
                  or has(buf, "statefulset.yaml")
                  or has(buf, "daemonset.yaml")
                  or has(buf, "configmap.yaml")
                  or has(buf, "secret.yaml")
                  or has(buf, "dockerfile")
                  or has(buf, "docker-compose.yml")
                  or has(buf, "docker-compose.yaml")
                  or has(buf, "compose.yml")
                  or has(buf, "containerfile")
              end,
            },

            ------------------------------------------------------------------
            -- Neovim
            ------------------------------------------------------------------
            {
              name = "Neovim",
              priority = GROUP.NEOVIM.priority,
              highlight = hl(GROUP.NEOVIM),

              matcher = function(buf)
                if not ext(buf, "lua") then
                  return false
                end

                local filepath = buf.name or ""
                local dir = vim.fn.fnamemodify(filepath, ":p:h")

                return has(buf, "/nvim/")
                  or has(buf, "/lazy/")
                  or has(buf, ".config/nvim")
                  or vim.fn.filereadable(dir .. "/lazyvim.json") == 1
              end,
            },

            ------------------------------------------------------------------
            -- Backend
            ------------------------------------------------------------------
            {
              name = "Backend",
              priority = GROUP.BACKEND.priority,
              highlight = hl(GROUP.BACKEND),

              matcher = function(buf)
                local n = name(buf)
                local fullpath = vim.api.nvim_buf_get_name(buf.id):lower()

                if n:match("_test%.[%w]+$") or n:match("%.test%.[%w]+$") or n:match("%.spec%.[%w]+$") then
                  return false
                end

                if ext(buf, "py", "go", "rs", "rb", "java", "kt") then
                  return true
                end

                if ext(buf, "js", "ts", "mjs", "cjs") then
                  return (
                    fullpath:find("-api/", 1, true)
                    or fullpath:find("_api/", 1, true)
                    or fullpath:find("/api-", 1, true)
                    or fullpath:find("/api_", 1, true)
                    or fullpath:find("/api/", 1, true)
                    or fullpath:find("/backend/", 1, true)
                    or fullpath:find("/server/", 1, true)
                    or fullpath:find("/services/", 1, true)
                    or fullpath:find("/workers/", 1, true)
                    or fullpath:find("/lambda/", 1, true)
                    or fullpath:find("/functions/", 1, true)
                    or fullpath:find("/jobs/", 1, true)
                    or fullpath:find("/scripts/", 1, true)
                    or fullpath:find("/bin/", 1, true)
                    or fullpath:find("/cli/", 1, true)
                    or fullpath:find("/cmd/", 1, true)
                    or fullpath:find("/nestjs/", 1, true)
                    or fullpath:find("/express/", 1, true)
                    or fullpath:find("prisma", 1, true)
                    or fullpath:find("server.ts", 1, true)
                    or fullpath:find("server.js", 1, true)
                    or fullpath:find("main.ts", 1, true)
                    or fullpath:find("main.js", 1, true)
                    or fullpath:find("worker.ts", 1, true)
                    or fullpath:find("worker.js", 1, true)
                    or fullpath:find("nest-cli.json", 1, true)
                    or fullpath:find("tsconfig.server", 1, true)
                    or n:match("%.node%.[jt]s$")
                  ) ~= nil
                end

                return false
              end,
            },

            ------------------------------------------------------------------
            -- Config
            ------------------------------------------------------------------
            {
              name = "Config",
              priority = GROUP.CONFIG.priority,
              highlight = hl(GROUP.CONFIG),

              matcher = function(buf)
                return ext(buf, "json", "jsonc", "yaml", "yml", "toml", "ini", "conf", "cfg", "env", "lock", "jsonnet")
                  or has(buf, ".editorconfig")
                  or has(buf, ".gitignore")
                  or has(buf, ".gitattributes")
                  or has(buf, ".prettierrc")
                  or has(buf, ".eslintrc")
                  or has(buf, ".yamllint")
                  or has(buf, ".markdownlint")
                  or has(buf, "package.json")
                  or has(buf, "tsconfig.json")
                  or has(buf, "biome.json")
              end,
            },

            ------------------------------------------------------------------
            -- Frontend
            ------------------------------------------------------------------
            {
              name = "Web Console",
              priority = GROUP.WEB.priority,
              highlight = hl(GROUP.WEB),

              matcher = function(buf)
                local fullpath = vim.api.nvim_buf_get_name(buf.id):lower()

                if
                  fullpath:find("-api/", 1, true)
                  or fullpath:find("_api/", 1, true)
                  or fullpath:find("/api-", 1, true)
                  or fullpath:find("/api_", 1, true)
                  or fullpath:find("/api/", 1, true)
                then
                  return false
                end

                if
                  fullpath:match("%.jsx$")
                  or fullpath:match("%.tsx$")
                  or fullpath:match("%.vue$")
                  or fullpath:match("%.svelte$")
                then
                  return true
                end

                if
                  fullpath:match("%.css$")
                  or fullpath:match("%.scss$")
                  or fullpath:match("%.sass$")
                  or fullpath:match("%.less$")
                  or fullpath:match("%.html$")
                then
                  return true
                end

                if
                  fullpath:match("%.js$")
                  or fullpath:match("%.ts$")
                  or fullpath:match("%.jsx$")
                  or fullpath:match("%.tsx$")
                then
                  return (
                    fullpath:find("console", 1, true)
                    or fullpath:find("/frontend/", 1, true)
                    or fullpath:find("/web/", 1, true)
                    or fullpath:find("/ui/", 1, true)
                    or fullpath:find("/client/", 1, true)
                    or fullpath:find("/app/", 1, true)
                    or fullpath:find("/pages/", 1, true)
                    or fullpath:find("/components/", 1, true)
                    or fullpath:find("/hooks/", 1, true)
                    or fullpath:find("/stores/", 1, true)
                    or fullpath:find("/utils/", 1, true)
                    or fullpath:find("/assets/", 1, true)
                    or fullpath:find("vite.config", 1, true)
                    or fullpath:find("next.config", 1, true)
                    or fullpath:find("nuxt.config", 1, true)
                    or fullpath:find("tailwind.config", 1, true)
                  ) ~= nil
                end

                return false
              end,
            },

            ------------------------------------------------------------------
            -- SQL / Data
            ------------------------------------------------------------------
            {
              name = "SQL",
              priority = GROUP.SQL.priority,
              highlight = hl(GROUP.SQL),

              matcher = function(buf)
                return ext(buf, "sql", "jinja") or has(buf, ".sql.")
              end,
            },
          },
        },
      },
    }
  end,
}
