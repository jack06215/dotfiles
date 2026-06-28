function chezmoi-data() {
  local tmp
  tmp=$(mktemp)
  chezmoi data > "$tmp"

  local key
  key=$(jq -r '[paths(scalars) | join(".")]|.[]' "$tmp" | fzf \
    --ansi \
    --layout=reverse \
    --border \
    --height=90% \
    --pointer='*' \
    --prompt='chezmoi data: ' \
    --preview "jq -r --arg k {} 'getpath(\$k | split(\".\") | map(if test(\"^[0-9]+$\") then tonumber else . end))' $tmp" \
    --preview-window=right:50%:wrap)

  [ -n "$key" ] && jq -r --arg k "$key" \
    'getpath($k | split(".") | map(if test("^[0-9]+$") then tonumber else . end))' "$tmp"
  rm -f "$tmp"
}
