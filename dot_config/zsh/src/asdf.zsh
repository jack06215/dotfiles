export ASDF_DIR="$HOME/.asdf"

if [ -f "$ASDF_DIR/asdf.sh" ]; then
  . "$ASDF_DIR/asdf.sh"
fi

if [ -f "$ASDF_DIR/completions/asdf.zsh" ]; then
  . "$ASDF_DIR/completions/asdf.zsh"
fi
