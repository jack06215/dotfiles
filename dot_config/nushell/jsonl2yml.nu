# Convert JSONL to a YAML sequence, one item per line.
def jsonl2yml []: any -> string {
  $in | from json --objects | to yaml
}
