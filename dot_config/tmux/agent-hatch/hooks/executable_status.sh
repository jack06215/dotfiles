#!/usr/bin/env bash
# Record a coding agent's status on the tmux pane it runs in.
#
#   status.sh <agent> <state> [--quiet] [--if-waiting]
#
#   agent         claude, copilot, ... - the name the picker and the bar show
#   state         idle | busy | waiting | gone (gone forgets the pane)
#   --quiet       no bell for this event; the agent rings its own
#   --if-waiting  act only while the pane is waiting. "A tool ran" means a
#                 permission prompt was answered when the agent was waiting,
#                 and nothing at all otherwise: a subagent's tool finishing
#                 after the turn ended must not turn a finished agent back
#                 into a working one.
#
# Each agent's own hooks call this, so the picker (prefix + u) and the status
# bar segment need no code per agent. Which hook means which state:
#
#   state     Claude Code                    Copilot CLI
#   idle      SessionStart (--quiet), Stop   sessionStart (--quiet), agentStop
#   busy      UserPromptSubmit               userPromptSubmitted
#             PostToolUse (--if-waiting)     postToolUse (--if-waiting)
#   waiting   PreToolUse  AskUserQuestion    preToolUse  ask_user
#             Notification permission_prompt|elicitation_dialog (both)
#   gone      SessionEnd                     sessionEnd
#
# Copilot CLI (1.0.97) loads user hooks only once its session has started, so
# its sessionStart never reaches this: a Copilot shows up at its first prompt,
# not at launch. The hook stays configured for when that changes.
#
# That config lives with each agent: the hooks block in
# ~/.config/claude/settings.json and ~/.config/copilot/hooks/agent-hatch.json.
# Adding an agent (Gemini CLI: SessionStart, BeforeAgent, AfterTool,
# Notification, AfterAgent, SessionEnd) takes the same mapping in its own hook
# config, plus its name in @hatch_agents to put it in the prefix + y menu.
#
# The record is one pane option, so a reader gets everything from one
# `tmux list-panes` and a writer replaces it in one go:
#
#   @hatch = agent|state|seen|session|command
#
# `session` is the agent's session id, from the JSON the hook gets on stdin.
# Only the session that owns a pane updates it. That keeps an agent run *inside*
# another one's pane - `claude -p` from a script, Copilot asked for a second
# opinion through Claude's shell tool - from overwriting the outer agent's
# status, or deleting its row when it exits.
#
# `command` is the pane's foreground command when the session claimed the pane.
# While the pane still runs that, the agent is alive; once it does not (the
# agent crashed before its SessionEnd, the pane is back at a shell), readers
# treat the record as stale. That is what lets them skip a process scan.
#
# Never fails and never prints. Agents read hook output, and Copilot's
# preToolUse is fail-closed: a non-zero exit there would deny the tool.

agent="${1:-}"
state="${2:-}"
quiet=''
only_waiting=''
for arg in "${@:3}"; do
  case "$arg" in
  --quiet) quiet=1 ;;
  --if-waiting) only_waiting=1 ;;
  esac
done

pane="${TMUX_PANE:-}"
[ -n "$pane" ] && [ -n "$agent" ] && [ -n "$state" ] || exit 0

# The record goes last: it is the only field that can be empty, and with a tab
# IFS `read` would swallow an empty field in the middle.
IFS=$'\t' read -r tty command record <<EOF
$(tmux display-message -p -t "$pane" $'#{pane_tty}\t#{pane_current_command}\t#{@hatch}' 2>/dev/null)
EOF
[ -n "$tty" ] || exit 0
IFS='|' read -r _ old_state _ owner owner_command <<EOF
$record
EOF

[ -z "$only_waiting" ] || [ "$old_state" = waiting ] || exit 0

# Claude sends session_id, Copilot sessionId. The first match is the top-level
# key - it leads the payload - and a quoted key nested inside a string value
# cannot match, since its quotes arrive escaped.
session=''
re='"session_?[iI]d"[[:space:]]*:[[:space:]]*"([^"]+)"'
[ -t 0 ] || {
  payload="$(cat)"
  [[ "$payload" =~ $re ]] && session="${BASH_REMATCH[1]}"
}

if [ "$state" = gone ]; then
  [ -n "$record" ] && [ "$owner" = "$session" ] &&
    tmux set-option -pu -t "$pane" @hatch 2>/dev/null
  exit 0
fi

if [ -z "$record" ] || [ "$owner" != "$session" ]; then
  # Claiming the pane. Only the agent in the pane's foreground may: the process
  # that ran this hook - past any shell in between - has to be on the pane's
  # terminal and in its foreground process group. An agent that a supervisor
  # or another agent's shell tool started inherits TMUX_PANE but not that. The
  # hook itself can't be asked: Claude Code starts hooks detached, with no
  # terminal of their own. Where ps can't say, TMUX_PANE is all there is.
  [ -z "$only_waiting" ] || exit 0
  pid=$PPID ptty=''
  for _ in 1 2 3 4; do
    read -r ppid pgid tpgid ptty comm <<<"$(ps -o ppid=,pgid=,tpgid=,tty=,comm= -p "$pid" 2>/dev/null)"
    comm="${comm##*/}"
    case "${comm#-}" in
    sh | bash | zsh | dash | ksh | fish) pid=$ppid ;;
    *) break ;;
    esac
  done
  [ -z "$ptty" ] || { [ "/dev/$ptty" = "$tty" ] && [ "$pgid" = "$tpgid" ]; } || exit 0
  owner_command="$command"
  old_state=''
fi

tmux set-option -p -t "$pane" @hatch \
  "$agent|$state|${EPOCHSECONDS:-$(date +%s)}|$session|$owner_command" 2>/dev/null

# Ring on the way into a state that wants you. A bell written to the pane's
# terminal is that pane's bell to tmux: it flags the window, and bell.sh
# forwards it from a dedicated session to the window that launched it. The
# 2>/dev/null goes first because the shell itself reports a failed redirection.
if [ -z "$quiet" ] && [ "$state" != "$old_state" ]; then
  case "$state" in
  waiting | idle) printf '\a' 2>/dev/null >"$tty" ;;
  esac
fi

exit 0
