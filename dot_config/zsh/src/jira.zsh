# shellcheck shell=bash
# shellcheck disable=SC1091

# Callers must use `_check_gum_cmd || return 1`: on its own the call reports
# the problem but does not stop the caller from running on without gum.
source "$ZDOTDIR/src/functions.zsh"

function jira_workitem() {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo "Usage: jira_workitem <ISSUE-KEY|URL>" >&2
    return 1
  fi

  # Extract key from URL if a URL is given, otherwise use as-is
  local key
  if [[ "$input" == https://* ]]; then
    key="${input##*/browse/}"
  else
    key="$input"
  fi

  acli jira workitem view "$key" --json \
    --fields 'key,issuetype,summary,status,assignee,description,comment' \
    | python "${XDG_CONFIG_HOME}"/myscripts/jira_render.py
}

function jira_project_list() {
  _check_gum_cmd || return 1

  local out key

  out=$(gum spin --spinner=minidot --show-error \
    --title="Listing Jira projects..." -- \
    acli jira project list --paginate --json) || return 1

  # --return-column=1 hands back just the KEY rather than the whole row, so the
  # pick is usable as-is. Note this is a *project* key, not an issue key, so it
  # deliberately does not feed jira_workitem - it prints the key to build a JQL
  # query or an issue reference from.
  key=$(jq -r '.[] | [.key, .name] | @csv' <<< "$out" \
    | gum table --columns=KEY,NAME --widths=14,60 --return-column=1) || return

  [[ -n "$key" ]] || return

  print -r -- "$key"
}
