# lazygit config

## Settings

`disableStartupPopups: true` — skips the intro popups lazygit shows on launch.

### gui

- `nerdFontsVersion: "3"` — enables Nerd Font icons (v3 glyph set) in file/branch/commit lists.
- `filterMode: "fuzzy"` — `/` search matches fuzzy substrings instead of requiring an exact substring.
- `showRandomTip: false` — hides the random usage tip shown in the command log on startup.
- `showCommandLog: false` — hides the command log panel.
- `language: "en"` — forces English UI instead of auto-detecting from the system locale.
- `showDivergenceFromBaseBranch: arrowAndNumber` — shows ahead/behind counts (e.g. `↑2 ↓1`) next to branches in the branches panel.

### git

- `overrideGpg: true` — runs GPG signing in-process instead of spawning a subprocess, avoiding hangs with some pinentry setups.
- `parseEmoji: false` — leaves `:emoji:` codes in commit messages as literal text instead of rendering them.
- `localBranchSortOrder: recency` — sorts local branches by last checked-out time instead of commit date.
- `autoForwardBranches: allBranches` — fast-forwards every local branch that's cleanly behind its upstream, not just main/master.
- `pagers` — uses [delta](https://github.com/dandavison/delta) to render diffs with syntax highlighting.

### os

- `editPreset: nvim` — opens files in Neovim, including jump-to-line from the staging view.

## Custom commands

| Key | Context | Command |
|-----|---------|---------|
| `c` | files | Conventional commit |
| `U` | files | Amend all changes into last commit |
| `T` | files | WIP checkpoint commit and push |
| `D` | localBranches | Delete local branches merged into the default branch |
| `w` | localBranches | Watch CI checks for this branch's PR |
| `B` | localBranches | Create PR against a chosen base branch |
| `u` | commits | Find PR containing this commit |

### Conventional commit

- **Command**: prompts for a type, an optional scope, and a description, then runs `git commit -m "type(scope): description"`.
- **Context**: `files`
- **Key**: `c`
- **Why it's useful**: enforces [Conventional Commits](https://www.conventionalcommits.org/) formatting without having to remember or hand-type the syntax every time.

### Amend all changes into last commit

- **Command**: `git add -A && git commit --amend --no-edit`
- **Context**: `files`
- **Key**: `U`
- **Why it's useful**: folds any new or forgotten changes into the previous commit in one step, without opening a commit message editor.

### WIP checkpoint commit and push

- **Command**: `git add -A && git commit -m "WIP: checkpoint" --no-verify && git push`
- **Context**: `files`
- **Key**: `T`
- **Why it's useful**: gives a fast, no-friction save point (skips pre-commit hooks via `skipHookPrefix: WIP`) that's immediately backed up to the remote — handy mid-task or before risky changes.

### Delete local branches merged into the default branch

- **Command**: `git branch --merged $(git symbolic-ref --short refs/remotes/origin/HEAD) | grep -v '^\*' | xargs -r git branch -d`
- **Context**: `localBranches`
- **Key**: `D`
- **Why it's useful**: bulk-cleans stale local branches that have already landed, instead of deleting them one at a time. Requires `origin/HEAD` to be set locally (`git remote set-head origin -a`).

### Watch CI checks for this branch's PR

- **Command**: `gh pr checks --watch`
- **Context**: `localBranches`
- **Key**: `w`
- **Why it's useful**: shows live CI status for the current branch's pull request without leaving the terminal or opening a browser.

### Create PR against a chosen base branch

- **Command**: prompts for a base branch (from `git branch -r`), then runs `gh pr create --web --base <branch>`.
- **Context**: `localBranches`
- **Key**: `B`
- **Why it's useful**: covers PRs that target something other than the repo's default branch (e.g. a release branch), which lazygit's built-in "create pull request" doesn't prompt for.

### Find PR containing this commit

- **Command**: `gh pr list --search "<commit-hash>" --state all --json number,title,url --jq '...'`
- **Context**: `commits`
- **Key**: `u`
- **Why it's useful**: quickly answers "which PR introduced this?" while browsing history, without switching to a browser or the `gh` CLI directly.
