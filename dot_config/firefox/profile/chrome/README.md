# Firefox userChrome.css

A "one line" Firefox: the tabs and the URL bar share a single row at the
**bottom** of the window, on a dark theme, with an animated RGB ring around the
window edge.

Everything below was checked against Firefox 156 on macOS unless marked
otherwise.

## Installing and applying changes

- chezmoi writes this directory to `~/.config/firefox/profile/chrome/`.
- **macOS:** `.chezmoiscripts/run_onchange_after_link-firefox-profile.sh.tmpl`
  symlinks `userChrome.css` (and `../user.js`) into the real profile,
  `data.firefox.profileDir`, which is
  `~/Library/Application Support/Firefox/Profiles/vfop1w54.default` via
  `.chezmoidata/lookups.toml`. Because it's a symlink, `chezmoi apply` is
  enough to update it.
- **Windows:** the `.ps1` counterpart copies both files instead, and re-runs
  whenever either file's hash changes.
- **Linux:** `lookups.toml` has a profiles path, but no script links anything,
  so this file isn't installed there.
- `user.js` sets `toolkit.legacyUserProfileCustomizations.stylesheets` to
  `true`. Without it Firefox ignores `userChrome.css`.
- Firefox reads `userChrome.css` **only at startup**. Restart it after every
  change.
- This README is deployed next to the CSS but isn't linked into the profile.

## Layout

| Part | What the CSS does |
|---|---|
| Title bar | Hides the window buttons (`.titlebar-buttonbox`) and spacers. |
| Row position | `#navigator-toolbox { order: 1 }` puts the toolbars after `#browser` in `<body>`'s flex column, so they sit under the page. |
| Nav bar | Takes the left 20% (`margin-right: 80vw`) and is pulled up by `--tabstrip-min-height` so it shares the tab strip's row. |
| Tabs | Take the rest (`#TabsToolbar { margin-left: 20vw }`). Icon and label are centred; close buttons are hidden. |
| Row height | 20px rows with 2px above and below, which Firefox turns into a 24px tab strip. The toolbox is 28px including the ring's lift (see below). |
| Buttons left | Back, URL bar, downloads, extensions. |
| Buttons hidden | Forward, reload/stop, home, library, account, flexible spaces, page actions, the tracking-protection shield, the ☰ app menu. |
| Status panel | The link-preview text floats bottom-left (1vw/1vh in), 10px, with no background. |
| Private windows | Firefox's "Private browsing" label is hidden. The selected tab's title gets an accent-coloured `P` prefix instead (`--private-icon-char`). *Not verified.* |
| Extensions panel | 12px icons, with the header, separators, per-item messages and "Manage extensions" hidden. *Not verified: the panel only exists once opened.* |

Firefox's own sizing variables (`--tab-min-height`, `--tab-margin-block`,
`--urlbar-height`, `--toolbarbutton-padding-*`) are overridden on `:root`.
Firefox sets them on `:root` too, hence `!important`.

## URL bar

- **At rest:** at most 20vw wide, transparent and borderless.
- **On focus:** the nav bar widens to the whole window and the URL bar grows
  into it.
  - It jumps to full width and plays a 0.25s `clip-path` reveal, instead of
    transitioning its width. Firefox decides whether the results wrap (URL bar
    under 650px) once, as they open, so a growing width could leave them
    wrapped.
  - Items to the right of the URL bar slide along with the reveal's edge.
  - Shrinking on blur is a normal transition.
- **Results open upwards:** Firefox pins the open URL bar's top to the
  toolbar, so at the bottom of the window its results would drop off screen.
  It's anchored to the bottom instead, with `flex-direction: column-reverse`.
- **Search mode switcher:** Firefox parks the unused switcher at
  `top: -999px`. The URL bar (`contain: layout`) is its containing block, so in
  a tall window that lands on screen. It's moved to `-200vh`.

## Fullscreen

- Firefox hides the toolbox in fullscreen by pulling it up by its own height,
  which would leave a bottom toolbar over the page. Instead it's collapsed
  (`visibility: collapse`).
- The reveal hotspot (`#fullscr-toggler`) is moved to the bottom edge.
- macOS's shift to clear the menu bar is cancelled (`translate: none`,
  `--toolbar-shift-translate: none`).
- The RGB ring is hidden around fullscreen video (`inDOMFullscreen`), and has
  square corners in fullscreen windows.

## RGB window border

CSS can't reach the native window frame, so the ring is drawn just inside it,
over the edge of the page and the bar. Clicks go through
(`pointer-events: none`).

- `body::before` is the crisp ring (`--rgb-border-width`, 2px).
- `body::after` is the glow: 50% at the edge, fading out `--rgb-glow` (8px)
  into the page.
- Stacking order is page (Firefox's `z-index: 2`) < glow (10) < toolbox (11) <
  ring (12), so the glow tints only the page and the ring draws over the bar.
- `--rgb-bar-lift` pads the bottom of the toolbox so the ring doesn't cover the
  buttons, and the open URL bar is lifted by the same amount.

### Motion

| Window state | What it does |
|---|---|
| Focused | Drifts slowly: one turn a minute, redrawing 6 times a second. |
| Hovering the bar, or URL bar focused | Adds a fast spin: an extra turn every 6s, redrawing 20 times a second. |
| In the background | Frozen, with no redraws. |
| Showing fullscreen video | Hidden. |

The two spins are separate animated angles, `--rgb-idle-angle` and
`--rgb-angle`, added together into `--rgb-turn`. The fast one pauses and
resumes where it left off. Changing a single animation's duration instead
would make the ring jump.

### Corner radius

The ring follows the window's rounded corners, or they'd cut it off:

| Platform | `--rgb-window-radius` |
|---|---|
| macOS | 10px |
| macOS Tahoe | 16px |
| Windows 11, not maximized | 8px |
| Fullscreen, Linux, maximized Windows | 0px |

### Knobs

All of these are in the `:root` block.

| Variable | Default | Effect |
|---|---|---|
| `--rgb-colors` | 7 colours | Gradient stops. Repeat the first colour last so the loop is seamless. |
| `--rgb-idle-speed` | `60s` | One drift turn. |
| `--rgb-idle-steps` | `360` | Drift redraws per turn. |
| `--rgb-speed` | `6s` | One fast turn, added while you use the bar. |
| `--rgb-steps` | `120` | Fast redraws per turn. |
| `--rgb-border-width` | `2px` | Ring thickness. |
| `--rgb-glow` | `8px` | Glow depth. `0px` removes the glow and its cost. |
| `--rgb-bar-lift` | border + 2px | Gap under the toolbar buttons. |

**Redraws per second = steps ÷ speed**, which is what costs CPU. The size of
each jump is 360° ÷ steps. A longer speed alone only makes each jump smaller;
it doesn't reduce redraws.

### Why it's built the way it is

The first version made the CPU fans audible. Profiling it in real Firefox
chrome found these rules, and the current CSS follows each one:

1. **An animated custom property can't run on the compositor.** Firefox only
   offloads `transform`, `opacity` and a few others, so each change of
   `--rgb-*-angle` restyles and repaints on the main thread. That's the
   reason for `steps()`: it repaints only when the angle actually changes.
2. **CSS masks are redrawn on the CPU on every repaint, over their whole
   area,** whenever the masked element's own painting changes. A full-window
   mask cost 30–55 ms per repaint. So the gradients *and* the masks are cut
   into bands along the edges:
   - Each band's `conic-gradient` is centred on the window with
     `50vw`/`50vh` offsets, so the bands line up as one gradient.
   - The ring's top and bottom bands are `--rgb-window-radius` tall, which is
     enough to hold the rounded corners.
3. **Only `mask-composite: add`.** `exclude` processes the whole window even
   when the layers are small. `subtract` and `intersect` weren't measured, but
   they're likely the same, since they also erase outside the layer. The
   obvious ring mask, "box minus content box" (`exclude`), cost 18 ms against
   2 ms, so the ring's mask is built by adding pieces:
   - one strip per edge;
   - one `radial-gradient` per corner that is transparent inside the inner
     curve, with `border-radius` rounding the outer edge.

   The corner gradients fade over ±0.25px (one Retina pixel), because a hard
   stop comes out jagged.
4. **No `opacity` on the glow.** Opacity on a multi-layer element renders it
   offscreen at full window size, so the 50% lives in the mask colours
   instead. The four glow bands overlap at the corners, where they come out a
   little brighter than a single mask would (at most 29/255 at square
   corners, which is invisible under rounded ones).

After the rewrite, frozen at the same angle, the ring and glow render the same
as the original version: out of about 5.7M pixels, 45 differ by more than 20%,
all on the inner curves.

Measured in headless Firefox at 1512×945 @2×. Headless mode renders in
software, so GPU work shows up as CPU here:

| | Original | Current |
|---|---|---|
| Focused, not using the bar | 145% CPU, spinning at 13 fps | 29% at 6 redraws/s |
| Using the bar | 145% | 92% at 26 redraws/s |
| Mask redraw per repaint | 55 ms | 3 ms |
| Background window | 0% | 0% |

On a real GPU, only about 7 ms of each redraw runs on the CPU. That puts the
focused drift at roughly 4% of one core. This is an estimate, not a
measurement on real hardware.

## Editing gotchas

- **`userChrome.css` is a user-origin stylesheet,** so Firefox's own chrome
  CSS beats it unless the rule is `!important`. When a rule seems to do
  nothing, that's the first thing to check. The selected tab's text colour
  silently stayed white until its rule got `!important`.
- **Old snippets can be dead code.** Firefox has removed `display: -moz-box`,
  so any declaration using it is dropped. A later `!important` rule for the
  same property also silently overrides an earlier one: `#nav-bar` once had a
  `background: transparent` that never applied.
- **Don't add the XUL default `@namespace`.** The chrome's root element is
  HTML now. With that namespace, `:root` stops matching and every variable in
  this file goes dead. That has happened here before.
- **Test in the real browser chrome, not in a web page mockup.** Things like
  the namespace, the cascade origin and `moz-urlbar` being HTML don't
  reproduce in a page.

## Testing changes

- **Live, in your own browser:** use the Browser Toolbox
  (<kbd>⌘⌥⇧I</kbd>). It needs "Enable browser chrome and add-on debugging
  toolboxes" and "Enable remote debugging" turned on in DevTools settings.
  - To check the CPU cost, watch Firefox in Activity Monitor while its window
    is focused. Focusing Activity Monitor itself freezes the ring.
- **Scripted, in a throwaway profile:**
  1. Render `user.js` with `chezmoi execute-template < ../user.js.tmpl`, add
     `user_pref("marionette.port", 2829);`, and copy this CSS into
     `<tmp>/chrome/`.
  2. Run
     `firefox --headless --no-remote --marionette -remote-allow-system-access --profile <tmp>`.
  3. Speak Marionette over TCP (`len:json` frames), send
     `Marionette:SetContext {value: "chrome"}`, then use
     `WebDriver:ExecuteScript` and `WebDriver:TakeScreenshot`.
  4. For A/B tests, `windowUtils.loadSheet(uri, AUTHOR_SHEET)` with
     `!important` overrides this file.
  5. To measure CPU, use `ChromeUtils.requestProcInfo()` for per-thread CPU
     time. `WRWorker` threads are the CPU mask redraws. Count paints with
     `MozAfterPaint` on the chrome window.
- **Headless quirks:**
  - `--window-size` is ignored; use `window.resizeTo`.
  - Native mouse events never arrive; use
    `InspectorUtils.addPseudoClassLock(el, ":hover")`.
  - Focus moves from the URL bar back to the page about a second after
    startup.
