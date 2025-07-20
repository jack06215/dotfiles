_G.general_info = {
  username = "jack06215",
  email = "jack06215@gmail.com",
  github = "https://github.com/jack06215",
}

vim.g.personal_options = {
  start_light_env = (vim.env.NVIM_LIGHT_ENV or "0") ~= "0",
  colorscheme = vim.env.NVIM_COLOR or "jellybeans-nvim",
  use_transparent = (vim.env.NVIM_USE_TRANSPARENT or "0") ~= "0",
  use_git_plugins = (vim.env.NVIM_DISABLE_GIT or "0") == "0",
  prefix = {
    -- telescope = "<Leader>f",
    -- gitsigns = "<Leader>h",
    -- neogit = "<Leader>g",
    -- language = "<Leader>l",
    -- iron = "<Leader>r",
    -- lsp = "<Leader>k",
    -- neorg = "<Leader>k",
    -- -- virt_notes = "<Leader>v",
    -- vira = "<Leader>v",
    -- dap = "<Leader>d",
  },
  debug = {
    lsp = false,
    null = false,
    neotree = (vim.env.NVIM_NEOTREE_DEV or "0") ~= "0",
  },
  signcolumn_length = 4,
  -- stylua: ignore
  lsp_icons = {
    Array = "󰅪 ",
    Boolean = " ",
    BreakStatement = "󰙧 ",
    Call = "󰃷 ",
    CaseStatement = "󱃙 ",
    Class = " ",
    Color = "󰏘 ",
    Constant = "󰏿 ",
    Constructor = " ",
    ContinueStatement = "→ ",
    Copilot = " ",
    Declaration = "󰙠 ",
    Delete = "󰩺 ",
    DoStatement = "󰑖 ",
    Enum = " ",
    EnumMember = " ",
    Event = " ",
    Field = " ",
    File = "󰈔 ",
    Folder = "󰉋 ",
    ForStatement = "󰑖 ",
    Function = "󰊕 ",
    Identifier = "󰀫 ",
    IfStatement = "󰇉 ",
    Interface = " ",
    Key = "󰌋 ",
    Keyword = "󰌋 ",
    List = "󰅪 ",
    Log = "󰦪 ",
    Lsp = " ",
    Macro = "󰁌 ",
    MarkdownH1 = "󰉫 ",
    MarkdownH2 = "󰉬 ",
    MarkdownH3 = "󰉭 ",
    MarkdownH4 = "󰉮 ",
    MarkdownH5 = "󰉯 ",
    MarkdownH6 = "󰉰 ",
    Method = "󰆧 ",
    Module = "󰏗 ",
    Namespace = "󰅩 ",
    Null = "󰢤 ",
    Number = "󰎠 ",
    Object = "󰅩 ",
    Operator = "󰆕 ",
    Package = "󰆦 ",
    Property = " ",
    Reference = "󰦾 ",
    Regex = " ",
    Repeat = "󰑖 ",
    Scope = "󰅩 ",
    Snippet = "󰩫 ",
    Specifier = "󰦪 ",
    Statement = "󰅩 ",
    String = "󰉾 ",
    Struct = " ",
    SwitchStatement = "󰺟 ",
    Terminal = " ",
    Text = " ",
    Type = " ",
    TypeParameter = "󰆩 ",
    Unit = " ",
    Value = "󰎠 ",
    Variable = "󰀫 ",
    WhileStatement = "󰑖 "
  },
}

vim.g.personal_lookup = {
  ---Lookup value with default key
  ---@param tbl string | table<string, table<string, any>> # lookup table. if string, uses `vim.g.personal_lookup`
  ---@param key string # key to lookup
  ---@param default any? # value to return if key not found. if `nil`, `tbl._` is returned
  ---@return any # value of lookup
  get = function(tbl, key, default)
    local t = type(tbl) == "string" and vim.g.personal_lookup[tbl] or tbl
    if type(t) ~= "table" then
      return nil
    end
    return t[key] or default or t._
  end,
  hlargs = {
    _ = "#ef9062",
    kanagawa = "#E6C384",
  },
  null = {
    _ = {},
    ["f.autopep8"] = { extra_args = { "--max-line-length=120", "--aggressive", "--aggressive" } },
    ["d.flake8"] = { extra_args = { "--max-line-length=120" } },
    -- ["f.black"] = { extra_args = { "--line-length=120" } },
    ["f.isort"] = { extra_args = { "--profile=black" } },
    ["f.nimpretty"] = { extra_args = { "--maxLineLen:120" } },
    ["f.sqlfluff"] = {
      extra_args = {
        vim.env.SQLFLUFF_CONFIG_PATH and string.format("--config=%s", vim.env.SQLFLUFF_CONFIG_PATH)
        or "--dialect=snowflake",
      },
    },
    ["d.sqlfluff"] = {
      extra_args = {
        vim.env.SQLFLUFF_CONFIG_PATH and string.format("--config=%s", vim.env.SQLFLUFF_CONFIG_PATH)
        or "--dialect=snowflake",
      },
    },
  },
}

-- neovim specific options
vim.opt.completeopt = "menuone,noselect"
vim.opt.cmdheight = 0
vim.opt.exrc = true
vim.opt.signcolumn = "yes:1"
vim.opt.spelloptions = "camel,noplainbuffer"
vim.opt.ignorecase = true
vim.opt.shortmess:append("C")

-- global status line
vim.opt.laststatus = 3
vim.opt.fillchars =
"vert:┃,horiz:━,verthoriz:╋,horizup:┻,horizdown:┳,vertleft:┫,vertright:┣,eob: " -- more obvious separator

local aug = vim.api.nvim_create_augroup("GeneralConfigAUG", { clear = true })
vim.api.nvim_create_autocmd("VimResized", {
  desc = "Resize Splits Automatically for Tmux",
  group = aug,
  pattern = "*",
  command = "wincmd =",
})
vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Auto Format Japanese Punctuation in Latex Files",
  group = aug,
  pattern = "*.tex",
  command = [[
  normal m`
  silent! %s/、/，/g
  silent! %s/。/．/g
  normal ``
  ]],
})
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight Copied Text for a Split Second",
  group = aug,
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

vim.filetype.add({
  extension = {
    jinja = "jinja",
    jinja2 = "jinja",
    j2 = "jinja",
  },
  pattern = {
    [".*%.sql%.jinja"] = "sqlj",
  },
})

if vim.env.PYENV_ROOT then
  vim.g.python3_host_prog = vim.env.PYENV_ROOT .. "/versions/global/bin/python"
end
