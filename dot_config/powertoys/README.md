# PowerToys

PowerToys has no configurable config path: it reads its settings from
`%LOCALAPPDATA%\Microsoft\PowerToys`, and only from there. So this directory is
the tracked copy, and
`.chezmoiscripts/run_onchange_after_link-powertoys-settings.ps1.tmpl` copies it
into place on Windows after every apply — the same arrangement as the VS Code,
Firefox and PowerShell configs. The destination is built from
`GetFolderPath('LocalApplicationData')` plus `Microsoft\PowerToys`, so no
per-user absolute path is baked into the repo.

`.chezmoiignore` keeps the tree out of the macOS and WSL2 homes, where it would
mean nothing. PowerToys is installed by `dot_config/powershell/chocolatey/packages.config`.

## Restarting

PowerToys holds its settings in memory and writes them back out whenever one
changes, so files replaced under a running instance can be overwritten again
from memory. The script warns when it finds PowerToys running; restart it to
pick the new settings up.

## What is tracked

The per-module settings only — every `settings.json`, plus the files that hold
real configuration under another name:

| File | Holds |
| --- | --- |
| `settings.json` (root) | the general settings: enabled modules, theme, startup |
| `Keyboard Manager/default.json` | the key and shortcut remappings |
| `Keyboard Manager/editorSettings.json` | the remapping editor's own state |
| `FancyZones/custom-layouts.json` | hand-drawn zone layouts |
| `FancyZones/layout-templates.json`, `default-layouts.json` | template parameters and the per-monitor defaults |
| `FancyZones/layout-hotkeys.json` | the number-key to layout bindings |
| `EnvironmentVariables/profiles.json` | the variable profiles (empty here) |
| `Workspaces/workspaces.json` | the saved app workspaces |
| `PowerToys Run/Settings/**` | the launcher's settings and its per-plugin settings |
| `*/…-settings.json` | Image Resizer, PowerRename, File Locksmith and Peek's second settings file |

The `*_version.txt` stamps next to PowerToys Run's settings are tracked with
them: they record the schema version each file was written at, and PowerToys Run
reads them to decide whether a settings file needs migrating.

`NewPlus/settings.json` is the one template here: its `TemplateLocation` is an
absolute path, so it is rendered from `%LOCALAPPDATA%` rather than committed with
this machine's username baked into it.

## What is deliberately not tracked

**Logs.** About 7,000 of the ~7,100 files in the live tree. They appear as
`Logs/`, `ModuleInterface/Logs/` and `LogsModuleInterface/`, plus a stray
`File Locksmith/last-run.log`.

**Caches, history and MRU lists** — rewritten as the tools get used, so tracking
them would put a diff in `git status` after nearly every session:

- `PowerToys Run/Settings/QueryHistory.json`, `ImageCache.json`, `Pinyin.json`,
  `UserSelectedRecord.json` (and their `_version.txt` stamps)
- `ColorPicker/colorHistory.json`
- `PowerRename/search-mru.json`, `replace-mru.json`, `power-rename-ui-flags`

**Per-machine state** — monitor IDs, virtual desktop GUIDs and window
positions, none of which mean anything on another machine:

- `FancyZones/applied-layouts.json`, `app-zone-history.json`,
  `editor-parameters.json`, `last-used-virtual-desktop.json`
- `settings-placement.json`

**Install bookkeeping and telemetry:** `UpdateState.json`,
`last_version_run.json`, `experimentation.json`, `oobe_settings.json`,
`settings-telemetry.json`.

**`NewPlus/Templates/`** — the three example files New+ ships with. Real
templates put there are user content; add them here if that changes.

**`MouseWithoutBorders/settings.json`** — it stores the pairing key in plain
text (`"SecurityKey":{"value":"…"}`), which anyone who has it can use to connect
to this machine and share its clipboard and files. It is left untracked rather
than published; the key is set by hand in the PowerToys UI on each machine. If
this needs to be tracked, the key has to come out of the file first — a
`private_` attribute is only file permissions, and does not apply on Windows.

## The `.ptb` file

`settings_134348742704088497.ptb` is an export from PowerToys' own
"Backup & restore" pane, restored by hand from the settings UI. It is not part
of the runtime tree, and the link script skips it (along with this README).
