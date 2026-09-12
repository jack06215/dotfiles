# Serialize pipeline input as CSV for external tools.
def tocsv [
  --noheaders (-n)                               # omit the header row
  --separator (-s): string = ","                 # field separator
  --date-format (-d): string = "%Y-%m-%d %H:%M"  # strftime format for datetime cells
]: any -> string {
  let data = $in
  # `to csv` writes an empty table as a lone `""`, which an external tool reads
  # as a header with one blank column; nothing at all is the honest answer.
  if ($data | is-empty) { return "" }

  $data
  | update cells {|v|
    if ($v | describe) == "datetime" { $v | format date $date_format } else { $v }
  }
  | collect
  | to csv --separator $separator --noheaders=$noheaders
}
