# Mirrors `alias cls='clear'` in dot_config/zsh/src/alias.zsh.tmpl.
alias cls = clear

# Count files by extension, most common first.
def ls_count_ext [] {
  ls **/* | where type == file | get name | path parse | get extension | uniq -c | sort-by count -r
}

# fzf over the whole tree: cd into the pick if it's a directory, else open it
# in $EDITOR. Port of ls_fzf_open in dot_config/zsh/src/ls.zsh.
#
# `complete` captures the exit code so cancelling fzf (esc / ctrl-c, exit 130)
# returns quietly instead of raising a non-zero-exit error; fzf still draws its
# UI because that goes to the terminal, not stdout.
def --env ls_fzf_open [] {
  let picked = (
    fd . --hidden --follow --exclude .git
    | fzf --preview '
      if [ -d {} ]; then
        eza --tree --level=2 --icons --color=always {}
      else
        eza -l --icons --color=always {}
      fi
    ' --preview-window=right:60%:wrap
    | complete
  )

  if $picked.exit_code != 0 { return }

  let target = ($picked.stdout | str trim)
  if ($target | is-empty) { return }

  if ($target | path type) == 'dir' {
    cd $target
  } else {
    ^($env.EDITOR? | default 'vi') $target
  }
}
