# tock

[tock](https://github.com/kriuchkov/tock) is a time tracker for the command
line. chezmoi installs this folder as `~/.config/tock`, where tock looks by
default. [`tock.yaml`](tock.yaml) is the only place for tock settings: the
shell layer sets no `TOCK_*` variables, because they would override the file.

tock stores the activities in SQLite at `~/.local/share/tock/tock.db`.
`tock.yaml` gives the reasons for SQLite and the table schema.

## Track your time

`tock start` stops the running activity and starts the new one. Thus one
command, `tk`, starts work and also switches to the next task.

| Command | Action |
| --- | --- |
| `tk fix the exporter` | Start or switch to an activity. The project is the git repository of the current directory, or the directory outside a repository. You do not need quotes around the description. |
| `tk` | Ask for a description, a tag and a note, then start. |
| `tkr` (`tockpick`) | Select an earlier activity and start it again. The prompt shows the note that you left the last time. |
| `tkn` | Print one line about the running activity. |
| `tkd` | Print where the time went today. `--yesterday` and `--date YYYY-MM-DD` select another day. The total includes the running activity. |
| `tks` | Stop the running activity. |
| `tkc` | Start a new entry with the details of the last one. |
| `tkl`, `tkw`, `tka` | Open the calendar, the stopwatch and the work-habit analysis. |

[`dot_config/zsh/src/tock.zsh`](../zsh/src/tock.zsh) defines these commands.
`tk` and `tockpick` are also programs in `~/.local/bin`, through `zshfn`. If the
first argument of `tk` is a flag, `tk` gives all the arguments to
`tock start` unchanged.

## Activity notes

A note is free text: what "done" means, the ticket URL, where you stopped. The
note prompt is a `gum write` box. `Enter` saves, `Ctrl-J` starts a new line and
`Esc` skips. `tk` with a description does not ask for a note.

## Tags

Use only these six tags: `deep`, `meeting`, `review`, `ops`, `admin` and
`learning`. The `_TOCK_TAGS` list in `tock.zsh` and `theme.tag_colors` in
`tock.yaml` must have the same tags, because `tag_colors` gives each tag its
color in the calendar.

## tmux

- The status bar shows the running activity, its elapsed time and the total for
  today. With no activity, it shows a dim `󰅐 —`, so you see when you forgot to
  start one. See
  [`dot_config/tmux-powerline/README.md`](../tmux-powerline/README.md).
- Press `prefix`, then `Space`, then `k` for a menu of the same actions as
  popups.

## Settings

- `working_hours` is off. It would stop an activity that runs past a time, but
  it needs a cutoff hour, and a guessed hour cuts real work short.
- The installed tock is the Homebrew core version. tock ignores a key that this
  version does not know and shows no error, so `tock.yaml` lists only the keys
  that this version reads.
