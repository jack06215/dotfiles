#!/bin/bash

# Monthly AI credit allowance that this month's spend is shown against
readonly AIC_BUDGET=1900

input=$(cat)

# ANSI color codes
readonly RESET="\033[0m"
readonly BOLD="\033[1m"
readonly DIM="\033[2m"
readonly CYAN="\033[36m"
readonly GREEN="\033[32m"
readonly YELLOW="\033[33m"
readonly RED="\033[31m"
readonly MAGENTA="\033[35m"
readonly BLUE="\033[34m"
readonly GRAY="\033[90m"

# Unicode separator
readonly SEP="${GRAY}│${RESET}"

# Extract all values in a single jq call. Fields are joined with the ASCII unit
# separator rather than @tsv's tab: tab is IFS whitespace, so read collapses a
# run of them and an empty field (most optional ones below) would shift every
# field after it. The cache field is the expiry clock time ("14:32"), "cold",
# or empty before any caching. jq's exit status, not `command -v jq`, picks
# the branch: a jq that is on PATH but can't run (an asdf shim for an amd64
# binary on an arm64 Mac) would otherwise leave every field empty.
#
# Context usage comes from Copilot's current_context_* fields when they're
# there: its total_input_tokens counts the whole session, not what's in the
# window now. Copilot sends no project_dir, so that falls back to the cwd.
# The effort arrives appended to the model name ("claude-opus-5.5 · medium"),
# so it's split off there.
if fields=$(echo "$input" | jq -r '[
            (.model.display_name // "" | sub(" · .*$"; "")),
            .model.id // "",
            (.context_window // {} | if .current_context_tokens != null and (.displayed_context_limit // 0) > 0
              then .current_context_used_percentage // (.current_context_tokens * 100 / .displayed_context_limit),
                .displayed_context_limit, .current_context_tokens
              else .used_percentage // 0, .context_window_size // 0, .total_input_tokens // 0 end),
            .workspace.current_dir // "~",
            .workspace.project_dir // .workspace.current_dir // "~",
            .cost.total_cost_usd // 0,
            .cost.total_duration_ms // 0,
            .cost.total_lines_added // 0,
            .cost.total_lines_removed // 0,
            .version // "",
            .vim.mode // "",
            (.model.display_name // "" | capture(" · (?<effort>.*)$").effort // ""),
            .fast_mode // false,
            (.session_name // "" | gsub("[\t\n\u001f]"; " ")),
            .agent.name // "",
            .worktree.name // .workspace.git_worktree // "",
            .pr.number // "",
            .pr.review_state // "",
            .pr.kind // "",
            .rate_limits.five_hour.used_percentage // "",
            .rate_limits.seven_day.used_percentage // "",
            .ai_used.total_nano_aiu // 0,
            .session_id // "",
            (.prompt_cache | if . == null then ""
              elif .warm and .expires_at != null then (.expires_at | floor | strflocaltime("%H:%M"))
              elif .caching_observed then "cold"
              else "" end)
        ] | map(if . == null then "" else tostring end) | join("\u001f")'); then
  IFS=$'\x1f' read -r model_name model_id used_pct ctx_size input_tokens current_dir project_dir \
    cost_usd duration_ms lines_added lines_removed version vim_mode effort_level fast_mode \
    session_name agent_name worktree_name pr_number pr_state pr_kind quota_5h quota_7d ai_nano session_id cache_state <<< "$fields"

  # Extract version from model.id
  if [[ "$model_id" =~ ([0-9]+)-([0-9]+) ]]; then
    model_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    if [[ "$model_name" != *"$model_version"* ]]; then
      model_name="${model_name} ${model_version}"
    fi
  fi
else
  model_name=""
  model_id=""
  used_pct=0
  ctx_size=0
  input_tokens=0
  current_dir=$(pwd)
  project_dir=$(pwd)
  cost_usd=0
  duration_ms=0
  lines_added=0
  lines_removed=0
  version=""
  vim_mode=""
  effort_level=""
  fast_mode=false
  session_name=""
  agent_name=""
  worktree_name=""
  pr_number=""
  pr_state=""
  pr_kind=""
  quota_5h=""
  quota_7d=""
  ai_nano=0
  session_id=""
  cache_state=""
fi

# Truncate float percentage to integer
used_pct=${used_pct%.*}
used_pct=${used_pct:-0}

# Format number with decimal precision (1.5k, 2.3M)
function format_number() {
  local n=$1
  n=${n:-0}
  if [ "$n" -ge 1000000 ]; then
    awk "BEGIN {printf \"%.1fM\", $n/1000000}"
  elif [ "$n" -ge 1000 ]; then
    awk "BEGIN {printf \"%.1fk\", $n/1000}"
  else
    echo "$n"
  fi
}

# Format duration from milliseconds to human-readable
function format_duration() {
  local ms=$1
  ms=${ms:-0}
  local secs=$((ms / 1000))
  if [ "$secs" -ge 3600 ]; then
    local hours=$((secs / 3600))
    local mins=$(((secs % 3600) / 60))
    if [ "$mins" -gt 0 ]; then
      echo "${hours}h${mins}m"
    else
      echo "${hours}h"
    fi
  elif [ "$secs" -ge 60 ]; then
    echo "$((secs / 60))m"
  else
    echo "${secs}s"
  fi
}

# Join non-empty parts with " │ ", skipping empty ones cleanly
function join_parts() {
  local result=""
  local part
  for part in "$@"; do
    if [ -n "$part" ]; then
      if [ -n "$result" ]; then
        result="${result} ${SEP} ${part}"
      else
        result="${part}"
      fi
    fi
  done
  printf '%s' "$result"
}

# Color for a 0-100 percentage used (green < 50%, yellow 50-80%, red >= 80%)
function pct_color() {
  if [ "$1" -lt 50 ]; then
    printf '%s' "$GREEN"
  elif [ "$1" -lt 80 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$RED"
  fi
}

# Plan quota for one window, e.g. "5h 38%"; empty when the plan doesn't report it
function format_quota() {
  local label=$1 pct=${2%.*}
  [ -z "$pct" ] && return
  printf '%s' "$(pct_color "$pct")${label} ${pct}%${RESET}"
}

# AI credits from Copilot's nano-AIU count (1 AIC = 1e9): 0.42, 12.3, 154
function format_aic() {
  awk -v n="$1" 'BEGIN {
    c = n / 1e9; f = c < 10 ? "%.2f" : c < 100 ? "%.1f" : "%.0f"; printf f, c }'
}

# This month's AI credits, in nano-AIU, across every Copilot CLI session on
# this machine. Copilot only reports the running session's total, so each run
# records it in a SQLite ledger, one row per session per month: credits banked
# before a /clear or /new reset the count, and the current count. Concurrent
# sessions are serialized by SQLite's locking, and the busy timeout makes a
# writer wait for the lock rather than drop its update. The month turns over
# with Copilot's quota, on the 1st in UTC, which is the clock strftime uses.
function aic_month_nano() {
  local dir="${XDG_STATE_HOME:-$HOME/.local/state}/copilot" upsert=""
  mkdir -p "$dir" 2> /dev/null || return
  # Both values are spliced into the SQL, so only a plain id and count pass
  if [[ "$session_id" =~ ^[A-Za-z0-9_-]+$ && "$ai_nano" =~ ^[0-9]+$ ]]; then
    upsert="INSERT INTO aic (month, session_id, session_nano)
      VALUES (strftime('%Y-%m', 'now'), '$session_id', $ai_nano)
      ON CONFLICT (month, session_id) DO UPDATE SET
        banked_nano = banked_nano + iif(excluded.session_nano < session_nano, session_nano, 0),
        session_nano = excluded.session_nano
      WHERE excluded.session_nano != session_nano;"
  fi
  sqlite3 "$dir/aic.db" 2> /dev/null << SQL
.timeout 2000
CREATE TABLE IF NOT EXISTS aic (
  month TEXT NOT NULL,
  session_id TEXT NOT NULL,
  banked_nano INTEGER NOT NULL DEFAULT 0,
  session_nano INTEGER NOT NULL,
  PRIMARY KEY (month, session_id)
);
$upsert
SELECT coalesce(sum(banked_nano + session_nano), 0) FROM aic
WHERE month = strftime('%Y-%m', 'now');
SQL
}

USAGE_COLOR=$(pct_color "$used_pct")

# Build progress bar (10 chars wide)
bar_width=10
filled=$((used_pct * bar_width / 100))
empty=$((bar_width - filled))
progress_bar="["
for ((i = 0; i < filled; i++)); do progress_bar+="█"; done
for ((i = 0; i < empty; i++)); do progress_bar+="░"; done
progress_bar+="]"

# Get git branch and status if in a git repo
git_info=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$current_dir" -c core.useBuiltinFSMonitor=false branch --show-current 2> /dev/null)

  # Handle detached HEAD
  if [ -z "$branch" ]; then
    branch=$(git -C "$current_dir" rev-parse --short HEAD 2> /dev/null)
    branch="detached:${branch}"
  fi

  if [ -n "$branch" ]; then
    git_info="$branch"

    # Check for uncommitted changes
    if ! git -C "$current_dir" diff --quiet 2> /dev/null || ! git -C "$current_dir" diff --cached --quiet 2> /dev/null; then
      git_info="$git_info ${YELLOW}*${RESET}"
    fi

    # Check ahead/behind status
    upstream=$(git -C "$current_dir" rev-parse --abbrev-ref @{upstream} 2> /dev/null)
    if [ -n "$upstream" ]; then
      ahead=$(git -C "$current_dir" rev-list --count @{upstream}..HEAD 2> /dev/null)
      behind=$(git -C "$current_dir" rev-list --count HEAD..@{upstream} 2> /dev/null)
      if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
        git_info="$git_info ${GREEN}↑$ahead${RED}↓$behind${RESET}"
      elif [ "$ahead" -gt 0 ]; then
        git_info="$git_info ${GREEN}↑$ahead${RESET}"
      elif [ "$behind" -gt 0 ]; then
        git_info="$git_info ${RED}↓$behind${RESET}"
      fi
    fi
  fi
fi

# Get project name from project_dir
project_name=$(basename "$project_dir")

dir_display="$project_name"
if [ "$current_dir" != "$project_dir" ]; then
  case "$current_dir" in
    "$project_dir"/*) dir_display="${project_name}/${current_dir#"$project_dir"/}" ;;
    "$HOME"/*) dir_display="${project_name} → ~/${current_dir#"$HOME"/}" ;;
    *) dir_display="${project_name} → ${current_dir}" ;;
  esac
fi

# Session name (from --name, /rename, or the AI-generated title), kept short
if [ "${#session_name}" -gt 40 ]; then
  session_name="${session_name:0:39}…"
fi

# Format context usage as tokens/window (e.g. "68.2k/1M"). The token count is
# what the percentage is computed from, so the two always agree. The window
# size is always round: drop the ".0" format_number leaves on it.
ctx_display=""
if [ "${ctx_size:-0}" -gt 0 ]; then
  size_display=$(format_number "$ctx_size")
  ctx_display="$(format_number "$input_tokens")/${size_display/.0/}"
fi

# Format cost
cost_display=""
if [ "${cost_usd%.*}" != "0" ] || [ "${cost_usd#*.}" != "$cost_usd" ]; then
  cost_display=$(awk "BEGIN {printf \"\$%.2f\", $cost_usd}")
fi

# Format AI credits: this session's, and this month's against AIC_BUDGET.
# Token-based billing reports no quota, so the month is tracked locally and
# misses what VS Code, github.com or another machine spent.
aic_display=""
[ "${ai_nano:-0}" != "0" ] && aic_display="$(format_aic "$ai_nano") AIC"
aic_month_part=""
month_nano=$(aic_month_nano)
if [ "${month_nano:-0}" != "0" ]; then
  month_pct=$(awk -v n="$month_nano" -v b="$AIC_BUDGET" 'BEGIN { printf "%d", n / 1e9 * 100 / b }')
  aic_month_part="$(pct_color "$month_pct")AIC used $(format_aic "$month_nano")/${AIC_BUDGET} ${month_pct}%${RESET}"
fi

# Format duration
duration_display=""
if [ "${duration_ms:-0}" -gt 0 ]; then
  duration_display=$(format_duration "$duration_ms")
fi

# Format code churn
churn_display=""
lines_added=${lines_added:-0}
lines_removed=${lines_removed:-0}
if [ "$lines_added" -gt 0 ] || [ "$lines_removed" -gt 0 ]; then
  churn_display="${GREEN}+${lines_added}${RESET}/${RED}-${lines_removed}${RESET}"
fi

pr_part=""
if [ -n "$pr_number" ]; then
  pr_label="PR #${pr_number}"
  [ "$pr_kind" = "mr" ] && pr_label="MR !${pr_number}"
  case "$pr_state" in
    approved) pr_color=$GREEN ;;
    changes_requested) pr_color=$RED pr_state="changes requested" ;;
    pending) pr_color=$YELLOW ;;
    *) pr_color=$GRAY ;; # draft, or no review state reported
  esac
  pr_part="${pr_color}${pr_label}${pr_state:+ ${pr_state}}${RESET}"
fi

cache_part=""
case "$cache_state" in
  "") ;;
  cold) cache_part="${RED}cache cold${RESET}" ;;
  *) cache_part="${GREEN}cache until ${cache_state}${RESET}" ;;
esac

# Build each row, joining only the segments that are present

# Row 1: vim mode indicator + working dir + session name.
vim_part=""
[ -n "$vim_mode" ] && vim_part="${YELLOW}${BOLD}${vim_mode}${RESET}"
session_part=""
[ -n "$session_name" ] && session_part="${GRAY}${session_name}${RESET}"
row1=$(join_parts "$vim_part" "${DIM}${dir_display}${RESET}" "$session_part")

# Row 2: git info (branch + dirty flag + ahead/behind), worktree, PR — omitted
# entirely outside a git repo with no worktree or PR
git_part=""
[ -n "$git_info" ] && git_part="${BLUE}${git_info}${RESET}"
worktree_part=""
[ -n "$worktree_name" ] && worktree_part="${MAGENTA}worktree ${worktree_name}${RESET}"
row2=$(join_parts "$git_part" "$worktree_part" "$pr_part")

# Row 3: cost, AI credits, code churn, session duration, plan quota, monthly
# AI credits — omitted when all are empty
cost_part=""
[ -n "$cost_display" ] && cost_part="${GREEN}${cost_display}${RESET}"
aic_part=""
[ -n "$aic_display" ] && aic_part="${GREEN}${aic_display}${RESET}"
duration_part=""
[ -n "$duration_display" ] && duration_part="${GRAY}${duration_display}${RESET}"
row3=$(join_parts "$cost_part" "$aic_part" "$churn_display" "$duration_part" \
  "$(format_quota 5h "$quota_5h")" "$(format_quota 7d "$quota_7d")" "$aic_month_part")

# Row 4: model name + effort + fast mode, agent (--agent or the agent
# setting), usage bar + context tokens, prompt cache
model_part=""
if [ -n "$model_name" ]; then
  model_part="${CYAN}${BOLD}${model_name}${RESET}"
  [ -n "$effort_level" ] && model_part="${model_part} ${MAGENTA}${effort_level}${RESET}"
  [ "$fast_mode" = "true" ] && model_part="${model_part} ${YELLOW}fast${RESET}"
fi
agent_part=""
[ -n "$agent_name" ] && agent_part="${CYAN}agent ${agent_name}${RESET}"
usage_part="${progress_bar} ${used_pct}%"
[ -n "$ctx_display" ] && usage_part="${usage_part} (${ctx_display})"
row4=$(join_parts "$model_part" "$agent_part" "${USAGE_COLOR}${usage_part}${RESET}" "$cache_part")

# Assemble output, skipping any row that ended up empty (e.g. no git repo, no churn)
output="$row1"
[ -n "$row2" ] && output="${output}\n${row2}"
[ -n "$row3" ] && output="${output}\n${row3}"
[ -n "$row4" ] && output="${output}\n${row4}"

echo -e "$output"
