# typescript

[pmizio/typescript-tools.nvim](https://github.com/pmizio/typescript-tools.nvim)
is a TypeScript LSP client that talks to `tsserver` directly. It loads for
TypeScript and JavaScript files, including JSX. Diagnostics come from a
separate server.

It does not start in a Deno project, which has a `deno.json` or a
`deno.jsonc`. Those projects use `denols`
([`lua/lsp-config/settings/denols.lua`](../../lsp-config/settings/denols.lua)).
With two servers on one buffer, lspsaga's peek definition opens two windows.

The LazyVim `lang.typescript` extra comes from [`../extras/`](../extras/).

## Keys

[`lua/config/keymaps/typescript.lua`](../../config/keymaps/typescript.lua)
sets these keys:

| Key | Action |
| --- | --- |
| `<leader>co` | Organize the imports. |
| `<leader>cR` | Rename the file and update the imports. |
