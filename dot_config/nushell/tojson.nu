# Serialize pipeline input as JSON for external tools.
def tojson [
  --ndjson (-n)            # one compact object per line (jq -c style stream)
  --indent (-i): int = 2   # pretty-print width; ignored with --ndjson
]: any -> string {
  let data = $in
  if $ndjson {
    $data | each {|row| $row | to json --raw } | str join "\n"
  } else {
    $data | to json --indent $indent
  }
}
