# My custom `dotfiles`

Personal, cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/).
Targets macOS (primary), WSL, plain Linux, Termux, and Windows, with
per-OS branches baked into the zsh startup sequence and into templated
config files.

## Pre-requisite

- [chezmoi](https://www.chezmoi.io/)

## Quick start

```sh
chezmoi init --apply <this-repo>
```

chezmoi prompts derive from `dot_config/chezmoi/chezmoi.toml.tmpl`, which
detects OS/arch, whether the machine is a "company machine"
(`IS_COMPANY_MACHINE` env var), and XDG paths, then exposes them to every
template as `.myComputer.*` / `.xdg.*`. `.chezmoiignore` uses the same data
to skip OS-inapplicable files (e.g. `AppData/**` is skipped everywhere
except Windows) and to drop `.tool-versions` on one specific hostname.

## Layout

Everything follows the [XDG base directory spec](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) —
`dot_zshenv` sets `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`,
`XDG_STATE_HOME`, `XDG_BIN_HOME`, then repoints dozens of tools
(cargo, go, npm, poetry, docker, gnupg, git, rustup, etc.) at XDG paths so
`$HOME` stays clean.

```
dot_zshenv                  → ~/.zshenv (XDG + tool env vars, ZDOTDIR)
dot_tool-versions           → ~/.tool-versions (asdf-managed toolchain)
dot_config/
  zsh/                      → shell config (see below)
  chezmoi/                  → chezmoi.toml.tmpl (prompt/data source)
  claude/                   → Claude Code settings + skills
  git/, gh-dash/, lazygit/  → git tooling
  starship/                 → prompt theme (Nord palette)
  wezterm/                  → terminal emulator config (Lua, templated)
  nvim/                     → LazyVim-based Neovim config
  zellij/                   → terminal multiplexer keybinds
  bottom/, btop/, htop/     → system monitors
  carapace/                 → shell completions
  npm/, pip/, pyproject/    → language package-manager config
  myscripts/, private_pet/  → misc scripts + `pet` snippet manager
dot_glzr/
  glazewm/, zebar/          → Windows tiling WM + status bar
AppData/                    → Windows-only app config (ignored elsewhere)
```

## Shell (zsh)

`ZDOTDIR` is `~/.config/zsh`; `dot_config/zsh/dot_zshrc` is a thin
loader that sources Flywheel-specific overrides (`~/.zshrc.flywheel`) if
present, then hands off to `src/init.zsh`.

`src/init.zsh` sources everything else in a fixed, commented order —
private credentials → core shell options → OS pre-init
(`darwin_pre_init` / `wsl_pre_init` / `termux_pre_init`) → asdf/rbenv →
functions → zinit plugins → history/PATH → completion (compinit then
carapace) → prompt tools (atuin, fzf, starship, zoxide) → domain modules
(aws, bazel, chezmoi, gh, git, jira, k8s, mysql, notify, pet, search) →
aliases/keybinds → OS post-init (last). Set `ZSH_DEBUG_INIT=1` or
`ZSH_PROFILE_STARTUP=1` to trace/profile startup.

Highlights under `src/`:

| File | Purpose |
| --- | --- |
| `core.zsh` | history opts, vi keybindings, `is_macos`/`is_wsl`/`is_termux` predicates |
| `zinit.zsh` | plugin manager bootstrap; `fzf-tab`, `fast-syntax-highlighting`, `zsh-autosuggestions`, `zsh-completions` |
| `functions.zsh` | `fman`, `mkcd`, `topcmds`, `csv2json`, `ls_stats`, Poetry venv activate/deactivate, `send_notification` |
| `notify.zsh` | cross-platform `notify()` (terminal-notifier on macOS, BurntToast over `pwsh` on WSL) |
| `gh.zsh` | `gh`-based PR helpers: fzf pickers (`ghpr_fzf_view`, `ghpr_fzf_open`), CI watchers (`ghpr_checks_watch`), draft PR creation |
| `git.zsh` | git helper functions |
| `jira.zsh` | `jira_workitem` (via `acli`, rendered through `myscripts/jira_render.py`), `jira_project_list` |
| `chezmoi.zsh` | `chezmoi-data`: fzf browser over `chezmoi data` output |
| `pet.zsh` | binds `Ctrl-S` to `pet search` snippet lookup |
| `meetingbar.zsh` | bridges MeetingBar → Python (`meetingbar.read_json`) for meeting notifications |
| `search.zsh` | fzf-based search helpers |
| `aws.zsh`, `bazel.zsh`, `k8s.zsh`, `mysql.zsh`, `dart.zsh` | domain-specific shortcuts |
| `zsh_python_init.zsh` | resolves the Poetry-managed venv under `python` per OS and exports `ZSH_PYTHON_BIN`, `LLM_BIN`, `RUFF_BIN`, `ALEMBIC_BIN`, `DBT_BIN`, `GDOWN_BIN` + aliases |
| `executable_sleep.zsh` / `executable_wakeup.zsh` | sleepwatcher hooks (macOS); skip weekends, gate on `sleepwatcher.should_run`, drive a Teamspirit clock-in/out script |
| `myscripts/` | standalone executables: `fzf-listprojects`, `fetch-blob`, `whisper-mic`, `transcribe-yt`, `convert-mp3-to-aiff`, AWS role listing, sleepwatcher enable/disable, etc. |
| `installed/` | Homebrew bundle manifests (`brew-formula-macos.txt`, `brew-cask-macos.txt`, `brew-wsl2-formula.txt`) and Termux setup |
| `prompt_repository/`, `template/` | reusable prompt/PR templates |

### Python workspace (`python`)

A single Poetry project (`pyproject.toml` + `dot_tool-versions`) backs
all Python tooling invoked from zsh:

- `common/` — shared utilities (subprocess execution, path/sys helpers, LangChain invocation, LLM client, logging)
- `llm_cli/` — LLM CLI plugin framework (`plugins/tools/*`, `plugins/models/*` for OpenAI/Azure backends)
- `llm_backend/` — LLM-backed helpers, e.g. `gh_create_pr_body` (generates PR descriptions from a template)
- `sleepwatcher/` — enable/disable sleepwatcher, `should_run` gate, sleep/wake hooks
- `meetingbar/` — MeetingBar notification bridge and model
- `whisper/` — Whisper transcription output post-processing
- `docx2md/`, `pptx2md/`, `xlsx2md/` — Office-document-to-Markdown converters (parser/formatter/CLI per format)
- `aws/`, `kubectl/` — AWS role/policy listing, kube context/namespace listing
- `regexlib/` — country-specific regex validators (Taiwan, Japan, international)
- `local_fs/` — filesystem utilities (e.g. copy-to-data-repo)

## Terminal & editor

- **wezterm** (`dot_config/wezterm/wezterm.lua.tmpl`) — templated via a
  small helper module (`chezmoi_tmpl.lua.tmpl`) that exposes chezmoi's
  `myComputer.*` data to Lua; picks the login shell per OS, defines
  hyperlink rules (including a custom `TICKET-123/branch-name` →
  GitHub monorepo tree link rule for Flywheel branches).
- **nvim** (`dot_config/nvim/`) — [LazyVim](https://github.com/LazyVim/LazyVim) starter, own fork at
  `jack06215/lazyvim-starter`.
- **zellij** (`dot_config/zellij/config.kdl`) — autogenerated keybind overrides.
- **starship** (`dot_config/starship/starship.toml`) — Nord palette prompt.
- **atuin, fzf, zoxide** — shell history/search/navigation, wired in `init.zsh`.
- **lazygit**, **gh-dash** — git/PR TUIs (`dot_config/lazygit`, `dot_config/gh-dash`); gh-dash is preconfigured with Flywheel-specific PR sections.
- **bottom, btop, htop** — system monitors.

## Git

`dot_config/git/config` sets `GIT_CONFIG_GLOBAL`-style global config:
`git-secrets` AWS credential-pattern scanning, a large alias set (`git a`
fzf-add, `git hist`/`git llog` graph logs, `git find` for pickaxe+diff via
fzf, rerere, GPG-signed commits, `origin main` as default branch, custom
merge helpers for unmerged files).

## Window management (Windows)

`dot_glzr/glazewm/config.yaml` + `dot_glzr/zebar/` configure
[GlazeWM](https://github.com/glzr-io/glazewm) (tiling WM) and
[Zebar](https://github.com/glzr-io/zebar) (status bar) for Windows machines.

## Claude Code

`dot_config/claude/settings.json` sets theme/editor mode; project skills
live under `dot_config/claude/skills/` (currently `commit-writer`, a
Conventional Commits-based commit skill). `myscripts/set_mcp_server_claude_desktop.py`
patches Claude Desktop's MCP server config on disk.

## Snippets & scripts

- `dot_config/private_pet/` — [pet](https://github.com/knqyf263/pet) snippet manager config + `snippet.toml`, plus a `gh_pr_reviews.py` helper for pulling PR review history via `gh`/GraphQL.
- `dot_config/myscripts/` — `jira_render.py` (renders `acli` JSON issue output), `set_mcp_server_claude_desktop.py`.

## Toolchain versions

Managed via [asdf](https://asdf-vm.com/) (`dot_tool-versions`): dasel,
helm, java (oracle-graalvm), jq, kind, kubectl, kustomize, node, python,
shellcheck, shfmt, mysql, poetry.
