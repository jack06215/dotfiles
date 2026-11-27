# Claude Code

chezmoi installs this folder as `~/.config/claude`.
[`dot_zshenv.tmpl`](../../dot_zshenv.tmpl) sets `CLAUDE_CONFIG_DIR` to that
folder, so Claude Code reads it instead of `~/.claude`.

| File | Purpose |
| --- | --- |
| [`settings.json.tmpl`](settings.json.tmpl) | The settings: model, permissions, sandbox, hooks and status line. |
| [`executable_statusline_command.sh`](executable_statusline_command.sh) | The status line script. It must run under the macOS `/bin/bash` 3.2, so it uses no bash 4 features. |
| [`agents/`](agents/) | Subagents: `bazel-verify`, `cpp-explore`, `deep-reflector`, `insight-documenter` and `instruction-reflector`. |
| [`symlink_skills.tmpl`](symlink_skills.tmpl) | Makes `~/.config/claude/skills` a relative symlink to [`skills/`](../../skills/) at the repository root. A skill edit takes effect without `chezmoi apply`. |

## What the settings template changes for each machine

- **Model.** `opus[1m]` on a company machine, because that account has the
  1M-context entitlement. `opus` on all other machines.
- **Extra directory.** On a personal machine that has the monorepo checkout,
  Claude Code can also read the monorepo.
- **Termux.** The status line and the hook commands run through `bash`. On
  Termux, Claude Code runs without termux-exec, so a `#!/bin/bash` line does
  not work.

## Hooks

- **agent-hatch.** On each session event, a hook runs
  [`dot_config/tmux/agent-hatch/hooks/executable_status.sh`](../tmux/agent-hatch/hooks/executable_status.sh).
  The script records the status of the session (busy, waiting, idle or gone)
  on its tmux pane. The tmux picker on `prefix`, then `u`, and the status bar
  show that status.
- **Orca.** Orca installs its own hook in `~/.claude/settings.json`, which
  Claude Code does not read because of `CLAUDE_CONFIG_DIR`. Thus this template
  calls the Orca hook script on the same events. The hook does work only in an
  Orca pane.
