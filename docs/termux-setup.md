# Termux setup

This guide sets up an Android phone with this repository's configuration in
[Termux](https://termux.dev). The phone gets the same shell and editor setup as
the other machines, but without Homebrew or asdf. Homebrew does not support
Android, and the asdf tools need glibc, which Android cannot run.
[`pkgfiles/termux`](../pkgfiles/termux) replaces both.

## Set up a new phone

1. Install Termux, Termux:API (for the clipboard) and Termux:Boot from the
   same source (F-Droid or GitHub). The add-ons must have the same signature as
   the app.
2. Install git and chezmoi:

   ```sh
   pkg install git chezmoi
   ```

3. Clone the repository and apply it:

   ```sh
   mkdir -p ~/workspace/jack06215
   git clone https://github.com/jack06215/dotfiles ~/workspace/jack06215/dotfiles
   chezmoi init --apply --source ~/workspace/jack06215/dotfiles
   ```

4. Run the setup script:

   ```sh
   ~/setup.sh
   ```

   Some steps wait for input. Android asks for the storage permission, and the
   Claude Code installer asks two questions.

5. Open a new Termux session. If `setup.sh` reported
   `termux-services not running yet`, run `~/setup.sh` again in the new
   session. The session that installs termux-services cannot start services.

## What `setup.sh` does

chezmoi writes [`executable_setup.sh.tmpl`](../executable_setup.sh.tmpl) to
`~/setup.sh`. On Termux, the script does these steps in this order:

| Step | What it does |
| --- | --- |
| Termux packages | Upgrades the installed packages. Then it installs the packages in `pkgfiles/termux` with apt-get. The `*-repo` entries go first, because they add the apt sources for the other packages. |
| Go tools | Builds tock into `~/.local/bin` with `go install`. Termux has no package for it. |
| Yarn v4 | Enables the corepack that comes with nodejs-lts. The shims go into `~/.local/bin`. |
| npm globals | Installs the same list as on the other machines, without mermaid-cli. Puppeteer has no Chrome build for Android. |
| gh extensions, tmux plugins | The same as on the other machines. |
| Termux app | Sets zsh as the login shell, opens the storage permission prompt, and installs PlemolJP Console NF as `~/.termux/font.ttf`. |
| sshd, ssh-agent | Writes `~/.ssh/authorized_keys` from the public keys of the GitHub account. Then it enables sshd (port 8022) and ssh-agent with termux-services. |
| Claude Code | Runs [`tools/setup/termux_install_claude_code.sh`](../tools/setup/termux_install_claude_code.sh), which comes from claude-code-android. |
| Monorepo | Clones the monorepo and runs its `tools/termux/setup.sh`. That script installs Bazel and the other packages that it needs, and makes the Bazel build of the monorepo work on Termux. |
| Dotfiles | Applies the dotfiles again and reloads the Termux settings. |

## Run it again

`setup.sh` skips each step that is already done, so you can run it again at any
time. If a step fails, the script continues. At the end, it lists the failed
steps and exits with status 1.

`setup.sh` does not rebuild tock when `~/.local/bin/tock` exists. To rebuild
it, delete that file and run `~/setup.sh` again.

`setup.sh` does not run the `tools/termux/setup.sh` of the monorepo when
`tools/termux/generated.bazelrc` exists in the monorepo. After you change the
Python or Node pin, run that script yourself.

## Run the setup on a PC

[`tools/termux-docker/`](../tools/termux-docker/) builds a Docker image from
the official termux-docker image, with the packages in `pkgfiles/termux` and
these dotfiles. Its [README](../tools/termux-docker/README.md) tells how to
build it and how the container differs from the phone.

## Package manifest

`pkgfiles/termux` lists the packages, one on each line. `setup.sh` reads it from
the repository each time it runs, so an edit needs no `chezmoi apply`.

To regenerate the manifest from the packages on the phone, run this command in
Termux:

```sh
"$(chezmoi source-path)/tools/setup/generate-termux-packages.sh"
```

[`tools/setup/generate-termux-packages.sh`](../tools/setup/generate-termux-packages.sh)
leaves out the Termux base system and the packages in its `EXCLUDED` list. To
exclude a package, add it to `EXCLUDED`. Do not delete its line from the
manifest, because the next run adds it again.

## chezmoi on Termux

- chezmoi reports `.chezmoi.os` as `android`, not `linux`. The Termux branches
  in the templates test for `android`.
- The app and Termux:Boot read their files from `~/.termux`. For this reason,
  their config is in [`dot_termux/`](../dot_termux/), not in `dot_config/`.
