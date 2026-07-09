#!/bin/bash

# Claude Code statusline script

# Read JSON input from stdin
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

# Extract all values in a single jq call using tab-separated output
if command -v jq &>/dev/null; then
	IFS=$'\t' read -r model_name model_id used_pct input_tokens output_tokens current_dir project_dir \
		cost_usd duration_ms lines_added lines_removed version <<< \
		"$(echo "$input" | jq -r '[
            .model.display_name // "Claude",
            .model.id // "",
            .context_window.used_percentage // 0,
            .context_window.total_input_tokens // 0,
            .context_window.total_output_tokens // 0,
            .workspace.current_dir // "~",
            .workspace.project_dir // "~",
            .cost.total_cost_usd // 0,
            .cost.total_duration_ms // 0,
            .cost.total_lines_added // 0,
            .cost.total_lines_removed // 0,
            .version // ""
        ] | @tsv')"

	# Extract version from model.id (e.g., "claude-opus-4-6" -> "4.6")
	# Only append if display_name doesn't already contain the version
	if [[ "$model_id" =~ ([0-9]+)-([0-9]+) ]]; then
		model_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
		if [[ "$model_name" != *"$model_version"* ]]; then
			model_name="${model_name} ${model_version}"
		fi
	fi
else
	model_name="Claude"
	model_id=""
	used_pct=0
	input_tokens=0
	output_tokens=0
	current_dir=$(pwd)
	project_dir=$(pwd)
	cost_usd=0
	duration_ms=0
	lines_added=0
	lines_removed=0
	version=""
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

# Determine color based on usage (green < 50%, yellow 50-80%, red >= 80%)
if [ "$used_pct" -lt 50 ]; then
	USAGE_COLOR=$GREEN
elif [ "$used_pct" -lt 80 ]; then
	USAGE_COLOR=$YELLOW
else
	USAGE_COLOR=$RED
fi

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
if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
	branch=$(git -C "$current_dir" -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null)

	# Handle detached HEAD
	if [ -z "$branch" ]; then
		branch=$(git -C "$current_dir" rev-parse --short HEAD 2>/dev/null)
		branch="detached:${branch}"
	fi

	if [ -n "$branch" ]; then
		git_info="$branch"

		# Check for uncommitted changes
		if ! git -C "$current_dir" diff --quiet 2>/dev/null || ! git -C "$current_dir" diff --cached --quiet 2>/dev/null; then
			git_info="$git_info ${YELLOW}*${RESET}"
		fi

		# Check ahead/behind status
		upstream=$(git -C "$current_dir" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
		if [ -n "$upstream" ]; then
			ahead=$(git -C "$current_dir" rev-list --count @{upstream}..HEAD 2>/dev/null)
			behind=$(git -C "$current_dir" rev-list --count HEAD..@{upstream} 2>/dev/null)
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

# Format tokens (input and output separately)
in_display=$(format_number "$input_tokens")
out_display=$(format_number "$output_tokens")

# Format cost
cost_display=""
if [ "${cost_usd%.*}" != "0" ] || [ "${cost_usd#*.}" != "$cost_usd" ]; then
	cost_display=$(awk "BEGIN {printf \"\$%.2f\", $cost_usd}")
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

# Build each row, joining only the segments that are present

# Row 1: project name
row1="${DIM}${project_name}${RESET}"

# Row 2: git info (branch + dirty flag + ahead/behind) — omitted entirely outside a git repo
row2=""
[ -n "$git_info" ] && row2="${BLUE}${git_info}${RESET}"

# Row 3: cost, tokens, code churn
cost_part=""
[ -n "$cost_display" ] && cost_part="${GREEN}${cost_display}${RESET}"
row3=$(join_parts "$cost_part" "${MAGENTA}${in_display} in / ${out_display} out${RESET}" "$churn_display")

# Row 4: model name + usage bar
row4=$(join_parts "${CYAN}${BOLD}${model_name}${RESET}" "${USAGE_COLOR}${progress_bar} ${used_pct}%${RESET}")

# Note: duration_display (e.g. "12m") is computed above but not shown in this layout.
# Add it into row3's join_parts call if you want it back.

# Assemble output, skipping any row that ended up empty (e.g. no git repo, no churn)
output="$row1"
[ -n "$row2" ] && output="${output}\n${row2}"
[ -n "$row3" ] && output="${output}\n${row3}"
[ -n "$row4" ] && output="${output}\n${row4}"

echo -e "$output"
