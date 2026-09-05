---
name: youtube-transcribe-skill
description: 'Extract subtitles/transcripts from YouTube videos. Triggers: "youtube transcript", "extract subtitles", "video captions".'
---

# YouTube Transcript Extraction

Extract subtitles/transcripts from a YouTube video URL and save them as a local file.

Input YouTube URL: $ARGUMENTS

## Language Preference

Only these languages are wanted, in this priority order:

1. **English** — `en` (and regional variants `en-US`, `en-GB`, …)
2. **Japanese** — `ja`
3. **Taiwanese Mandarin** — `zh-TW`, falling back to `zh-Hant`, then to bare `zh`

Prefer the video's original spoken language when it is one of the three; otherwise take the highest-priority available. Prefer manually-authored subtitles over auto-generated ones for the same language.

**Never** download Simplified Chinese (`zh-Hans`, `zh-CN`) or any other language. If none of the accepted languages are available, report which languages *are* available and ask the user how to proceed instead of downloading a substitute.

### The bare `zh` track

A track tagged plain `zh` carries no script information — it is usually Traditional, but it can be Simplified. Accept it as a last resort for Taiwanese Mandarin, and when it is the track that gets used:

- **Warn the user** in the completion report: the track was tagged `zh`, so the script was not guaranteed and may turn out to be Simplified.
- Confirm by inspecting the saved text: characters like 这/说/机/会 (Simplified) versus 這/說/機/會 (Traditional). State what you actually found in the file rather than guessing from the tag alone.

## Step 1: Verify URL

Confirm the input is a valid YouTube URL (supports `youtube.com/watch?v=`, `youtu.be/`, and `youtube.com/shorts/` formats). If no URL is provided via arguments, check the conversation context for a YouTube link.

## Step 2: CLI Quick Extraction (Priority Attempt)

Use command-line tools to quickly extract subtitles.

### 2.1 Check Tool Availability

Execute `which yt-dlp`.

- If `yt-dlp` is **found**, proceed to 2.2.
- If `yt-dlp` is **not found**, skip to **Step 3**.

### 2.2 Get Video Title

```bash
yt-dlp --cookies-from-browser=chrome --get-title "[VIDEO_URL]"
```

- **Tip**: Always add `--cookies-from-browser` to avoid sign-in restrictions. Default to `chrome`.
- If it fails with a browser error (e.g., "Could not open Chrome"), ask the user to specify their available browser (e.g., `firefox`, `safari`, `edge`) and retry.

### 2.3 Download Subtitles

First list what the video actually offers, so the choice is made against real data rather than guessed:

```bash
yt-dlp --cookies-from-browser=chrome --list-subs "[VIDEO_URL]"
```

Pick the best track per the **Language Preference** section, then download it:

```bash
yt-dlp --cookies-from-browser=chrome --write-auto-sub --write-sub --sub-lang "en.*,ja.*,zh-TW,zh-Hant.*,zh" --skip-download --output "<Video Title>.%(ext)s" "[VIDEO_URL]"
```

- `--sub-lang` entries are regexes anchored at the end by yt-dlp (it appends `$`), so `en.*` covers `en-US`/`en-GB`, `zh-Hant.*` covers `zh-Hant-TW`, and bare `zh` matches **only** the exact `zh` tag. Do not write it as `zh.*` — that would also pull in `zh-Hans`.
- If the listing showed only Simplified Chinese or other unwanted languages, stop here and ask the user (see **Language Preference**).
- If the download pulled multiple accepted languages, keep the highest-priority one and delete the rest.

### 2.4 Convert to Plain Text

`yt-dlp` saves subtitles as `.vtt` or `.srt` files. Convert the downloaded file to plain `Timestamp Text` format:

1. Read the downloaded subtitle file (`.vtt` or `.srt`).
2. Strip VTT/SRT headers, styling tags, and duplicate lines.
3. Save as `<Video Title>.txt` with one `Timestamp Text` entry per line.

### 2.5 Verify Results

- **Exit code 0**: Convert and save the subtitle file, then report completion.
- **Exit code non-0**:
  - If error is related to browser/cookies, ask user for correct browser and retry.
  - If other errors (e.g., video unavailable), proceed to **Step 3**.

## Step 3: Browser Automation (Fallback)

When the CLI method fails or `yt-dlp` is missing, use Chrome DevTools MCP to extract subtitles via browser UI automation.

### 3.1 Check Tool Availability

Check if Chrome DevTools MCP tools are available (look for tools matching `chrome__new_page` or similar).

If Chrome DevTools MCP is **not** available and `yt-dlp` was **not** found in Step 2, stop and notify the user: "Unable to proceed. Please either install `yt-dlp` (for fast CLI extraction) or configure Chrome DevTools MCP (for browser automation)."

### 3.2 Open Video Page

Use Chrome DevTools MCP `new_page` to open the video URL.

### 3.3 Analyze Page State

Use Chrome DevTools MCP `take_snapshot` to read the page accessibility tree.

### 3.4 Expand Video Description

The "Show transcript" button is usually hidden within the collapsed description area.

1. Search the snapshot for the expand button in the description block below the video title. Depending on the YouTube UI language it is labeled **"...more"** / **"Show more"** (English), **"...もっと見る"** (Japanese), or **"...顯示更多"** / **"更多"** (Traditional Chinese).
2. Use Chrome DevTools MCP `click` to click that button.

### 3.5 Open Transcript Panel

1. Use Chrome DevTools MCP `take_snapshot` to get the updated UI.
2. Search for the transcript button: **"Show transcript"** (English), **"文字起こしを表示"** (Japanese), or **"顯示轉錄稿"** / **"顯示字幕記錄"** (Traditional Chinese).
3. Use Chrome DevTools MCP `click` to click that button.
4. If the button is not found, the video may not have a transcript available — notify the user and stop.
5. The transcript panel has a language selector when several tracks exist. If the shown language is not the preferred one per **Language Preference**, open the selector and switch to it before extracting.

### 3.6 Extract Content via DOM

Directly reading the accessibility tree for long transcript lists is slow and token-heavy. Use Chrome DevTools MCP `evaluate_script` to run this JavaScript instead:

```javascript
() => {
  const segments = document.querySelectorAll("ytd-transcript-segment-renderer");
  if (!segments.length) return "BUFFERING";
  return Array.from(segments)
    .map((seg) => {
      const time = seg.querySelector(".segment-timestamp")?.innerText.trim();
      const text = seg.querySelector(".segment-text")?.innerText.trim();
      return `${time} ${text}`;
    })
    .join("\n");
};
```

If it returns `"BUFFERING"`, wait a few seconds and retry (up to 3 attempts).

### 3.7 Save and Cleanup

1. Save the extracted text as `<Video Title>.txt`.
2. Use Chrome DevTools MCP `close_page` to release resources.

## Output Requirements

- Save the subtitle file to the current working directory.
- Filename format: `<Video Title>.txt`
- File content format: Each line should be `Timestamp Subtitle Text`.
- Report upon completion: file path, subtitle language code (e.g. `en`, `ja`, `zh-TW`), whether the track was manual or auto-generated, and total number of lines.
- If the language code was bare `zh`, include the script warning described in **Language Preference**.
