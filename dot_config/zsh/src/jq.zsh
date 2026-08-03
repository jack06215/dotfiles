function jqf() {
  # Reindent JSONC with the `#`, `//` and `/* */` comments left in place
  # (`--comment-style l` keeps each one as authored instead of rewriting it).
  # jsonnetfmt emits Jsonnet-style trailing commas, so drop any comma whose only
  # remaining neighbours before `}` / `]` are whitespace and comments. Comments
  # are matched and kept verbatim rather than skipped, so a `"` or `,` inside one
  # cannot be mistaken for the start of a string or for a trailing comma.
  local str='(?<s>\"(\\\\.|[^\"\\\\])*\")'
  local com='(?:#|//)[^\n]*|/\\*[^*]*\\*+(?:[^/*][^*]*\\*+)*/'
  local untrail='gsub("'"$str"'|(?<c>'"$com"')|,(?<g>(?:\\s|'"$com"')*[}\\]])"; .s // .c // .g)'

  if (($#)); then cat -- "$@"; else cat; fi \
    | jsonnetfmt --string-style d --comment-style l --no-pretty-field-names - \
    | jq -Rsj "$untrail"
}
