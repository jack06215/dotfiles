# shellcheck disable=SC2034,SC2153,SC2086,SC2155

# Above line is because shellcheck doesn't support zsh, per
# https://github.com/koalaman/shellcheck/wiki/SC1071, and the ignore: param in
# ludeeus/action-shellcheck only supports _directories_, not _files_. So
# instead, we manually add any error the shellcheck step finds in the file to
# the above line ...

# Source this in your ~/.zshrc

# Guard: everything below shells out to `atuin` on every prompt/command, so
# without this the whole file breaks noisily on any machine without atuin.
if ! command -v atuin >/dev/null 2>&1; then
  return
fi

# This file is a saved copy of `atuin init zsh` output, which writes this line
# from `[tmux] enabled` in atuin's config.toml. A change to that setting has no
# effect here until this line changes too. Removing the line turns the popup
# on, because __atuin_tmux_popup_check treats an unset ATUIN_TMUX_POPUP as true.
export ATUIN_TMUX_POPUP=false

autoload -U add-zsh-hook

zmodload zsh/datetime 2>/dev/null

# If zsh-autosuggestions is installed, configure it to use Atuin's search. If
# you'd like to override this, then add your config after the $(atuin init zsh)
# in your .zshrc
_zsh_autosuggest_strategy_atuin() {
    # silence errors, since we don't want to spam the terminal prompt while typing.
    # '$all-user' is a literal atuin author filter, not a shell variable
    # shellcheck disable=SC2016
    suggestion=$(ATUIN_QUERY="$1" atuin search --cmd-only --author '$all-user' --limit 1 --search-mode prefix 2>/dev/null)
}

if [ -n "${ZSH_AUTOSUGGEST_STRATEGY:-}" ]; then
    ZSH_AUTOSUGGEST_STRATEGY=("atuin" "${ZSH_AUTOSUGGEST_STRATEGY[@]}")
else
    ZSH_AUTOSUGGEST_STRATEGY=("atuin")
fi

if [[ -z "${ATUIN_SESSION:-}" || "${ATUIN_SHLVL:-}" != "$SHLVL" ]]; then
    export ATUIN_SESSION=$(atuin uuid)
    export ATUIN_SHLVL=$SHLVL
fi
ATUIN_HISTORY_ID=""

if [[ -z ${__atuin_pty_proxy_owns_tty-} ]] && [[ -n ${ATUIN_PTY_PROXY_ACTIVE-} ]]; then
    # The pty-proxy preamble also sets this variable, but make sure it's set here,
    # so a manually started proxy still functions when `pty_proxy.enabled` is false.
    if __atuin_pty_proxy_answer=$(atuin __internal pty-proxy-active 2>/dev/null) &&
      [[ $__atuin_pty_proxy_answer = [01] ]]
    then
      __atuin_pty_proxy_owns_tty=$__atuin_pty_proxy_answer
    else
      __atuin_pty_proxy_owns_tty=-1
    fi
    unset -v __atuin_pty_proxy_answer
fi

__atuin_mark_output_start() {
    [[ ${__atuin_pty_proxy_owns_tty-} = 1 ]] || return 0

    if [[ -n ${__atuin_needs_osc133_reset-} ]]; then
        unset -v __atuin_needs_osc133_reset
        # Old pty-proxy will reset an in-progress capture on a `B` marker.
        # Always reset, even if there's no history ID, to avoid capturing a
        # filtered command.
        printf '\033]133;B\a'
    fi

    [[ -n "${ATUIN_HISTORY_ID:-}" ]] || return 0

    if [[ ${ATUIN_PTY_PROXY_ACTIVE-} = 1 ]]; then
        # Current pty-proxy is an older version that expects OSC 133; new
        # pty-proxy sets ATUIN_PTY_PROXY_ACTIVE to 2.
        printf '\033]133;C\a'
    else
        printf '\033]18188735;C;%s\a' "$ATUIN_HISTORY_ID"
    fi
}

__atuin_mark_output_end() {
    [[ ${__atuin_pty_proxy_owns_tty-} = 1 ]] || return 0
    [[ -n "${ATUIN_HISTORY_ID:-}" ]] || return 0

    if [[ ${ATUIN_PTY_PROXY_ACTIVE-} = 1 ]]; then
        printf '\033]133;D;%s;history_id=%s\a' "$1" "$ATUIN_HISTORY_ID"
    else
        printf '\033]18188735;D;%s\a' "$ATUIN_HISTORY_ID"
    fi
}

_atuin_preexec() {
    local id
    id=$(ATUIN_SHELL=zsh atuin history start --hook -- "$1" 2>/dev/null)
    export ATUIN_HISTORY_ID="$id"
    __atuin_mark_output_start
    __atuin_preexec_time=${EPOCHREALTIME-}
}

_atuin_precmd() {
    local EXIT="$?" __atuin_precmd_time=${EPOCHREALTIME-}

    [[ -z "${ATUIN_HISTORY_ID:-}" ]] && return 0

    local duration=""
    if [[ -n $__atuin_preexec_time && -n $__atuin_precmd_time ]]; then
        printf -v duration %.0f $(((__atuin_precmd_time - __atuin_preexec_time) * 1000000000))
        ((duration < 0)) && duration=0
    fi

    __atuin_mark_output_end "$EXIT"
    (atuin history end --hook --exit $EXIT ${duration:+--duration=$duration} -- $ATUIN_HISTORY_ID >/dev/null 2>&1 &)
    export ATUIN_HISTORY_ID=""
}

# Allow comment lines at the interactive prompt, matching the default
# behavior of bash and fish (oh-my-zsh also enables this).
setopt interactive_comments

# With interactive_comments, a line starting with '#' is added to history
# without executing anything, so preexec never fires for it. Record such
# lines from the history hook instead.
_atuin_zshaddhistory() {
    # Guard in case the user unset the option after atuin init: the line then
    # executes as a normal command and is recorded by preexec/precmd.
    [[ -o interactive_comments ]] || return 0
    local line=${1%$'\n'}
    # Skip multi-line buffers: anything after the comment executes, so the
    # whole buffer is recorded by preexec/precmd.
    [[ $line == \#* && $line != *$'\n'* ]] || return 0
    local id
    id=$(ATUIN_SHELL=zsh atuin history start --hook -- "$line" 2>/dev/null)
    [[ -n $id ]] && (atuin history end --hook --exit 0 --duration=0 -- "$id" >/dev/null 2>&1 &)
    return 0
}

# Check if tmux popup is available (tmux >= 3.2)
__atuin_tmux_popup_check() {
    [[ -n "${TMUX-}" ]] || return 1
    [[ "${ATUIN_TMUX_POPUP:-true}" != "false" ]] || return 1

    # https://github.com/tmux/tmux/wiki/FAQ#how-often-is-tmux-released-what-is-the-version-number-scheme
    local tmux_version
    tmux_version=$(tmux -V 2>/dev/null | sed -n 's/^[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p') # Could have used grep...
    [[ -z "$tmux_version" ]] && return 1

    local m1 m2
    m1=${tmux_version%%.*}
    m2=${tmux_version#*.}
    m2=${m2%%.*}
    [[ "$m1" =~ ^[0-9]+$ ]] || return 1
    [[ "$m2" =~ ^[0-9]+$ ]] || m2=0
    (( m1 > 3 || (m1 == 3 && m2 >= 2) ))
}

# Use global variable to fix scope issues with traps
__atuin_popup_tmpdir=""
__atuin_tmux_popup_cleanup() {
    [[ -n "$__atuin_popup_tmpdir" && -d "$__atuin_popup_tmpdir" ]] && command rm -rf "$__atuin_popup_tmpdir"
    __atuin_popup_tmpdir=""
}

__atuin_search_cmd() {
    local -a search_args=("$@")

    if __atuin_tmux_popup_check; then
        __atuin_popup_tmpdir=$(mktemp -d) || return 1
        local result_file="$__atuin_popup_tmpdir/result"

        trap '__atuin_tmux_popup_cleanup' EXIT HUP INT TERM

        local escaped_query escaped_args
        escaped_query=$(printf '%s' "$BUFFER" | sed "s/'/'\\\\''/g")
        escaped_args=""
        for arg in "${search_args[@]}"; do
            escaped_args+=" '$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")'"
        done

        # In the popup, atuin goes to terminal, stderr goes to file
        local cdir popup_width popup_height
        cdir=$(pwd)
        popup_width="${ATUIN_TMUX_POPUP_WIDTH:-80%}" # Keep default value anyways
        popup_height="${ATUIN_TMUX_POPUP_HEIGHT:-60%}"
        tmux display-popup -d "$cdir" -w "$popup_width" -h "$popup_height" -E -E -- \
            sh -c "PATH='$PATH' ATUIN_SESSION='$ATUIN_SESSION' ATUIN_SHELL=zsh ATUIN_QUERY='$escaped_query' atuin search $escaped_args -i 2>'$result_file'"

        if [[ -f "$result_file" ]]; then
            cat "$result_file"
        fi

        __atuin_tmux_popup_cleanup
        trap - EXIT HUP INT TERM
    else
        ATUIN_SHELL=zsh ATUIN_QUERY=$BUFFER atuin search "${search_args[@]}" -i 3>&1 1>&2 2>&3 3>&-
    fi
}

_atuin_search() {
    emulate -L zsh
    zle -I

    # swap stderr and stdout, so that the tui stuff works
    # TODO: not this
    local output __atuin_status
    # shellcheck disable=SC2048
    output=$(__atuin_search_cmd $*)
    __atuin_status=$?

    zle reset-prompt
    # re-enable bracketed paste
    # shellcheck disable=SC2154
    echo -n ${zle_bracketed_paste[1]} >/dev/tty

    if (( __atuin_status != 0 )); then
        [[ -n $output ]] && print -r -- "$output" >/dev/tty
        return $__atuin_status
    fi

    if [[ -n $output ]]; then
        RBUFFER=""
        LBUFFER=$output

        if [[ $LBUFFER == __atuin_accept__:* ]]
        then
            LBUFFER=${LBUFFER#__atuin_accept__:}
            zle accept-line
        fi
    fi
}
_atuin_search_vicmd() {
    _atuin_search --keymap-mode=vim-normal
}
_atuin_search_viins() {
    _atuin_search --keymap-mode=vim-insert
}

_atuin_up_search() {
    # Only trigger if the buffer is a single line
    if [[ ! $BUFFER == *$'\n'* ]]; then
        _atuin_search --shell-up-key-binding "$@"
    else
        zle up-line
    fi
}
_atuin_up_search_vicmd() {
    _atuin_up_search --keymap-mode=vim-normal
}
_atuin_up_search_viins() {
    _atuin_up_search --keymap-mode=vim-insert
}

# `atuin threads resume`: pick a captured AI coding-agent session. The result uses
# the same protocol as the history search: `__atuin_accept__:` runs it.
_atuin_ai_resume() {
    emulate -L zsh
    zle -I

    local output __atuin_status
    output=$(ATUIN_SHELL=zsh ATUIN_QUERY=$BUFFER atuin threads resume --shell-widget "$@" 3>&1 1>&2 2>&3 3>&-)
    __atuin_status=$?

    zle reset-prompt
    # re-enable bracketed paste
    # shellcheck disable=SC2154
    echo -n ${zle_bracketed_paste[1]} >/dev/tty

    if (( __atuin_status != 0 )); then
        [[ -n $output ]] && print -r -- "$output" >/dev/tty
        return $__atuin_status
    fi

    if [[ -n $output ]]; then
        RBUFFER=""
        LBUFFER=$output

        if [[ $LBUFFER == __atuin_accept__:* ]]
        then
            LBUFFER=${LBUFFER#__atuin_accept__:}
            zle accept-line
        fi
    fi
}
_atuin_ai_resume_vicmd() {
    _atuin_ai_resume --keymap-mode=vim-normal
}
_atuin_ai_resume_viins() {
    _atuin_ai_resume --keymap-mode=vim-insert
}

add-zsh-hook preexec _atuin_preexec
add-zsh-hook precmd _atuin_precmd
add-zsh-hook zshaddhistory _atuin_zshaddhistory

zle -N atuin-search _atuin_search
zle -N atuin-search-vicmd _atuin_search_vicmd
zle -N atuin-search-viins _atuin_search_viins
zle -N atuin-up-search _atuin_up_search
zle -N atuin-up-search-vicmd _atuin_up_search_vicmd
zle -N atuin-up-search-viins _atuin_up_search_viins
zle -N atuin-ai-resume _atuin_ai_resume
zle -N atuin-ai-resume-vicmd _atuin_ai_resume_vicmd
zle -N atuin-ai-resume-viins _atuin_ai_resume_viins

# These are compatibility widget names for "atuin <= 17.2.1" users.
zle -N _atuin_search_widget _atuin_search
zle -N _atuin_up_search_widget _atuin_up_search

(ATUIN_SHELL=zsh atuin __internal prepare-search-index >/dev/null 2>&1 &)

if [[ ${__atuin_pty_proxy_owns_tty-} = 1 ]] && [[ ${ATUIN_PTY_PROXY_ACTIVE-} = 1 ]]; then
    # We're running in an old pty-proxy that expects OSC 133 markers. The outer
    # shell may have already sent a `C` marker, causing the proxy to start
    # capturing output. We need to clear this state before the first command's
    # output starts, or else the prompt and command itself will be erroneously
    # included in the output.
    __atuin_needs_osc133_reset=1
fi
# bindkey -M emacs '^r' atuin-search
# bindkey -M viins '^r' atuin-search-viins
#
# The vicmd bindings below depend on ZVM_LAZY_KEYBINDINGS=false in
# vi_mode.zsh: with zsh-vi-mode's lazy default the vicmd keymap is not bound
# at init but on the first <ESC>, which would overwrite `/`, `k`, `?` and ^R
# here the first time normal mode is entered.
bindkey -M vicmd '/' atuin-search
bindkey -M emacs '^[[A' atuin-up-search
bindkey -M vicmd '^[[A' atuin-up-search-vicmd
bindkey -M viins '^[[A' atuin-up-search-viins
bindkey -M emacs '^[OA' atuin-up-search
bindkey -M vicmd '^[OA' atuin-up-search-vicmd
bindkey -M viins '^[OA' atuin-up-search-viins
bindkey -M vicmd 'k' atuin-up-search-vicmd

# Lines up the columns of the picker below. Reads NUL-separated
# "age<TAB>author<TAB>directory<TAB>command" records from `atuin search` and
# writes them back with age, author and directory padded to the widest value
# in this batch, because atuin's --format has no padding. A directory longer
# than 32 characters keeps its last 30 behind "..". The tabs stay as field
# separators, so fzf's --accept-nth=4.. still returns the bare command. This
# body runs on its own under `zsh -fc` in the shell fzf starts for a reload,
# so it must not call anything else defined in this file.
#
# The input is read whole with $(cat) and split on NUL, not looped over with
# `read -d ''`. fzf runs a reload in a background process group, and zsh's
# `read -d` changes the terminal's settings, so the kernel stops the whole
# group with SIGTTOU and fzf keeps loading forever with an empty list.
_atuin_pick_format() {
    local -a recs age author dir cmd
    local input rec a d
    local -i wa=0 wd=0 dmax=32 cut i
    input=$(cat)
    recs=(${(0)input})
    for rec in "${recs[@]}"; do
        age+=("${rec%%$'\t'*}")
        rec=${rec#*$'\t'}
        a=${rec%%$'\t'*}
        rec=${rec#*$'\t'}
        d=${rec%%$'\t'*}
        cmd+=("${rec#*$'\t'}")
        d=${d/#$HOME/\~}
        if ((${#d} > dmax)); then
            ((cut = ${#d} - dmax + 2))
            d="..${d:$cut}"
        fi
        author+=("$a")
        dir+=("$d")
        ((${#a} > wa)) && wa=${#a}
        ((${#d} > wd)) && wd=${#d}
    done
    for ((i = 1; i <= ${#cmd}; i++)); do
        printf '%4s \t%-*s \t%-*s \t%s\0' "${age[i]}" $wa "${author[i]}" $wd "${dir[i]}" "${cmd[i]}"
    done
}

# Atuin's search screen leaves out commands that agents such as Claude Code
# ran, on every query, and ignores --author. Plain `atuin search` honours
# --author, so this widget lists your commands and the agents' with it and
# picks one in fzf. `/` and the up arrow keep atuin's own screen, which shows
# only your commands. `atuin search` prints oldest first, hence --tac.
#
# ctrl-r cycles the scope through global, workspace (the git repo) and
# directory, the way it cycles filter modes in atuin's own screen. The prompt
# holds the current scope, and the ctrl-r transform reads it back from
# $FZF_PROMPT. fzf runs reload and transform commands in a child shell, which
# can't see this file's functions, so the three actions and the body of
# _atuin_pick_format are passed in exported variables and used verbatim; that
# also keeps the literal '$all-user' from being expanded on the way.
#
# --tabstop=1 draws each tab as one space, so the padding from
# _atuin_pick_format decides the column positions. --nth=2.. keeps the age
# column out of matching.
_atuin_search_with_agents() {
    emulate -L zsh
    setopt pipefail
    local tab=$'\t' selected ret
    local src="atuin search --author '\$all-user' --author '\$all-agent' --print0"
    src+=" --format '{relativetime}${tab}{author}${tab}{directory}${tab}{command}'"
    local -x _ATUIN_PICK_FMT=${functions[_atuin_pick_format]}
    local mode
    for mode in global workspace directory; do
        local -x "_ATUIN_PICK_${(U)mode}=change-prompt($mode> )+reload($src --filter-mode $mode -- '' 2>/dev/null | zsh -fc \"\$_ATUIN_PICK_FMT\")"
    done
    selected=$(
        fzf --read0 --tac --scheme=history --delimiter=$'\t' --accept-nth=4.. \
            --tabstop=1 --nth=2.. \
            --preview-window=hidden --prompt='global> ' --query="$BUFFER" \
            --header='ctrl-r: scope global / workspace / directory' \
            --bind 'start:transform:printf %s "$_ATUIN_PICK_GLOBAL"' \
            --bind 'ctrl-r:transform:case $FZF_PROMPT in
                global*) printf %s "$_ATUIN_PICK_WORKSPACE" ;;
                workspace*) printf %s "$_ATUIN_PICK_DIRECTORY" ;;
                *) printf %s "$_ATUIN_PICK_GLOBAL" ;;
            esac' </dev/null
    )
    ret=$?
    if [[ -n $selected ]]; then
        RBUFFER=""
        LBUFFER=$selected
    fi
    zle reset-prompt
    return $ret
}

# ^R opens the same picker in every keymap, in place of fzf's history widget,
# which reads only zsh's own history. An empty FZF_CTRL_R_COMMAND makes
# `fzf --zsh` in fzf.zsh skip its ^R bindings, and these bindkeys still win if
# fzf.zsh is ever sourced first. Without atuin this file returns early, so fzf
# keeps ^R.
if command -v fzf >/dev/null 2>&1; then
    zle -N atuin-search-with-agents _atuin_search_with_agents
    bindkey -M vicmd '?' atuin-search-with-agents
    bindkey -M emacs '^R' atuin-search-with-agents
    bindkey -M viins '^R' atuin-search-with-agents
    bindkey -M vicmd '^R' atuin-search-with-agents
    FZF_CTRL_R_COMMAND=
fi
