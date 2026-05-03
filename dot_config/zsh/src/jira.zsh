function jira_workitem() {
  local key="$1"

  if [[ -z "$key" ]]; then
    echo "Usage: jira_view_text <ISSUE-KEY>" >&2
    return 1
  fi

  acli jira workitem view "$key" --json \
  | jq -r '
  {
    displayName: .fields.assignee.displayName,
    email: .fields.assignee.emailAddress,
    summary: .fields.summary,
    status: .fields.status.statusCategory.name,
    description: (
      .fields.description.content
      | map(
          if .type == "paragraph" then
            (.content // [] | map(.text // "") | join(""))
          elif .type == "blockCard" then
            .attrs.url
          else
            ""
          end
        )
      | map(select(length > 0))
      | join("\n")
    ),
    id,
    key
  }
  ' | cat
}

function jira_project_list() {
    acli jira project list --paginate --json \
    | jq -r '.[] | { key, name, uuid }' | cat
}
