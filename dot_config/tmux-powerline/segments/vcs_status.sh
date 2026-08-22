# shellcheck shell=bash
# Branch + upstream divergence + working-tree counts, from ONE git call.
#
#    master ↑2↓1 +3 ~5 ?2
#    │      │    │  │  └─ untracked files
#    │      │    │  └──── tracked files modified but not staged
#    │      │    └─────── files staged for the next commit
#    │      └──────────── 2 commits ahead of the upstream, 1 behind
#    └─────────────────── branch (or the short SHA when HEAD is detached)
#
# A clean tree collapses to "  master ✓", and outside a repository the segment
# produces nothing, so tmux-powerline drops it along with its separator.
#
# Why a custom segment instead of the stock ones: vcs_branch, vcs_compare,
# vcs_staged, vcs_modified and vcs_others each detect the VCS and shell out to
# git on their own, so stacking the five costs five git invocations per status
# refresh per attached client. `git status --porcelain=v2 --branch` already
# contains everything all five print, so one call and one awk pass does it.
#
# --no-optional-locks is the important flag: without it git refreshes and locks
# the index as a side effect of `status`, and a bar ticking every few seconds
# would race lazygit and your own `git commit` for .git/index.lock.

# shellcheck source=/dev/null
source "${TMUX_POWERLINE_DIR_LIB}/tmux_adapter.sh"

# U+E0A0, the powerline branch glyph, as UTF-8 bytes — it sits in the Nerd Font
# private use area, which editors and pipes are prone to eating. Under a font
# without it the branch name simply stands on its own; a tofu box in front of
# every branch would be worse than no marker at all.
if tp_patched_font_in_use; then
	TMUX_POWERLINE_SEG_VCS_STATUS_SYMBOL_DEFAULT=$'\xee\x82\xa0'
else
	TMUX_POWERLINE_SEG_VCS_STATUS_SYMBOL_DEFAULT=""
fi
TMUX_POWERLINE_SEG_VCS_STATUS_MAX_LEN_DEFAULT="24"

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Branch glyph (U+E0A0, from the Nerd Font powerline set).
export TMUX_POWERLINE_SEG_VCS_STATUS_SYMBOL=\$'\\xee\\x82\\xa0'
# Truncate branch names longer than this.
export TMUX_POWERLINE_SEG_VCS_STATUS_MAX_LEN="${TMUX_POWERLINE_SEG_VCS_STATUS_MAX_LEN_DEFAULT}"
# Colours, in Catppuccin Mocha by default. Any tmux colour spec works.
export TMUX_POWERLINE_SEG_VCS_STATUS_SYMBOL_COLOUR="#cba6f7"
export TMUX_POWERLINE_SEG_VCS_STATUS_AHEAD_COLOUR="#89b4fa"
export TMUX_POWERLINE_SEG_VCS_STATUS_BEHIND_COLOUR="#fab387"
export TMUX_POWERLINE_SEG_VCS_STATUS_STAGED_COLOUR="#a6e3a1"
export TMUX_POWERLINE_SEG_VCS_STATUS_MODIFIED_COLOUR="#f9e2af"
export TMUX_POWERLINE_SEG_VCS_STATUS_UNTRACKED_COLOUR="#9399b2"
export TMUX_POWERLINE_SEG_VCS_STATUS_CONFLICT_COLOUR="#f38ba8"
export TMUX_POWERLINE_SEG_VCS_STATUS_CLEAN_COLOUR="#a6e3a1"
EORC
	echo "$rccontents"
}

run_segment() {
	__process_settings

	local cwd status_out
	cwd=$(tp_get_tmux_cwd)
	[ -d "$cwd" ] || return 0

	# Subshell so the cd does not leak into the segments that run after this one
	# (tmux-powerline sources every segment into the same shell).
	status_out=$(
		cd "$cwd" 2>/dev/null || exit 1
		git --no-optional-locks status --porcelain=v2 --branch --untracked-files=normal 2>/dev/null
	) || return 0
	[ -n "$status_out" ] || return 0

	# One awk pass over the porcelain-v2 output. Header lines are "# key value";
	# entry lines start with 1/2 (changed/renamed, with a two-char XY state where
	# X is the index and Y the working tree), u (unmerged) or ? (untracked).
	local parsed
	parsed=$(awk '
		$1 == "#" {
			if      ($2 == "branch.head") head = $3
			else if ($2 == "branch.oid")  oid  = substr($3, 1, 7)
			else if ($2 == "branch.ab") { ahead = $3 + 0; behind = -($4 + 0) }
			next
		}
		$1 == "1" || $1 == "2" {
			if (substr($2, 1, 1) != ".") staged++
			if (substr($2, 2, 1) != ".") modified++
			next
		}
		$1 == "u" { conflict++;  next }
		$1 == "?" { untracked++; next }
		END {
			print head "\t" oid "\t" ahead+0 "\t" behind+0 "\t" \
			      staged+0 "\t" modified+0 "\t" untracked+0 "\t" conflict+0
		}
	' <<<"$status_out")

	local head oid ahead behind staged modified untracked conflict
	IFS=$'\t' read -r head oid ahead behind staged modified untracked conflict <<<"$parsed"

	# "(detached)" is git's literal placeholder for a HEAD that is not on a
	# branch — mid-rebase, mid-bisect, or after checking out a tag or SHA. The
	# short object id is the useful thing to show there. "(initial)" is a repo
	# with no commits yet.
	local label="$head"
	if [ "$head" = "(detached)" ]; then
		label="${oid:-detached}"
	elif [ -z "$head" ]; then
		return 0
	fi
	if [ "${#label}" -gt "$TMUX_POWERLINE_SEG_VCS_STATUS_MAX_LEN" ]; then
		label="${label:0:$((TMUX_POWERLINE_SEG_VCS_STATUS_MAX_LEN - 1))}…"
	fi

	local fg="$TMUX_POWERLINE_CUR_SEGMENT_FG"
	local out=""
	[ -n "$TMUX_POWERLINE_SEG_VCS_STATUS_SYMBOL" ] &&
		out="#[fg=${TMUX_POWERLINE_SEG_VCS_STATUS_SYMBOL_COLOUR}]${TMUX_POWERLINE_SEG_VCS_STATUS_SYMBOL} "
	out+="#[fg=${fg}]${label}"

	# ↑ and ↓ butt up against each other as one "how far from the upstream"
	# token, so the leading space belongs to whichever of the two comes first.
	if [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
		out+=" "
		[ "$ahead" -gt 0 ] && out+="#[fg=${TMUX_POWERLINE_SEG_VCS_STATUS_AHEAD_COLOUR}]↑${ahead}"
		[ "$behind" -gt 0 ] && out+="#[fg=${TMUX_POWERLINE_SEG_VCS_STATUS_BEHIND_COLOUR}]↓${behind}"
	fi

	if [ $((staged + modified + untracked + conflict)) -eq 0 ]; then
		out+=" #[fg=${TMUX_POWERLINE_SEG_VCS_STATUS_CLEAN_COLOUR}]✓"
	else
		[ "$conflict" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_VCS_STATUS_CONFLICT_COLOUR}]!${conflict}"
		[ "$staged" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_VCS_STATUS_STAGED_COLOUR}]+${staged}"
		[ "$modified" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_VCS_STATUS_MODIFIED_COLOUR}]~${modified}"
		[ "$untracked" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_VCS_STATUS_UNTRACKED_COLOUR}]?${untracked}"
	fi

	echo "${out}#[fg=${fg}]"
	return 0
}

__process_settings() {
	: "${TMUX_POWERLINE_SEG_VCS_STATUS_SYMBOL:=$TMUX_POWERLINE_SEG_VCS_STATUS_SYMBOL_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_VCS_STATUS_MAX_LEN:=$TMUX_POWERLINE_SEG_VCS_STATUS_MAX_LEN_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_VCS_STATUS_SYMBOL_COLOUR:=#cba6f7}"
	: "${TMUX_POWERLINE_SEG_VCS_STATUS_AHEAD_COLOUR:=#89b4fa}"
	: "${TMUX_POWERLINE_SEG_VCS_STATUS_BEHIND_COLOUR:=#fab387}"
	: "${TMUX_POWERLINE_SEG_VCS_STATUS_STAGED_COLOUR:=#a6e3a1}"
	: "${TMUX_POWERLINE_SEG_VCS_STATUS_MODIFIED_COLOUR:=#f9e2af}"
	: "${TMUX_POWERLINE_SEG_VCS_STATUS_UNTRACKED_COLOUR:=#9399b2}"
	: "${TMUX_POWERLINE_SEG_VCS_STATUS_CONFLICT_COLOUR:=#f38ba8}"
	: "${TMUX_POWERLINE_SEG_VCS_STATUS_CLEAN_COLOUR:=#a6e3a1}"
}
