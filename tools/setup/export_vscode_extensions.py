#!/usr/bin/env python3
"""Adds this machine's installed VS Code extensions to .chezmoidata/vscode.toml.

    bazel run //tools/setup:export_vscode_extensions                  # from the repo
    bazel run //tools/setup:export_vscode_extensions -- --dry-run     # look first
    bazel run //tools/setup:export_vscode_extensions -- --prune       # drop what's gone
    python3 tools/setup/export_vscode_extensions.py                   # without bazel

The inverse of run_onchange_after_install-vscode-extensions.sh.tmpl: that
installs what the list names, this brings what was installed by hand back into
the list. Three properties it is built around:

1. vscode.toml is hand-sorted into commented groups, so it is merged into,
   never regenerated. An extension the list lacks is appended to the end of
   its array, under a marker comment that says to sort it into a group; every
   other line is left as it was. An unchanged machine leaves `git status`
   clean.

2. The `code` CLI decides what is installed, as it does for the install
   script. VS Code's own extensions.json only adds what the CLI doesn't say:
   where an extension came from, and its package.json. An extension installed
   from a .vsix (nvicode, `bazel run //packages/nvim_in_vscode:install` in
   the monorepo) is reported and left out, since `code --install-extension
   <id>` could never find it. One that runs only on the UI side
   ("extensionKind": ["ui"], the Remote extensions) goes to
   vscodeExtensionsDarwin on macOS, as WSL's VS Code Server can't take it.

3. Nothing is written that doesn't parse back to exactly the lists intended.

Tracked extensions that aren't installed are reported, not removed: the list is
shared by the Mac and WSL2, and one machine lacking an extension doesn't mean
the other should. --prune removes them, from vscodeExtensionsDarwin only on
macOS; run it on the machine that has the full set.

Stdlib only, and no tomllib: the runtime_env toolchain runs whatever python3 is
on PATH, which on a Mac without mise is Apple's 3.9.
"""

from __future__ import annotations

import argparse
import difflib
import json
import os
import platform
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

DATA_FILE = ".chezmoidata/vscode.toml"
MAIN = "vscodeExtensions"
DARWIN = "vscodeExtensionsDarwin"
MARKER = "  # --- new since the last export: sort these into a group above ---"

# Where the install script looks for the CLI on macOS, when `code` isn't on PATH.
MACOS_CODE = "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

# Local VS Code, and the VS Code Server that WSL2's extensions live in.
EXTENSION_DIRS = ("~/.vscode/extensions", "~/.vscode-server/extensions")


# vscode.toml ----------------------------------------------------------------------


def _entry(line: str) -> str | None:
    """The extension ID on an array line such as `  "a.b",  # why`; None for any other line."""
    stripped = line.strip()
    if not stripped.startswith('"'):
        return None
    end = stripped.find('"', 1)
    return stripped[1:end] if end > 0 else None


def _array_span(lines: list[str], name: str) -> tuple[int, int] | None:
    """The line numbers of `name = [` and of its closing `]`."""
    for start, line in enumerate(lines):
        if line.rstrip() == f"{name} = [":
            for end in range(start + 1, len(lines)):
                if lines[end].rstrip() == "]":
                    return start, end
            raise ValueError(f"{DATA_FILE}: `{name} = [` is never closed by a `]` line")
    return None


def read_lists(text: str) -> dict[str, list[str]]:
    """Each array of extension IDs in vscode.toml, by name, in file order."""
    lines = text.splitlines()
    lists: dict[str, list[str]] = {}
    for name in (MAIN, DARWIN):
        span = _array_span(lines, name)
        if span is not None:
            start, end = span
            lists[name] = [i for i in (_entry(line) for line in lines[start + 1 : end]) if i]
    return lists


def merge(text: str, add: dict[str, list[str]], remove: set[str]) -> str:
    """vscode.toml with `add`'s IDs appended under the marker, and `remove`'s lines gone.

    Removal matches IDs case-insensitively, as the install script compares
    them. A list in `add` that the file lacks is created at its end.
    """
    removing = {i.lower() for i in remove}
    lines = [line for line in text.splitlines() if (_entry(line) or "").lower() not in removing]
    for name, ids in add.items():
        if not ids:
            continue
        span = _array_span(lines, name)
        if span is None:
            if lines and lines[-1].strip():
                lines.append("")
            lines += [f"{name} = [", "]"]
            span = (len(lines) - 2, len(lines) - 1)
        start, end = span
        new = [f'  "{i}",' for i in ids]
        if MARKER not in lines[start:end]:
            new = ([""] if end - start > 1 else []) + [MARKER] + new
        lines[end:end] = new
    return "\n".join(lines) + "\n"


# This machine ---------------------------------------------------------------------


@dataclass(frozen=True)
class Installed:
    id: str
    #: Installed from a .vsix rather than the marketplace.
    vsix: bool = False
    #: Runs only on the UI side, so a VS Code Server can't install it.
    ui_only: bool = False


def find_code(explicit: str | None) -> str:
    for candidate in (explicit, shutil.which("code"), MACOS_CODE):
        if candidate and os.access(candidate, os.X_OK):
            return candidate
    sys.exit("export_vscode_extensions: no `code` CLI on PATH or in the app bundle; pass --code")


def list_installed(code: str) -> list[str]:
    """`code --list-extensions`, which also prints Electron's noise on stderr."""
    done = subprocess.run(
        [code, "--list-extensions"], capture_output=True, text=True, check=False
    )
    ids = [line.strip() for line in done.stdout.splitlines() if "." in line.strip()]
    if done.returncode != 0 and not ids:
        sys.exit(f"export_vscode_extensions: `code --list-extensions` failed:\n{done.stderr}")
    return ids


def _registry(dirs: list[Path]) -> dict[str, dict]:
    """VS Code's extensions.json entries, by lower-case ID, from every directory that has one."""
    entries: dict[str, dict] = {}
    for directory in dirs:
        try:
            data = json.loads((directory / "extensions.json").read_text(encoding="utf-8"))
        except (OSError, ValueError):
            continue
        for entry in data if isinstance(data, list) else []:
            ident = (entry.get("identifier") or {}).get("id")
            if isinstance(ident, str):
                entries.setdefault(ident.lower(), {**entry, "_dir": str(directory)})
    return entries


def _ui_only(entry: dict) -> bool:
    location = (entry.get("location") or {}).get("path")
    if not location and entry.get("relativeLocation"):
        location = os.path.join(entry["_dir"], entry["relativeLocation"])
    try:
        package = json.loads(Path(location, "package.json").read_text(encoding="utf-8"))
    except (OSError, ValueError, TypeError):
        return False
    kind = package.get("extensionKind")
    return (kind if isinstance(kind, list) else [kind]) == ["ui"]


def describe(ids: list[str], dirs: list[Path]) -> list[Installed]:
    registry = _registry(dirs)
    out = []
    for ident in ids:
        entry = registry.get(ident.lower())
        if entry is None:
            out.append(Installed(ident))
            continue
        source = (entry.get("metadata") or {}).get("source")
        out.append(Installed(ident, vsix=source == "vsix", ui_only=_ui_only(entry)))
    return out


# The export -----------------------------------------------------------------------


@dataclass
class Plan:
    add: dict[str, list[str]] = field(default_factory=dict)
    remove: set[str] = field(default_factory=set)
    #: Tracked but not installed here, and not being removed.
    missing: list[str] = field(default_factory=list)
    vsix: list[str] = field(default_factory=list)


def plan(lists: dict[str, list[str]], installed: list[Installed], *, darwin: bool, prune: bool) -> Plan:
    """What to add where, and what to drop: `lists` is vscode.toml's, `installed` this machine's."""
    result = Plan(add={MAIN: [], DARWIN: []})
    tracked = {i.lower() for ids in lists.values() for i in ids}
    have = {e.id.lower() for e in installed}
    for ext in installed:
        if ext.vsix:
            result.vsix.append(ext.id)
        elif ext.id.lower() not in tracked:
            result.add[DARWIN if darwin and ext.ui_only else MAIN].append(ext.id)
    # The Darwin list can't be installed off macOS, so it isn't "missing" there.
    checked = [MAIN, DARWIN] if darwin else [MAIN]
    for name in checked:
        for ident in lists.get(name, []):
            if ident.lower() in have:
                continue
            if prune:
                result.remove.add(ident)
            else:
                result.missing.append(ident)
    return result


def source_dir() -> Path:
    workspace = os.environ.get("BUILD_WORKSPACE_DIRECTORY")
    if workspace:
        return Path(workspace)
    chezmoi = shutil.which("chezmoi")
    found = chezmoi and subprocess.run(
        [chezmoi, "source-path"], capture_output=True, text=True, check=False
    )
    if not found or found.returncode != 0:
        sys.exit("export_vscode_extensions: run it with `bazel run`, or with chezmoi on PATH")
    return Path(found.stdout.strip())


def _section(title: str, ids: list[str]) -> None:
    if ids:
        print(title)
        for ident in ids:
            print(f"  {ident}")


def report(result: Plan) -> None:
    for name, ids in result.add.items():
        _section(f"added to {name}:", ids)
    _section("removed (not installed here):", sorted(result.remove))
    _section("left out (installed from a .vsix, not the marketplace):", result.vsix)
    _section("tracked but not installed here (--prune drops them):", result.missing)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--dry-run", action="store_true", help="print the diff, write nothing")
    parser.add_argument("--prune", action="store_true", help="drop tracked extensions that aren't installed")
    parser.add_argument("--code", help="the `code` CLI to ask (default: PATH, then the macOS app)")
    args = parser.parse_args(argv)

    path = source_dir() / DATA_FILE
    text = path.read_text(encoding="utf-8")
    lists = read_lists(text)
    if MAIN not in lists:
        sys.exit(f"export_vscode_extensions: no `{MAIN} = [` array in {path}")

    darwin = platform.system() == "Darwin"
    dirs = [Path(d).expanduser() for d in EXTENSION_DIRS]
    installed = describe(list_installed(find_code(args.code)), dirs)
    result = plan(lists, installed, darwin=darwin, prune=args.prune)

    merged = merge(text, result.add, result.remove)
    removed = {i.lower() for i in result.remove}
    got = read_lists(merged)
    for name in (MAIN, DARWIN):
        kept = [i for i in lists.get(name, []) if i.lower() not in removed]
        if got.get(name, []) != kept + result.add.get(name, []):
            sys.exit(f"export_vscode_extensions: {name} doesn't read back as intended; nothing written")

    report(result)
    if merged == text:
        print(f"{DATA_FILE}: up to date")
        return 0
    if args.dry_run:
        sys.stdout.writelines(
            difflib.unified_diff(
                text.splitlines(keepends=True), merged.splitlines(keepends=True), DATA_FILE, DATA_FILE
            )
        )
        return 0
    path.write_text(merged, encoding="utf-8")
    print(f"{DATA_FILE}: written; sort the new entries into their groups")
    return 0


if __name__ == "__main__":
    sys.exit(main())
