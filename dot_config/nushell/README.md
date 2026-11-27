# nushell

chezmoi installs this folder as `~/.config/nushell`. The files have two jobs:
they configure nushell as a shell, and they hold the nushell code that some zsh
functions run.

## Files

| File | Purpose |
| --- | --- |
| [`env.nu`](env.nu) | Loads before `config.nu`. It sets the fzf variables and `ATUIN_DATA_DIR`. |
| [`config.nu`](config.nu) | The shell config: theme, menus and keybindings. At the end, it sources the other `.nu` files. |
| [`function.nu`](function.nu) | Shell commands: `pet` and `navi` (each pinned to its nushell-only snippets, on `Ctrl-O` and `Ctrl-G`), `ls_fzf_open`, `ls_count_ext` and `cls`. |
| [`compare_dir_diff.nu`](compare_dir_diff.nu) | `dir-cmp`, `dir-diff`, `dir-rdiff`, `dir-both`, `dir-xor` and `dir-report`: compare the file names in two directories. |
| [`lsz.nu`](lsz.nu) | `lsz`: directories sized by all the files below them, largest first. |
| [`csv2.nu`](csv2.nu), [`jsonl2csv.nu`](jsonl2csv.nu), [`jsonl2yml.nu`](jsonl2yml.nu), [`yml2jsonl.nu`](yml2jsonl.nu) | Format converters between CSV, JSON, JSONL and YAML. |
| [`tocsv.nu`](tocsv.nu), [`tojson.nu`](tojson.nu) | Write pipeline input as CSV or JSON for an external program. |

## nushell code for zsh

Some zsh functions do their work in nushell. The logic stays in a `.nu` file
here, and the zsh function only calls it:

```sh
nu -c 'source ($nu.default-config-dir | path join csv2.nu); …'
```

The zsh function sends its data in environment variables, not in the nushell
source text.

| zsh function | In | Runs |
| --- | --- | --- |
| `csv2json`, `csv2jsonl`, `csv2yml` | [`functions.zsh`](../zsh/src/functions.zsh) | `csv2.nu` |
| `jsonl2csv`, `jsonl2yml`, `yml2jsonl` | `functions.zsh` | the `.nu` file with the same name |
| `lsz` | `functions.zsh` | `lsz.nu` and `tocsv.nu` |
| `ls_count_ext` | [`ls.zsh`](../zsh/src/ls.zsh) | `function.nu` |

To add one, write the logic in a new `.nu` file and add a `source` line for it
at the end of `config.nu`. Then write a short zsh function that sources the
file and calls it.

## Integrations

[`.chezmoiscripts/run_onchange_after_nushell-integrations.sh.tmpl`](../../.chezmoiscripts/run_onchange_after_nushell-integrations.sh.tmpl)
writes the fzf and atuin integration scripts into nushell's vendor autoload
folder (`~/.local/share/nushell/vendor/autoload`). nushell loads that folder
after `config.nu`, so the keybindings in those scripts are not lost when
`config.nu` sets `$env.config`. The script runs again when the fzf or atuin
version changes.

- fzf gets `Ctrl-T`, `Ctrl-R` and `Alt-C`.
- atuin gets the up arrow only, as in zsh.
- `env.nu` sets `ATUIN_DATA_DIR`, so the nushell history is separate from the
  zsh history.
