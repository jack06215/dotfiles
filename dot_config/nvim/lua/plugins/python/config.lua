-- Tell LazyVim to use plain “pyright” for Python LSP
vim.g.lazyvim_python_lsp = "pyright"

local python_env = require("utils.python_env")

return {
  -- Treesitter: support requirements.txt
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "requirements" })
      end
    end,
  },

  -- Manage & upgrade entries in requirements.txt. Also loads for pyproject.toml,
  -- where K (hover) and diagnostics work but upgrades don't: the plugin can't
  -- place edits inside Poetry tables yet.
  {
    "MeanderingProgrammer/py-requirements.nvim",
    event = { "BufRead requirements*.txt", "BufRead pyproject.toml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    -- Final releases only: an "rc"/"post" part is a string to the plugin's
    -- Version, and comparing it against a number (the ranges below) errors.
    opts = { filter = { final_release = true } },
    config = function(_, opts)
      -- On open the plugin starts one curl per dependency, all at once.
      -- pyproject.toml's ~125 of them exhaust macOS's default 256 file
      -- descriptors (EMFILE, which also takes gitsigns down), so queue the
      -- async requests. The sync call behind K (hover) is left alone.
      local curl = require("py-requirements.lib.curl")
      local get = curl.get
      local max_running, running, queue = 16, 0, {}

      local function drain()
        while running < max_running and #queue > 0 do
          local job = table.remove(queue, 1)
          running = running + 1
          local ok = pcall(get, job.endpoint, job.headers, function(out)
            running = running - 1
            drain()
            job.callback(out)
          end)
          if not ok then
            running = running - 1
            job.callback(nil)
          end
        end
      end

      curl.get = function(endpoint, headers, callback)
        if not callback then
          return get(endpoint, headers)
        end
        queue[#queue + 1] = { endpoint = endpoint, headers = headers, callback = callback }
        drain()
      end

      -- The plugin reads a Poetry entry by gluing key and value into a
      -- requirements.txt line ("fastapi^0.143.0") and parsing that. "^", "~"
      -- and bare versions aren't PEP 508, so the parse often comes back with
      -- the version as the name and PyPI 404s ("Error fetching versions").
      -- Take the name from the key and translate the constraint instead.
      local toml = require("py-requirements.parser.toml")
      local requirements = require("py-requirements.parser.requirements")

      -- Upper bound for ^ and ~: bump part i, drop the rest.
      local function bump(parts, i)
        local upper = { unpack(parts, 1, i - 1) }
        upper[i] = parts[i] + 1
        return table.concat(upper, ".")
      end

      local function to_pep440(constraint)
        if constraint:find("||", 1, true) then
          return "" -- PEP 440 has no "or": leave it unconstrained
        end
        local specs = {}
        for piece in vim.gsplit(constraint, ",", { plain = true, trimempty = true }) do
          piece = vim.trim(piece)
          local op, version = piece:match("^([~^]?)(%d[%w.*+!-]*)$")
          if not version then
            if piece ~= "*" then
              specs[#specs + 1] = piece -- already PEP 440: >=, ~=, ...
            end
          elseif op == "" then
            specs[#specs + 1] = "==" .. version
          else
            local release = version:match("^[%d.]*%d")
            local parts = vim.tbl_map(tonumber, vim.split(release, ".", { plain = true }))
            local i = #parts
            if op == "^" then
              -- ^1.2.3 -> <2, ^0.143.0 -> <0.144, ^0.0.3 -> <0.0.4
              for j, part in ipairs(parts) do
                if part ~= 0 then
                  i = j
                  break
                end
              end
            else
              -- ~1.2.3 -> <1.3, ~1 -> <2
              i = math.min(i, 2)
            end
            specs[#specs + 1] = ">=" .. version
            specs[#specs + 1] = "<" .. bump(parts, i)
          end
        end
        -- K (hover) fetches the description of the last spec's version, so
        -- end on one naming a real release (>=, ==) rather than a bound.
        local bounds, releases = {}, {}
        for _, spec in ipairs(specs) do
          table.insert(spec:match("^[<!]") and bounds or releases, spec)
        end
        return table.concat(vim.list_extend(bounds, releases), ",")
      end

      toml.parse_poetry = function(buf, root)
        local key, value = root:named_child(0), root:named_child(1)
        if not key or not value then
          return nil
        end
        local name = vim.treesitter.get_node_text(key, buf)
        if value:type() == "inline_table" then
          local version = nil
          for pair in value:iter_children() do
            local field = pair:named_child(0)
            if field and vim.treesitter.get_node_text(field, buf) == "version" then
              version = pair:named_child(1)
            end
          end
          value = version -- nil for path/git/url dependencies: not on PyPI
        end
        if name == "python" or not value or value:type() ~= "string" then
          return nil
        end
        local constraint = vim.treesitter.get_node_text(value, buf):sub(2, -2)
        local pack = requirements.line(name .. to_pep440(constraint) .. "\n")
        if pack then
          -- Column nil, as upstream does: upgrades can't write into the table.
          pack:shift(value:range(), nil)
        end
        return pack
      end

      require("py-requirements").setup(opts)
    end,
    keys = {
      {
        "<leader>pyu",
        function()
          require("py-requirements").upgrade()
        end,
        desc = "Update Package",
      },
      {
        "<leader>pyi",
        function()
          require("py-requirements").show_description()
        end,
        desc = "Package Info",
      },
      {
        "<leader>pya",
        function()
          require("py-requirements").upgrade_all()
        end,
        desc = "Update All Packages",
      },
    },
  },

  -- nvim-cmp: add both py-requirements & emoji sources
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    opts = function(_, opts)
      table.insert(opts.sources, { name = "py-requirements" })
    end,
  },

  -- LSPConfig: configure pyright to use our cached pythonPath
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          -- Resolved when pyright starts, not while lazy.nvim reads this spec:
          -- get_path() runs `poetry env info`, which cost ~300ms of every
          -- startup even in sessions that never open a Python file.
          before_init = function(_, config)
            config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
              python = { pythonPath = python_env.get_path() },
            })
          end,
        },
      },
    },
  },
}
