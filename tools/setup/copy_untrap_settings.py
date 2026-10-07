#!/usr/bin/env python3
"""Copies the tracked Untrap for YouTube settings to the clipboard, base64-encoded.

    bazel run //tools/setup:copy_untrap_settings   # from the repo
    python3 tools/setup/copy_untrap_settings.py    # without bazel, same thing

Untrap keeps its settings in the browser's extension storage, which nothing in
this repo can write to. dot_config/untrap_for_youtube/settings.json is the
tracked copy; getting it back into the extension means pasting it, encoded, into
Untrap's import box. This puts that string on the clipboard.

The file is encoded byte for byte, after a check that it parses: a broken
string pasted into the import box fails without saying why.

Stdlib only. The clipboard is whichever of pbcopy (macOS, and the win32yank
shim in ~/.local/bin on WSL2), wl-copy, xclip or clip (Windows) is found first.
"""

import base64
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

SETTINGS_FILE = "dot_config/untrap_for_youtube/settings.json"

CLIPBOARD_COMMANDS = (
    ["pbcopy"],
    ["wl-copy"],
    ["xclip", "-selection", "clipboard"],
    ["clip"],
)


def resolve_source_dir() -> Path:
    """The checkout to read from - never a build sandbox or the target tree.

    `bazel run` exports BUILD_WORKSPACE_DIRECTORY; outside bazel, ask chezmoi
    where its source directory is. Same shape as the other tools here.
    """
    from_bazel = os.environ.get("BUILD_WORKSPACE_DIRECTORY")
    if from_bazel:
        return Path(from_bazel)
    try:
        out = subprocess.run(
            ["chezmoi", "source-path"], capture_output=True, text=True, check=True
        )
    except (OSError, subprocess.CalledProcessError):
        die("neither BUILD_WORKSPACE_DIRECTORY nor `chezmoi source-path` is available")
    return Path(out.stdout.strip())


def die(message: str) -> None:
    print(f"copy-untrap-settings: {message}", file=sys.stderr)
    raise SystemExit(1)


def copy_to_clipboard(text: str) -> str:
    """Pipes `text` into the first clipboard command on PATH; returns its name."""
    for command in CLIPBOARD_COMMANDS:
        if shutil.which(command[0]):
            try:
                subprocess.run(command, input=text, text=True, check=True)
            except (OSError, subprocess.CalledProcessError) as error:
                die(f"{command[0]} failed ({error})")
            return command[0]
    names = ", ".join(command[0] for command in CLIPBOARD_COMMANDS)
    die(f"no clipboard command found (tried {names})")


def main() -> int:
    path = resolve_source_dir() / SETTINGS_FILE
    try:
        raw = path.read_bytes()
    except OSError as error:
        die(f"cannot read {path} ({error})")
    try:
        json.loads(raw)
    except ValueError as error:
        die(f"{path} is not valid JSON ({error})")

    encoded = base64.b64encode(raw).decode("ascii")
    tool = copy_to_clipboard(encoded)
    print(f"untrap: copied {len(encoded)} base64 characters of {SETTINGS_FILE} via {tool}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
