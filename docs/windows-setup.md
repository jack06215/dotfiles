# Windows setup

How to bring a brand-new Windows 11 machine up to this repo's configuration.

`chezmoi init` cannot be the first step: it needs git, and `setup.ps1` needs
chezmoi. So the bootstrap is manual, and everything after it is one script.

Everything below assumes **PowerShell 7**, not the Windows PowerShell 5.1 that
ships with Windows. They are different programs with different profile
directories, and `setup.ps1` refuses to run on 5.1.

## What Windows gets, and what it does not

| Area | Windows | Where it comes from |
| --- | --- | --- |
| GUI apps, CLI utilities | yes | Chocolatey, `dot_config/powershell/chocolatey/packages.config` |
| Tools Chocolatey lacks | yes | winget, `dot_config/powershell/winget/packages.json` |
| Pinned toolchain | yes, 11 of 13 | mise, reading the same `~/.tool-versions` asdf reads elsewhere |
| PowerShell profile, `MyModule` | yes | `dot_config/powershell/`, copied into `Documents\PowerShell` |
| Neovim, VS Code, language servers | no | development happens in WSL2 |
| tmux, zsh, lynx, colordiff, ncdu | no | no native Windows build exists |
| Java, MySQL | no | see [Known gaps](#known-gaps) |

## Bootstrap on a brand-new machine

### 1. WSL2

```powershell
wsl --install
```

Reboot when it asks. This machine's distro is `ubuntu_default2404`; the WezTerm
config and `Scripts\start_wsl.ps1` both refer to it by that name.

### 2. PowerShell 7

winget ships with Windows 11 (as part of App Installer), so it is the one
package manager already present:

```powershell
winget install --id Microsoft.PowerShell --exact --accept-package-agreements
```

Close the window and **open a new PowerShell 7 terminal** (`pwsh`) for
everything that follows.

### 3. Execution policy

The profile and `setup.ps1` are local scripts, so they need more than the
default `Restricted`:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### 4. Git

```powershell
winget install --id Git.Git --exact --accept-package-agreements
```

### 5. Chocolatey, then chezmoi

Chocolatey installs machine-wide and needs an **elevated** shell. Start one with
`Start-Process pwsh -Verb RunAs`, then:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install chezmoi --yes
```

`setup.ps1` will install Chocolatey itself if it is missing, so this step exists
only to get `chezmoi` — the thing that renders `setup.ps1` in the first place.

Open a new elevated shell afterwards so `choco` and `chezmoi` are on `PATH`.

### 6. Clone and apply

```powershell
git clone https://github.com/jack06215/dotfiles $HOME\workspace\jack06215\dotfiles
chezmoi init --apply --source $HOME\workspace\jack06215\dotfiles
```

This writes `~/setup.ps1`, `~/.tool-versions`, `~/.config/powershell/` and the
rest, and runs `run_onchange_after_link-powershell-profile.ps1`, which copies the
profile and `MyModule` into `Documents\PowerShell`.

### 7. Run setup

From an **elevated** PowerShell 7 (`setup.ps1` checks, and stops if not):

```powershell
pwsh -File $HOME\setup.ps1
```

Expect 20-40 minutes on a fresh machine, most of it Chocolatey. The script does
not stop at the first failure: anything that fails is listed at the end and the
exit code is non-zero.

Useful switches:

| Switch | Effect |
| --- | --- |
| `-IncludeMinGW` | also installs the winlibs GCC toolchain into `C:\tools\mingw64`. Off by default; nothing here needs it. |
| `-IgnoreChecksums` | passes `--ignore-checksums` to Chocolatey, for packages published without one. Scoped to the single run, unlike the global `allowEmptyChecksums` the old installer menu used to enable. |

### 8. Reopen the terminal

Open a **normal, non-elevated** PowerShell 7. The profile should print
`Use 'Show-Help' to display help`, and starship, zoxide and mise should all be
active. `Show-Help` lists what the profile provides.

## Re-running

`setup.ps1` is idempotent and is the normal way to update the machine:

```powershell
pwsh -File $HOME\setup.ps1
```

Per section: Chocolatey installs what is missing then `choco upgrade all`; winget
checks each package and skips the installed ones; mise installs the pinned
versions; PowerShell modules are updated with `Update-Module`; the font is
skipped if the family is already registered.

## Manual steps `setup.ps1` deliberately does not take

### Windows Terminal settings

`dot_config/windows-terminal/settings.json` is only pushed from WSL2, by
`run_onchange_after_push-windows-configs.sh`. A native-Windows apply does not
place it. Copy it by hand if you are not provisioning from WSL2:

```powershell
$ws = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
Copy-Item $HOME\.config\windows-terminal\settings.json $ws\settings.json
```

`settings.jsonnet` is the source; regenerate `settings.json` with
`jsonnet` (which is not packaged for Windows — do it in WSL2).

### Scheduled tasks

`Scripts\sleep.ps1`, `Scripts\wakeup.ps1` and `Scripts\start_wsl.ps1` are driven
by scheduled tasks. Registering them is a machine-state change, so it is left to
you:

```powershell
Get-ScheduledTask | Where-Object TaskName -in 'Run on Sleep','Run on Wake up','Start WSL'
```

On this machine `Run on Sleep` and `Run on Wake up` exist but are **Disabled**,
and `Start WSL` is `Ready`.

### The old %APPDATA%\yazi\config

yazi's default config directory on Windows is `%APPDATA%\yazi\config`, not
`~/.config/yazi` (on Unix the latter is yazi's own default, which is why nothing
in `dot_zshenv` sets this). `YAZI_CONFIG_HOME` now points at the chezmoi-managed
directory, set in three places because each covers a different scope:

- the PowerShell profile, for interactive shells;
- `setup.ps1`, persisted at User scope, for a yazi started from Explorer or a
  non-pwsh terminal;
- `run_onchange_after_install-yazi-packages.ps1`, which chezmoi runs with
  `-NoProfile` and so inherits neither.

That leaves whatever is already in `%APPDATA%\yazi\config` unread - on this
machine `keymaps.toml`, `theme.toml` and `yazi.toml`, an older hand-maintained
set (note `keymaps.toml`, where this repo has `keymap.toml`). Nothing deletes it;
remove it by hand once you are satisfied the managed config is the one in use:

```powershell
ya pkg list   # should list 6 plugins and 1 flavor
```

`package.toml` is `.chezmoiignore`'d on Windows. `ya pkg install` rewrites every
`hash` in it from the deployed files, and those come out different on Windows
than on macOS/WSL2 at identical `rev`s, so a managed copy would make every later
apply stop on `has changed since chezmoi last wrote it` - which would also block
`setup.ps1`'s final apply. The run_onchange script seeds the file on a fresh
machine and `ya` owns it afterwards; those hashes are ya's integrity record, and
overwriting them makes it refuse to redeploy (`You have modified the contents of
the ... plugin`). If the repo's pins and the on-disk ones diverge, the script
says so and leaves them alone — reconcile with `ya pkg upgrade`.

### Retiring the Chocolatey copies of mise-managed tools

mise now owns node, python, jq, kubectl and helm. Chocolatey's copies of those
are no longer in the manifest, but an existing machine still has them installed,
and their shims in `C:\ProgramData\chocolatey\bin` stay on `PATH`.
`mise activate` prepends its own shims so mise wins in an interactive shell, but
a `-NoProfile` script or a GUI-launched tool will still find the Chocolatey one.

To clean up, from an elevated shell:

```powershell
choco uninstall nodejs python jq kubernetes-cli kubernetes-helm openjdk volta --yes
```

`volta` is in that list because it is a second Node version manager and would
compete with mise for `node`.

## Known gaps

### Java

`.tool-versions` pins `java oracle-graalvm-21.0.8`. mise's Java registry has **no
21.0.8 build at all** — not for Windows, not for any platform. 21.0.7 and 21.0.9
both exist. Chocolatey's `graalvm-java21` is stuck at 21.0.2 from January 2024
and is a community OpenJDK-based build rather than Oracle's.

Java is therefore skipped on Windows (`$MISE_SKIP_TOOLS` in `setup.ps1`), and
`.tool-versions` is left untouched so asdf on macOS and WSL2 keeps its pin. To
check whether the gap has closed:

```powershell
(Invoke-RestMethod 'https://mise-java.jdx.dev/jvm/ga/windows/x86_64.json' |
  Where-Object vendor -eq 'oracle-graalvm' |
  Where-Object version -like '21.0.8*').Count
```

### MySQL

Also skipped. mise's `vfox-mysql` plugin checks for `libncurses.so.6`,
`libaio.so.1` and `libnuma.so.1` through apt/dnf/pacman and calls `uname`; the
asdf fallback is a bash plugin. Neither works on native Windows. Use the WSL2
MySQL, which is what `src/mysql.zsh` targets anyway.

### Version drift on first run

On an existing machine, mise takes over tools Chocolatey had installed at
different versions, so the first run moves some of them **down** to the pinned
version:

| Tool | Chocolatey had | `.tool-versions` pins |
| --- | --- | --- |
| nodejs | 24.2.0 | 23.9.0 |
| python | 3.13.5 | 3.13.13 |
| jq | 1.7.1 | 1.8.2 |
| kubectl | 1.33.2 | 1.36.2 |
| helm | 3.18.2 | 4.2.2 |

This is the point of the change — `.tool-versions` becomes the single source of
truth — but it is a downgrade for node.

## Package manifests

### Chocolatey

`dot_config/powershell/chocolatey/packages.config`, fed to `choco install`.
Regenerate from what the machine has installed:

```powershell
pwsh -File $HOME\generate-chocofile.ps1
```

This is the counterpart of `generate-brewfile.sh`. Chocolatey has no
`brew leaves`, so the script derives one: any installed package that appears as
a `<dependency>` in another installed package's `.nuspec` is a dependency rather
than something asked for. That drops the `*.install` shims, `vcredist*`, the
`KB*` hotfixes, `chocolatey-*.extension` and `webview2-runtime`.

Like `brew bundle dump`, it rewrites the file wholesale, so re-apply the
curation from the diff afterwards — the header comment in the manifest lists the
rules. There is no Bazel target, unlike the Brewfile exporters: `BUILD.bazel`
drives those through `sh_binary`, which cannot wrap a `.ps1`.

### winget

`dot_config/powershell/winget/packages.json`, for tools Chocolatey has no
package for. JSON allows no comments, so the reasons live here:

| Package | Why winget |
| --- | --- |
| `jdx.mise` | not on Chocolatey |
| `Atuinsh.Atuin` | not on Chocolatey |
| `rsteube.Carapace` | not on Chocolatey |
| `charmbracelet.gum` | not on Chocolatey |
| `fullstorydev.grpcurl` | not on Chocolatey |
| `Zellij.Zellij` | not on Chocolatey; this is the official package, not the `arndawg` community fork |
| `aristocratos.btop4win` | btop itself is Unix-only; this is the same author's Windows port |
| `chmln.sd` | **Chocolatey's `sd` is an HF contest logger for ham radio**, not the sed alternative |

`setup.ps1` does **not** use `winget import`. Passing `--no-upgrade` to it still
reinstalls an already-installed package in place, so the script checks each id
with `winget list` and installs only what is missing — which is what makes a
rerun a genuine no-op.

`win32yank` stays on Chocolatey even though winget has a newer 0.1.1:
`.chezmoi.toml.tmpl` locates it under `C:\ProgramData\chocolatey\lib`, and
WSL2's `pbcopy`/`pbpaste` break if it moves.

## How the profile reaches `$PROFILE`

pwsh reads `$PROFILE` from `Documents\PowerShell`, and that directory is also the
only per-user entry on `$env:PSModulePath` — so `Modules\MyModule` has to be
there, not under `.config`. Two paths put it there:

- **Native Windows**: `chezmoi apply` writes `~/.config/powershell/`, then
  `run_onchange_after_link-powershell-profile.ps1` copies the tree into
  `Documents\PowerShell`. It resolves the folder with
  `[Environment]::GetFolderPath('MyDocuments')`, so a OneDrive-redirected
  Documents still works. It copies rather than symlinks, because symlinks on
  Windows need admin rights or Developer Mode. It deletes nothing, so the
  gallery modules and the `Help\` tree survive.
- **From WSL2**: `run_onchange_after_push-windows-configs.sh` writes the same
  files into `%USERPROFILE%\Documents\PowerShell` alongside the WezTerm, GlazeWM,
  Zebar, VS Code and Firefox configs. This path assumes Documents is not
  OneDrive-redirected, since `GetFolderPath` is not reachable from WSL.

Both scripts rerun whenever any file under `dot_config/powershell/` changes: the
rendered script carries a hash taken over the whole tree, so adding a file needs
no edit to either script.

The profile itself is deliberately **not** a chezmoi template. The same file is
pushed to Windows from WSL2, where `.xdg.configHome` is a Linux path, so baking
paths in at render time would produce a profile full of `/home/<user>/...`.
`$env:STARSHIP_CONFIG` and friends are resolved at runtime instead.

## Troubleshooting

**The profile warns that a module is not installed.** `setup.ps1` has not run, or
its PowerShell-modules section failed. Rerun it.

**`mise` is not found, so no pinned tools are on `PATH`.** mise comes from the
winget manifest. Check `winget list --id jdx.mise`, then reopen the terminal —
`mise activate` runs from the profile.

**`mise activate pwsh` errors.** It needs PowerShell 7.2 or newer, and it breaks
if mise's install path contains spaces.

**Starship shows the wrong theme.** The profile used to point
`$env:STARSHIP_CONFIG` at `~/.starship/starship.toml`, an unmanaged copy. It now
points at `~/.config/starship/starship.toml`. Delete the stale `~/.starship`
directory if it is still there.

**`choco install` fails on a checksum.** Rerun with `-IgnoreChecksums`.

**`setup.ps1` says it must run as Administrator.** Chocolatey installs
machine-wide. `Start-Process pwsh -Verb RunAs`, then rerun.

**A `.bak-<timestamp>` file appeared next to the profile.** The link script found
a `Microsoft.PowerShell_profile.ps1` it had not written and backed it up once
before taking over. It only does this when no backup exists yet, so it will not
accumulate.
