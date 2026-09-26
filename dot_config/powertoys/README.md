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

## Refreshing this copy from the live tree

Settings changed in the PowerToys UI land in `%LOCALAPPDATA%`, not here. To
bring them back:

```console
$ bazel run //:export_powertoys_settings                # on Windows
$ bazel run //:export_powertoys_settings -- --dry-run   # look first
```

`python ~/export-powertoys-settings.py` runs the same script without bazel. It
is the inverse of the link script, and three things it deliberately does not do:

- **It does not decide what is tracked.** Only paths already in this directory
  are refreshed. Live files that are neither tracked nor on the ignore list
  below are printed as candidates and otherwise left alone, so a newly enabled
  module is adopted on purpose and a future PowerToys release cannot slip a new
  cache — or a new secret — into the repo just by existing.
- **It does not touch `NewPlus/settings.json.tmpl`.** The value a template
  action rendered to cannot be recovered from the rendered file, so the template
  is compared rather than overwritten: the templated `TemplateLocation` matches
  anything, and any other drift is reported by name for a hand edit.
- **It changes nothing but the formatting**, with one exception: the
  `VOLATILE_KEYS` table drops the session-state keys named below. It deletes
  those keys and never edits a value. Every file is parsed, re-emitted and
  re-parsed before it replaces the tracked copy; a half-written live file is
  reported and skipped, never committed.

The JSON comes out exactly as `jq .` renders it — two-space indent, keys in the
order PowerToys wrote them, non-ASCII raw, LF, no BOM — so re-exporting an
unchanged machine leaves `git status` clean. `json.dumps` does that formatting:
PowerShell's `ConvertTo-Json` truncates at `-Depth 2` and escapes non-ASCII, and
jq would be a runtime dependency for output the stdlib already matches
byte-for-byte. The one rule that has to be stated is `U+007F`, which jq escapes
and `json.dumps` does not — `PowerToys Run/settings.json` has a literal DEL in a
plugin description, so the exporter escapes it too.

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

The exporter's `IGNORED` list is this section in code — it is what decides
whether an untracked live file is passed over or reported as a candidate, so
the two have to be kept in step.

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

**Session state inside a file that is otherwise worth tracking** — dropped key
by key on the way in, rather than by leaving the whole file untracked. The
exporter's `VOLATILE_KEYS` is the list, and it only ever deletes:

- `Awake/settings.json`'s `properties.expirationDateTime`, a wall-clock stamp
  written whenever Awake is armed. It is read only in expirable mode — the
  tracked mode is `1`, indefinite — and PowerToys writes a fresh one from memory
  when it needs one, so the copy the link script pushes out is none the worse
  for arriving without it.

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
