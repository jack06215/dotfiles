#!/usr/bin/env python3
"""Convert a JSONL file with into human-readable UTF-8 JSONL, written to stdout.

Usage:
    python jsonl_unescape.py input.jsonl | pbcopy
    python jsonl_unescape.py input.jsonl > output.jsonl
    cat input.jsonl | python jsonl_unescape.py | pbcopy

Add --pretty to indent each JSON object instead of keeping it on one line.
"""

import argparse
import json
import sys


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "input",
        nargs="?",
        type=argparse.FileType("r", encoding="utf-8"),
        default=sys.stdin,
        help="Path to the JSONL file (defaults to stdin)",
    )
    parser.add_argument(
        "--pretty",
        action="store_true",
        help="Pretty-print each JSON object with indent=2 instead of one line",
    )
    args = parser.parse_args()

    indent = 2 if args.pretty else None

    for line_number, line in enumerate(args.input, start=1):
        stripped = line.strip()
        if not stripped:
            continue
        try:
            obj = json.loads(stripped)
        except json.JSONDecodeError as exc:
            print(f"Line {line_number}: invalid JSON ({exc})", file=sys.stderr)
            continue
        sys.stdout.write(json.dumps(obj, ensure_ascii=False, indent=indent))
        sys.stdout.write("\n")


if __name__ == "__main__":
    main()
