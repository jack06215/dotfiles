# Refactoring shell workflows with `gum`

A proposal for finishing the `gum` migration that `dot_config/zsh/src/git.zsh`
started.

Verified against **gum 0.17.0** (`/opt/homebrew/bin/gum`) and **gh 2.x** on
macOS. Every flag used below was checked against `gum <cmd> --help` on this
machine, not recalled from the README.

## Status: implemented on `feat/gum-workflows`

Everything below is landed except two items deliberately dropped, plus two
places where the proposal was wrong and the implementation diverges. Read those
four notes before treating this document as a description of the code.

**Deliberately not implemented**

- **§8 `wsl.zsh` (`pbexec`).** Skipped. `gum` was only added to
  `brew-formula-macos.txt`, so a gum call there would land on a machine without
  it. The raw `read -r ans` prompt stays.
- **§8 `aws_login`.** Skipped. `gum spin` gives the wrapped command no TTY for
  *input*, and `aws login` may need a device code typed or a browser
  interaction, so the spinner risked hanging the login. `aws_login` is
  unchanged.

**Corrections to this document**

- **§7c is wrong about ordering.** It claims gum "is guaranteed installed by
  this point (it runs after `upgrade_homebrew_packages`)". It does not —
  `setup_macos` calls `brew_trust_taps` *before* `upgrade_homebrew_packages`,
  which is what installs gum. The implementation therefore routes every tap
  through a `run_step` helper that falls back to a plain `echo` + direct call
  when gum is absent, and a first run takes that fallback throughout.
- **§8 `jira_project_list` is wrong about the hand-off.** It suggests piping the
  pick "straight into `jira_workitem`". `acli jira project list` returns
  *project* keys; `jira_workitem` expects an *issue* key. The implementation
  renders the table and prints the selected project key, and stops there.

**One addition beyond the proposal**

- `ghpr_checks_watch` now rejects an empty check array. The `all(.[]; …)`
  settled test is vacuously true on `[]`, so a PR with no checks configured
  would have fired an "all checks passed" notification.

The `gh.zsh` work went further than §5a described: per review, `ghpr_fzf_view`
folded into `ghpr` as well, and `ghpr_watch` was rewritten to call gh's native
`--watch` directly rather than through the deleted flag parser. That file went
from 12 functions to 9.

---

## 1. State of play

This is not a greenfield "introduce gum" exercise. You already did the hard
part:

| File | gum call sites | Status |
| --- | ---: | --- |
| `dot_config/zsh/src/git.zsh` | 27 | Migrated — `gbr`, `gcm`, `grb`, `grbc`, `gfix` |
| `dot_config/zsh/src/aws.zsh` | 3 | Migrated — `_aws_choose_profile` |
| `dot_config/zsh/src/functions.zsh` | 1 | The shared `_check_gum_cmd` guard |
| everything else | 0 | — |

The history reads `7c1067f init git gum workflow` → `0eb1b39 more gum workflow`
→ `99a9c51 gcm add files select`. The house style is already established:

- guard with `_check_gum_cmd || return 1` at the top of any function that needs gum
- `gum choose --label-delimiter="|"` for `label|value` menus
- `gum filter --header=... --placeholder=...` for longer lists
- `gum confirm` immediately before anything destructive
- comments explain *why*, in full sentences, above the code they describe

Everything proposed below follows that style rather than inventing a new one.

---

## 2. The decision rule: gum vs fzf

You asked to keep fzf where preview matters. That maps onto a hard technical
constraint, which is worth writing down so the boundary stops being a judgement
call:

> **`gum filter` and `gum choose` have no `--preview` flag.** Confirmed against
> `gum filter --help` on 0.17.0 — there is `--header`, `--placeholder`,
> `--height`, `--limit`/`--no-limit`, `--fuzzy`, `--strip-ansi`, but no preview
> pane and no `--bind`.

So:

**Use `gum` for** — `confirm` (yes/no), `input` (one line), `input --password`
(secrets), `write` (multi-line), `spin` (waiting), `style` (headers/banners),
`format` (markdown/code), `log` (levelled status lines), `table` (columnar
picks), and short pickers where the label is self-describing.

**Keep `fzf` for** — any picker whose value comes from the preview pane or from
`--bind`/`reload`. In this repo that is:

- `ghpr_fzf_view`, `ghpr_fzf_open` (`gh.zsh`) — preview renders PR title + branch
- `ghpr_fzf_checks_open` (`gh.zsh`) — preview shows state/check/link
- `chezmoi_data` (`chezmoi.zsh`) — preview runs `jq getpath` per key
- all of `bazel.zsh` — preview runs `bazel query --output=build`
- `rgsearch` (`search.zsh`) — `start:reload` / `change:reload` live re-query
- `vimfind`, `vimrecent` (`search.zsh`), `fzf-listprojects` — `bat`/git previews

Converting any of those would be a downgrade. They are explicitly out of scope.

The productive combination is **fzf to pick the thing, gum to decide what to do
with it** — which is exactly what §5 proposes for `gh.zsh`.

---

## 3. P0 — the bootstrap bug

**`gum` is installed on this machine but is in none of the brew manifests.**

```
$ grep -in 'gum\|fzf' brew-formula-macos.txt brew-formula-wsl2.txt
brew-formula-wsl2.txt:25:fzf
brew-formula-macos.txt:44:fzf
```

`fzf` is there. `gum` is not — not in `brew-formula-macos.txt`, not in
`brew-formula-wsl2.txt`, not in `brew-cask-macos.txt`. `setup.sh.tmpl` installs
strictly from those files via `xargs -a "${formula_file}" brew install`.

So a fresh `chezmoi init --apply` on a new Mac produces a shell where `gbr`,
`gcm`, `grb`, `grbc`, `gfix`, `aws_login` and `aws_get_caller_identity` all fail
with `... requires 'gum' to be installed.` Your daily commit flow is dead on
arrival until you notice and `brew install gum` by hand.

**Fix** — add `gum` to `brew-formula-macos.txt`, keeping the file's existing
alphabetical grouping:

```diff
  fzf
+ gum
```

This is a one-line change and it is the highest-value item in this document.
Everything else is an improvement; this one is a repair.

---

## 4. P1 — `gcg`, the last un-migrated git function

`git.zsh:72`. Every other function in this file was migrated; `gcg` was left
behind, and it is the most destructive one in the repo.

### Current

```zsh
function gcg() {
  # git clean gone
  local branches
  branches=$(git branch -vv | grep ': gone]' | awk '{print $1}')

  if [[ -z "$branches" ]]; then
    echo "No gone branches found."
    return 0
  fi

  echo "Deleting the following branches:"
  echo "$branches"
  echo

  read "confirm?Are you sure? (y/N): "
  if [[ "$confirm" != "y" ]]; then
    echo "Cancelled."
    return 1
  fi

  echo "$branches" | xargs -I {} git branch -D {}
}
```

Four separate problems:

1. **All-or-nothing.** No way to spare one branch. You either nuke every gone
   branch or none.
2. **`-D`, always.** Force-delete with no merged/unmerged distinction. Unpushed
   work on a branch whose upstream was deleted is gone silently.
3. **The `awk '{print $1}'` bug.** `git branch -vv` prefixes the checked-out
   branch with `* `, so if the *current* branch is gone, this emits `*` and the
   pipeline runs `git branch -D '*'`, which fails with "branch '*' not found"
   and is swallowed. The branch you were most likely to care about is the one
   it silently skips.
4. `read "confirm?..."` is the only raw prompt left in the file.

### Proposed

```zsh
function gcg() {
  # git clean gone: delete local branches whose upstream has been deleted.
  _check_gum_cmd || return 1

  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
    echo "Not a git repository." >&2
    return 1
  }

  local current out b
  local -a gone picked unmerged

  # for-each-ref rather than `git branch -vv | awk '{print $1}'`: that pipeline
  # returns "*" for the checked-out branch, so the branch most likely to matter
  # is the one it silently fails to delete.
  gone=(${(f)"$(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads \
    | awk '$2 == "[gone]" { print $1 }')"})

  ((${#gone})) || {
    echo "No gone branches found. (git fetch --prune first if that seems wrong.)"
    return 0
  }

  # A checked-out branch cannot be deleted, so keep it out of the menu rather
  # than letting the pick fail later at the git call.
  current=$(git symbolic-ref --short HEAD 2> /dev/null)
  [[ -n "$current" ]] && gone=(${gone:#$current})

  ((${#gone})) || {
    echo "Only '$current' is gone, and it is checked out - switch away first."
    return 0
  }

  # --selected='*' starts with everything ticked, so the common case is still
  # one keystroke, but sparing a branch no longer means aborting the whole run.
  out=$(printf '%s\n' "${gone[@]}" \
    | gum choose --no-limit \
      --height=15 \
      --selected='*' \
      --header="Delete which gone branches? (tab to toggle, enter to confirm)") || return 1

  picked=(${(f)out})
  ((${#picked})) || return 0

  # -d refuses anything not merged into HEAD. Collect the refusals rather than
  # reaching for -D up front, so the force is a separate informed decision.
  for b in "${picked[@]}"; do
    git branch -d "$b" 2> /dev/null || unmerged+=("$b")
  done

  ((${#unmerged})) || return 0

  echo "Not fully merged into ${current:-HEAD}:"
  printf '  %s\n' "${unmerged[@]}"

  # --default=false makes "No" the resting position; gum confirm otherwise
  # defaults to Yes, which is the wrong way round for an unrecoverable delete.
  gum confirm "Force-delete these ${#unmerged} branch(es)?" --default=false || return 1

  git branch -D -- "${unmerged[@]}"
}
```

**Payoff** — the safe branches delete silently with `-d`; only genuinely
unmerged work reaches a prompt, and that prompt names exactly which branches are
at risk. The `*` bug is gone.

---

## 5. P2 — `gh.zsh`, the biggest un-migrated surface

284 lines, zero gum. Three distinct opportunities.

### 5a. Retire the `return 10` flag hack

`gh.zsh:17-45` defines `__gh_parse_pbcopy_flag`, which signals "pbcopy mode" by
**returning exit code 10** and printing the remaining args to stdout. Four
functions (`ghpr_view`, `ghpr_url`, `ghpr_watch`, `ghpr_fzf_open`) each re-parse
it and each branch on `(( rc == 10 ))`.

It works, but the cost is real: an out-of-band exit code doubles as data, every
caller repeats the same six lines of parsing, and adding a fifth output format
means touching five functions.

The insight is that `--pbcopy` is not a flag — it is *one of several things you
might want to do with a PR you have already chosen*. That is a menu.

```zsh
# Pick once with fzf (the preview is the point), then act repeatedly from a gum
# menu. Replaces ghpr_view / ghpr_url / ghpr_open / ghpr_fzf_open and the
# --pbcopy flag that each of them parsed separately.
function ghpr() {
  _check_gum_cmd || return 1

  local pr action body

  # Unchanged: this is the existing ghpr_fzf_open picker, kept on fzf because
  # the preview pane renders the PR title, branch and body while you scroll.
  pr="$(_ghpr_fzf_pick "$@")" || return
  [[ -n "$pr" ]] || return

  while true; do
    action=$(printf '%s\n' \
      "view      Read the PR body in a pager|view" \
      "web       Open the PR in a browser|web" \
      "url       Copy the PR URL|url" \
      "branch    Copy the head branch name|branch" \
      "body      Copy title + body as Markdown|body" \
      "checks    Watch CI until it settles|checks" \
      "quit      Done|quit" \
      | gum choose --label-delimiter="|" \
        --height=9 \
        --header="PR #$pr - what next?") || return

    case "$action" in
      view)
        gh pr view "$pr" --json title,body --jq '"# " + .title + "\n\n" + .body' \
          | gum format -t markdown | gum pager
        ;;
      web) gh pr view -w "$pr" ;;
      url)
        gh pr view "$pr" --json url --jq .url | tr -d '\n' | pbcopy
        gum log --level info "copied" what "PR url"
        ;;
      branch)
        gh pr view "$pr" --json headRefName --jq .headRefName | tr -d '\n' | pbcopy
        gum log --level info "copied" what "head branch"
        ;;
      body)
        gh pr view "$pr" --json title,body --jq '"# " + .title + "\n\n" + .body' | pbcopy
        gum log --level info "copied" what "title + body as Markdown"
        ;;
      checks) ghpr_checks_watch "$pr" ;;
      quit) return 0 ;;
    esac
  done
}
```

`_ghpr_fzf_pick` is the body of your existing `ghpr_fzf_open` picker lifted into
its own function, unchanged — the fzf preview stays exactly as it is.

**Payoff** — one entry point instead of four; the loop means "look at the body,
then copy the branch, then watch CI" is one `ghpr` invocation rather than three
commands and three re-picks. Adding a new action is one line in one array.
`__gh_parse_pbcopy_flag` and `__gh_copy` both delete.

### 5b. `ghpr_checks_watch` — let `gh` and `gum` do the work

`gh.zsh:218`. The current implementation hand-rolls a `while true; clear; …
sleep` loop and string-matches four state values in four separate `jq`
expressions. Two things make most of it unnecessary:

- **`gh pr checks --json` emits a `bucket` field** that categorises `state` into
  exactly `pass` / `fail` / `pending` / `skipping` / `cancel`. Confirmed in
  `gh pr checks --help`. Your four-way `.state=="FAILURE" or .state=="CANCELLED"
  … .state!="PENDING" and .state!="IN_PROGRESS"` matching collapses into
  `bucket` tests.
- **`clear` wipes the scrollback** every interval, including whatever you were
  looking at before you started watching.

There is also a redundancy worth resolving: `ghpr_watch` (`gh.zsh:85`) already
shells out to `gh pr checks --watch -i 3`, gh's *native* watch. So the repo has
both a native watcher and a hand-rolled one. `ghpr_checks_watch` earns its
existence only through the desktop notification — so keep that, drop the rest.

```zsh
function ghpr_checks_watch() {
  _check_gum_cmd || return 1

  local pr="${1:-}" interval="${2:-5}" checks rc failed
  local -a args
  [[ -n "$pr" ]] && args=("$pr")

  while true; do
    # gum spin passes the command's stdout through when stdout is not a TTY,
    # so $(...) still captures the JSON while the spinner draws on stderr.
    # --show-error keeps the spinner clean unless the fetch itself breaks.
    checks=$(gum spin --spinner=minidot --show-error \
      --title="Checking CI${pr:+ on PR #$pr}..." -- \
      gh pr checks "${args[@]}" --json name,state,bucket)
    rc=$?

    # gh exits 8 while checks are still pending and 1 when one has failed, so
    # a non-zero exit here is normal mid-run. Only an empty payload is fatal.
    if [[ -z "$checks" ]]; then
      echo "Could not read checks (gh exit $rc)." >&2
      return 1
    fi

    # A bordered table redrawn in place of the old `clear`: readable at a
    # glance, and it does not wipe what was on screen before the watch started.
    jq -r '["STATE","CHECK"], (.[] | [.state, .name]) | @csv' <<< "$checks" \
      | gum table --print --border=rounded --widths=14,60

    if jq -e 'any(.[]; .bucket == "fail" or .bucket == "cancel")' <<< "$checks" > /dev/null; then
      failed=$(jq -r '.[] | select(.bucket == "fail" or .bucket == "cancel") | .name' <<< "$checks")
      gum log --level error --time kitchen "CI failed" checks "${failed//$'\n'/, }"
      notify_error "CI failed: ${failed//$'\n'/, }"
      return 1
    fi

    if jq -e 'all(.[]; .bucket != "pending")' <<< "$checks" > /dev/null; then
      gum log --level info --time kitchen "All checks passed"
      notify_news "All checks passed (including SKIPPED)"
      return 0
    fi

    sleep "$interval"
  done
}
```

> **Verified on this machine:** `out=$(gum spin --title=x -- printf 'CAPTURED\n')`
> yields `CAPTURED`. Passing `--show-stdout` makes it explicit if you prefer not
> to rely on the TTY check.

**Payoff** — four brittle state-string comparisons become two `bucket` tests;
the exit-code-8 trap that would break a naive `|| return 1` is handled; the
screen stops being wiped; and the function gains the PR-number argument it
needed to be callable from the `ghpr` menu in 5a.

### 5c. `ghpr_create` — wire in the dead-code safety check

`git.zsh:350` defines `check_pushed_to_remote`. **It is never called.**

```
$ grep -rn "check_pushed_to_remote" --include="*.zsh" .
dot_config/zsh/src/git.zsh:350:function check_pushed_to_remote() {
```

Twenty lines of correct, careful branch/upstream validation, dead in the tree.
Meanwhile `ghpr_create` (`gh.zsh:189`) checks only whether a PR already exists,
then runs `gh pr create --draft` — which fails confusingly if the branch was
never pushed.

To be precise about what is and is not missing here: `gh pr create --draft`
**does** prompt for title and body interactively, so gum should not try to
replace that. The gaps are the pre-flight check and the base branch.

```zsh
function ghpr_create() {
  _check_gum_cmd || return 1

  if gh pr view > /dev/null 2>&1; then
    echo "Pull request already exists for this branch." >&2
    return 1
  fi

  # check_pushed_to_remote already reports precisely why it failed (no branch /
  # no upstream / ahead of upstream), so offer the fix rather than repeating it.
  if ! check_pushed_to_remote; then
    gum confirm "Push this branch to origin first?" || return 1
    gum spin --spinner=minidot --show-error --title="Pushing..." -- \
      git push -u origin HEAD || return 1
  fi

  local base
  base=$(git branch -r --format='%(refname:lstrip=3)' \
    | grep -v '^HEAD$' \
    | gum filter --header="Open the PR against which base branch?" \
      --placeholder="base") || return
  [[ -n "$base" ]] || return 1

  # gh prompts for title and body itself; do not duplicate that in gum.
  gh pr create --draft --base "$base" || return 1
  gh pr view --web
}
```

**Payoff** — twenty lines of dead code start earning their keep, the "you forgot
to push" failure becomes a one-keystroke fix instead of a cryptic gh error, and
the base branch stops being an implicit default.

---

## 6. P3 — `k8s.zsh`, where a pet snippet is doing a function's job

The entire file is 13 lines:

```zsh
function k() {
  local ctx="${CONTEXT:-${KUBE_CONTEXT:-}}"
  local ns="${NAMESPACE:-default}"
  local cmd=(kubectl)
  [[ -n "$ctx" ]] && cmd+=(--context "$ctx")
  cmd+=(-n "$ns" "$@")
  ...
}
```

Context and namespace come from environment variables with **no way to set them
interactively**. The evidence that this hurts is in `snippet.toml`:

```toml
[[snippets]]
    description = "kubectl with context and namespace"
    command = "kubectl --context <context=opal-staging> --namespace <namespace> <subcommand>"
```

You built a pet snippet to work around your own shell function. Two small
additions close that loop.

```zsh
# Choose the kube context for this shell. Exported rather than written to
# kubeconfig with `use-context`, so two terminals can sit on two clusters.
function kctx() {
  _check_gum_cmd || return 1

  local ctx
  ctx=$(kubectl config get-contexts -o name \
    | gum filter --header="Which context?" --placeholder="context") || return
  [[ -n "$ctx" ]] || return 1

  export KUBE_CONTEXT="$ctx"
  gum log --level info "context" "$ctx"
}

# Choose the namespace for this shell, listed from the current context.
function kns() {
  _check_gum_cmd || return 1

  local ns out
  local -a ctx_args
  [[ -n "${KUBE_CONTEXT:-}" ]] && ctx_args=(--context "$KUBE_CONTEXT")

  # Listing namespaces is a network round trip; the spinner is the difference
  # between "thinking" and "hung" on a slow VPN.
  out=$(gum spin --spinner=minidot --show-error \
    --title="Listing namespaces${KUBE_CONTEXT:+ on $KUBE_CONTEXT}..." -- \
    kubectl "${ctx_args[@]}" get namespace \
      -o custom-columns=NAME:.metadata.name --no-headers) || return 1

  ns=$(printf '%s\n' "$out" \
    | gum filter --header="Which namespace?" --placeholder="namespace") || return
  [[ -n "$ns" ]] || return 1

  export NAMESPACE="$ns"
  gum log --level info "namespace" "$ns"
}
```

`k()` needs no change — it already reads `KUBE_CONTEXT` and `NAMESPACE`. These
just give you a way to set them without retyping.

**Payoff** — the snippet stops being needed; `k get pods` works after two
pickers instead of an `export` you have to remember the spelling of. Consider
surfacing both in the prompt via `starship`'s kubernetes module so the exported
values are visible.

---

## 7. P4 — `setup.sh.tmpl`, the first thing a new machine shows you

Three targeted changes. Note this file is **bash**, not zsh (`#!/usr/bin/env
bash`, `set -euo pipefail -o posix`), and it runs on a machine where gum may not
be installed yet — so every gum use here needs a fallback, unlike the zsh
functions.

### 7a. Hand-rolled ANSI → `gum style`

```zsh
# Current, setup.sh.tmpl:129
function section() {
  local msg="$1" color='' reset=''
  if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    color=$'\033[1;34m'
    reset=$'\033[0m'
  fi
  printf '\n%s==>%s %s\n' "${color}" "${reset}" "${msg}"
}
```

```zsh
# Proposed - gum when available, the existing ANSI path when it is not, because
# this script is what installs gum in the first place.
function section() {
  local msg="$1"
  if command -v gum > /dev/null 2>&1 && [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    gum style --foreground=39 --bold --border=rounded --padding="0 2" --margin="1 0" "${msg}"
    return
  fi
  local color='' reset=''
  if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    color=$'\033[1;34m'
    reset=$'\033[0m'
  fi
  printf '\n%s==>%s %s\n' "${color}" "${reset}" "${msg}"
}
```

### 7b. The Xcode CLT poll (`setup.sh.tmpl:70`)

```bash
until xcode-select -p &> /dev/null; do
  sleep 5
done
```

A silent, indefinite wait on a GUI dialog. This is exactly what `gum spin` is
for:

```bash
if command -v gum > /dev/null 2>&1; then
  gum spin --spinner=moon --title="Waiting for Xcode Command Line Tools (accept the GUI prompt)..." -- \
    bash -c 'until xcode-select -p &> /dev/null; do sleep 5; done'
else
  until xcode-select -p &> /dev/null; do sleep 5; done
fi
```

Realistically the CLT install runs *before* Homebrew, hence before gum exists —
so this one will usually take the fallback path. Worth doing anyway for reruns.

### 7c. `brew_trust_taps` (`setup.sh.tmpl:180`) — the best fit in the file

This loop runs `brew tap` then `brew trust` per tap, echoing "Tapping X…" and
collecting failures. Both commands are slow and network-bound, and gum is
guaranteed installed by this point (it runs after `upgrade_homebrew_packages`).

```bash
for tap in "${taps[@]}"; do
  if ! gum spin --spinner=dot --show-error --title="Tapping ${tap}..." -- brew tap "${tap}"; then
    failed+=("${tap}")
    continue
  fi
  if ! gum spin --spinner=dot --show-error --title="Trusting ${tap}..." -- brew trust "${tap}"; then
    failed+=("${tap}")
  fi
done

if (( ${#failed[@]} )); then
  gum style --foreground=196 --bold "Failed to tap/trust: ${failed[*]}"
  return 1
fi
gum style --foreground=42 "All taps added and trusted."
```

`--show-error` is the key flag: silent on success, full output on failure.

**Payoff** — cosmetic, but bootstrap is the one script you run when you are
least able to debug it, and "is it hung or is it working" is the question it
currently cannot answer.

---

## 8. Tier 2 — small, self-contained wins

Not prioritised, but each is a ten-minute change.

| Site | Now | With gum |
| --- | --- | --- |
| `functions.zsh:169` `export_secret` | `read -rs` + manual `echo >&2` + `printf -v` | `gum input --password --header="Enter ${var_name}"` — one line, correct masking, no terminal-state juggling |
| `functions.zsh:68` `preview_sound` | zsh `select` builtin (renders a numbered list you must type an index into, and loops forever) | `gum filter` over `/System/Library/Sounds/*.aiff` → `afplay`; pairs naturally with `convert-mp3-to-aiff --install` |
| `myscripts/executable_uniqlo-akamai` | `printf "…[y/n]: "` + `read answer` + `case` | `gum format -t code -l bash` to show the payload, `gum confirm` to run it |
| `jira.zsh:22` `jira_project_list` | `jq -r '.[] \| {key,name,uuid}' \| cat` — raw JSON dump | `jq -r '.[] \| [.key,.name] \| @csv' \| gum table -c KEY,NAME -r 1` → pipe straight into `jira_workitem` |
| `bazel.zsh:56` `_bazel_buffer_and_pick` | `bazel query` writes to a temp file with stderr on `/dev/tty`; no progress indication | wrap the query in `gum spin --show-error --title="Querying targets..."`; **keep the fzf pick** — the `bazel query --output=build` preview is the whole point |
| `aws.zsh:56` `aws_login` | `aws login --profile "$profile"` with no feedback | `gum spin --show-output` — SSO login is slow and prints a device code you must actually read, so `--show-output` not `--show-error` |
| `wsl.zsh:13` | `read -r ans` | `gum confirm` (macOS-only priority, so low urgency) |

### Not recommended: a gum-based pet replacement

Worth naming explicitly since it looks tempting. Your 33 snippets in
`snippet.toml` use pet's `<param=default>` placeholder syntax, and it would be
easy to build a `gum filter` snippet picker that prompts for each placeholder
with `gum input`. Resist it: `pet search` already does this, it is bound to
`^O` in `pet.zsh`, and it writes the result into `BUFFER` so you can edit before
executing. A gum rewrite would lose the `BUFFER` integration, which is the best
part. Leave pet alone.

---

## 9. Suggested sequencing

1. **`gum` → `brew-formula-macos.txt`.** One line. Do it first; everything else
   assumes gum is present. (§3)
2. **`gcg`.** Self-contained, removes a real data-loss path and a real bug, and
   completes `git.zsh`. (§4)
3. **`ghpr_checks_watch` → `bucket`.** Independent of the rest of `gh.zsh` and
   makes the function callable with a PR number, which 5a depends on. (§5b)
4. **`ghpr` action menu.** The largest change; do it once 5b lands so `checks`
   works from the menu. Delete `__gh_parse_pbcopy_flag`, `__gh_copy`,
   `ghpr_view`, `ghpr_url`, `ghpr_open`, `ghpr_fzf_open` as it goes in. (§5a)
5. **`ghpr_create` + `check_pushed_to_remote`.** Small, and stops the dead code
   from rotting further. (§5c)
6. **`kctx` / `kns`.** Independent of everything above. (§6)
7. **`setup.sh.tmpl`.** Cosmetic; land it whenever. (§7)
8. **Tier 2** as the mood takes you. (§8)

Steps 1–2 are worth doing regardless of whether the rest of this proposal
survives review. Step 1 is a bug fix; step 2 closes a hole through which unmerged
work can quietly disappear.

---

## Appendix — gum 0.17.0 flags used here

Checked against `gum <subcommand> --help` on this machine, since several differ
from what the README shows.

| Command | Flags relied on |
| --- | --- |
| `choose` | `--no-limit`, `--height`, `--header`, `--label-delimiter`, `--selected` (`'*'` selects all) |
| `filter` | `--header`, `--placeholder`, `--height`, `--limit`/`--no-limit`, `--fuzzy` — **no `--preview`** |
| `confirm` | `--default` (`=false` makes No the resting position), `--affirmative`, `--negative`, `--timeout` |
| `input` | `--header`, `--placeholder`, `--password`, `--value`, `--char-limit` |
| `write` | `--header`, `--height`, `--placeholder`, `--show-line-numbers` |
| `spin` | `--spinner`, `--title`, `--show-output`, `--show-error`, `--show-stdout`, `--show-stderr` |
| `log` | `--level`, `--structured`, `--time` (`kitchen`, `rfc822`, …), `--prefix`, `--min-level` |
| `table` | `--print`, `--columns`, `--separator`, `--widths`, `--border`, `--return-column` |
| `style` | `--foreground`, `--border`, `--padding`, `--margin`, `--bold`, `--align`, `--width` |
| `format` | `-t markdown\|code\|template\|emoji`, `-l <language>`, `--theme` |
| `pager` | `--show-line-numbers`, `--soft-wrap` |

Two behaviours confirmed empirically rather than from docs:

- `$(gum spin -- cmd)` **does** capture the command's stdout — gum passes it
  through when stdout is not a TTY. `--show-stdout` makes it explicit.
- `gum table --print` parses `jq -r '… | @csv'` output correctly, including
  quoted fields containing spaces and slashes.

And one `gh` behaviour that shapes §5b:

- `gh pr checks` uses **exit code 8 for "checks pending"** and 1 for failure, so
  a naive `|| return 1` around it breaks mid-run. Its `--json` output includes a
  `bucket` field (`pass`/`fail`/`pending`/`skipping`/`cancel`) that replaces
  hand-rolled `state` string matching.
