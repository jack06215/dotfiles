# tmux: a beginner's guide to *this* config

You have never used tmux before, and this config is not stock tmux — it rebinds
the prefix key and puts most day-to-day actions on **Alt** instead. Reading a
generic tmux tutorial online will teach you keys that do not work here.

This document is the one to read. Work through **Part 1** with a terminal open;
that is the 15 minutes that makes tmux click. Everything after is reference.

---

## Part 0 — What tmux is, in one minute

A terminal window gives you one shell. When you close it, everything running in
it dies. tmux fixes both problems:

1. **Splitting.** One terminal window can hold many shells, side by side, in
   tabs, laid out however you like.
2. **Persistence.** Your shells live inside a background *server*, not inside
   the terminal window. Close the window, your laptop lid, or your SSH
   connection — the programs keep running. Reconnect and everything is exactly
   where you left it.

That second point is the real reason people use tmux. A long build, a dev
server, a training run: start it in tmux, walk away, come back.

### The three nouns

Learn these words; every key below is named after one of them.

```
server ── the background process holding everything (you never see it)
 │
 ├── session ── a workspace. Usually "one project". Named, e.g. "dotfiles".
 │    │
 │    ├── window ── a tab inside that session. Numbered 1, 2, 3…
 │    │    │
 │    │    ├── pane ── a rectangle running one shell. Numbered 1, 2, 3…
 │    │    └── pane
 │    └── window
 └── session
```

Rough analogy: **session = project**, **window = tab**, **pane = split**.

You *detach* from a session (leave it running) and *attach* to it again later.

---

## Part 1 — Your first 15 minutes

### Step 1: install the plugin manager (do this first)

This config expects a plugin manager called **TPM**, and it is **not installed
on your machine right now**. Without it, tmux works fine but prints an error
line on startup and five plugins silently do nothing.

Run this once, in a normal terminal (not inside tmux):

```sh
git clone https://github.com/tmux-plugins/tpm ~/.local/share/tmux/plugins/tpm
```

> The path matters. Stock TPM installs to `~/.tmux/plugins/tpm`, but line 160 of
> `tmux.conf` points it at `~/.local/share/tmux/plugins`. Use the path above.

You will install the actual plugins in Step 8, once you know how to press a
prefix key.

### Step 2: start a session

```sh
tmux new -s learn
```

`new` creates a session, `-s learn` names it `learn`. Your prompt comes back
looking normal, but there is now a **status bar across the top** of the window.
You are inside tmux.

### Step 3: the prefix key

tmux needs a way to tell "this keystroke is for tmux" apart from "this keystroke
is for the program in the pane". It uses a **prefix**: press it, release it, then
press the real key.

> **In this config the prefix is `Ctrl-s`.**
> (Stock tmux uses `Ctrl-b`. It has been unbound here — it will not work.)

So when this document writes **`prefix + r`**, you press `Ctrl-s`, let go, then
press `r`. It is two separate keystrokes, not a chord.

Try it now: **`prefix + ?`** opens the full list of every key binding. Scroll with
arrows or `j`/`k`, search with `/`, quit with `q`. You will not understand most
of it yet — the point is that this list always exists when you forget something.

<details>
<summary>Why <code>Ctrl-s</code>, and the one trap it has</summary>

`Ctrl-s` is easier to reach than `Ctrl-b` and rarely used by shells. The trap:
in a classic terminal `Ctrl-s` means "freeze output" (XOFF) and `Ctrl-q`
unfreezes it. If a stray `Ctrl-s` ever reaches your shell, the terminal appears
to hang. Your zsh config already disables this (`stty -ixon` in
`dot_config/zsh/src/pet.zsh`), so it should never bite you here — but if you SSH
to a machine without that setting and the terminal freezes, press `Ctrl-q`.

</details>

### Step 4: the Alt shortcut layer (this config's big idea)

Most tmux setups make you press the prefix for everything. This one puts the
common actions on **Alt** with *no prefix at all* — one chord, instant.

**On macOS, `Alt` is the `Option` key.** Your WezTerm config already makes Option
send a real Alt (`send_composed_key_when_left_alt_is_pressed = false`), so this
works out of the box. If Alt keys type `∆` and `¬` instead of doing things, jump
to [Troubleshooting](#troubleshooting).

> **Either Option key works.** GlazeWM, the tiling window manager on this
> machine, used to bind plain `alt` and swallowed most of the keys below before
> tmux could see them. Its config now reserves plain Alt + letter/digit for
> tmux — everything GlazeWM owns carries `ctrl` or `shift` too, or uses an arrow
> key. See [Troubleshooting](#troubleshooting) if an Alt key ever goes dead.

Throughout this doc, **`M-`** means Alt/Option. `M-v` = hold Option, press `v`.

Try these three right now:

| Press | What happens |
|---|---|
| `M-v` | Splits the pane — new shell **below** |
| `M-b` | Splits the pane — new shell **to the right** |
| `M-x` | Closes the current pane (asks `y/n` first) |

You now have panes. Note that new panes open in the **same directory** as the
pane you split from — `cd` once, split freely.

### Step 5: move between panes

`M-h` `M-j` `M-k` `M-l` — left, down, up, right.

These are vim's direction keys: `h` is left because it is the leftmost, `l` is
right, `j` points down, `k` points up. Same layout used by nvim, `less`, and
copy mode. Learning them once pays off everywhere.

Make a 3-pane layout (`M-v`, then `M-b`) and hop around until it is automatic.

**`M-z` zooms** the current pane to fill the whole window; `M-z` again restores
the layout. Use it constantly — for reading a long error, running a test suite,
anything that needs room. The other panes are not gone, just hidden.

To **resize** a pane you need the prefix, because these are rarer:
`prefix + <` and `prefix + >` (narrower/wider), `prefix + =` and `prefix + +`
(shorter/taller). These *repeat*: after one prefix you can tap `>>>>` to keep
growing, as long as you do not pause for more than half a second.

### Step 6: windows (tabs)

Panes are for things you watch at once. Windows are for switching context.

| Press | What happens |
|---|---|
| `M-c` | New window (again, inherits the current directory) |
| `M-1` … `M-9` | Jump straight to window 1–9 |
| `M-,` / `M-;` | Previous / next window |
| `prefix + X` | Kill this window (capital X) |

Create a couple of windows and watch the status bar at the top left — it lists
them, with the current one highlighted in red.

Windows are numbered from **1**, not 0, so `M-1` is the leftmost. (`M-0` is
wired to window 10, which is where the tenth one naturally lands.)

### Step 7: detach and re-attach — the payoff

In one pane, start something long-running:

```sh
ping -i 2 example.com
```

Now press **`M-d`** (detach). tmux vanishes and you are back at your plain
terminal — but nothing was killed. Confirm it:

```sh
tmux ls
```

```
learn: 3 windows (created ...) 
```

Come back:

```sh
tmux a -t learn      # "attach to session named learn"
```

The ping has been running the whole time. **This is tmux.** You can close the
terminal window entirely, even reboot the terminal app, and `tmux a` brings the
session back.

Command-line essentials for session juggling:

```sh
tmux new -s work     # create a session called "work"
tmux ls              # list sessions
tmux a               # attach to the most recent session
tmux a -t work       # attach to a specific one
tmux kill-session -t work
tmux kill-server     # nuke everything (rarely what you want)
```

### Step 8: install the plugins

Back inside tmux, press **`prefix + I`** — that is `Ctrl-s`, then capital `I`
(Shift+i).

The status bar shows "Installing plugins..." for a few seconds, then
"Done". The five plugins listed at the bottom of `tmux.conf` are now live; see
[Part 4 — Plugins](#part-4--plugins) for what they do.

If nothing happens at all, TPM did not get cloned — redo Step 1.

### Step 9: reload after editing the config

**`prefix + r`** re-reads `tmux.conf` and flashes "Reloaded!" in the status bar.
You will use this every time you change a keybinding. No restart needed.

> ⚠️ These dotfiles are managed by **chezmoi**. Do not edit
> `~/.config/tmux/tmux.conf` directly — the next `chezmoi apply` will overwrite
> it. Edit the source instead:
>
> ```sh
> chezmoi edit ~/.config/tmux/tmux.conf   # opens the repo copy
> chezmoi apply                           # writes it to ~/.config
> ```
>
> then `prefix + r` inside tmux. The real file lives at
> `dot_config/tmux/tmux.conf` in your dotfiles repo.

That is the whole core. Everything below is detail you can pick up as you need
it.

---

## Part 2 — Full key reference

`prefix` = `Ctrl-s`. `M-` = Alt/Option. Keys with **no prefix** are single
chords; press them any time.

### Panes

| Key | Action |
|---|---|
| `M-h` `M-j` `M-k` `M-l` | Move focus left / down / up / right |
| `M-v` | Split → new pane **below**, same directory |
| `M-b` | Split → new pane **right**, same directory |
| `M-y` | Split right, then fix width to 100 columns (a reading/reference pane) |
| `M-t` | Split below, then fix height to 16 rows (a "terminal drawer") |
| `M-z` | Zoom / unzoom this pane |
| `M-x` | Kill this pane (confirms first) |
| `prefix + \|` | Split right — **does not** inherit the directory |
| `prefix + -` | Split below — **does not** inherit the directory |
| `prefix + <` `>` | Narrower / wider (repeatable) |
| `prefix + =` `+` | Shorter / taller (repeatable) |

The `M-` splits carry your current directory over; the `prefix + |` / `prefix + -`
pair deliberately do not, for when you want to start fresh in `$HOME`.

`M-y` and `M-t` exist because "a fixed-width side pane" and "a short pane at the
bottom" are the two layouts you end up building by hand over and over.

### Windows

| Key | Action |
|---|---|
| `M-c` | New window in the current directory |
| `M-1` … `M-9` | Go to window 1–9 |
| `M-0` | Go to window 10 |
| `M-,` | Previous window |
| `M-;` | Next window |
| `prefix + X` | Kill this window |
| `prefix + ,` | Rename this window |

Renaming is worth the habit once you have four windows — the status bar becomes
`1:edit 2:server 3:logs` instead of three identical `zsh`es.

### Sessions

| Key | Action |
|---|---|
| `M-d` | Detach (leave everything running) |
| `M-s` | Session picker — fuzzy tree, newest first |
| `M-i` | Toggle to the previous session and back |
| `prefix + $` | Rename this session |

`M-s` opens a searchable list; type to filter, `Enter` to switch, `q` to cancel.
It hides the session you are already in, plus the two popup sessions below, so
the list only ever shows somewhere useful to go.

`M-i` is the session equivalent of `cd -` — flip between two projects with one
key.

### Popup scratch sessions

| Key | Action |
|---|---|
| `M-w` | Floating **scratch** session (80% × 80%) |
| `M-r` | Floating **monitor** session (90% × 95%) |

These open a session in a floating window on top of your layout. To dismiss the
popup press **`M-d`** (detach) or type `exit` — pressing `M-w` again from inside
would just stack another popup, since your keys are now going to the popup's
session. They are *persistent*: whatever you leave running in `scratch` is still
there next time you press `M-w`.

Use `M-w` for the throwaway command you do not want to disturb your layout for
(`git status`, a quick `curl`, some arithmetic). Use `M-r` for long-lived
monitoring — `btop`, `lazygit`, log tails — since it is nearly full-screen.

### Copy mode (scrollback, search, copy)

Your shell's own scrollback is not how you scroll in tmux. tmux keeps 50,000
lines of history per pane, and you read it in **copy mode**.

| Key | Action |
|---|---|
| `M-m` | Enter copy mode |
| mouse wheel up | Also enters copy mode |
| `prefix + [` | Also enters copy mode (stock tmux key, still works) |

Once inside, the keys are vim's:

| Key | Action |
|---|---|
| `h` `j` `k` `l` | Move by character / line |
| `w` `b` | Word forward / back |
| `0` `$` | Start / end of line |
| `g` `G` | Top / bottom of history |
| `Ctrl-u` `Ctrl-d` | Half page up / down |
| `/` then text | Search **down**, `Enter` to run |
| `?` then text | Search **up** |
| `n` `N` | Next / previous match |
| `v` | Start selecting |
| `V` | Select whole lines |
| `Ctrl-v` | Rectangle (column) selection |
| `y` or `Enter` | **Copy** and leave copy mode |
| `Escape` or `q` | Leave without copying |

Copying puts the text on your **real system clipboard** — `Cmd-v` works in any
Mac app afterwards. It also works over SSH (the config uses OSC 52, which sends
the clipboard through the terminal connection itself).

To paste *into* a tmux pane:

| Key | Action |
|---|---|
| `M-p` | Paste the system clipboard |
| `prefix + ]` | Paste tmux's own last-copied buffer |

`Cmd-v` also works normally — `M-p` exists so your hands can stay on the
keyboard, and so it behaves identically on Linux.

### Mouse

The mouse is enabled. You can click a pane to focus it, click a window name in
the status bar to switch, drag a border to resize, and drag across text to
select — releasing the drag copies to the clipboard automatically.

> **Gotcha:** with mouse mode on, tmux intercepts drags, so your terminal's own
> text selection (for copying multiple panes at once, or a URL that spans a
> pane border) is shadowed. Hold **`Shift`** while dragging to bypass tmux and
> select the raw terminal window instead.

### Still-available stock tmux keys

The config only *adds* to tmux's defaults, so anything you read in generic
documentation still works — just with `Ctrl-s` as the prefix instead of
`Ctrl-b`:

| Key | Action |
|---|---|
| `prefix + ?` | List every binding (searchable) |
| `prefix + :` | tmux command prompt — run any command by name |
| `prefix + d` | Detach |
| `prefix + c` | New window |
| `prefix + w` | Window/session tree picker |
| `prefix + z` | Zoom pane |
| `prefix + Space` | Cycle through preset pane layouts |
| `prefix + !` | Break the current pane out into its own window |
| `prefix + x` | Kill pane (lowercase — same idea as `M-x`) |
| `prefix + Ctrl-s` | Send a literal `Ctrl-s` through (see below) |

`prefix + Ctrl-s` matters when you run tmux **inside** tmux — usually when you
SSH into a machine that also uses tmux. Press it and the keystroke goes to the
*inner* tmux, so `prefix + Ctrl-s` then `c` makes a window on the remote one.

---

## Part 3 — Reading the status bar

The bar sits at the **top** of the window.

```
learn 2 1     │  1:zsh  2:nvim* 3:ping     │  nvim TUTORIAL.md   [2026-08-21(Fri) 23:40]
└───────────┘                              └────────────────┘
   left                                          right
```

**Left side** — where you are, in the three nouns from Part 0:

- green — **session name** (`learn`)
- yellow — **window number** (`2`)
- cyan — **pane number** (`1`)

**Middle** — the window list. The current window is white-on-red. A window
where output has appeared while you were looking elsewhere gets flagged
(`monitor-activity` is on) — useful for spotting "the build finished" without
switching. There is no popup interrupting you; the flag is the whole
notification.

**Right side** — the command actually running in the current pane (so you can
tell a busy pane from an idle shell at a glance), then the date and time.

The bar refreshes every 15 seconds, so the clock is approximate and the command
name can lag a moment. That is deliberate — refreshing faster costs a subprocess
every tick.

---

## Part 4 — Plugins

Installed via TPM (`prefix + I` to install, `prefix + U` to update, all of them
listed at the bottom of `tmux.conf`).

| Plugin | Key | What it does |
|---|---|---|
| **extrakto** | `prefix + Tab` | Fuzzy-picks any word, path, URL, or git hash *visible in the pane* and copies or inserts it. Instead of mousing over a long path, hit `Tab` and type a few letters of it. |
| **tmux-copy-toolkit** | `prefix + S` | "Easycopy" — labels every copyable token on screen; press the label to copy it. |
| | `prefix + Q` | Quickcopy — copy by pattern match. |
| | `prefix + P` | Quickopen — open a path or URL from the screen. |
| | `prefix + W` | Copy a whole line by label. |
| **tmux-fingers** | `prefix + F` | Same family: overlays letter hints on paths/hashes/IPs; press a hint to copy. |
| **tmux-suspend** | `M-q` | Freezes the *outer* tmux so every key passes to a nested inner tmux (over SSH). The status bar greys out to show it is suspended; `M-q` again resumes. |
| **tmux-claude-session-manager** | — | Manages Claude Code sessions across panes. Check its README (or `prefix + ?` after installing) for its keys. |

There is a lot of overlap between extrakto, copy-toolkit, and fingers. Do not
try to learn all three. Start with **`prefix + Tab`** (extrakto) — it covers the
common case — and ignore the others until you hit something it does not do.

---

## Part 5 — Recipes

**Set up a project workspace**

```sh
cd ~/workspace/jack06215/dotfiles
tmux new -s dotfiles
```

Then `M-b` for a side pane, `M-t` for a short one at the bottom, `M-c` for a
second window. Detach with `M-d` when you stop for the day; `tmux a -t dotfiles`
tomorrow puts it all back.

**Run something long over SSH**

```sh
ssh server
tmux new -s build
./long-build.sh
```

`M-d`, then close your laptop. Later: `ssh server`, `tmux a -t build` — the
build carried on without you. This works even if the SSH connection *drops*,
which is the real reason to do it.

**Read a huge error you just triggered**

`M-z` to zoom, `M-m` to enter copy mode, `?` to search backwards for `error`,
`n`/`N` between matches, `v` and `y` to copy the relevant part, `q` to exit,
`M-z` to unzoom.

**Compare two files side by side**

`M-y` gives you a fixed 100-column pane on the right — wide enough for code,
narrow enough to leave room. Open one file in each.

**Get a path off the screen and into your command**

`prefix + Tab`, type a few characters of the path, `Enter`. Much faster than
selecting it with the mouse.

---

## Troubleshooting

**Alt keys type `∆ ˚ ¬ √` instead of switching panes.**
Your terminal is treating Option as a character-composition key. In WezTerm this
is already handled by your dotfiles. In other terminals:
- **Terminal.app** — Settings → Profiles → Keyboard → check *Use Option as Meta
  key*.
- **iTerm2** — Settings → Profiles → Keys → set Left Option to *Esc+*.

**Alt keys do nothing at all.**
Something above tmux is eating them. A global hotkey app grabs the key at the OS
level, so it never reaches the terminal — which reads as "the key does nothing"
rather than as an obvious clash.

On this machine that was **GlazeWM**, whose bindings all used to sit on plain
`alt`. It collided with most of this config: `M-h/j/k/l`, `M-v`, `M-t`, `M-r`,
`M-m`, `M-s`, `M-d` and `M-1`–`M-9`.

The fix is already applied. GlazeWM's config now reserves **plain Alt + a bare
letter or digit for tmux**; everything the window manager owns carries `ctrl` or
`shift` alongside `alt`, or uses an arrow key:

| Now belongs to | Keys |
|---|---|
| **tmux** | `Alt` + letter/digit — `M-v`, `M-h`, `M-1` … |
| **GlazeWM** | `Alt+Ctrl+…`, `Alt+Shift+…`, `Alt`+arrows, `Alt+Enter` |

(In GlazeWM's config file that Control modifier must be spelled `control`, not
`ctrl` — an unrecognised name is dropped silently, with no error anywhere.)

The reasoning is written up in the header comment of
`~/.glzr/glazewm/config.yaml` — read it before adding a GlazeWM binding, and
check `tmux list-keys -T root` first so you don't re-create the clash.

> Note: splitting the two Option keys (GlazeWM on `ralt`, tmux on `lalt`) does
> **not** work. GlazeWM's docs list `lalt`/`ralt` as valid modifiers and the
> config parses cleanly, but its macOS build ignores the distinction and fires
> on both keys. Don't retry that.

To confirm whether a key is being swallowed before the terminal sees it, open a
shell **outside** tmux and run `cat -v`, then press the key:

| Output | Meaning |
|---|---|
| `^[v` | The key arrives fine — the problem is inside tmux |
| `√` | Your terminal is composing glyphs instead of sending Meta (see above) |
| nothing at all | A global hotkey app is eating it |

If it is the third case, the culprit is whatever else is running: check GlazeWM's
config first, then any other hotkey app (`AltTab`, AeroSpace, Karabiner,
Hammerspoon). Whichever app grabs the key wins — rebind it there, not in tmux.

**tmux prints an error about `tpm/tpm` when it starts.**
TPM is not installed. See Part 1, Step 1.

**`prefix + I` does nothing.**
Same cause. Also check you pressed *capital* `I`.

**The terminal seems frozen after I pressed something.**
Press `Ctrl-q`. (See the `Ctrl-s` note in Part 1, Step 3.)

**Colors look wrong, or nvim looks washed out.**
You are probably running tmux from a terminal that does not advertise true
color. The config sets `default-terminal "tmux-256color"` and forces `Tc`; if
you launched from a bare `TERM=xterm`, quit tmux fully (`tmux kill-server`) and
restart it from WezTerm.

**I edited `~/.config/tmux/tmux.conf` and my change disappeared.**
chezmoi overwrote it. Edit via `chezmoi edit ~/.config/tmux/tmux.conf`, then
`chezmoi apply`. See Part 1, Step 9.

**I want to see what a key is actually bound to.**
`prefix + ?`, then `/` to search. Or from a shell: `tmux list-keys | grep M-h`.

---

## A note on what is *not* bound

The config deliberately leaves `Ctrl-j` and `Ctrl-k` alone. Many tmux setups
bind them prefix-lessly for pane movement, which quietly breaks `Ctrl-j`/`Ctrl-k`
navigation in nvim, `^J` accept-line in zsh, and `Ctrl-j` newline in Claude Code
— the keystroke is swallowed by tmux before the program ever sees it. That is
why pane movement here lives on `M-hjkl` instead.

Similarly, `Ctrl-h/j/k/l` inside a pane goes straight through to whatever is
running. In nvim that moves between *nvim's* splits. So the rule is simple:

> **`Ctrl` + `hjkl` moves inside nvim. `Alt` + `hjkl` moves between tmux panes.**

Two layers, no overlap, nothing to guess.

---

## The 12 keys that matter

If you only memorise one block, memorise this one. Everything else you can look
up with `prefix + ?`.

```
M-v / M-b     split below / right
M-h j k l     move between panes
M-z           zoom pane
M-x           kill pane
M-c           new window
M-1 … M-9     jump to window
M-d           detach
M-s           switch session
M-m           scroll / copy mode  (v select, y copy, q quit)
M-w           scratch popup
prefix + r    reload config
prefix + ?    every keybinding
```
