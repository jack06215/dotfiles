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
