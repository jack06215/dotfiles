# shellcheck shell=bash
# shellcheck disable=SC1091

# `y` is yazi's cd-on-quit wrapper: quit with `q` and the shell follows you to
# whatever directory you browsed to; quit with `Q` and it stays put.
#
# This has to be a shell function rather than a script or an alias, because only
# the shell that owns the prompt can change its own working directory. yazi
# itself just writes the path it exited from to --cwd-file.
if command -v yazi > /dev/null 2>&1; then
  # Inside tuios (WezTerm's ruby tab), make yazi place its images directly.
  # When tuios can forward kitty graphics it sets TERM_PROGRAM=ghostty in its
  # panes. yazi then treats the terminal as Ghostty and draws with kitty
  # Unicode placeholders. tuios passes those to WezTerm unchanged, WezTerm
  # cannot draw them, and the preview fills with boxes. yazi uses direct
  # placement (its KgpOld driver) only for Konsole, which it recognises by
  # KONSOLE_VERSION when TERM_PROGRAM is a name it does not know. tuios
  # forwards direct placements, and WezTerm draws them.
  #
  # When the host has sixel but no kitty graphics (Termux), tuios sets
  # TERM_PROGRAM=WezTerm instead. yazi reads that as WezTerm, whose first choice
  # is iTerm2 inline images, and tuios drops those, so the preview stays blank.
  # BlackBox is the name yazi maps to sixel alone, which tuios does forward.
  # yazi reads TERM_PROGRAM before WEZTERM_EXECUTABLE and friends, so a daemon
  # started from WezTerm cannot pull it back. These variables reach only yazi
  # and the programs it starts.
  function yazi() {
    if [[ -n "${TUIOS_SESSION:-}" && "${TERM_PROGRAM:-}" == ghostty ]]; then
      TERM_PROGRAM=TUIOS KONSOLE_VERSION=1 command yazi "$@"
    elif [[ -n "${TUIOS_SESSION:-}" && "${TERM_PROGRAM:-}" == WezTerm ]]; then
      TERM_PROGRAM=BlackBox command yazi "$@"
    else
      command yazi "$@"
    fi
  }

  function y() {
    local tmp cwd
    tmp=$(mktemp -t yazi-cwd.XXXXXX) || return 1

    yazi "$@" --cwd-file="$tmp"

    # -d '' reads to a NUL rather than a newline, so a directory whose name
    # contains one still round-trips. It returns non-zero at EOF when the file
    # is empty (`Q`, or a crash), which is the "stay put" case, so the result is
    # deliberately not checked - `cwd` is simply left empty.
    IFS= read -r -d '' cwd < "$tmp"
    rm -f -- "$tmp"

    if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
      # builtin, so a `cd` wrapper further up (zoxide's, for one) cannot turn
      # this into a database write for a directory that was only browsed.
      builtin cd -- "$cwd" || return 1
    fi

    # Without this, `y` reports failure whenever the directory did not change,
    # which the prompt would render as a failed command.
    return 0
  }
fi
