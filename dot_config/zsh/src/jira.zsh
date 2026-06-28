function jira_workitem () {
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
    acli jira project list --paginate --json \
    | jq -r '.[] | { key, name, uuid }' | cat
}
