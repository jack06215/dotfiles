#!/usr/bin/env python3
"""Analyze Monkeytype results copied with the Surfingkeys `yr` mapping.

Does the counting and arithmetic for the monkeytype-review skill and prints a
compact Markdown report: results against the accuracy goal, slow vs fast words,
each typo classified by alignment against a QWERTY finger map, speed through
the test, trends from a history log, and a draft practice list.

The input is the fixed YAML subset `yr` writes (dot_config/surfingkeys/index.js),
so a strict reader below parses it with the standard library alone: the script
runs on the macOS system python3 with nothing to install.

Usage:
  analyze.py result.yml             analyze, then append new results to the log
  analyze.py - <<'EOF' ... EOF      same, reading stdin
  analyze.py --recent 5             re-analyze the last 5 results in the log
"""
from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys
from collections import Counter
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

DEFAULT_LOG = (
    Path(os.environ.get('XDG_DATA_HOME') or Path.home() / '.local' / 'share')
    / 'monkeytype' / 'results.yml'
)
RECURRING_WINDOW = 20  # results scanned for recurring problem words and key confusions
PRACTICE_LIMIT = 20
AFK_FLAG_PCT = 2

# ---------------------------------------------------------------------------
# Reader for the YAML subset `yr` writes
# ---------------------------------------------------------------------------


class ParseError(ValueError):
    pass


KEY_LINE = re.compile(r'^( *)([A-Za-z_]\w*):(?: (.*))?$')
FLOW_KEY = re.compile(r'^[A-Za-z_]\w*$')
NUMBER = re.compile(r'^-?\d+(?:\.\d+)?$')


@dataclass
class Result:
    data: dict
    source: str  # normalized document text, appended verbatim to the log

    @property
    def words(self) -> list[dict]:
        return [w for w in self.data.get('words') or [] if isinstance(w, dict)]

    @property
    def language(self) -> str:
        return str(self.data.get('language') or 'custom')

    @property
    def flags(self) -> list[str]:
        other = self.data.get('other') or []
        return [str(flag) for flag in (other if isinstance(other, list) else [other])]

    @property
    def fingerprint(self) -> tuple:
        # `date` is when `yr` was pressed, so copying one result twice gives two
        # dates; the measured values identify the test itself.
        keys = ('test', 'language', 'wpm', 'raw', 'acc', 'consistency', 'time')
        return tuple(self.data.get(key) for key in keys)

    @property
    def timestamp(self) -> float:
        try:
            return datetime.fromisoformat(str(self.data.get('date'))).timestamp()
        except ValueError:
            return float('-inf')


def parse_scalar(text: str, line_no: int):
    text = text.strip()
    if text.startswith('"'):
        try:
            return json.loads(text)  # `yr` quotes with JSON.stringify
        except json.JSONDecodeError:
            raise ParseError(f'line {line_no}: bad quoted string {text}') from None
    if text in ('true', 'false'):
        return text == 'true'
    if text in ('', '~', 'null'):
        return None
    if text == '.inf':
        return math.inf
    if NUMBER.match(text):
        return float(text) if '.' in text else int(text)
    return text


def split_flow(inner: str, line_no: int) -> list[str]:
    """Split the inside of {...} or [...] on commas outside quoted strings."""
    items, current = [], []
    in_quote = escaped = False
    for ch in inner:
        if in_quote:
            current.append(ch)
            if escaped:
                escaped = False
            elif ch == '\\':
                escaped = True
            elif ch == '"':
                in_quote = False
        elif ch == '"':
            in_quote = True
            current.append(ch)
        elif ch == ',':
            items.append(''.join(current).strip())
            current = []
        elif ch in '{}[]':
            raise ParseError(f'line {line_no}: nested collections are not supported')
        else:
            current.append(ch)
    if in_quote:
        raise ParseError(f'line {line_no}: unterminated quoted string')
    tail = ''.join(current).strip()
    if tail or items:
        items.append(tail)
    return items


def parse_value(text: str, line_no: int):
    text = text.strip()
    if text.startswith('{'):
        if not text.endswith('}'):
            raise ParseError(f'line {line_no}: unclosed {{')
        mapping = {}
        for item in split_flow(text[1:-1], line_no):
            key, sep, value = item.partition(':')
            if not sep or not FLOW_KEY.match(key.strip()):
                raise ParseError(f'line {line_no}: expected "key: value", got {item!r}')
            mapping[key.strip()] = parse_scalar(value, line_no)
        return mapping
    if text.startswith('['):
        if not text.endswith(']'):
            raise ParseError(f'line {line_no}: unclosed [')
        return [parse_scalar(item, line_no) for item in split_flow(text[1:-1], line_no)]
    return parse_scalar(text, line_no)


def parse_result(chunk: list[tuple[int, str]]) -> Result:
    first_no, first = chunk[0]
    if first != 'monkeytype:':
        raise ParseError(f'line {first_no}: expected "monkeytype:", got {first.strip()!r}')
    data: dict = {}
    words = None
    for line_no, line in chunk[1:]:
        if line.startswith('    - '):
            if words is None:
                raise ParseError(f'line {line_no}: list item outside "words:"')
            item = parse_value(line[6:], line_no)
            if not isinstance(item, dict) or 'word' not in item:
                raise ParseError(f'line {line_no}: expected {{word: ..., ...}}')
            words.append(item)
            continue
        match = KEY_LINE.match(line)
        if not match or match.group(1) != '  ':
            raise ParseError(f'line {line_no}: unexpected line {line.strip()!r}')
        key, value = match.group(2), match.group(3)
        if value is None:
            words = data.setdefault(key, [])  # only `words:` opens a block list
        else:
            words = None
            data[key] = parse_value(value, line_no)
    if 'wpm' not in data:
        raise ParseError(f'line {first_no}: result has no wpm')
    source = '---\n' + '\n'.join(line for _, line in chunk) + '\n'
    return Result(data, source)


def parse_results(text: str) -> list[Result]:
    """Split text into `monkeytype:` documents; blank lines, comments and code fences are skipped."""
    chunks: list[list[tuple[int, str]]] = []
    for line_no, raw in enumerate(text.splitlines(), 1):
        line = raw.rstrip()
        stripped = line.strip()
        if not stripped or stripped.startswith(('#', '```')):
            continue
        if stripped == '---':
            chunks.append([])
            continue
        if not chunks or (line == 'monkeytype:' and chunks[-1]):
            chunks.append([])  # first document, or one pasted without its --- line
        chunks[-1].append((line_no, line))
    return [parse_result(chunk) for chunk in chunks if chunk]


# ---------------------------------------------------------------------------
# Keyboard model: US QWERTY (HHKB letter block) with touch-typing fingers
# ---------------------------------------------------------------------------

ROWS = [
    (0.0, '`1234567890-='),
    (1.5, 'qwertyuiop[]\\'),
    (1.75, "asdfghjkl;'"),
    (2.25, 'zxcvbnm,./'),
]
KEY_POS = {ch: (offset + i, row) for row, (offset, keys) in enumerate(ROWS) for i, ch in enumerate(keys)}
SHIFTED = dict(zip('~!@#$%^&*()_+{}|:"<>?', "`1234567890-=[]\\;',./"))
FINGERS = {
    ('left', 'pinky'): '`1qaz',
    ('left', 'ring'): '2wsx',
    ('left', 'middle'): '3edc',
    ('left', 'index'): '45rtfgvb',
    ('right', 'index'): '67yuhjnm',
    ('right', 'middle'): '8ik,',
    ('right', 'ring'): '9ol.',
    ('right', 'pinky'): "0-=p[]\\;'/",
}
FINGER_OF = {ch: finger for finger, keys in FINGERS.items() for ch in keys}
NEIGHBOUR_DISTANCE = 1.3  # key pitches; covers side and diagonal neighbours


def base_key(ch: str) -> str:
    ch = ch.lower()
    return SHIFTED.get(ch, ch)


def shift_count(word: str) -> int:
    return sum(1 for ch in word if ch.isupper() or ch in SHIFTED)


def symbol_count(word: str) -> int:
    return sum(1 for ch in word if not ch.isalnum())


def wrong_key_kind(expected: str, typed: str) -> str:
    a, b = base_key(expected), base_key(typed)
    if a == b:
        return 'Shift error'
    pos_a, pos_b = KEY_POS.get(a), KEY_POS.get(b)
    if pos_a and pos_b and math.dist(pos_a, pos_b) < NEIGHBOUR_DISTANCE:
        return 'wrong key: neighbour'
    finger_a, finger_b = FINGER_OF.get(a), FINGER_OF.get(b)
    if finger_a and finger_b:
        if finger_a == finger_b:
            return 'wrong key: same finger'
        if finger_a[1] == finger_b[1]:
            return 'wrong key: mirror'  # same finger, other hand
    return 'wrong key: other'


CATEGORIES = [
    'swapped letters',
    'wrong key: neighbour',
    'wrong key: same finger',
    'wrong key: mirror',
    'wrong key: other',
    'Shift error',
    'missing letter',
    'extra letter',
    'doubled letter',
    'early space',
]

# ---------------------------------------------------------------------------
# Typo classification
# ---------------------------------------------------------------------------


def align(target: str, typed: str) -> list[tuple[str, str, str]]:
    """Optimal string alignment of target vs typed: (op, expected, typed) for each edit."""
    n, m = len(target), len(typed)
    dist = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n + 1):
        dist[i][0] = i
    for j in range(m + 1):
        dist[0][j] = j
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            cost = 0 if target[i - 1] == typed[j - 1] else 1
            dist[i][j] = min(dist[i - 1][j] + 1, dist[i][j - 1] + 1, dist[i - 1][j - 1] + cost)
            if is_swap(target, typed, i, j):
                dist[i][j] = min(dist[i][j], dist[i - 2][j - 2] + 1)

    ops = []
    i, j = n, m
    while i > 0 or j > 0:
        if i and j and target[i - 1] == typed[j - 1] and dist[i][j] == dist[i - 1][j - 1]:
            i, j = i - 1, j - 1
        elif is_swap(target, typed, i, j) and dist[i][j] == dist[i - 2][j - 2] + 1:
            ops.append(('swap', target[i - 2:i], typed[j - 2:j]))
            i, j = i - 2, j - 2
        elif i and j and dist[i][j] == dist[i - 1][j - 1] + 1:
            ops.append(('sub', target[i - 1], typed[j - 1]))
            i, j = i - 1, j - 1
        elif i and dist[i][j] == dist[i - 1][j] + 1:
            ops.append(('missing', target[i - 1], ''))
            i -= 1
        else:
            neighbours = {typed[j - 2] if j > 1 else '', target[i] if i < n else ''}
            ops.append(('doubled' if typed[j - 1] in neighbours else 'extra', '', typed[j - 1]))
            j -= 1
    return ops[::-1]


def is_swap(target: str, typed: str, i: int, j: int) -> bool:
    return (
        i > 1 and j > 1
        and target[i - 1] == typed[j - 2]
        and target[i - 2] == typed[j - 1]
        and target[i - 1] != target[i - 2]
    )


def classify(word: dict) -> list[tuple[str, str, str]]:
    """(category, detail, confusion) for each typo in the word's first attempt."""
    target, typed = str(word.get('word', '')), word.get('typed')
    if typed is None:
        return []
    typed = str(typed)
    # Monkeytype shows a space pressed before the word was finished as `_`
    if typed.endswith('_') and not target.startswith(typed) and target.startswith(typed[:-1]):
        return [('early space', f'space after "{typed[:-1]}"', '')]
    typos = []
    for op, expected, got in align(target, typed):
        if op == 'swap':
            typos.append(('swapped letters', f'"{expected}"→"{got}"', f'{expected}→{got}'))
        elif op == 'sub':
            typos.append((wrong_key_kind(expected, got), f'"{expected}"→"{got}"', f'{expected}→{got}'))
        elif op == 'missing':
            typos.append(('missing letter', f'"{expected}" missing', ''))
        else:
            typos.append((f'{op} letter', f'extra "{got}"', ''))
    return typos


def is_mistake(word: dict) -> bool:
    return word.get('typed') is not None or bool(word.get('fixed')) or bool(word.get('error'))


# ---------------------------------------------------------------------------
# Statistics
# ---------------------------------------------------------------------------


def number(value):
    return value if isinstance(value, (int, float)) and not isinstance(value, bool) else None


def mean(values):
    values = [v for v in values if v is not None and math.isfinite(v)]
    return sum(values) / len(values) if values else None


def text(word: dict) -> str:
    return str(word.get('word', ''))


def split_speed(words: list[dict]) -> tuple[list[dict], list[dict]]:
    """Slowest and fastest ~15% of words (at least 3 each when there are enough)."""
    timed = sorted((w for w in words if number(w.get('wpm')) is not None), key=lambda w: w['wpm'])
    k = min(max(3, round(len(timed) * 0.15)), len(timed) // 2)
    return timed[:k], timed[::-1][:k]


def lost_seconds(result: Result):
    """Lower bound of time spent on wrong keys + backspaces."""
    keys = result.data.get('keys') if isinstance(result.data.get('keys'), dict) else {}
    incorrect, raw = number(keys.get('incorrect')), number(result.data.get('raw'))
    if incorrect is None or not raw:
        return None
    return incorrect * 2 * 60 / (raw * 5)


def segments(n: int) -> list[tuple[str, int, int]]:
    if n >= 30:
        return [('first 10', 0, 10), ('middle', 10, n - 10), ('last 10', n - 10, n)]
    if n >= 3:
        return [('first third', 0, n // 3), ('middle third', n // 3, n - n // 3), ('last third', n - n // 3, n)]
    return [('all', 0, n)]


def by_date(results: list[Result]) -> list[Result]:
    return sorted(results, key=lambda r: r.timestamp)


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------


def fmt(value, digits: int = 1) -> str:
    value = number(value)
    if value is None:
        return '–'
    if math.isinf(value):
        return '∞'
    if isinstance(value, int):
        return str(value)
    rounded = f'{value:.{digits}f}'
    return rounded.rstrip('0').rstrip('.') if '.' in rounded else rounded


def plural(n: int, noun: str) -> str:
    return f'{n} {noun}' + ('' if n == 1 else 's')


def table(header: list[str], rows: list[list[str]]) -> list[str]:
    lines = ['| ' + ' | '.join(header) + ' |', '|' + '---|' * len(header)]
    lines += ['| ' + ' | '.join(row) + ' |' for row in rows]
    return lines + ['']


def results_section(session: list[Result], goal: float) -> list[str]:
    rows = []
    for result in session:
        d = result.data
        acc, time = number(d.get('acc')), number(d.get('time'))
        lost = lost_seconds(result)
        lost_text = '–' if lost is None else f'{lost:.1f}s' + (f' ({lost / time:.0%})' if time else '')
        chars = d.get('chars') if isinstance(d.get('chars'), dict) else None
        left = '–' if chars is None else str(sum(number(chars.get(k)) or 0 for k in ('incorrect', 'extra', 'missed')))
        flags = result.flags
        afk = number(d.get('afk_pct'))
        if afk is not None and afk > AFK_FLAG_PCT:
            flags = flags + [f'afk {fmt(afk)}%']
        rows.append([
            str(d.get('date', '–'))[:16].replace('T', ' '),
            str(d.get('test', '–')),
            result.language,
            fmt(d.get('wpm'), 2),
            fmt(d.get('raw'), 2),
            f'{fmt(acc, 2)}%',
            '–' if acc is None else ('met' if acc >= goal else 'missed'),
            f'{fmt(d.get("consistency"))}% ({fmt(d.get("key_consistency"))}%)',
            f'{fmt(time, 2)}s',
            lost_text,
            left,
            'yes' if d.get('pb') else '',
            ', '.join(flags),
        ])
    header = ['date', 'test', 'language', 'wpm', 'raw', 'acc', 'goal', 'consistency (key)',
              'time', 'lost to mistakes', 'left wrong', 'pb', 'flags']
    return [f'## Results (goal: acc ≥ {fmt(goal)}%)', ''] + table(header, rows)


def speed_section(words: list[dict]) -> list[str]:
    slow, fast = split_speed(words)

    def row(label, group):
        return [
            label,
            str(len(group)),
            fmt(mean(number(w.get('wpm')) for w in group)),
            fmt(mean(len(text(w)) for w in group)),
            fmt(mean(shift_count(text(w)) for w in group)),
            fmt(mean(symbol_count(text(w)) for w in group)),
            str(sum(1 for w in group if is_mistake(w))),
        ]

    header = ['group', 'words', 'mean wpm', 'mean length', 'Shift presses/word', 'symbols/word', 'with mistakes']
    lines = [f'## Word speed ({len(words)} typed words)', '']
    lines += table(header, [row(f'slowest {len(slow)}', slow), row(f'fastest {len(fast)}', fast), row('all', words)])
    lines.append('Slowest: ' + ', '.join(f'{text(w)} {fmt(w["wpm"], 0)}' for w in slow))
    lines.append('Fastest: ' + ', '.join(f'{text(w)} {fmt(w["wpm"], 0)}' for w in fast))
    return lines + ['']


def mistakes_section(words: list[dict]) -> list[str]:
    flagged = [(w, classify(w)) for w in words if is_mistake(w)]
    typo_count = sum(len(typos) for _, typos in flagged)
    lines = [f'## Mistakes ({len(flagged)} of {len(words)} words, {typo_count} typos)', '']
    if not flagged:
        return lines + ['No mistakes.', '']

    counts, examples = Counter(), {}
    confusions = Counter()
    for word, typos in flagged:
        for category, detail, confusion in typos:
            counts[category] += 1
            examples.setdefault(category, []).append(f'{text(word)} ({detail})')
            if confusion:
                confusions[confusion] += 1
    rows = [[c, str(counts[c]), ', '.join(examples[c][:3])] for c in CATEGORIES if counts[c]]
    lines += table(['type', 'count', 'examples'], rows)

    lines.append('Per word (typed = first attempt, before corrections):')
    shown = 30
    for word, typos in flagged[:shown]:
        typed = word.get('typed')
        what = '; '.join(detail for _, detail, _ in typos) or 'no first attempt recorded'
        extras = [f'wpm {fmt(word.get("wpm"), 0)}']
        if word.get('fixed'):
            extras.append(f'fixed {word["fixed"]}')
        if word.get('error'):
            extras.append('still wrong when submitted')
        arrow = f' ← {typed}' if typed is not None else ''
        lines.append(f'- {text(word)}{arrow}: {what} ({", ".join(extras)})')
    if len(flagged) > shown:
        lines.append(f'- … and {len(flagged) - shown} more')
    if confusions:
        top = ', '.join(f'{pair} ×{n}' for pair, n in confusions.most_common(10))
        lines += ['', f'Key confusions (expected→typed): {top}']
    return lines + ['']


def position_section(session: list[Result]) -> list[str]:
    buckets: dict[str, list[dict]] = {}
    for result in session:
        words = result.words
        for label, start, end in segments(len(words)):
            buckets.setdefault(label, []).extend(words[start:end])
    rows = [
        [label, str(len(group)), fmt(mean(number(w.get('wpm')) for w in group)),
         str(sum(1 for w in group if is_mistake(w)))]
        for label, group in buckets.items()
    ]
    return ['## Position in test', ''] + table(['part', 'words', 'mean wpm', 'words with mistakes'], rows)


def trend_section(session: list[Result], earlier: list[Result], goal: float, last: int) -> list[str]:
    lines = []
    for language in dict.fromkeys(r.language for r in session):
        previous = [r for r in by_date(earlier) if r.language == language][-last:]
        current = [r for r in session if r.language == language]
        lines += [f'## Trend: {language}', '']
        if not previous:
            lines += ['No earlier results for this word list in the log yet.', '']
            continue
        rows = by_date(previous + current)[-last:]
        current_ids = {id(r) for r in current}
        table_rows = []
        for r in rows:
            acc = number(r.data.get('acc'))
            table_rows.append([
                str(r.data.get('date', '–'))[:16].replace('T', ' ') + (' *' if id(r) in current_ids else ''),
                str(r.data.get('test', '–')),
                fmt(r.data.get('wpm'), 2),
                f'{fmt(acc, 2)}%',
                '–' if acc is None else ('met' if acc >= goal else 'missed'),
                f'{fmt(r.data.get("consistency"))}%',
                'yes' if r.data.get('pb') else '',
                ', '.join(r.flags),
            ])
        lines += table(['date (* = this session)', 'test', 'wpm', 'acc', 'goal', 'consistency', 'pb', 'flags'],
                       table_rows)
        latest = current[-1]
        deltas = []
        for key in ('wpm', 'acc', 'consistency'):
            now, before = number(latest.data.get(key)), mean(number(r.data.get(key)) for r in previous)
            if now is not None and before is not None:
                deltas.append(f'{key} {now - before:+.1f}')
        lines.append(f'Latest vs average of previous {len(previous)}: ' + (', '.join(deltas) or '–'))
        met = sum(1 for r in rows if (number(r.data.get('acc')) or 0) >= goal)
        lines += [f'Goal met in {met} of {len(rows)} results shown.', '']
    return lines


def recurring_section(session: list[Result], earlier: list[Result]) -> tuple[list[str], list[str]]:
    window = by_date(earlier + session)[-RECURRING_WINDOW:]
    slow_in, mistyped_in, in_results, confusions = Counter(), Counter(), Counter(), Counter()
    for result in window:
        slow, _ = split_speed(result.words)
        slow_words = {text(w) for w in slow}
        mistyped_words = {text(w) for w in result.words if is_mistake(w)}
        slow_in.update(slow_words)
        mistyped_in.update(mistyped_words)
        in_results.update(slow_words | mistyped_words)
        for word in result.words:
            confusions.update(confusion for _, _, confusion in classify(word) if confusion)
    recurring = sorted((w for w, n in in_results.items() if n >= 2), key=lambda w: (-in_results[w], w))[:10]

    lines = [f'## Recurring problems (last {plural(len(window), "result")})', '']
    if recurring:
        lines += [f'- {w}: slow ×{slow_in[w]}, mistyped ×{mistyped_in[w]}' for w in recurring]
    else:
        lines.append('No word was slow or mistyped in more than one result.')
    repeated = [(pair, n) for pair, n in confusions.most_common(10) if n >= 2]
    if repeated:
        lines.append('Repeated key confusions (expected→typed): ' + ', '.join(f'{p} ×{n}' for p, n in repeated))
    return lines + [''], recurring


def practice_section(words: list[dict], recurring: list[str]) -> list[str]:
    slow, _ = split_speed(words)
    mistyped = sorted((w for w in words if is_mistake(w)), key=lambda w: -len(classify(w)))
    ordered = recurring + [text(w) for w in mistyped] + [text(w) for w in slow]
    practice = list(dict.fromkeys(w for w in ordered if w))[:PRACTICE_LIMIT]
    lines = ['## Practice list (draft: recurring, then mistyped, then slowest)', '']
    if not practice:
        return lines + ['Nothing to practice.']
    return lines + ['```', ' '.join(practice), '```']


def render(session: list[Result], earlier: list[Result], goal: float, last: int, notes: list[str]) -> str:
    lines = ['# Monkeytype analysis', ''] + [f'- {note}' for note in notes] + ['']
    lines += results_section(session, goal)
    words = [w for r in session for w in r.words]
    if words:
        lines += speed_section(words) + mistakes_section(words) + position_section(session)
    else:
        lines += ['No input history in these results: open it on the result screen before pressing `yr`.', '']
    lines += trend_section(session, earlier, goal, last)
    recurring_lines, recurring = recurring_section(session, earlier)
    lines += recurring_lines
    if words:
        lines += practice_section(words, recurring)
    return '\n'.join(lines).rstrip() + '\n'


# ---------------------------------------------------------------------------
# Log and CLI
# ---------------------------------------------------------------------------


def append_to_log(path: Path, results: list[Result]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    needs_newline = path.exists() and path.stat().st_size > 0 and not path.read_bytes().endswith(b'\n')
    with path.open('a', encoding='utf-8') as log:
        if needs_newline:
            log.write('\n')
        log.writelines(r.source for r in results)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('files', nargs='*', help='YAML files with new results; - reads stdin')
    parser.add_argument('--goal', type=float, default=96, help='accuracy goal in %% (default: 96)')
    parser.add_argument('--log', type=Path, default=DEFAULT_LOG, help=f'history log (default: {DEFAULT_LOG})')
    parser.add_argument('--no-save', action='store_true', help="don't append new results to the log")
    parser.add_argument('--recent', type=int, default=1, metavar='N',
                        help='with no files: analyze the last N results in the log (default: 1)')
    parser.add_argument('--last', type=int, default=10, metavar='N', help='results per trend table (default: 10)')
    args = parser.parse_args(argv)

    notes = []
    history: list[Result] = []
    if args.log.exists():
        try:
            history = parse_results(args.log.read_text(encoding='utf-8'))
        except (OSError, ParseError) as err:
            notes.append(f'WARNING: could not read the log {args.log}, trends skipped: {err}')

    session: list[Result] = []
    try:
        for name in args.files:
            source = sys.stdin.read() if name == '-' else Path(name).read_text(encoding='utf-8')
            session += parse_results(source)
    except (OSError, ParseError) as err:
        print(f'error: {err}', file=sys.stderr)
        return 2

    if args.files:
        if not session:
            print('error: no monkeytype results in the input', file=sys.stderr)
            return 2
        known = {r.fingerprint for r in history}
        new = []
        for result in session:
            if result.fingerprint not in known:
                new.append(result)
                known.add(result.fingerprint)
        if args.no_save:
            notes.append('Not saved to the log (--no-save).')
        elif not new:
            notes.append(f'Already in the log {args.log}, not saved again.')
        else:
            try:
                append_to_log(args.log, new)
                notes.append(f'Saved {plural(len(new), "new result")} to {args.log}.')
            except OSError as err:
                notes.append(f'WARNING: could not save to the log: {err}')
    else:
        session = by_date(history)[-args.recent:]
        if not session:
            print(f'error: no results given and the log {args.log} is empty', file=sys.stderr)
            return 2

    session_ids = {r.fingerprint for r in session}
    earlier = [r for r in history if r.fingerprint not in session_ids]
    notes.insert(0, f'Session: {plural(len(session), "result")}. History: {plural(len(earlier), "earlier result")}.')
    sys.stdout.write(render(session, earlier, args.goal, args.last, notes))
    return 0


if __name__ == '__main__':
    sys.exit(main())
