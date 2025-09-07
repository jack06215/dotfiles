-- Convert tabs to spaces
vim.opt.expandtab = true

-- Tab and indent widths
vim.opt.tabstop = 2        -- Number of spaces a tab displays as
vim.opt.softtabstop = 2    -- Number of spaces a <Tab> or <BS> uses during editing
vim.opt.shiftwidth = 2     -- Indent width used for >> << and smartindent

-- Indentation behavior
vim.opt.autoindent = true  -- Copy indent from current line when starting new one
vim.opt.smartindent = true -- Auto-insert extra indent in some cases (e.g., after `{`)
vim.opt.smarttab = true    -- Makes <Tab>/<BS> respect shiftwidth at beginning of line

-- Format options
vim.opt.formatoptions:remove({ "c", "r", "o" })  -- Don't auto-insert comment leaders on new lines