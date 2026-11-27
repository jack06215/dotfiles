# tmux-powerline

The [tmux-powerline](https://github.com/erikw/tmux-powerline) plugin draws the
tmux status bar. chezmoi installs this folder as `~/.config/tmux-powerline`.
[`dot_config/tmux/tmux.conf`](../tmux/tmux.conf) does not set the bar content.
The files here do.

| File | Purpose |
| --- | --- |
| [`config.sh`](config.sh) | Only the settings that differ from the plugin defaults: theme name, update intervals and segment options. |
| [`themes/mocha.sh`](themes/mocha.sh) | The Catppuccin Mocha colors, and the segments that the bar shows. |
| [`segments/`](segments/) | Custom segments. A segment here replaces a plugin segment with the same name. |

> [!IMPORTANT]
> `config.sh` must set `TMUX_POWERLINE_DIR_USER_THEMES` and
> `TMUX_POWERLINE_DIR_USER_SEGMENTS`. Without them, the plugin looks for
> `mocha` only in its own folder, and the status bar is empty.

## Segments

From left to right:

| Segment | Shows |
| --- | --- |
| `mode_indicator` | `TMUX`, or `PREFIX` in red after you press the prefix, `COPY` in copy mode, `SUSPEND` when tmux-suspend is on. |
| `tmux_session_info` | The session name. In an agent popup, it is `claude-…` or `copilot-…`. |
| `hostname` | The machine name. |
| `vcs_status` (custom) | The git branch, the commits ahead and behind, and the staged, changed and untracked file counts. |
| `tock` (custom) | The tock activity: project, description, elapsed time and the total for today. The elapsed time turns yellow after 90 minutes and red after 180 minutes (`…_TOCK_WARN_MINUTES` and `…_TOCK_STALE_MINUTES` in `config.sh`). With no activity, it shows a dim `󰅐 —`. |
| `agents` (custom) | How many coding agents wait for you (yellow), are idle (green) and are working (red). It uses the same colors as the agent-hatch picker on `prefix`, then `u`. With no agent, the segment does not appear. |
| `pwd` | The directory of the current pane. |
| `battery` (custom) | The plugin's battery segment, with support for Termux. It shows a percentage only when the battery charges or discharges. |
| `date_day`, `date`, `time` | The day, the date and the time. |

## Debug a segment

- `~/.local/share/tmux/plugins/tmux-powerline/doctor.sh` prints the values that
  the plugin uses and checks the dependencies.
- `~/.local/share/tmux/plugins/tmux-powerline/generate_config.sh` writes
  `config.sh.default` with every option and its default value. It does not
  change `config.sh`.
