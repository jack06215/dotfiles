# package-info

[vuki656/package-info.nvim](https://github.com/vuki656/package-info.nvim)
shows the latest version of each dependency in a `package.json` file, and runs
the package manager for you. It loads with the first JSON buffer.

## Keys

[`lua/config/keymaps/package-info.lua`](../../config/keymaps/package-info.lua)
sets these keys in JSON buffers:

| Key | Action |
| --- | --- |
| `<leader>pjs` | Show the package versions. |
| `<leader>pju` | Update the dependency on the cursor line. |
| `<leader>pjd` | Delete the dependency. |
| `<leader>pji` | Install a dependency. |
| `<leader>pjc` | Change the version of the dependency. |

The config is in [`config.lua`](config.lua).
