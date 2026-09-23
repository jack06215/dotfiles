---
name: monkeytype-review
description: 'Analyze Monkeytype typing test results and coach what to practice next. Use when the user pastes a Monkeytype result as YAML (a `monkeytype:` block copied with the Surfingkeys `yr` shortcut), asks to review their typing test or typing progress, or runs /monkeytype-review.'
---

# Monkeytype Review

Input: $ARGUMENTS

Turn Monkeytype results into a short, evidence-based diagnosis and a few concrete things to practice next. `scripts/analyze.py` does every count and calculation. Your job is the judgment: what matters most and what to practice. Use the script's numbers as they are; don't recompute them.

## About the typist (edit as needed)

- Practices code word lists (e.g. `code python 5k`, `code vim`) in 50-word tests.
- Priorities in order: accuracy ≥ 96% (Monkeytype fails tests below that), then consistency, then speed. The goal is passed to the script as `--goal 96`; keep it in sync with Monkeytype's min accuracy setting.
- Keyboard: HHKB Studio, QWERTY.

## Step 1: Run the script

The script is `scripts/analyze.py` in this skill's base directory (shown when the skill loads; normally `~/.config/claude/skills/monkeytype-review`). It needs only `python3`, no packages.

**YAML pasted** in the arguments or the conversation: pipe it in unchanged. Leave out chat text around it; code fences are fine, and so are several results at once.

```bash
python3 <skill-dir>/scripts/analyze.py - --goal 96 <<'MONKEYTYPE_YAML'
<the pasted YAML>
MONKEYTYPE_YAML
```

**No YAML, but the user asks about progress or recent tests**: analyze the last N results from the log instead, e.g. `python3 <skill-dir>/scripts/analyze.py --recent 5 --goal 96`.

New results are appended to the history log `~/.local/share/monkeytype/results.yml` (a result copied twice is saved once), and the report compares against everything in it.

- If the report starts with `WARNING: could not save to the log` and the error is a permission error, the sandbox blocked the write. Rerun the same command with the sandbox disabled so the result is saved, and mention that `/sandbox` can allow `~/.local/share/monkeytype` permanently.
- If the script exits with a parse error, quote the line it names and ask the user to copy the result again with `yr`. Don't edit the YAML to make it parse.

## Step 2: Read the report

- **Results**: one row per pasted result. `acc` counts every wrong keypress, including ones fixed with backspace; `left wrong` counts characters still wrong in the final text. `lost to mistakes` is a lower bound: wrong keys plus backspaces, not the hesitation after a mistake. Consistency is how steady the second-by-second speed was; the figure in brackets is how even the gaps between keypresses were. Flags come from Monkeytype (`failed (min accuracy)`, `invalid`, …), plus `afk` above 2%.
- **Word speed**: the slowest and fastest ~15% of words with their length, Shift presses, symbols and how many had mistakes. The script only measures. You judge what separates the groups, for example whether slow words are abbreviations with letter combinations English doesn't use (`rlc`, `qrt`) while fast ones are made of English words. If most slow words had mistakes, the mistakes are the cause.
- **Mistakes**: each typo, found by aligning the first attempt (`typed`, before corrections) with the target word and placing keys on the standard touch-typing finger map: swapped letters, wrong key (neighbour key, same finger, mirror = same finger on the other hand, other), Shift error, missing, extra or doubled letter, early space.
- **Position in test**: first 10, middle and last 10 words. A slow start suggests warm-up; more mistakes at the end suggest fatigue or lost focus.
- **Trend** and **Recurring problems**: history from the log, per word list. Code word lists are much slower than English for everyone, so never compare speed across word lists.
- **Practice list**: a draft. Reorder or trim it if your findings point elsewhere.

Not available anywhere: the second-by-second speed chart, timing between individual keys, and which finger actually pressed each key (the finger map is the standard assignment, not a measurement). Don't infer or invent them.

Evidence rules:

- A 50-word test is a small sample. Call something a pattern only if it appears in at least 3 words (or in at least 2 results); otherwise label it a one-off.
- Back every claim with words and numbers from the report.
- No "average typist" benchmarks. Compare the typist only with their own results.
- A PB on the first test of a new setup is automatic, not an achievement.

## Step 3: Answer

Stay around 300 words, not counting the practice list. No preamble and no filler praise.

**Summary**: one or two sentences on the main thing holding the score back.

**Numbers**: a small table with wpm, raw, acc (vs goal), consistency, and time lost to mistakes. With history, add the change from the previous average.

**What's slowing you down**: 2–4 bullets, each a pattern followed by its evidence (words, numbers).

**Next session**: at most 3 concrete actions (e.g. "type at ~35 wpm aiming for 98%", "one warm-up test first"), each tied to a finding above.

**Practice list**: at most 20 words, space-separated on one line in a code block, ready to paste into Monkeytype's custom text mode.

If the input isn't a Monkeytype result from `yr`, say so and ask for one.
