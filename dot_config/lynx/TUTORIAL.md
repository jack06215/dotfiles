# lynx: a beginner's guide to *this* config

You have never used a text-mode browser before, and this config is not stock
lynx — it turns on vi keys and rebinds nine of them. A generic lynx tutorial
will teach you keys that behave differently here.

This document is the one to read. Work through **Part 1** with a terminal open;
that is the 10 minutes that makes lynx click. Everything after is reference.

> **Before anything else:** `q` quits lynx **immediately**, with no "are you
> sure". So does `Ctrl-D`. There is no unsaved work to lose, but it surprises
> everyone once.

---

## Part 0 — What lynx is, in one minute

lynx fetches a web page and renders it as **text in your terminal**. It throws
away CSS, JavaScript, images and video, keeps the words and links, and lays
them out in a column.

It is fast — no rendering engine, no network round-trips for a hundred assets,
no tracking — and it works over SSH on a box with no display. Reading
documentation in lynx is genuinely pleasant.

### What it is good for

- Documentation, man-page-style references, RFCs, mailing list archives
- Wikipedia, news articles, anything that is mostly prose
- Reading a URL without leaving the terminal or breaking flow
- Scraping page text into a script or pipeline (see [Part 3](#part-3--lynx-from-the-command-line))

### What it is bad at

Be honest with yourself early so you do not fight it: **a site that requires
JavaScript will not work.** Not "will look worse" — will not work. Single-page
apps render as a blank page or a spinner that never resolves. Google Docs,
Figma, most dashboards, most modern web apps: no.

That is not a bug in the config. lynx has no JavaScript engine at all. When you
hit such a site, press `.` to hand the link to your real browser and move on.

### The one concept that matters

lynx has a **current link**, not a mouse pointer or a text cursor. Exactly one
link on the page is "current" — highlighted black-on-yellow — and most keys
either move that highlight or act on it.

Links are also **numbered**, because this config turns that on:

```
   The [1]installation guide covers macOS and [2]Linux.
```

So there are two ways to get anywhere: walk the highlight with `j`/`k`, or jump
straight to a number.

---

## Part 1 — Your first 10 minutes

### Step 1: start it

```sh
lynx
```

You land on DuckDuckGo's lite page, which this config sets as the start page.
It is one of the few search engines that is real server-rendered HTML, so it
actually works here.

If you get `command not found`, install it:

```sh
brew install lynx
```

### Step 2: move between links

Press **`j`** a few times, then **`k`**.

The black-on-yellow highlight jumps from link to link. Arrow keys work too.

> **This is the thing that confuses everyone.** `j` and `k` move between
> **links**, not lines. On a page with no links — a plain text file, a code
> block — they do nothing at all and the page appears frozen. That is expected.
> Use the scrolling keys in Step 3 instead.

### Step 3: scroll the page

| Key | Moves |
|---|---|
| `Space` | Down one page |
| `b` | Up one page |
| `d` | Down half a page |
| `u` | Up half a page |
| `g` | Top of document |
| `G` | Bottom of document |

`d`/`u`/`g`/`G` are vim's, and are rebound by this config to match. In stock
lynx `d` means "download" — here that is `W`.

### Step 4: follow a link, and come back

With a link highlighted, press **`l`** (or `Enter`, or `→`) to follow it.

To go back, press **`h`** (or `←`).

That is the h/j/k/l set, adapted: **`h` back, `l` forward, `j`/`k` between
links.** If you know vim, this is the whole navigation model.

`Ctrl-U` goes *forward* again after going back.

### Step 5: jump to a numbered link

Type a **digit**. A prompt appears at the bottom:

```
Follow link (or page) number:
```

Type the rest of the number and press Enter. On a long page this is far faster
than pressing `j` forty times.

> Because digits are captured for this, searching for a number needs `/` first
> (Step 7).

### Step 6: go to a URL

Press **`:`** — the same key vim uses to start a command.

```
URL to open:
```

Type an address and press Enter. You can omit `https://`.

> Stock lynx uses `g` for this, but this config gives `g` to "top of document"
> (vim's `gg`), so the URL prompt moved to `:`. Press **`U`** to *edit* the
> current URL instead of typing a fresh one — handy for changing one path
> segment.

### Step 7: search within the page

Press **`/`**, type a word, press Enter. Matches highlight black-on-magenta.

- `n` — next match
- `N` — previous match

This searches the *rendered text* of the current page only.

### Step 8: bail out to a real browser

You will hit a page lynx cannot render. Two keys rescue you:

- **`.`** — open the **current link** in your desktop browser
- **`,`** — open the **current page** in your desktop browser

This config wires both to macOS `open` (and `wslview` on WSL2). Stock lynx only
handles `http://` here, so this config adds `https://` — which is to say,
almost everything.

### Step 9: bookmarks

- **`a`** — add current page. It asks whether to bookmark the document (`d`)
  or the current link (`l`).
- **`v`** — view your bookmark list. It is an ordinary page: `j`/`k` and `l`.
- **`r`** — remove a bookmark, from inside the bookmark list.

They live in `~/.local/share/lynx/bookmarks.html` — real HTML you can open in
any browser.

### Step 10: the key you should remember

Press **`K`**.

That is the complete, live key map — every binding this config actually has,
generated by lynx itself rather than written down in a document that can drift.
`j`/`k` to scroll it, `h` to come back.

`?` or `H` opens the full lynx help.

### Step 11: quit

Press **`q`**. It exits immediately.

---

## Part 2 — Full key reference

Non-stock keys are marked ⚡. Press `K` in lynx for the authoritative list.

### Moving around

| Key | Action |
|---|---|
| `j` / `↓` | Next link |
| `k` / `↑` | Previous link |
| `l` / `→` / `Enter` | Follow current link |
| `h` / `←` | Back |
| `Ctrl-U` | Forward (undo back) |
| `Space` / `+` / `Ctrl-F` | Page down |
| `b` / `-` / `Ctrl-B` | Page up |
| ⚡ `d` | Half page down |
| ⚡ `u` | Half page up |
| `Ctrl-N` / `Ctrl-P` | Down / up two lines |
| ⚡ `g` | Top of document |
| ⚡ `G` | Bottom of document |
| `^` / `$` | First / last link on the line |
| `<` / `>` | Previous / next link, by screen position |
| `Ctrl-H` / `Delete` | History list of visited documents |

### Getting somewhere

| Key | Action |
|---|---|
| ⚡ `:` | Open a URL |
| ⚡ `U` | Edit current URL, then go |
| `E` | Edit current *link's* URL, then go |
| digit | Follow link by number |
| `m` | Back to the start page |
| `V` | Links visited this session |
| `L` | List every link on this page |
| `A` | Like `L`, but always shows full URLs |

### Searching

| Key | Action |
|---|---|
| `/` | Search within page |
| `n` / `N` | Next / previous match |
| `s` | Submit a search to a searchable index page |

### Page actions

| Key | Action |
|---|---|
| ⚡ `i` / `=` | Page and link info |
| `\` | Toggle rendered view ↔ HTML source |
| `]` | Send a HEAD request (headers only) |
| `Ctrl-R` | Reload |
| `x` | Reload bypassing cache |
| `z` | Interrupt a slow load |
| `*` | Toggle showing images as links |
| `|` | Toggle line wrapping |
| `{` / `}` | Shift the screen left / right |

### Bookmarks and saving

| Key | Action |
|---|---|
| `a` | Add bookmark |
| `v` | View bookmarks |
| `r` | Remove bookmark (in the bookmark list) |
| ⚡ `W` / `D` | Download current link |
| `p` | Print menu — mainly "save to a local file" |

### Escaping lynx

| Key | Action |
|---|---|
| `,` | Open current **page** in desktop browser |
| `.` | Open current **link** in desktop browser |
| `e` | Edit current document or textarea in nvim |
| `!` | Drop to a shell (`exit` returns to lynx) |

### Settings and inspection

| Key | Action |
|---|---|
| `o` | Options menu |
| `K` | Show the live key map |
| `?` / `H` | Help |
| `Ctrl-K` | Cookie jar — what the session is holding |
| `Ctrl-X` | Cache jar — what is cached |
| `_` | Clear all session authorisation |

### Quitting

| Key | Action |
|---|---|
| ⚡ `q` | Quit **immediately, no prompt** |
| `Ctrl-D` | Same |

### Forms

Forms work, but the interaction is unusual — see
[Filling in a form](#filling-in-a-form).

| Key | Action |
|---|---|
| `Enter` | Activate the field under the cursor |
| `Enter` / `Tab` | Leave the field |
| `Ctrl-U` | Clear the field (while inside it) |
| `Enter` on a submit button | Submit |
| `x` | Submit bypassing the cache |

---

## Part 3 — lynx from the command line

You do not have to open the UI. `-dump` renders a page and prints it, which
makes lynx a decent HTML-to-text converter for scripts and pipelines.

```sh
lynx -dump https://example.com
```

By default that appends a numbered `References` list of every link. Usually you
want one of these instead:

```sh
lynx -dump -nolist https://example.com       # text only, no link list
lynx -listonly -dump https://example.com     # links only, no text
lynx -source https://example.com             # raw HTML, no rendering
lynx -dump -width=100 https://example.com    # wider than the default 80
```

Useful combinations:

```sh
# Render local HTML to text
lynx -dump -nolist ./page.html

# Read HTML from a pipe
curl -s https://example.com | lynx -stdin -dump -nolist

# Every link on a page, one per line
lynx -listonly -nonumbers -dump https://example.com

# Into your pager or editor
lynx -dump -nolist https://example.com | less
lynx -dump -nolist https://example.com | nvim -
```

> `-dump` mode ignores `lynx.lss` entirely — colour styles are a curses-mode
> feature. Do not expect ANSI colour in a dump.

This config sets `CONNECT_TIMEOUT:15` and `READ_TIMEOUT:60` largely for this
use. Stock lynx waits **18000 seconds** — five hours — which is survivable
interactively where `Ctrl-C` works, but would hang a script indefinitely
against a black-holed host.

---

## Part 4 — Recipes

### Filling in a form

This is the part that feels strangest. Because this config enables vi keys,
text fields must be **activated** before they accept typing — otherwise `j` and
`k` would be swallowed as literal characters instead of navigating.

1. `j` / `k` onto the field. The status line shows what kind of field it is.
2. Press **`Enter`** to enter it. Now you are typing text.
3. Type.
4. Press **`Enter`** or **`Tab`** to leave the field.
5. Navigate to the submit button and press `Enter`.

`Ctrl-U` clears a field while you are inside it.

### Reading a page in your editor

Press `e` to open the current document in nvim directly.

To hand a page off from the shell instead:

```sh
lynx -dump -nolist "$URL" | nvim -
```

From inside lynx, `p` opens the print menu — despite the name, its useful
option is **"Save to a local file"**. This config defines no `PRINTER` entries,
so the menu offers saving and mailing only.

### Checking what a redirect does

```sh
lynx -dump -head https://example.com
```

Or press `]` on a link inside lynx to send a HEAD request without fetching the
body.

### Seeing the actual HTML

Press `\` to toggle between the rendered page and its source. Press it again to
go back.

### Auditing your cookies

Press `Ctrl-K`. This config accepts all cookies without prompting so logins
work, but keeps them **in memory only** — nothing is written to disk and
everything is gone when you quit.

---

## Troubleshooting

**Everything is one colour / colours look wrong.**
`lynx.lss` is only loaded via `$LYNX_LSS`, set in `dot_zshenv.tmpl`. Check it:

```sh
echo "$LYNX_CFG" "$LYNX_LSS"
```

Both should point into `~/.config/lynx/`. If they are empty, your shell has not
picked up `.zshenv` — start a new login shell.

**lynx behaves like stock — none of my keys work.**
The config `INCLUDE`s the system `lynx.cfg`, and lynx does **not warn** when an
include target is missing; it silently falls back to defaults. Confirm the
system file is where lynx expects:

```sh
ls -l "$(brew --prefix)/etc/lynx.cfg"
lynx -dump 'LYNXKEYMAP:' | grep '^:'    # should show ':  GOTO'
```

**`Ctrl-S` does nothing.**
lynx binds it to "copy link URL to clipboard", but tmux takes `Ctrl-S` as its
prefix key first, so lynx never sees it. Use `p` to save, or `.` to open the
link in a real browser.

**I cannot select text with the mouse.**
`USE_MOUSE:TRUE` lets lynx handle clicks and scrolling, which means it captures
mouse events inside tmux. Hold **Shift** while dragging to select. If you would
rather have normal selection, delete the `USE_MOUSE` line from `lynx.cfg.tmpl`.

**The page is blank or just a spinner.**
The site needs JavaScript. lynx has no JavaScript engine — this is not fixable
from config. Press `.` and read it in a real browser.

**Accented characters or emoji show as garbage.**
Check your locale is UTF-8:

```sh
locale | grep LANG
```

The config sets `CHARACTER_SET:utf-8` explicitly so this holds even where
`$LANG` is unset, but a terminal in a non-UTF-8 locale will still mangle it.

**A site rejects lynx.**
This config deliberately does not spoof a user agent — claiming to be Chrome
mostly makes sites serve a JavaScript layout lynx cannot render. For the rare
site that blocks text browsers outright, override it per-invocation:

```sh
lynx -useragent='Mozilla/5.0 (compatible)' https://example.com
```

**I want the quit confirmation back.**
Change `KEYMAP:q:ABORT` to `KEYMAP:q:QUIT` in `lynx.cfg.tmpl`, then
`chezmoi apply ~/.config/lynx`.

---

## The 12 keys that matter

Learn these and you can use lynx. Everything else is `K` away.

| Key | |
|---|---|
| `j` `k` | Between links |
| `l` `h` | Follow / back |
| `Space` `b` | Page down / up |
| `g` `G` | Top / bottom |
| `:` | Open a URL |
| `/` | Search this page |
| digit | Jump to a numbered link |
| `.` | Open link in a real browser |
| `a` `v` | Bookmark / view bookmarks |
| `\` | View source |
| `K` | Show every key |
| `q` | Quit (no prompt!) |

---

For what each setting does and why, see [README.md](README.md).
