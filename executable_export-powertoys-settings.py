#!/usr/bin/env python3
"""Refreshes the tracked PowerToys settings from this machine's live tree.

    bazel run //:export_powertoys_settings       # from the repo
    python ~/export-powertoys-settings.py        # standalone, same thing

PowerToys reads its settings only from %LOCALAPPDATA%\\Microsoft\\PowerToys, so
dot_config/powertoys is a tracked copy and
.chezmoiscripts/run_onchange_after_link-powertoys-settings.ps1 pushes that copy
back out. This script is the other direction: settings changed in the PowerToys
UI come home to the repo.

Three properties it is built around:

1. The repo decides what is tracked, not this script. Only paths that already
   exist under dot_config/powertoys are refreshed. Live files that are neither
   tracked nor on IGNORED below are *reported* and never written, so a future
   PowerToys release cannot slip a new cache - or a new secret - into the tree
   just by existing.

2. The output is byte-identical to `jq .`, which is what the tracked files were
   prettified with. json.dumps(indent=2, ensure_ascii=False) reproduces jq's
   output for all 47 of them, given the one escaping rule in prettify().
   Re-exporting an unchanged machine therefore leaves `git status` clean.

3. Nothing is written that has not been parsed and round-tripped first, so a
   truncated or half-written live file is reported rather than committed.

Stdlib only, and no jq: PowerShell's ConvertTo-Json truncates at -Depth 2,
escapes non-ASCII as \\uXXXX and mangles empty collections, and jq would add a
runtime dependency for something json.dumps already does exactly.
"""

import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys
from pathlib import Path

SOURCE_SUBDIR = "dot_config/powertoys"

# Not part of the runtime tree: the .ptb is a PowerToys "Backup & restore"
# archive kept for hand-restoring, the .md is the directory's README.
SKIP_SUFFIXES = (".ptb", ".md")

# The live files that are deliberately not tracked, from the README's own list.
# Consulted only to classify files that are NOT in the repo: anything here is
# passed over in silence, anything else unknown is reported as a candidate.
# Patterns are fnmatch against the forward-slash relative path; logs are handled
# separately by is_log(), which mirrors the link script's `-imatch 'log'`.
IGNORED = (
    # Caches, history and MRU lists - rewritten as the tools get used.
    "ColorPicker/colorHistory.json",
    "PowerRename/search-mru.json",
    "PowerRename/replace-mru.json",
    "PowerRename/power-rename-ui-flags",
    "PowerToys Run/Settings/QueryHistory.json",
    "PowerToys Run/Settings/QueryHistory_version.txt",
    "PowerToys Run/Settings/ImageCache.json",
    "PowerToys Run/Settings/ImageCache_version.txt",
    "PowerToys Run/Settings/Pinyin.json",
    "PowerToys Run/Settings/Pinyin_version.txt",
    "PowerToys Run/Settings/UserSelectedRecord.json",
    "PowerToys Run/Settings/UserSelectedRecord_version.txt",
    # Per-machine state: monitor IDs, virtual desktop GUIDs, window positions.
    "FancyZones/applied-layouts.json",
    "FancyZones/app-zone-history.json",
    "FancyZones/editor-parameters.json",
    "FancyZones/last-used-virtual-desktop.json",
    "settings-placement.json",
    "*/settings-placement.json",
    # Install bookkeeping and telemetry.
    "UpdateState.json",
    "last_version_run.json",
    "experimentation.json",
    "oobe_settings.json",
    "settings-telemetry.json",
    # The example files New+ ships with. Real templates are user content.
    "NewPlus/Templates/*",
    # Mouse Without Borders stores its pairing key in plain text, which anyone
    # holding it can use to connect to this machine and share its clipboard and
    # files. It is not tracked, and this script must never be the thing that
    # starts tracking it.
    "MouseWithoutBorders/settings.json",
)

# Session state living inside a file that is otherwise worth tracking, keyed by
# path and given as dotted paths into the JSON. Dropped on the way in, so the
# tracked copy does not pick up a diff every time the tool is used.
#
# Awake writes expirationDateTime whenever it is armed - a wall-clock timestamp
# that changes on every run and means nothing on another machine. It is read
# only in "expirable" mode (the tracked mode is 1, indefinite), and PowerToys
# writes it back out from memory when it needs one, so the link script pushing
# a copy without the key costs nothing.
VOLATILE_KEYS = {
    "Awake/settings.json": ("properties.expirationDateTime",),
}

# A chezmoi template action, and the placeholder it is compared as. A tracked
# .tmpl is never overwritten - it is only checked for drift, and the value any
# action produces is unknowable here, so it matches anything.
TEMPLATE_COMMENT = re.compile(r"\{\{-?\s*/\*.*?\*/\s*-?\}\}", re.DOTALL)
TEMPLATE_ACTION = re.compile(r"\{\{.*?\}\}", re.DOTALL)
ANY_VALUE = "\x00chezmoi-template-action\x00"


def resolve_source_dir() -> Path:
    """The checkout to write into - never a build sandbox or the target tree.

    `bazel run` exports BUILD_WORKSPACE_DIRECTORY; outside bazel, ask chezmoi
    where its source directory is. Same shape as generate-brewfile.sh, so this
    file needs no chezmoi rendering and works from either entry point.
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


def resolve_live_dir() -> Path:
    local_appdata = os.environ.get("LOCALAPPDATA")
    if not local_appdata:
        die("LOCALAPPDATA is not set - this exports a Windows machine's settings")
    return Path(local_appdata) / "Microsoft" / "PowerToys"


def die(message: str) -> None:
    print(f"export-powertoys-settings: {message}", file=sys.stderr)
    raise SystemExit(1)


def is_log(rel: str) -> bool:
    """Logs/, ModuleInterface/Logs/, LogsModuleInterface/ and stray *.log alike.

    ~7,000 of the ~7,100 files in the live tree, so they are filtered before
    anything else looks at them.
    """
    return "log" in rel.lower()


def is_ignored(rel: str) -> bool:
    return any(fnmatch.fnmatch(rel, pattern) for pattern in IGNORED)


def read_text(path: Path) -> str:
    """utf-8-sig, so a BOM PowerToys wrote cannot leak into the tracked copy."""
    return path.read_bytes().decode("utf-8-sig")


def drop_volatile(rel: str, value):
    """Strip the session-state keys VOLATILE_KEYS lists for this file.

    The only place the exporter changes what it copies, and only by deletion.
    """
    for dotted in VOLATILE_KEYS.get(rel, ()):
        *parents, leaf = dotted.split(".")
        node = value
        for key in parents:
            if not isinstance(node, dict) or key not in node:
                node = None
                break
            node = node[key]
        if isinstance(node, dict):
            node.pop(leaf, None)
    return value


def prettify(value) -> str:
    """`jq .`, reimplemented on the stdlib.

    Two-space indent, keys left in the order PowerToys wrote them, non-ASCII
    emitted raw rather than escaped, trailing newline - all of which json.dumps
    already matches. The one place the two formatters disagree is U+007F, which
    jq escapes and json.dumps (which only escapes below U+0020) does not; one
    PowerToys Run plugin description contains a literal DEL, and leaving that
    unescaped would put a phantom diff in the tree on the first export.
    """
    text = json.dumps(value, indent=2, ensure_ascii=False)
    return text.replace("", "\\u007f") + "\n"


def write_text(path: Path, text: str) -> None:
    """LF and UTF-8 without a BOM, per .editorconfig.

    core.autocrlf is true in this checkout, so git normalises CRLF away and sees
    no churn from a refreshed file arriving with LF endings.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def strip_template(text: str):
    """A .tmpl parsed as JSON, with every action standing in for any value."""
    text = TEMPLATE_COMMENT.sub("", text)
    # A lambda, not the string itself: re would read the \u escapes json.dumps
    # produces as replacement-template escapes.
    text = TEMPLATE_ACTION.sub(lambda _: json.dumps(ANY_VALUE), text)
    return json.loads(text)


def drift(expected, actual, prefix: str = "") -> list:
    """Dotted paths at which `actual` departs from `expected`.

    ANY_VALUE matches anything: it is what a template action rendered to, and
    NewPlus' TemplateLocation is an absolute path that differs per machine by
    design.
    """
    if expected == ANY_VALUE:
        return []
    if isinstance(expected, dict) and isinstance(actual, dict):
        paths = []
        for key in sorted(set(expected) | set(actual)):
            where = f"{prefix}.{key}" if prefix else key
            if key not in expected or key not in actual:
                paths.append(where)
            else:
                paths += drift(expected[key], actual[key], where)
        return paths
    if isinstance(expected, list) and isinstance(actual, list):
        if len(expected) != len(actual):
            return [prefix or "(root)"]
        paths = []
        for index, (want, have) in enumerate(zip(expected, actual)):
            paths += drift(want, have, f"{prefix}[{index}]")
        return paths
    return [] if expected == actual else [prefix or "(root)"]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Refresh dot_config/powertoys from %LOCALAPPDATA%.",
        epilog="New modules are reported, never adopted: add them by hand.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="report what would change without writing anything",
    )
    args = parser.parse_args()

    tracked_root = resolve_source_dir() / SOURCE_SUBDIR
    if not tracked_root.is_dir():
        die(f"{tracked_root} does not exist")
    live_root = resolve_live_dir()
    if not live_root.is_dir():
        die(f"{live_root} does not exist - is PowerToys installed?")

    refreshed, unchanged, absent, problems, drifted, checked = [], [], [], [], [], []

    tracked = set()
    for path in sorted(tracked_root.rglob("*")):
        if not path.is_file() or path.suffix in SKIP_SUFFIXES:
            continue
        rel = path.relative_to(tracked_root).as_posix()
        # A .tmpl tracks the live file whose name it is, minus the suffix.
        live_rel = rel[: -len(".tmpl")] if rel.endswith(".tmpl") else rel
        tracked.add(live_rel)

        live = live_root / live_rel
        if not live.is_file():
            absent.append(live_rel)
            continue

        # Templates are checked, never written: the value of a template action
        # cannot be recovered from the rendered file.
        if rel.endswith(".tmpl"):
            try:
                expected = strip_template(read_text(path))
                actual = json.loads(read_text(live))
            except (ValueError, OSError) as error:
                problems.append(f"{rel}: cannot compare against live ({error})")
                continue
            checked.append(rel)
            differences = drift(expected, actual)
            if differences:
                drifted.append((rel, differences))
            continue

        try:
            live_text = read_text(live)
        except OSError as error:
            problems.append(f"{live_rel}: cannot read live file ({error})")
            continue

        if path.suffix == ".json":
            try:
                value = drop_volatile(live_rel, json.loads(live_text))
                formatted = prettify(value)
                # Reformatting must not change what the file means - the keys
                # dropped just above are the only intended difference. Cheap,
                # and the same guarantee the prettify commit made with jq.
                if json.loads(formatted) != value:
                    raise ValueError("reformatting changed the parsed value")
            except ValueError as error:
                problems.append(f"{live_rel}: not usable JSON ({error})")
                continue
        else:
            # Version stamps and the like: copied through as they are, since
            # they are not JSON and have no formatting to normalise.
            formatted = live_text

        # Compared with CRLF normalised away, since core.autocrlf checks these
        # out with CRLF while the blobs and everything written here are LF. A
        # file is refreshed only when its content really changed, so nothing is
        # rewritten - or reported - purely to flip its line endings.
        if formatted == read_text(path).replace("\r\n", "\n"):
            unchanged.append(live_rel)
            continue
        refreshed.append(live_rel)
        if not args.dry_run:
            write_text(path, formatted)

    # Anything live that the repo does not track and the README does not
    # deliberately exclude. Reported so a newly enabled module can be adopted
    # on purpose, rather than appearing in a diff one day.
    candidates = sorted(
        rel
        for rel in (
            p.relative_to(live_root).as_posix()
            for p in live_root.rglob("*")
            if p.is_file()
        )
        if not is_log(rel) and rel not in tracked and not is_ignored(rel)
    )

    verb = "would refresh" if args.dry_run else "refreshed"
    summary = f"powertoys: {verb} {len(refreshed)}, {len(unchanged)} unchanged"
    if checked:
        plural = "" if len(checked) == 1 else "s"
        summary += f", {len(checked)} template{plural} checked"
    print(summary)
    for rel in refreshed:
        print(f"  * {rel}")

    if drifted:
        print("\nTemplates that no longer match the live file - update by hand:")
        for rel, differences in drifted:
            print(f"  {rel}: {', '.join(differences)}")

    if candidates:
        print("\nLive settings this repo does not track. Add by hand if wanted:")
        for rel in candidates:
            print(f"  {rel}")

    if absent:
        print("\nTracked, but not in the live tree - module removed, or renamed:")
        for rel in absent:
            print(f"  {rel}")

    if problems:
        print("\nSkipped:", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        return 1

    if refreshed and not args.dry_run:
        print("\nRead the diff before committing.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
