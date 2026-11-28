# Termux on a PC (repo only)

[`Dockerfile`](Dockerfile) builds the Termux setup of the phone as a Docker
image for a PC. It starts from the official
[termux-docker](https://github.com/termux/termux-docker) image, installs the
packages in [`pkgfiles/termux`](../../pkgfiles/termux) and applies these
dotfiles. chezmoi does not install this folder.

## Build and run the image

Run these commands from the root of a checkout. The build reads
`pkgfiles/termux` and copies the whole checkout into the image, so the build
context must be the root:

```sh
docker build -f tools/termux-docker/Dockerfile -t termux-dotfiles .
docker run -it --name termux termux-dotfiles
```

The container keeps the changes that you make in it. To open it again, run
`docker start -ai termux`. To get a new container from a changed manifest or
changed dotfiles, build the image again.

The `latest` tag of termux-docker is multi-platform. Docker pulls the build
for the CPU of the PC, so no binary runs under QEMU.

The Dockerfile uses `RUN --mount` and a heredoc, so the build needs BuildKit
(the buildx plugin). Without buildx, docker uses the legacy builder, and the
build fails. On macOS,
[`dot_config/docker/modify_private_config.json`](../../dot_config/docker/modify_private_config.json)
tells docker where Homebrew installs buildx.

## Test changes without a rebuild

The image holds a copy of the checkout from the time of the build. To use
the current checkout instead, mount it over that copy. Run this command from
the root of the checkout:

```sh
docker run -it --name termux-dev -v "$PWD":/data/data/com.termux/files/home/workspace/jack06215/dotfiles termux-dotfiles
```

Edit the files on the PC. Then run `chezmoi diff` or `chezmoi apply` in the
container. chezmoi reads the mounted checkout, so you do not have to build
the image again. To open the container again, run `docker start -ai termux-dev`.

The container writes to the checkout on the PC, for example when git updates
its index. On colima with virtiofs, the mounted files belong to the container
user, so git and chezmoi work without more steps. git prints
`warning: remote repository '...' is incompatible with fsmonitor`, because
the global git config sets `core.fsmonitor`. git then works without
fsmonitor.

## What the image contains

| Step | What it does |
| --- | --- |
| Termux packages | Upgrades the packages of the base image. Then it installs the packages in `pkgfiles/termux` with apt-get, the `*-repo` entries first, as `setup.sh` does. |
| CA certificates | Sets `SSL_CERT_FILE` to the CA bundle of Termux. Without it, gh fails with `x509: certificate signed by unknown authority`, because it looks for CA certificates in Android's `/system/etc/security`. |
| Dotfiles | Copies the checkout to `~/workspace/jack06215/dotfiles`, the path that [`docs/termux-setup.md`](../../docs/termux-setup.md) uses, and runs `chezmoi init --apply` on it. |
| Login shell | Sets zsh as the login shell with `chsh -s zsh`. |

The image runs everything as the `system` user (uid 1000) of termux-docker,
because Termux's apt must not run as root. `docker run` and `docker exec` also
open a shell as `system`.

## Differences from the phone

- `pkgfiles/termux` comes from an aarch64 phone. A package that has no build
  for the CPU of the PC is not installed. For each one, the build prints
  `warning: no <package> package for <cpu>; skipping`.
- The image has no Android system, so termux-api, `termux-setup-storage` and
  `am` do not work. For this reason, the image does not run the other steps
  of `setup.sh`, such as the Go tools, the npm globals, sshd and Claude Code.
  To get them, run `~/setup.sh` in the container. The steps that need Android
  fail, and `setup.sh` lists them at the end.
- The container uses the kernel of the PC. The limits that Android puts on
  apps, such as no hard links in app data, do not apply. Thus a command that
  works in the container can still fail on the phone.
- termux-docker containers sometimes need
  `--security-opt seccomp:unconfined` or `--privileged`, because Docker
  limits the `personality()` system call. The termux-docker README tells
  more.

## Build the monorepo in the container

`generate-termux-packages.sh` excludes `bazel`, so the image does not have it.
To build the monorepo with Bazel in the container, clone it and follow its
[Termux README](https://github.com/jack06215/monorepo/blob/master/tools/termux/README.md).

## See also

- [`docs/termux-setup.md`](../../docs/termux-setup.md): the setup on the phone.
- [termux-docker](https://github.com/termux/termux-docker): the base image,
  its tags and its known issues.
