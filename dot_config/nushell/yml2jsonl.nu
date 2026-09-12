# Convert YAML to JSONL: each item of a sequence, or each '---' document, is a line.
def yml2jsonl [
  --path (-p): string                # dotted mapping keys down to the sequence
  --encoding (-e): string = "utf-8"  # decode input as this WHATWG label
]: any -> string {
  mut doc = ($in | into binary | decode $encoding | from yaml)

  # `get` alone would not say which key missed or what was there instead, so
  # walk a step at a time and say where the descent stopped.
  if not ($path | is-empty) {
    for k in ($path | split row ".") {
      let shape = ($doc | describe)
      if not ($shape | str starts-with "record") {
        error make --unspanned { msg: $"cannot look up ($k): the path reached a ($shape), not a mapping" }
      }
      if $k not-in ($doc | columns) {
        let have = ($doc | columns | str join ", ")
        error make --unspanned { msg: $"no such key: ($k) -- mapping has: ($have)" }
      }
      $doc = ($doc | get $k)
    }
  }

  # A scalar is what a file that is not YAML at all looks like - `from yaml`
  # reads prose as one long string - so refuse it. Empty input has no lines.
  let shape = ($doc | describe)
  let rows = if $shape == "nothing" {
    []
  } else if (($shape | str starts-with "list") or ($shape | str starts-with "table")) {
    $doc
  } else if ($shape | str starts-with "record") {
    [$doc]
  } else {
    error make --unspanned { msg: $"expected a mapping or a sequence, got a ($shape)" }
  }
  $rows | each {|row| $row | to json --raw } | to text
}
