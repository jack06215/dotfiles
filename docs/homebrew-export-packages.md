# Homebrew: How to export packages

## Export formula
```sh
brew info --formula --json=v2 $(brew list --formula) | jq -r '.formulae[] | [{name, tap}]'
```

- Export casks
```sh
brew info --cask --json=v2 $(brew list --cask) | jq -r '.casks[] | select(.depends_on != {}) | {token, tap}'
```

Since Homebrew 6.0, any non-official binary built need to perform tap trust to be able to download, see [here](https://docs.brew.sh/Tap-Trust) for details.
## Generating the Brewfile

The jq recipes above are the manual way to read out `name`/`tap` pairs.
`generate-brewfile.sh` at the repo root does the whole export in one step and
writes `Brewfile` next to it:

```sh
~/generate-brewfile.sh          # or: bash generate-brewfile.sh from the repo
```

It wraps `brew bundle dump --formula --cask --tap`, which is worth preferring
over the jq recipes because it records **tap trust inline**:

```
tap "hashicorp/tap", trusted: true
tap "dbcli/tap"
cask "vorssaint/tap/vorssaint", trusted: true
```

So the Brewfile carries the Tap-Trust state that `brew-trust-taps.txt` tracks
separately, and `brew bundle install` can reproduce it on a fresh machine
without a second list.

Two things the script handles that a bare `brew bundle dump` does not:

- **tmux.** `brew bundle dump` calls `brew services list`, which hard-refuses
  to run under tmux. The script drops `$TMUX` for that one call so it works
  from inside a pane.
- **Partial writes.** It dumps to a temp file and moves it into place, so a
  failed run leaves the committed Brewfile alone.

macOS only. `setup.sh` installs from this Brewfile on macOS
(`brew bundle install --file=Brewfile`), which retired
`brew-formula-macos.txt` and `brew-cask-macos.txt`. It also retired the
separate tap-trust pass on that path: `brew bundle install` applies every
`trusted: true` option *before* it loads any entry, and installs taps ahead of
what lives in them. The Linux path still uses `brew-formula-wsl2.txt` plus
`brew-trust-taps.txt`, so both of those stay.

### Regenerating drops what is not installed

`brew bundle dump` only emits what Homebrew recorded as installed *on request*.
Uninstall something, regenerate, and its line is gone from the repo with
nothing to notice in review. So the script diffs the old Brewfile against the
new one and prints what disappeared:

```
Dropped (in the old Brewfile, not installed on request now):
  brew lynx
  brew wordnet
Reinstall them and rerun, or restore the lines, if they are still wanted.
```

The Brewfile is still written — the warning is there so the drop is a decision
rather than an accident. Packages that exist only as dependencies of something
else in the Brewfile (`freetype`, `glib`, `node`, `shellcheck`, …) are omitted
on purpose; Homebrew pulls them in transitively.
