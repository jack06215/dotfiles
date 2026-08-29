# shellcheck shell=bash
# shellcheck disable=SC1091

# `y` is yazi's cd-on-quit wrapper: quit with `q` and the shell follows you to
# whatever directory you browsed to; quit with `Q` and it stays put.
#
# This has to be a shell function rather than a script or an alias, because only
# the shell that owns the prompt can change its own working directory. yazi
# itself just writes the path it exited from to --cwd-file.
if command -v yazi > /dev/null 2>&1; then
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
