-- LazyVim default <leader> keymaps, re-declared as which-key spec entries.
--
-- Generated against LazyVim v16.0.0 (tag `stable`, commit c10948c). The active
-- surface for this config is:
--
--   * core            -- lazyvim.plugins.{keymaps,editor,ui,util,formatting,lsp}
--   * snacks_picker   -- auto-enabled: v16 falls back to the first entry of
--                        `checks.picker` when no picker extra is imported, so
--                        every <leader>f*/<leader>s*/<leader>g* picker key below
--                        comes from `editor.snacks_picker`, not telescope
--   * neo-tree        -- imported in config/lazy.lua:23
--   * typescript      -- imported in plugins/extras/config.lua:3, resolves to
--                        lang/typescript/vtsls.lua
--   * json            -- imported in plugins/extras/config.lua:4 (no leader keys)
--
-- which-key's `spec` is declared with `opts_extend = { "spec" }` upstream
-- (LazyVim/lua/lazyvim/plugins/editor.lua:61), so this list is APPENDED to
-- LazyVim's own group definitions rather than replacing them.
--
-- IMPORTANT: a which-key entry that carries an rhs is not just a label -- it
-- calls vim.keymap.set (which-key.nvim/lua/which-key/mappings.lua:303). So a
-- live entry here really is the binding, and editing it here rebinds the key.
-- The trade-off you accepted: these rhs values are copied from LazyVim's source
-- and will drift when LazyVim is upgraded. Re-derive them after a major bump.
--
-- Layering
-- --------
-- This file is the complete stock LazyVim baseline: every default is live,
-- including the ones this config replaces. Personal overrides are applied on
-- top afterwards, from lua/config/keymaps:
--
--   startup       lazy.nvim installs its lazy-load key stubs
--   VeryLazy      LazyVim's own config.keymaps runs
--   VeryLazy+n    which-key applies this spec  <- stock baseline lands here
--   after that    config/keymaps applies your overrides  <- these win
--
-- which-key applies its spec from a vim.schedule'd callback, which is why
-- config/keymaps.lua waits for `which-key.config`.loaded before applying (see
-- after_which_key() there). Without that wait the baseline would clobber your
-- overrides, not the other way round.
--
-- Legend
-- ------
--   live entry        the LazyVim default, applied by which-key.
--
--   -- overridden by <file> -- "<desc>"
--                     a live default that config/keymaps replaces afterwards.
--                     The comment names the file that wins. Delete that
--                     override to fall back to the default sitting right here.
--
--   -- [yours] ...    a key LazyVim never defines, listed so this file doubles
--                     as the full <leader> map. Its real home is named beside
--                     it; nothing here binds it.
--
--   -- [removed] ...  a LazyVim default that config/keymaps/lazyvim.lua deletes
--                     on VeryLazy.
--
--   -- [lsp] ...      buffer-local and capability-gated: attached on LspAttach
--                     through nvim-lspconfig `opts.servers['*'].keys`, with a
--                     `has = "<capability>"` guard. Left commented because a
--                     global copy would drop the guard and fire in buffers with
--                     no LSP client. Rebind these in an lspconfig opts override,
--                     not here.

return {
  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ Top level                                                            │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  {
    "<leader>.",
    function()
      Snacks.scratch()
    end,
    desc = "Toggle Scratch Buffer",
  },
  {
    "<leader>S",
    function()
      Snacks.scratch.select()
    end,
    desc = "Select Scratch Buffer",
  },
  {
    "<leader>,",
    function()
      Snacks.picker.buffers()
    end,
    desc = "Buffers",
  },
  {
    "<leader>/",
    function()
      LazyVim.pick.open("grep")
    end,
    desc = "Grep",
  },
  {
    "<leader>:",
    function()
      Snacks.picker.command_history()
    end,
    desc = "Command History",
  },
  -- {
  --   "<leader><space>",
  --   function()
  --     LazyVim.pick.open("files")
  --   end,
  --   desc = "Find Files (Root Dir)",
  -- },
  -- { "<leader>`", "<cmd>e #<cr>", desc = "Switch to Other Buffer" },
  {
    "<leader>n",
    function()
      Snacks.picker.notifications()
    end,
    desc = "Notification History",
  },
  {
    "<leader>?",
    function()
      require("which-key").show({ global = false })
    end,
    desc = "Buffer Keymaps",
  },
  {
    "<leader>L",
    function()
      LazyVim.news.changelog()
    end,
    desc = "LazyVim Changelog",
  },
  {
    "<leader>e",
    function()
      require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
    end,
    desc = "Explorer NeoTree",
  },
  -- [removed]
  -- { "<leader>E", "<leader>fE", desc = "Explorer NeoTree (cwd)", remap = true },
  { "<leader>-", "<C-W>s", desc = "Split Window Below", remap = true },
  { "<leader>|", "<C-W>v", desc = "Split Window Right", remap = true },
  -- [removed]
  -- { "<leader>l", "<cmd>Lazy<cr>", desc = "Lazy" },
  -- [removed]
  -- { "<leader>K", "<cmd>norm! K<cr>", desc = "Keywordprg" },

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ <leader>b -- buffer                                                  │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  {
    "<leader>bd",
    function()
      Snacks.bufdelete()
    end,
    desc = "Delete Buffer",
  },
  {
    "<leader>bi",
    function()
      Snacks.bufdelete.invisible()
    end,
    desc = "Delete Invisible Buffers",
  },
  { "<leader>bD", "<cmd>:bd<cr>", desc = "Delete Buffer and Window" },
  { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
  { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
  { "<leader>bj", "<cmd>BufferLinePick<cr>", desc = "Pick Buffer" },
  {
    "<leader>be",
    function()
      require("neo-tree.command").execute({ source = "buffers", toggle = true })
    end,
    desc = "Buffer Explorer",
  },

  -- overridden by config/keymaps/buffer.lua -- "Switch to Last Buffer"
  -- { "<leader>bb", "<cmd>e #<cr>", desc = "Switch to Other Buffer" },

  -- overridden by config/keymaps/buffer.lua -- "Delete Other Buffers" (%bd|e#)
  {
    "<leader>bo",
    function()
      Snacks.bufdelete.other()
    end,
    desc = "Delete Other Buffers",
  },

  -- overridden by config/keymaps/buffer.lua -- "Delete Buffers to the Right"
  -- { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },

  -- overridden by config/keymaps/buffer.lua -- "Delete Buffers to the Left"
  -- { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },

  -- [yours] config/keymaps/buffer.lua:8  -- <leader>bx "Delete All Buffers (Confirm)"
  -- [yours] config/keymaps/buffer.lua:19 -- <leader>b# "Current Buffer Number"

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ <leader>c -- code                                                    │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  {
    "<leader>cF",
    function()
      require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
    end,
    mode = { "n", "x" },
    desc = "Format Injected Langs",
  },
  { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" },
  { "<leader>cS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions/... (Trouble)" },

  -- overridden by config/keymaps/lspsaga.lua -- "LSP Finder"
  -- {
  --   "<leader>cf",
  --   function()
  --     LazyVim.format({ force = true })
  --   end,
  --   mode = { "n", "x" },
  --   desc = "Format",
  -- },

  -- overridden by config/keymaps/lspsaga.lua -- "Line Diagnostics" (Lspsaga)
  -- { "<leader>cd", vim.diagnostic.open_float, desc = "Line Diagnostics" },

  -- overridden by config/keymaps/lspsaga.lua -- "Signature Help"
  -- { "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },

  -- [lsp] capability-gated, attached per buffer -- see legend
  -- { "<leader>cl", function() Snacks.picker.lsp_config() end, desc = "Lsp Info" },
  -- { "<leader>cc", vim.lsp.codelens.run, mode = { "n", "x" }, desc = "Run Codelens" },        -- has = "codeLens"
  -- { "<leader>cC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens" },           -- has = "codeLens"
  -- { "<leader>cA", LazyVim.lsp.action.source, desc = "Source Action" },                       -- has = "codeAction"
  -- { "<leader>cM", LazyVim.lsp.action["source.addMissingImports.ts"], desc = "Add missing imports" },   -- vtsls
  -- { "<leader>cD", LazyVim.lsp.action["source.fixAll.ts"], desc = "Fix all diagnostics" },              -- vtsls
  -- { "<leader>cV", function() LazyVim.lsp.execute({ title = "Select TypeScript Version", filter = "vtsls", command = "typescript.selectTypeScriptVersion" }) end, desc = "Select TS workspace version" }, -- vtsls

  -- overridden by config/keymaps/lspsaga.lua -- "Code Action" (Lspsaga).
  -- plugins/ui/config.lua:37 also claims <leader>ca (actions-preview, "Code
  -- Action Preview") as a lazy `keys` entry; the config/keymaps layer runs last,
  -- so Lspsaga wins -- which is what happened before this file existed too.
  -- Global here, so it loses upstream's `has = "codeAction"` gate; harmless,
  -- because the override replaces it in every buffer anyway.
  -- { "<leader>ca", vim.lsp.buf.code_action, mode = { "n", "x" }, desc = "Code Action" },

  -- overridden by config/keymaps/lspsaga.lua -- "Rename" (Lspsaga)
  -- { "<leader>cr", vim.lsp.buf.rename, desc = "Rename" },

  -- overridden by config/keymaps/typescript.lua -- "Rename File" (TSToolsRenameFile).
  -- That override is buffer-local to TS buffers, so this global copy stays
  -- reachable elsewhere. Verified safe: Snacks.rename.rename_file() works with
  -- no LSP client attached.
  -- {
  --   "<leader>cR",
  --   function()
  --     Snacks.rename.rename_file()
  --   end,
  --   desc = "Rename File",
  -- },

  -- overridden by config/keymaps/typescript.lua -- "Organize Imports"
  -- (TSToolsOrganizeImports). Buffer-local to TS buffers, so this global copy
  -- stays reachable elsewhere. Verified safe: with no LSP client attached the
  -- code action resolves to a no-op rather than an error.
  {
    "<leader>co",
    function()
      LazyVim.lsp.action["source.organizeImports"]()
    end,
    desc = "Organize Imports",
  },

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ <leader>d -- debug / profiler                                        │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  {
    "<leader>dpp",
    function()
      Snacks.toggle.profiler():toggle()
    end,
    desc = "Toggle Profiler",
  },
  {
    "<leader>dph",
    function()
      Snacks.toggle.profiler_highlights():toggle()
    end,
    desc = "Toggle Profiler Highlights",
  },
  {
    "<leader>dps",
    function()
      Snacks.profiler.scratch()
    end,
    desc = "Profiler Scratch Buffer",
  },

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ <leader>f -- file/find                                               │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  { "<leader>fn", "<cmd>enew<cr>", desc = "New File" },
  {
    "<leader>fc",
    function()
      LazyVim.pick.open("files", { cwd = vim.fn.stdpath("config") })
    end,
    desc = "Find Config File",
  },
  {
    "<leader>fF",
    function()
      LazyVim.pick.open("files", { root = false })
    end,
    desc = "Find Files (cwd)",
  },
  {
    "<leader>fB",
    function()
      Snacks.picker.buffers({ hidden = true, nofile = true })
    end,
    desc = "Buffers (all)",
  },
  {
    "<leader>fR",
    function()
      Snacks.picker.recent({ filter = { cwd = true } })
    end,
    desc = "Recent (cwd)",
  },
  {
    "<leader>fT",
    function()
      Snacks.terminal()
    end,
    desc = "Terminal (cwd)",
  },
  -- [removed]
  -- {
  --   "<leader>fe",
  --   function()
  --     require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
  --   end,
  --   desc = "Explorer NeoTree (Root Dir)",
  -- },
  -- [removed]
  -- {
  --   "<leader>fE",
  --   function()
  --     require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
  --   end,
  --   desc = "Explorer NeoTree (cwd)",
  -- },

  -- overridden by config/keymaps/telescope.lua -- "Find files"
  -- {
  --   "<leader>ff",
  --   function()
  --     LazyVim.pick.open("files")
  --   end,
  --   desc = "Find Files (Root Dir)",
  -- },

  -- overridden by config/keymaps/telescope.lua -- "Find buffers"
  -- {
  --   "<leader>fb",
  --   function()
  --     Snacks.picker.buffers()
  --   end,
  --   desc = "Buffers",
  -- },

  -- overridden by config/keymaps/telescope.lua -- "Live grep"
  -- {
  --   "<leader>fg",
  --   function()
  --     Snacks.picker.git_files()
  --   end,
  --   desc = "Find Files (git-files)",
  -- },

  -- overridden by config/keymaps/telescope.lua -- "Resume last search"
  -- {
  --   "<leader>fr",
  --   function()
  --     LazyVim.pick.open("oldfiles")
  --   end,
  --   desc = "Recent",
  -- },

  -- overridden by config/keymaps/telescope.lua -- "Treesitter symbols"
  -- {
  --   "<leader>ft",
  --   function()
  --     Snacks.terminal(nil, { cwd = LazyVim.root() })
  --   end,
  --   desc = "Terminal (Root Dir)",
  -- },

  -- overridden by config/keymaps/general.lua -- "Copy Relative Path to Clipboard".
  -- Three-way collision: plugins/telescope/keymaps.lua:3 also claims <leader>fp
  -- ("Find Plugin File"), but the config/keymaps layer runs last and wins, so
  -- that telescope entry is dead code -- it was already dead before this file.
  -- {
  --   "<leader>fp",
  --   function()
  --     Snacks.picker.projects()
  --   end,
  --   desc = "Projects",
  -- },

  -- [yours] plugins/telescope/keymaps.lua:14 -- <leader>fh "Help tags"
  -- [yours] plugins/telescope/keymaps.lua:15 -- <leader>fk "Keymaps"
  -- [yours] plugins/telescope/keymaps.lua:16 -- <leader>fm "Marks"
  -- [yours] plugins/telescope/keymaps.lua:18 -- <leader>fs "Document symbols"
  -- [yours] plugins/telescope/keymaps.lua:19 -- <leader>fS "Workspace symbols"
  -- [yours] plugins/telescope/keymaps.lua:21 -- <leader>fo "Old files"
  -- [yours] plugins/telescope/keymaps.lua:22 -- <leader>fC "Commands"
  -- [yours] plugins/owner-code-search/config.lua:37 -- <leader>fd "Owner Code Fd Search"
  -- [yours] plugins/owner-code-search/config.lua:52 -- <leader>fD "Owner Code Fd Search"

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ <leader>g -- git                                                     │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  {
    "<leader>gL",
    function()
      Snacks.picker.git_log()
    end,
    desc = "Git Log (cwd)",
  },
  {
    "<leader>gb",
    function()
      Snacks.picker.git_log_line()
    end,
    desc = "Git Blame Line",
  },
  {
    "<leader>gf",
    function()
      Snacks.picker.git_log_file()
    end,
    desc = "Git Current File History",
  },
  {
    "<leader>gl",
    function()
      Snacks.picker.git_log({ cwd = LazyVim.root.git() })
    end,
    desc = "Git Log",
  },
  {
    "<leader>gB",
    function()
      Snacks.gitbrowse()
    end,
    mode = { "n", "x" },
    desc = "Git Browse (open)",
  },
  {
    "<leader>gY",
    function()
      Snacks.gitbrowse({
        open = function(url)
          vim.fn.setreg("+", url)
        end,
        notify = false,
      })
    end,
    mode = { "n", "x" },
    desc = "Git Browse (copy)",
  },
  {
    "<leader>gd",
    function()
      Snacks.picker.git_diff()
    end,
    desc = "Git Diff (hunks)",
  },
  {
    "<leader>gD",
    function()
      Snacks.picker.git_diff({ base = "origin", group = true })
    end,
    desc = "Git Diff (origin)",
  },
  {
    "<leader>gs",
    function()
      Snacks.picker.git_status()
    end,
    desc = "Git Status",
  },
  {
    "<leader>gS",
    function()
      Snacks.picker.git_stash()
    end,
    desc = "Git Stash",
  },
  {
    "<leader>gi",
    function()
      Snacks.picker.gh_issue()
    end,
    desc = "GitHub Issues (open)",
  },
  {
    "<leader>gI",
    function()
      Snacks.picker.gh_issue({ state = "all" })
    end,
    desc = "GitHub Issues (all)",
  },
  {
    "<leader>gp",
    function()
      Snacks.picker.gh_pr()
    end,
    desc = "GitHub Pull Requests (open)",
  },
  {
    "<leader>gP",
    function()
      Snacks.picker.gh_pr({ state = "all" })
    end,
    desc = "GitHub Pull Requests (all)",
  },
  {
    "<leader>ge",
    function()
      require("neo-tree.command").execute({ source = "git_status", toggle = true })
    end,
    desc = "Git Explorer",
  },

  -- hunks (<leader>gh)
  -- NOTE: upstream sets these buffer-locally from gitsigns' on_attach, so
  -- stock LazyVim leaves them unmapped outside a git-tracked buffer. As spec
  -- entries they become global. Verified harmless: gitsigns' functions no-op
  -- on a buffer it has not attached to, and its buffer-local maps still take
  -- precedence where it has. Comment the block out to get the stock scoping.
  { "<leader>ghs", ":Gitsigns stage_hunk<CR>", mode = { "n", "x" }, desc = "Stage Hunk" },
  { "<leader>ghr", ":Gitsigns reset_hunk<CR>", mode = { "n", "x" }, desc = "Reset Hunk" },
  {
    "<leader>ghS",
    function()
      require("gitsigns").stage_buffer()
    end,
    desc = "Stage Buffer",
  },
  {
    "<leader>ghu",
    function()
      require("gitsigns").undo_stage_hunk()
    end,
    desc = "Undo Stage Hunk",
  },
  {
    "<leader>ghR",
    function()
      require("gitsigns").reset_buffer()
    end,
    desc = "Reset Buffer",
  },
  {
    "<leader>ghp",
    function()
      require("gitsigns").preview_hunk_inline()
    end,
    desc = "Preview Hunk Inline",
  },
  {
    "<leader>ghb",
    function()
      require("gitsigns").blame_line({ full = true })
    end,
    desc = "Blame Line",
  },
  {
    "<leader>ghB",
    function()
      require("gitsigns").blame()
    end,
    desc = "Blame Buffer",
  },
  {
    "<leader>ghd",
    function()
      require("gitsigns").diffthis()
    end,
    desc = "Diff This",
  },
  {
    "<leader>ghD",
    function()
      require("gitsigns").diffthis("~")
    end,
    desc = "Diff This ~",
  },

  -- overridden by config/keymaps/neogit.lua -- "Open Neogit"
  -- {
  --   "<leader>gg",
  --   function()
  --     Snacks.lazygit({ cwd = LazyVim.root.git() })
  --   end,
  --   desc = "Lazygit (Root Dir)",
  -- },

  {
    "<leader>gG",
    function()
      Snacks.lazygit()
    end,
    desc = "Lazygit",
  },

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ <leader>q -- quit/session                                            │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  { "<leader>qq", "<cmd>qa<cr>", desc = "Quit All" },
  {
    "<leader>qs",
    function()
      require("persistence").load()
    end,
    desc = "Restore Session",
  },
  {
    "<leader>qS",
    function()
      require("persistence").select()
    end,
    desc = "Select Session",
  },
  {
    "<leader>ql",
    function()
      require("persistence").load({ last = true })
    end,
    desc = "Restore Last Session",
  },
  {
    "<leader>qd",
    function()
      require("persistence").stop()
    end,
    desc = "Don't Save Current Session",
  },

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ <leader>s -- search                                                  │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  {
    "<leader>sr",
    function()
      local grug = require("grug-far")
      local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
      grug.open({ transient = true, prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil } })
    end,
    mode = { "n", "x" },
    desc = "Search and Replace",
  },
  {
    "<leader>sb",
    function()
      Snacks.picker.lines()
    end,
    desc = "Buffer Lines",
  },
  {
    "<leader>sB",
    function()
      Snacks.picker.grep_buffers()
    end,
    desc = "Grep Open Buffers",
  },
  {
    "<leader>sg",
    function()
      LazyVim.pick.open("live_grep")
    end,
    desc = "Grep (Root Dir)",
  },
  {
    "<leader>sG",
    function()
      LazyVim.pick.open("live_grep", { root = false })
    end,
    desc = "Grep (cwd)",
  },
  {
    "<leader>sp",
    function()
      Snacks.picker.lazy()
    end,
    desc = "Search for Plugin Spec",
  },
  {
    "<leader>sw",
    function()
      LazyVim.pick.open("grep_word")
    end,
    mode = { "n", "x" },
    desc = "Visual selection or word (Root Dir)",
  },
  {
    "<leader>sW",
    function()
      LazyVim.pick.open("grep_word", { root = false })
    end,
    mode = { "n", "x" },
    desc = "Visual selection or word (cwd)",
  },
  {
    '<leader>s"',
    function()
      Snacks.picker.registers()
    end,
    desc = "Registers",
  },
  {
    "<leader>s/",
    function()
      Snacks.picker.search_history()
    end,
    desc = "Search History",
  },
  {
    "<leader>sa",
    function()
      Snacks.picker.autocmds()
    end,
    desc = "Autocmds",
  },
  {
    "<leader>sc",
    function()
      Snacks.picker.command_history()
    end,
    desc = "Command History",
  },
  {
    "<leader>sC",
    function()
      Snacks.picker.commands()
    end,
    desc = "Commands",
  },
  {
    "<leader>sd",
    function()
      Snacks.picker.diagnostics()
    end,
    desc = "Diagnostics",
  },
  {
    "<leader>sD",
    function()
      Snacks.picker.diagnostics_buffer()
    end,
    desc = "Buffer Diagnostics",
  },
  {
    "<leader>sh",
    function()
      Snacks.picker.help()
    end,
    desc = "Help Pages",
  },
  {
    "<leader>sH",
    function()
      Snacks.picker.highlights()
    end,
    desc = "Highlights",
  },
  {
    "<leader>si",
    function()
      Snacks.picker.icons()
    end,
    desc = "Icons",
  },
  {
    "<leader>sj",
    function()
      Snacks.picker.jumps()
    end,
    desc = "Jumps",
  },
  {
    "<leader>sk",
    function()
      Snacks.picker.keymaps()
    end,
    desc = "Keymaps",
  },
  {
    "<leader>sl",
    function()
      Snacks.picker.loclist()
    end,
    desc = "Location List",
  },
  {
    "<leader>sM",
    function()
      Snacks.picker.man()
    end,
    desc = "Man Pages",
  },
  {
    "<leader>sm",
    function()
      Snacks.picker.marks()
    end,
    desc = "Marks",
  },
  {
    "<leader>sR",
    function()
      Snacks.picker.resume()
    end,
    desc = "Resume",
  },
  {
    "<leader>sq",
    function()
      Snacks.picker.qflist()
    end,
    desc = "Quickfix List",
  },
  {
    "<leader>su",
    function()
      Snacks.picker.undo()
    end,
    desc = "Undotree",
  },
  {
    "<leader>sT",
    function()
      Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
    end,
    desc = "Todo/Fix/Fixme",
  },

  -- noice (<leader>sn)
  {
    "<leader>snl",
    function()
      require("noice").cmd("last")
    end,
    desc = "Noice Last Message",
  },
  {
    "<leader>snh",
    function()
      require("noice").cmd("history")
    end,
    desc = "Noice History",
  },
  {
    "<leader>sna",
    function()
      require("noice").cmd("all")
    end,
    desc = "Noice All",
  },
  {
    "<leader>snd",
    function()
      require("noice").cmd("dismiss")
    end,
    desc = "Dismiss All",
  },
  {
    "<leader>snt",
    function()
      require("noice").cmd("pick")
    end,
    desc = "Noice Picker (Telescope/FzfLua)",
  },

  -- overridden by config/keymaps/todo-comments.lua -- "Todo (Telescope)"
  -- {
  --   "<leader>st",
  --   function()
  --     Snacks.picker.todo_comments()
  --   end,
  --   desc = "Todo",
  -- },

  -- [lsp] capability-gated, attached per buffer -- see legend
  -- { "<leader>ss", function() Snacks.picker.lsp_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "LSP Symbols" },            -- has = "documentSymbol"
  -- { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "LSP Workspace Symbols" }, -- has = "workspace/symbols"

  -- [yours] plugins/sort/keymaps.lua:3 -- <leader>so "Sort lines (ascending)" (visual)
  -- [yours] plugins/sort/keymaps.lua:9 -- <leader>sO "Sort lines (descending)" (visual)

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ <leader>u -- ui / toggles                                            │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  -- NOTE: upstream builds these with `Snacks.toggle.X():map(lhs)`, which both
  -- sets the key and registers the on/off icon with which-key. A spec entry
  -- can only carry the rhs, so these call `:toggle()` on an identically
  -- constructed toggle. Same behaviour; the icon still comes from LazyVim's
  -- own :map() registration.
  {
    "<leader>ur",
    "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
    desc = "Redraw / Clear hlsearch / Diff Update",
  },
  {
    "<leader>uf",
    function()
      LazyVim.format.snacks_toggle():toggle()
    end,
    desc = "Toggle Auto Format (Global)",
  },
  {
    "<leader>uF",
    function()
      LazyVim.format.snacks_toggle(true):toggle()
    end,
    desc = "Toggle Auto Format (Buffer)",
  },
  {
    "<leader>us",
    function()
      Snacks.toggle.option("spell", { name = "Spelling" }):toggle()
    end,
    desc = "Toggle Spelling",
  },
  {
    "<leader>uw",
    function()
      Snacks.toggle.option("wrap", { name = "Wrap" }):toggle()
    end,
    desc = "Toggle Wrap",
  },
  {
    "<leader>uL",
    function()
      Snacks.toggle.option("relativenumber", { name = "Relative Number" }):toggle()
    end,
    desc = "Toggle Relative Number",
  },
  {
    "<leader>ud",
    function()
      Snacks.toggle.diagnostics():toggle()
    end,
    desc = "Toggle Diagnostics",
  },
  {
    "<leader>uc",
    function()
      Snacks.toggle
        .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" })
        :toggle()
    end,
    desc = "Toggle Conceal Level",
  },
  {
    "<leader>uA",
    function()
      Snacks.toggle
        .option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" })
        :toggle()
    end,
    desc = "Toggle Tabline",
  },
  {
    "<leader>uT",
    function()
      Snacks.toggle.treesitter():toggle()
    end,
    desc = "Toggle Treesitter Highlight",
  },
  {
    "<leader>ub",
    function()
      Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):toggle()
    end,
    desc = "Toggle Dark Background",
  },
  {
    "<leader>uD",
    function()
      Snacks.toggle.dim():toggle()
    end,
    desc = "Toggle Dim",
  },
  {
    "<leader>ua",
    function()
      Snacks.toggle.animate():toggle()
    end,
    desc = "Toggle Animate",
  },
  {
    "<leader>ug",
    function()
      Snacks.toggle.indent():toggle()
    end,
    desc = "Toggle Indent Guides",
  },
  {
    "<leader>uS",
    function()
      Snacks.toggle.scroll():toggle()
    end,
    desc = "Toggle Smooth Scroll",
  },
  {
    "<leader>uh",
    function()
      Snacks.toggle.inlay_hints():toggle()
    end,
    desc = "Toggle Inlay Hints",
  },
  {
    "<leader>uZ",
    function()
      Snacks.toggle.zoom():toggle()
    end,
    desc = "Toggle Zoom",
  },
  {
    "<leader>uz",
    function()
      Snacks.toggle.zen():toggle()
    end,
    desc = "Toggle Zen Mode",
  },
  {
    "<leader>uG",
    function()
      Snacks.toggle({
        name = "Git Signs",
        get = function()
          return require("gitsigns.config").config.signcolumn
        end,
        set = function(state)
          require("gitsigns").toggle_signs(state)
        end,
      }):toggle()
    end,
    desc = "Toggle Git Signs",
  },
  {
    "<leader>un",
    function()
      Snacks.notifier.hide()
    end,
    desc = "Dismiss All Notifications",
  },
  { "<leader>ui", vim.show_pos, desc = "Inspect Pos" },
  {
    "<leader>uI",
    function()
      vim.treesitter.inspect_tree()
      vim.api.nvim_input("I")
    end,
    desc = "Inspect Tree",
  },
  {
    "<leader>uC",
    function()
      Snacks.picker.colorschemes()
    end,
    desc = "Colorschemes",
  },

  -- overridden by config/keymaps/general.lua -- "Toggle Relative Line Numbers"
  -- {
  --   "<leader>ul",
  --   function()
  --     Snacks.toggle.line_number():toggle()
  --   end,
  --   desc = "Toggle Line Number",
  -- },

  -- [yours] config/keymaps/blink.lua:37 -- <leader>uj "Toggle Japanese IM completion"

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ <leader>w -- windows, <leader><tab> -- tabs                          │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  { "<leader>wd", "<C-W>c", desc = "Delete Window", remap = true },
  {
    "<leader>wm",
    function()
      Snacks.toggle.zoom():toggle()
    end,
    desc = "Toggle Zoom",
  },
  { "<leader><tab>l", "<cmd>tablast<cr>", desc = "Last Tab" },
  { "<leader><tab>o", "<cmd>tabonly<cr>", desc = "Close Other Tabs" },
  { "<leader><tab>f", "<cmd>tabfirst<cr>", desc = "First Tab" },
  { "<leader><tab><tab>", "<cmd>tabnew<cr>", desc = "New Tab" },
  { "<leader><tab>]", "<cmd>tabnext<cr>", desc = "Next Tab" },
  { "<leader><tab>d", "<cmd>tabclose<cr>", desc = "Close Tab" },
  { "<leader><tab>[", "<cmd>tabprevious<cr>", desc = "Previous Tab" },

  -- [yours] config/keymaps.lua:6  -- <leader>w> "Increase window width"
  -- [yours] config/keymaps.lua:12 -- <leader>w< "Decrease window width"
  -- [yours] config/keymaps.lua:18 -- <leader>w+ "Increase window height"
  -- [yours] plugins/nvim-window-picker/config.lua:9 and
  --         config/keymaps/nvim-window-picker.lua:4 -- <leader>wp "Pick window".
  --         Note <leader>w is declared upstream with `proxy = "<c-w>"`, so
  --         which-key also surfaces the native <c-w>p under this prefix.

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ <leader>x -- diagnostics/quickfix                                    │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  {
    "<leader>xl",
    function()
      local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
      if not success and err then
        vim.notify(err, vim.log.levels.ERROR)
      end
    end,
    desc = "Location List",
  },
  {
    "<leader>xq",
    function()
      local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
      if not success and err then
        vim.notify(err, vim.log.levels.ERROR)
      end
    end,
    desc = "Quickfix List",
  },
  { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
  { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
  { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
  { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },

  -- overridden by config/keymaps/todo-comments.lua -- "Todo (Trouble)" (TodoTrouble)
  -- { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },

  -- overridden by config/keymaps/todo-comments.lua -- "Todo/Fix/Fixme (Trouble)"
  -- {
  --   "<leader>xT",
  --   "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>",
  --   desc = "Todo/Fix/Fixme (Trouble)",
  -- },

  -- ╭──────────────────────────────────────────────────────────────────────╮
  -- │ Yours only -- no LazyVim default on these prefixes                   │
  -- ╰──────────────────────────────────────────────────────────────────────╯
  -- [yours] config/keymaps/octo.lua:8       -- <leader>or  "Octo: PRs Requesting My Review"
  -- [yours] config/keymaps/octo.lua:12      -- <leader>op  "Octo: My Open PRs"
  -- [yours] config/keymaps/octo.lua:13      -- <leader>os  "Octo: Start Review"
  -- [yours] config/keymaps/python.lua:4     -- <leader>pym "Copy Module Name"
  -- [yours] plugins/python/config.lua:25    -- <leader>pyu "Update Package"
  -- [yours] plugins/python/config.lua:32    -- <leader>pyi "Package Info"
  -- [yours] plugins/python/config.lua:39    -- <leader>pya "Update All Packages"
  -- [yours] config/keymaps/package-info.lua:11 -- <leader>pjs "Show package versions"
  -- [yours] config/keymaps/package-info.lua:13 -- <leader>pju "Update dependency"
  -- [yours] config/keymaps/package-info.lua:14 -- <leader>pjd "Delete dependency"
  -- [yours] config/keymaps/package-info.lua:15 -- <leader>pji "Install dependency"
  -- [yours] config/keymaps/package-info.lua:16 -- <leader>pjc "Change dependency version"
  -- [yours] plugins/owner-code-search/config.lua:7  -- <leader>rg "Owner Code Grep Search"
  -- [yours] plugins/owner-code-search/config.lua:22 -- <leader>rG "Owner Code Grep Search"
  -- [yours] plugins/summarize-commit/config.lua:7   -- <leader>ail "[Ollama] Summarize commit"
  -- [yours] plugins/conform/keymaps.lua:3   -- <leader>mp "Format file or range" (n, v)
  -- [yours] plugins/sort/keymaps.lua:15     -- <leader>SD "Smart sort (plugin)" (visual)
  -- [yours] config/keymaps/nvim-lint.lua:15 -- <leader>ll "Lint current file"
  -- [yours] config/keymaps/nvim-lint.lua:19 -- <leader>lL "Re-run lint"
  --         LazyVim defines no <leader>l* two-character key, so these are
  --         yours outright. config/keymaps/lazyvim.lua used to safe_del ll, lL,
  --         li, lR and lS; all five were no-ops and have been removed.
}
