# Re-emit CSV as json, jsonl or yaml, keeping non-ASCII text literal.
def csv2 [
  format: string                     # json, jsonl or yaml
  --columns (-c): string             # comma-separated; selects and reorders, or names them with --noheaders
  --noheaders (-n)                   # input has no header row
  --encoding (-e): string = "utf-8"  # decode input as this WHATWG label
  --separator (-s): string = ","     # field separator
  --infer (-i)                       # type the fields; off so 0123456 and 007 keep their zeros
  --flexible                         # allow rows with a varying number of fields
]: any -> string {
  # stdin arrives as text whenever its bytes happen to be valid UTF-8; going
  # back to bytes lets `decode` apply --encoding whichever way it arrived.
  # A CRLF file keeps its CR inside multi-line quoted cells, which a YAML block
  # scalar cannot hold, so it is dropped for every format alike.
  let rows = (
    $in
    | into binary
    | decode $encoding
    | from csv --separator $separator --noheaders=$noheaders --no-infer=(not $infer) --flexible=$flexible
    | update cells {|v|
      if ($v | describe) == "string" {
        $v | str replace --all "\r\n" "\n" | str replace --all "\r" "\n"
      } else { $v }
    }
  )

  let rows = if ($columns | is-empty) {
    $rows
  } else if $noheaders {
    $rows | rename ...($columns | split row ",")
  } else {
    # `select` alone would not say which name missed or what the header holds -
    # worth it when a stray full-width space in a Japanese header is invisible.
    let want = ($columns | split row ",")
    let missing = ($want | where {|c| $c not-in ($rows | columns)})
    if not ($missing | is-empty) {
      let names = ($missing | str join ", ")
      let have = ($rows | columns | str join ", ")
      error make --unspanned { msg: $"no such column: ($names) -- header has: ($have)" }
    }
    $rows | select ...$want
  }

  match $format {
    "json" => ($rows | to json)
    "jsonl" => ($rows | each {|row| $row | to json --raw } | to text)
    "yaml" => ($rows | to yaml)
    _ => (error make --unspanned { msg: $"unknown format: ($format) -- expected json, jsonl or yaml" })
  }
}
