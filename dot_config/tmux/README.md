# tmux

chezmoi installs this folder as `~/.config/tmux`. If you are new to tmux, read
[`TUTORIAL.md`](TUTORIAL.md) first. This config is not stock tmux, so a generic
tmux tutorial teaches keys that do not work here.

## Keys to know

The prefix is `Ctrl-S`. Press it and release it, then press the next key. Most
daily actions do not use the prefix: they are on `Alt` keys.

| Keys | Action |
| --- | --- |
| `prefix`, then `Space` | Open a menu of all actions (tmux-which-key). |
| `prefix`, then `?` | List the key bindings that have a note. |
| `prefix`, then `r` | Load the config again. |
| `prefix`, then `I` | Install the plugins. |
| `prefix`, then `y` | Start Claude Code or Copilot CLI in a popup for the current directory. |
| `prefix`, then `u` | Select one of the running agents. |
| `Alt-S` | Switch to another session. |
| `Alt-P` | Paste from the system clipboard. |

## Files

| File | Purpose |
| --- | --- |
| [`tmux.conf`](tmux.conf) | The config. |
| [`TUTORIAL.md`](TUTORIAL.md) | A guide to this config for a tmux beginner, with a full key reference. |
| [`which-key.yaml`](which-key.yaml) | The menu for `prefix`, then `Space`. The plugin reads its config only from its own folder, so `tmux.conf` links this file there. After an edit, press `prefix`, then `r`. The file header gives two quoting rules. If you break one, the menu fails without an error. |
| [`executable_dev-workspace.sh`](executable_dev-workspace.sh) | Makes or attaches a four-pane coding session: an editor above a strip of logs, shell and server panes. The first WezTerm tab runs it. `-r` deletes the session and makes it again. |
| [`agent-hatch/`](agent-hatch/) | The plugin behind `prefix`, then `y` and `u`. It is a fork of craftzdog/tmux-claude-hatch (MIT). Each agent's hooks write the agent status on its pane, so one picker covers all agents. |

## Plugins

chezmoi installs TPM, the tmux plugin manager, from
[`.chezmoiexternal.toml`](../../.chezmoiexternal.toml) into
`~/.local/share/tmux/plugins/tpm` (not on Windows). `tmux.conf` sets
`TMUX_PLUGIN_MANAGER_PATH` to that folder. `~/setup.sh` installs the plugins,
or you can press `prefix`, then `I`. Thus you do not need Step 1 of
`TUTORIAL.md`, which clones TPM by hand.

The status bar content comes from
[`dot_config/tmux-powerline/`](../tmux-powerline/).

## Alt keys and other programs

`tmux.conf` puts many bindings on `Alt` plus a letter or a digit, without the
prefix. Other programs must not take those keys:

- GlazeWM does not bind them. See
  [`dot_glzr/README.md`](../../dot_glzr/README.md).
- WezTerm binds its own keys to `Cmd` on macOS and to `Ctrl-Shift` on other
  platforms. On macOS, it also makes both Option keys send `Alt`, so they do
  not type special characters.
