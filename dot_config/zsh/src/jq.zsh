function jqc() {
  local -a jqargs files
  local a
  for a in "$@"; do
    if [[ -f $a ]]; then files+=("$a"); else jqargs+=("$a"); fi
  done
  (($#jqargs)) || jqargs=('.')

  local strip='gsub("(?<s>\"(\\\\.|[^\"\\\\])*\")|#[^\n]*"; .s // "")'

  if (($#files)); then cat -- "${files[@]}"; else cat; fi \
    | jq -Rsr "$strip" \
    | jq "${jqargs[@]}"
}

function jqf() {
  # Reindent JSONC with the `#` comments left in place. jsonnetfmt keeps them
  # but emits Jsonnet-style trailing commas, so drop any comma whose only
  # remaining neighbours before `}` / `]` are whitespace and comments.
  local untrail='gsub("(?<s>\"(\\\\.|[^\"\\\\])*\")|(?<c>#[^\n]*)|,(?<g>(\\s|#[^\n]*\n)*[}\\]])"; .s // .c // .g)'

  if (($#)); then cat -- "$@"; else cat; fi \
    | jsonnetfmt --string-style d --comment-style h --no-pretty-field-names - \
    | jq -Rsj "$untrail"
}
