# asdf >= 0.16 (the Go rewrite, from Homebrew on every OS). It is one binary:
# there is no asdf.sh to source any more, only the shims dir to put on PATH.
# Its data - plugins, installs, shims - stays in ASDF_DATA_DIR (~/.asdf, set in
# ~/.zshenv), which is also where the old bash asdf kept it, so a machine that
# ran the old one keeps its installed versions.
#
# CLI changes from the bash asdf: `asdf set` (-u for the home .tool-versions)
# replaces global/local, and `asdf shell` is gone (set ASDF_<TOOL>_VERSION).
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
fi
