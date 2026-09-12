# Convert JSONL to CSV; binary comes back for --bom or any encoding but utf-8.
def jsonl2csv [
  --columns (-c): string             # emit only these columns, in this order (comma-separated)
  --encoding (-e): string = "utf-8"  # encode output as this WHATWG label
  --bom (-b)                         # prepend a UTF-8 BOM, so Excel reads UTF-8 as UTF-8
  --separator (-s): string = ","     # output separator
  --noheaders (-n)                   # omit the header row
]: any -> any {
  # `from json --objects` passes a line it cannot read on as a plain string, and
  # the type error `to csv` then raises names neither the line nor the problem.
  let rows = ($in | into binary | decode utf-8 | from json --objects | collect)
  let bad = ($rows | enumerate | where {|r| not (($r.item | describe) | str starts-with "record")})
  if not ($bad | is-empty) {
    let n = (($bad | first | get index) + 1)
    error make --unspanned { msg: $"line ($n) is not a JSON object -- expected one object per line" }
  }

  # A CSV cell holds one scalar, so a nested array or object becomes compact
  # JSON. `update cells` streams, and a streamed `to csv` dies when a later
  # record brings a new column - `collect` puts the table back together first.
  let rows = ($rows | update cells {|v|
    let t = ($v | describe)
    if (($t | str starts-with "list") or ($t | str starts-with "table") or ($t | str starts-with "record")) {
      $v | to json --raw
    } else {
      $v
    }
  } | collect)

  # No records means no columns to name - `to csv` would emit a lone `""`.
  let out = if ($rows | is-empty) {
    ""
  } else if ($columns | is-empty) {
    $rows | to csv --separator $separator --noheaders=$noheaders
  } else {
    let want = ($columns | split row ",")
    let missing = ($want | where {|c| $c not-in ($rows | columns)})
    if not ($missing | is-empty) {
      let names = ($missing | str join ", ")
      let have = ($rows | columns | str join ", ")
      error make --unspanned { msg: $"no such column: ($names) -- record has: ($have)" }
    }
    $rows | select ...$want | to csv --separator $separator --noheaders=$noheaders
  }

  if $bom {
    0x[EF BB BF] ++ ($out | encode utf-8)
  } else if $encoding == "utf-8" {
    $out
  } else {
    $out | encode $encoding
  }
}
