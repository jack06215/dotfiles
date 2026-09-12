def lsz [dir: string = "."] {
  ls -a $dir | each {|e|
    if $e.type == "dir" {
      $e | update size (
        try {
          # Glob from inside the directory: joined into the pattern, its name is
          # read as glob syntax, so `[ab]` sums a/ and b/ and a leading `~`
          # walks $HOME. cd expands a bare `~` too, hence the absolute path.
          do {
            cd ($env.PWD | path join $e.name)
            ls -a **/*
            | where type == file
            | get size
            | append 0B
            | math sum
          }
        } catch { 0B }
      )
    } else { $e }
  } | sort-by size --reverse
}
