# Serialize pipeline input as CSV for external tools.
def tocsv [
  --noheaders (-n)                # omit the header row
  --separator (-s): string = ","  # field separator
]: any -> string {
  $in | to csv --separator $separator --noheaders=$noheaders
}
