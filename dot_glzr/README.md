# GlazeWM and Zebar (Windows)

[GlazeWM](https://github.com/glzr-io/glazewm) tiles the windows, and
[Zebar](https://github.com/glzr-io/zebar) draws the status bar. chezmoi installs
this folder as `~/.glzr` on Windows only. On WSL2,
[`.chezmoiscripts/run_onchange_after_push-windows-configs.sh.tmpl`](../.chezmoiscripts/run_onchange_after_push-windows-configs.sh.tmpl)
copies the files to `%USERPROFILE%\.glzr`.

| File | Purpose |
| --- | --- |
| [`glazewm/config.yaml.tmpl`](glazewm/config.yaml.tmpl) | GlazeWM config: gaps, window rules, workspaces 1 to 9, binding modes and keybindings. It is a template, so edit it here, not in `~/.glzr`. |
| [`zebar/settings.json`](zebar/settings.json) | The widgets that Zebar starts. Here it is one widget: `top-bar` from the `emptope.attaquer-modified` pack. |
| [`zebar/dot_marketplace/emptope.attaquer-modified.json`](zebar/dot_marketplace/emptope.attaquer-modified.json) | The pack ID and version of that marketplace pack. The pack's own files are not in this repository. |
| [`zebar/vanilla-clear.zebar.json`](zebar/vanilla-clear.zebar.json), [`vanilla-clear.html`](zebar/vanilla-clear.html), [`styles.css`](zebar/styles.css) | A second widget, `vanilla-clear`. `settings.json` does not start it. |
| [`zebar/config.yaml`](zebar/config.yaml) | A bar config in a `bars:` format. It calls a script at a fixed path, `C:/Users/jack0/myscripts/get_keyboard_language.py`. |

## GlazeWM keybindings

GlazeWM takes its keys at the OS level, so the focused app never receives a key
that GlazeWM binds. The bindings follow these rules:

| Keys | Action |
| --- | --- |
| `alt` + arrows | Focus the window in that direction. |
| `alt` + `shift` + `h`/`j`/`k`/`l` | Move the window in that direction. |
| `alt` + `control` + `h`/`j`/`k`/`l` | Resize the window. |
| `alt` + `control` + `shift` + `h`/`j`/`k`/`l` | Move the workspace to the monitor in that direction. |
| `alt` + `control` + `1`…`9` | Focus workspace N. |
| `alt` + `shift` + `1`…`9` | Send the window to workspace N. |

> [!IMPORTANT]
> Plain `alt` with a letter or a digit belongs to tmux. Give each new GlazeWM
> binding `control` or `shift` as well as `alt`, or use an arrow key. Before you
> add a plain-`alt` binding, run `tmux list-keys -T root`. Also write
> `control`, not `ctrl`: GlazeWM drops an unknown modifier without an error,
> and the binding never fires.

The header of `config.yaml.tmpl` gives the full reasons. The template also has a
macOS branch (`alt` + `control` + arrows for focus), but
[`.chezmoiignore`](../.chezmoiignore) installs `~/.glzr` only on Windows.
