# Mirrors `alias cls='clear'` in dot_config/zsh/src/alias.zsh.tmpl.
alias cls = clear

# Count files by extension, most common first.
def ls_count_ext [] {
  ls **/* | where type == file | get name | path parse | get extension | uniq -c | sort-by count -r
}

# pet, pinned to the nushell-only config so snippets live in snippet.nu.toml
# rather than the snippet.toml zsh shares. `--wrapped` passes flags straight
# through, so `pet new`, `pet edit` and `pet list` all act on the nu file.
def --wrapped pet [...args] {
  ^pet --config ($nu.home-dir | path join ".config" "pet" "config.nu.toml") ...$args
}

# ctrl-s -> snippet search, mirroring the pet_select widget in
# dot_config/zsh/src/pet.zsh. No `stty -ixon` counterpart is needed: reedline
# puts the terminal in raw mode, so ctrl-s never reaches XOFF flow control.
#
# Unlike the zsh widget (which assigns the empty result straight to BUFFER),
# cancelling the picker leaves whatever was already typed alone.
$env.config.keybindings = ($env.config.keybindings | append {
  name: pet_select
  modifier: control
  keycode: char_o
  mode: [emacs, vi_normal, vi_insert]
  event: {
    send: executehostcommand
    cmd: '
      let picked = (pet search --query (commandline) | complete)
      if $picked.exit_code == 0 {
        let snippet = ($picked.stdout | str trim)
        if ($snippet | is-not-empty) { commandline edit --replace $snippet }
      }
    '
  }
})

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
