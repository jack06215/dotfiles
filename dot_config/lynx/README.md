# lynx config

[lynx](https://lynx.invisible-island.net/) is a text-mode web browser — it
fetches a page, throws away the CSS, JavaScript and images, and lays the
remaining text out in your terminal.

New to lynx? Read [TUTORIAL.md](TUTORIAL.md) first. This file explains *what
the config does and why*; the tutorial teaches you to drive it.

## File map

| Source | Installed to | Purpose |
|---|---|---|
| `lynx.cfg.tmpl` | `~/.config/lynx/lynx.cfg` | Behaviour, keys, paths |
| `lynx.lss` | `~/.config/lynx/lynx.lss` | Colour scheme |
| — | `~/.local/share/lynx/` | Bookmarks (created by `dot_local/share/lynx/`) |

Neither file is found by default. `dot_zshenv.tmpl` points lynx at them:

```sh
export LYNX_CFG="$XDG_CONFIG_HOME/lynx/lynx.cfg"
export LYNX_LSS="$XDG_CONFIG_HOME/lynx/lynx.lss"
```

`lynx.cfg.tmpl` is a chezmoi template because the external-browser command
differs per machine (`open` on macOS, `wslview` on WSL2). Everything else in it
is platform-independent.

## The design: overrides, not a fork

Stock `lynx.cfg` is a ~3800-line file that is roughly 99% documentation. The
obvious thing to do — copy it into your dotfiles and uncomment the lines you
want — is what this config used to do, and it does not age well. That copy was
lynx 2.8.9 from July 2018 carrying about 40 real settings, while the installed
binary was 2.9.3; it had already drifted past `zstd` support, `IDNA_MODE`,
`COOKIE_VERSION`, `NO_TABLE_CENTER`, `REDIRECTION_LIMIT`, `UPDATE_TERM_TITLE`
and `LIST_DECODED`.

So this config states **only the differences from stock**. The first line is:

```
INCLUDE:lynx.cfg
```

lynx reads config lines in order and the last assignment wins, so everything
below that line overrides whatever the system file set. The result is ~40
settings instead of 3838 lines, and `brew upgrade lynx` brings new upstream
defaults along for free.

Three things worth knowing about that one line:

- **The bare filename is deliberate.** lynx searches `$LYNX_CFG_PATH`, then the
  directory of its own compiled-in default config. That resolves to
  `/opt/homebrew/etc/lynx.cfg` on macOS and `/etc/lynx/lynx.cfg` on a
  Debian-ish box without hardcoding either prefix.
- **A missing include fails silently.** lynx does not warn; it just falls back
  to built-in defaults. If lynx ever starts behaving like stock, check that the
  system config still exists.
- **Never put `~/.config/lynx` on `$LYNX_CFG_PATH`** or this line will include
  itself.

To see the settings without the commentary:

```sh
grep -vE '^\s*#|^\s*$' ~/.config/lynx/lynx.cfg
```

## Settings

### Entry points

- `STARTFILE` / `DEFAULT_INDEX_FILE` → `https://duckduckgo.com/lite` — DDG's
  lite endpoint is server-rendered HTML with no JavaScript, making it one of
  the few search pages that genuinely works in a text browser.

### Character set

- `CHARACTER_SET:utf-8` — the previous value was `iso-8859-1`. `LOCALE_CHARSET`
  reads the real value from `$LANG`, which hid the problem interactively, but
  anything running without a locale (cron, a script, a `-dump` in a pipeline)
  got Latin-1 and mojibake.
- `LOCALE_CHARSET:TRUE` — keep the `$LANG` override on top.
- `ASSUME_CHARSET:utf-8` — what to assume for a page that declares no charset.
  Stock still guesses Latin-1.
- `PREPEND_CHARSET_TO_SOURCE:FALSE` — `\` (view source) shows the document as
  it came off the wire, without a synthesised charset line at the top.

### Files

- `DEFAULT_BOOKMARK_FILE` → `~/.local/share/lynx/bookmarks.html`. The previous
  value was a *relative* path into a directory this repo does not have, so `a`
  and `v` wrote into whatever directory lynx happened to start in.

**`SSL_CERT_FILE` is deliberately not set.** It used to point at
`/etc/ssl/certs/ca-certificates.crt`, a Debian path that does not exist on
macOS. Homebrew's lynx links `openssl@4`, whose `OPENSSLDIR` is
`/opt/homebrew/etc/openssl@4` with `cert.pem` symlinked to the `ca-certificates`
formula — so leaving it unset finds the right bundle and keeps working across
brew upgrades and prefix changes. Only override it if verification actually
starts failing.

### Cookies

- `SET_COOKIES:TRUE` + `ACCEPT_ALL_COOKIES:TRUE` — take cookies without
  prompting, so logins and paywalled docs work.
- `PERSISTENT_COOKIES:FALSE` — but keep them in memory only. Nothing survives
  the process, and there is no cookie file to manage.
- `FORCE_SSL_COOKIES_SECURE:TRUE` — never send a `Secure` cookie over plain
  HTTP.
- `SYSLOG_REQUESTED_URLS:FALSE` — belt and braces; lynx only logs URLs when
  built with syslog support, but being explicit documents the intent.

> `NO_FROM_HEADER`, `NO_FILE_REFERER` and `REFERER_WITH_QUERY:DROP` are **not**
> set here. All three are already the stock defaults, so the old config was
> only restating them.

### Interface

- `DEFAULT_USER_MODE:ADVANCED` — show the URL of the current link on the status
  line instead of beginner hints.
- `SHOW_CURSOR:TRUE` — park the terminal cursor on the active link. Much easier
  to track than colour alone.
- `SCROLLBAR:TRUE`, `SHOW_KB_RATE:TRUE`
- `NO_PAUSE:TRUE` — skip the "press any key" pauses on informational messages.
- `UPDATE_TERM_TITLE:TRUE` — new in 2.9.x; keeps the terminal/tab title in sync
  with the page. WezTerm supports it.
- `NESTED_TABLES:false` — lynx's nested-table rendering makes layout-table
  sites worse, not better.
- `USE_MOUSE:TRUE` — click links and scroll. See [Gotchas](#gotchas).

### Keyboard

- `VI_KEYS_ALWAYS_ON:TRUE` — `h`/`j`/`k`/`l` navigate.
- `DEFAULT_KEYPAD_MODE:LINKS_AND_FIELDS_ARE_NUMBERED` — every link gets a
  `[42]` label so you can jump straight to it.
- `TEXTFIELDS_NEED_ACTIVATION:TRUE` — **required** with vi keys on. Without it,
  moving onto a text field swallows `j`/`k`/`l` as typed characters instead of
  navigation.
- `NO_DOT_FILES:FALSE` — show dotfiles when browsing local directories.

### External programs

- `DEFAULT_EDITOR:nvim` — used by `e` (edit document or textarea). Note this
  intentionally differs from `$EDITOR`, which `dot_zshenv.tmpl` sets to `vim`
  for quick throwaway edits.
- `EXTERNAL:https:` **and** `EXTERNAL:http:` — bound to `,` and `.`, these hand
  the current page or link to the desktop browser. The old config only had an
  `http` entry, so https — i.e. nearly everything — had no external opener.
- `XLOADIMAGE_COMMAND` — opens an image link in the desktop viewer.

### Network timeouts

- `CONNECT_TIMEOUT:15`, `READ_TIMEOUT:60` — upstream's own comment on the
  18000-second (five hour) defaults is "rather huge". Survivable interactively
  where `Ctrl-C` works, but a `lynx -dump` in a script or an editor job hitting
  a black-holed host would hang until someone noticed.

## Keymap deviations

Everything else is stock. Press `K` inside lynx for the complete live list.

| Key | Does | Stock behaviour |
|---|---|---|
| `d` | Half page **down** | `DOWNLOAD` |
| `u` | Half page **up** | — |
| `U` | Edit current URL and go | `u` was unbound |
| `W` | Download current link | `d` |
| `g` | Top of document | `GOTO` (open a URL) |
| `G` | Bottom of document | `ECGOTO` |
| `:` | Open a URL | unbound |
| `i` | Page info | `INDEX`; info was `=` |
| `q` | Quit **immediately** | Quit with confirmation |

Two of these deserve explanation:

**`d` and `u` were previously broken, not just different.** They were bound
backwards (`d` scrolled up), and the `u` binding was then shadowed by a later
`KEYMAP:u:ECGOTO` line in the same file, which left half-page-down reachable
only via `)`. They now follow vim, and `ECGOTO` moved to `U`.

**`:` exists because `g`/`G` displaced `GOTO`.** Rebinding `g` to "top of
document" costs you stock lynx's "open a URL" prompt, which would otherwise
leave no way to type a new address. `:` is where a vim user reaches for it
anyway. It is written `KEYMAP:0x3A:GOTO` in hex so the colon is not parsed as a
field separator.

The old config also rebound `^U`, space, `-`, `(`, `)`, `o`, `/`, `n`, `e`, `a`
and `v`. Every one of those was already the stock binding, so they are gone.

## Colour scheme

`lynx.lss` maps HTML elements to terminal attributes. Syntax is
`element:attributes:foreground[:background]`.

lynx has **no truecolour** — only the 16 ANSI names (`black`, `red`, `green`,
`brown`, `blue`, `magenta`, `cyan`, `lightgray`, `gray`, `brightred`,
`brightgreen`, `yellow`, `brightblue`, `brightmagenta`, `brightcyan`, `white`)
plus `default`. Note there is no `brightyellow` (it is `yellow`, with `brown`
as the dark one) and no `brightblack` (it is `gray`).

Because every rule names an ANSI *slot* rather than a colour, the actual palette
comes from WezTerm (Catppuccin Mocha) and this file stays correct if that theme
changes. `normal:` and `default:` are left undefined on purpose so lynx inherits
the terminal's own foreground and background rather than painting its own.

This replaces the upstream sample file, which was ~70% demonstration rules for
classes no real page emits (`ul.red`, `li.blue`, `tr.baone`, `strong.debug`,
`font.letter`, `link.green.toc`).

The four rules that matter most are lynx's own chrome rather than page content:

| Rule | Appearance | What it marks |
|---|---|---|
| `alink` | black on yellow | The link under the cursor |
| `whereis` | black on magenta | `/` search matches |
| `status` | black on blue | Bottom status/prompt line |
| `alert` | white on red | Error messages |

> lynx's lss parser is **silent** about unknown element names and invalid
> colours — it ignores them. A rule that does nothing looks exactly like a rule
> that works, so check changes visually.

## Gotchas

- **`q` quits with no confirmation**, and so does `Ctrl-D`. This is inherited
  from the config this was adapted from. Change `KEYMAP:q:ABORT` to
  `KEYMAP:q:QUIT` if you want the prompt back.
- **`USE_MOUSE:TRUE` captures mouse events inside tmux**, so selecting terminal
  text needs Shift held down. Drop the line if that trade stops being worth it.
- **`Ctrl-S` is unreachable inside tmux.** lynx binds it to `TO_CLIPBOARD`, but
  tmux takes it as the prefix key first. Use `p` → save-to-file, or `.` to open
  the link in a real browser.
- **Digits open a "follow link number" prompt**, because links are numbered. To
  search for a number, press `/` first.

## Changing it

```sh
chezmoi edit ~/.config/lynx/lynx.cfg   # edits the .tmpl in this repo
chezmoi diff ~/.config/lynx            # preview
chezmoi apply ~/.config/lynx           # install
```

Verify a change actually took effect — remember lynx ignores what it cannot
parse:

```sh
lynx -show_cfg | grep -i cookie      # effective settings
lynx -dump 'LYNXKEYMAP:'             # the live keymap, all of it
```

`-show_cfg` echoes every line it read, *including* the ones the include set, so
a setting may appear twice with the later one winning. `LYNXKEYMAP:` resolves
the conflicts for you and is the better check for key bindings.
