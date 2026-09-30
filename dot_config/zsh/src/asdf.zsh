# asdf >= 0.16 (the Go rewrite, from Homebrew on every OS). It is one binary:
# there is no asdf.sh to source any more, only the shims dir to put on PATH.
# Its data - plugins, installs, shims - stays in ASDF_DATA_DIR (~/.asdf, set in
# ~/.zshenv), which is also where the old bash asdf kept it, so a machine that
# ran the old one keeps its installed versions.
#
# CLI changes from the bash asdf: `asdf set` (-u for the home .tool-versions)
# replaces global/local, and `asdf shell` is gone (set ASDF_<TOOL>_VERSION).
#
# Something earlier in startup may still `source ~/.asdf/asdf.sh` from a bash
# asdf clone left in ~/.asdf (the flywheel monorepo's config.zsh, via
# .zprofile). That defines an `asdf` function and puts the clone's bin/ ahead
# of Homebrew's, so every `asdf` call - `asdf completion zsh` below included -
# runs the old CLI. Drop both so `asdf` is the Homebrew binary again.
(($+functions[asdf])) && unfunction asdf
path=(${path:#${ASDF_DIR:-$HOME/.asdf}/bin})
path=("${ASDF_DATA_DIR:-$HOME/.asdf}/shims" $path)

# Completion ships inside the binary. Regenerate it when asdf is newer than
# the file (a brew upgrade) and drop the compinit dump, since completion.zsh
# runs `compinit -C`, which never notices a new function on its own.
if (($+commands[asdf])); then
  _asdf_comp_dir="$XDG_CACHE_HOME/zsh/completions"
  if [[ ! -s "$_asdf_comp_dir/_asdf" || "$commands[asdf]" -nt "$_asdf_comp_dir/_asdf" ]]; then
    mkdir -p "$_asdf_comp_dir" \
      && asdf completion zsh >| "$_asdf_comp_dir/_asdf" \
      && rm -f "${ZDOTDIR:-$HOME}/.zcompdump"
  fi
  fpath=("$_asdf_comp_dir" $fpath)
  unset _asdf_comp_dir

  # Any other asdf that installs or reshims - the bash clone above, or the one
  # the monorepo's Bazel rules fetch, both sharing ASDF_DATA_DIR - rewrites the
  # shims to exec itself by absolute path. The bash one costs ~120ms a call,
  # enough for the python shim to blow starship's command_timeout. Homebrew's
  # asdf writes `exec asdf exec ...`, so a shim with `exec /...` is someone
  # else's: reshim. Only shims changed since the last check get read - the glob
  # just stats them, so a startup where nothing changed forks nothing. The stamp
  # is left alone when reshim fails, so the next shell tries again.
  _asdf_shims="${ASDF_DATA_DIR:-$HOME/.asdf}/shims"
  _asdf_stamp="$XDG_CACHE_HOME/zsh/asdf-shims-checked"
  if [[ -e "$_asdf_stamp" ]]; then
    _asdf_changed=("$_asdf_shims"/*(N.e:'[[ $REPLY -nt $_asdf_stamp ]]':))
  else
    _asdf_changed=("$_asdf_shims"/*(N.))
  fi
  if (($#_asdf_changed)); then
    if ! grep -qs '^exec /' $_asdf_changed || asdf reshim; then
      mkdir -p "${_asdf_stamp:h}" && touch "$_asdf_stamp"
    fi
  fi
  unset _asdf_shims _asdf_stamp _asdf_changed
fi
