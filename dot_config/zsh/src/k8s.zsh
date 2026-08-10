# shellcheck shell=bash
# shellcheck disable=SC1091

# Callers must use `_check_gum_cmd || return 1`: on its own the call reports
# the problem but does not stop the caller from running on without gum.
source "$ZDOTDIR/src/functions.zsh"

function k() {
  local ctx="${CONTEXT:-${KUBE_CONTEXT:-}}"
  local ns="${NAMESPACE:-default}"
  local cmd=(kubectl)
  [[ -n "$ctx" ]] && cmd+=(--context "$ctx")
  cmd+=(-n "$ns" "$@")

  if [[ -t 2 ]]; then tput setaf 3; fi
  printf '%s\n' "\$ ${cmd[*]}" >&2
  if [[ -t 2 ]]; then tput sgr0; fi

  command "${cmd[@]}"
}

# The context k() would actually use, following the same precedence it does.
# Both pickers list against this rather than against the kubeconfig's
# current-context, so what you are choosing from matches what you will hit.
function _k8s_effective_context() {
  print -r -- "${CONTEXT:-${KUBE_CONTEXT:-}}"
}

# Choose the kube context for this shell. Exported rather than written to the
# kubeconfig with `use-context`, so two terminals can sit on two clusters
# without fighting over a shared file.
function kctx() {
  _check_gum_cmd || return 1

  command -v kubectl > /dev/null 2>&1 || {
    echo "kubectl not found" >&2
    return 127
  }

  local ctx
  ctx=$(kubectl config get-contexts -o name \
    | gum filter --header="Which context?" --placeholder="context") || return
  [[ -n "$ctx" ]] || return 1

  export KUBE_CONTEXT="$ctx"

  # k() reads CONTEXT first, so leaving a stale CONTEXT behind would point every
  # later command at the old cluster while this picker reported success. CONTEXT
  # names the same thing, so move it onto the pick rather than let the pick be
  # decorative - but say so, because something outside this function set it.
  if [[ -n "${CONTEXT:-}" && "$CONTEXT" != "$ctx" ]]; then
    gum log --level warn "CONTEXT took precedence and was moved too" \
      from "$CONTEXT" to "$ctx"
    export CONTEXT="$ctx"
  fi

  gum log --level info "context" "$ctx"
}

# Choose the namespace for this shell, listed from the context in effect.
function kns() {
  _check_gum_cmd || return 1

  command -v kubectl > /dev/null 2>&1 || {
    echo "kubectl not found" >&2
    return 127
  }

  local ns out ctx
  local -a ctx_args
  ctx=$(_k8s_effective_context)
  [[ -n "$ctx" ]] && ctx_args=(--context "$ctx")

  # Listing namespaces is a network round trip, and on a slow VPN the spinner
  # is the difference between "thinking" and "hung".
  out=$(gum spin --spinner=minidot --show-error \
    --title="Listing namespaces${ctx:+ on $ctx}..." -- \
    kubectl "${ctx_args[@]}" get namespace \
    -o custom-columns=NAME:.metadata.name --no-headers) || return 1

  ns=$(printf '%s\n' "$out" \
    | gum filter --header="Which namespace?" --placeholder="namespace") || return
  [[ -n "$ns" ]] || return 1

  export NAMESPACE="$ns"
  gum log --level info "namespace" "$ns"
}
