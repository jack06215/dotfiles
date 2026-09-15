-- navi cheatsheets. `;` is navi's comment character - `#` starts a cheat
-- description, so `gcc` must not reach for it.
vim.opt_local.commentstring = "; %s"

-- Commands are one per line and often long; wrapping them would make the
-- column structure of the file harder to read than a horizontal scroll.
vim.opt_local.wrap = false
