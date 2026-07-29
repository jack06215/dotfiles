# compare-dir-diff.nu
#
# Non-recursive filename set comparison between two directories.
#
#   use compare-dir-diff.nu *
#   dir-diff  ./old ./new          # set(a) - set(b)
#   dir-cmp   ./old ./new --op xor
#   dir-report ./old ./new

# --- private helper ----------------------------------------------------------

# Names directly under $dir (non-recursive). `ls` globs $dir/* so no flag needed.
def dir-names [dir: path, dotfiles: bool, dirs: bool] {
  let items = if $dotfiles { ls -a $dir } else { ls $dir }
  let items = if $dirs { $items } else { $items | where type == file }
  # `name` is "dir/file"; basename is required or nothing ever matches.
  $items | get name | path basename
}

# --- public commands --------------------------------------------------------

# Compare the filenames of two directories as sets.
export def dir-cmp [
  a: path                # left directory
  b: path                # right directory
  --op: string = "diff"  # diff | rdiff | both | xor
  --dotfiles(-a)         # include dotfiles
  --dirs(-d)             # include directories, not just files
] {
  let l = (dir-names $a $dotfiles $dirs)
  let r = (dir-names $b $dotfiles $dirs)
  match $op {
    "diff"  => ($l | where {|x| $x not-in $r})
    "rdiff" => ($r | where {|x| $x not-in $l})
    "both"  => ($l | where {|x| $x in $r})
    "xor"   => (($l | where {|x| $x not-in $r}) ++ ($r | where {|x| $x not-in $l}))
    _ => (error make {msg: $"unknown op: ($op) -- expected diff|rdiff|both|xor"})
  }
}

# set(a) - set(b)
export def dir-diff [a: path, b: path, --dotfiles(-a), --dirs(-d)] {
  dir-cmp $a $b --op diff --dotfiles=$dotfiles --dirs=$dirs
}

# set(b) - set(a)
export def dir-rdiff [a: path, b: path, --dotfiles(-a), --dirs(-d)] {
  dir-cmp $a $b --op rdiff --dotfiles=$dotfiles --dirs=$dirs
}

# set(a) & set(b)
export def dir-both [a: path, b: path, --dotfiles(-a), --dirs(-d)] {
  dir-cmp $a $b --op both --dotfiles=$dotfiles --dirs=$dirs
}

# set(a) ^ set(b)
export def dir-xor [a: path, b: path, --dotfiles(-a), --dirs(-d)] {
  dir-cmp $a $b --op xor --dotfiles=$dotfiles --dirs=$dirs
}

# All three sets at once, as a record.
export def dir-report [a: path, b: path, --dotfiles(-a), --dirs(-d)] {
  let l = (dir-names $a $dotfiles $dirs)
  let r = (dir-names $b $dotfiles $dirs)
  {
    only_left: ($l | where {|x| $x not-in $r})
    only_right: ($r | where {|x| $x not-in $l})
    both: ($l | where {|x| $x in $r})
  }
}
