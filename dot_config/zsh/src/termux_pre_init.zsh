export TERMUX_ROOT="/data/data/com.termux/files"
export TERMUX_DOT_TERMUX="/data/data/com.termux/files/home/.termux"

# ssh-agent runs as a termux-services service, which setup.sh enables; this is
# the socket its run script ($PREFIX/var/service/ssh-agent/run) listens on.
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-$PREFIX/var/run}/ssh-agent.socket"

# Android denies hard links to apps, even within one filesystem, so uv's
# default link mode always fails here and warns before falling back to a copy.
export UV_LINK_MODE=copy
