# syntax=docker/dockerfile:1
#
# The phone's Termux setup for a PC: termux-docker, the packages in
# pkgfiles/termux and these dotfiles. The build context must be the root of
# this repository, because the build reads pkgfiles/termux and copies the
# whole chezmoi source:
#
#   docker build -f tools/termux-docker/Dockerfile -t termux-dotfiles .
#   docker run -it --name termux termux-dotfiles
#   docker start -ai termux    # later, to return to the same container
#
# The image has no Android system under Termux. termux-api,
# termux-setup-storage and am do not work, so the Termux app steps of
# setup.sh are left out.

# The `latest` tag is multi-platform. Docker pulls the build for the CPU of
# the PC, so no binary runs under QEMU.
FROM termux/termux-docker:latest

# The base image ends as root, and its entrypoint changes to `system`
# (uid 1000) only when a container starts. Termux's apt must run as `system`,
# because `system` cannot later update the files that apt writes as root. This
# user also stays in effect at run time, so the entrypoint starts `login`
# directly and `docker exec` opens a shell as `system`.
USER 1000:1000

# The same steps as install_termux_packages in setup.sh, in POSIX sh because
# the sh of the image is dash. pkgfiles/termux comes from an aarch64 phone, so
# a package can be missing for the CPU of the PC. The build skips such a
# package with a warning, so that one missing package does not stop the others.
RUN --mount=type=bind,source=pkgfiles/termux,target=/termux-packages <<'EOF'
set -eu
export DEBIAN_FRONTEND=noninteractive
apt_opts='-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold'

available() {
  for package in "$@"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
      echo "$package"
    else
      echo "warning: no $package package for $(uname -m); skipping" >&2
    fi
  done
}

entries=$(sed -E 's/[[:space:]]*#.*$//' /termux-packages | grep -E '[^[:space:]]')
apt-get update
apt-get full-upgrade $apt_opts
# Each *-repo package adds an apt source. apt finds the packages in that
# source only after the next update.
apt-get install $apt_opts $(available $(echo "$entries" | grep -- '-repo$'))
apt-get update
apt-get install $apt_opts $(available $(echo "$entries" | grep -v -- '-repo$'))
apt-get clean
rm -rf "$PREFIX"/var/lib/apt/lists/*
EOF

# gh does not read the CA bundle of Termux. It looks for CA certificates in
# Android's /system/etc/security, which the image does not have, so every
# request fails with `x509: certificate signed by unknown authority`. gh is a
# Go program, and Go also reads the file that SSL_CERT_FILE names. The
# entrypoint clears the environment only when the container starts as root,
# so `system` keeps this variable.
ENV SSL_CERT_FILE=/data/data/com.termux/files/usr/etc/tls/cert.pem

# The path from docs/termux-setup.md. chezmoi writes this path into the files
# that it renders, so the same path as on the phone gives the same files.
ARG SOURCE_DIR=/data/data/com.termux/files/home/workspace/jack06215/dotfiles
# Makes the parent directories as `system`, so that `system` owns them
# whatever COPY does with the directories that it makes.
RUN mkdir -p "$SOURCE_DIR"
COPY --chown=1000:1000 . $SOURCE_DIR

# `login` runs the commands in the environment of a Termux session. It sets
# LD_PRELOAD for termux-exec, which the environment of the base image does not
# set.
RUN login -c "chezmoi init --apply --source '$SOURCE_DIR' && chsh -s zsh"
