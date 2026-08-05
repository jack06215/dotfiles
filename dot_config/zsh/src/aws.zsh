# function aws_login() {
#   local profile="$1"
#   if [[ -z "$profile" ]]; then
#     echo "Usage: aws_login <profile>" >&2
#     return 2
#   fi
#   if ! command -v aws-azure-login >/dev/null 2>&1; then
#     echo "aws-azure-login not found" >&2
#     return 127
#   fi
#   az2aws --profile "$profile" --no-prompt && export AWS_PROFILE="$profile"
# }

source "$ZDOTDIR/src/functions.zsh"

# Print the profile to act on: <profile> when one is passed in, otherwise one
# picked from the configured profiles. <header> labels the picker. Returns
# non-zero when there is nothing to pick or the picker is cancelled, so callers
# should use `profile=$(_aws_choose_profile ...) || return $?`.
function _aws_choose_profile() {
  local profile="$1"
  local header="${2:-Which AWS profile?}"

  if ! command -v aws > /dev/null 2>&1; then
    echo "aws not found" >&2
    return 127
  fi

  if [[ -n "$profile" ]]; then
    print -r -- "$profile"
    return 0
  fi

  _check_gum_cmd || return 1

  local -a profiles
  profiles=(${(f)"$(aws configure list-profiles 2> /dev/null)"})

  if ((${#profiles} == 0)); then
    echo "No AWS profiles configured." >&2
    return 1
  fi

  # gum draws its menu on stderr, so the pick is all that lands on stdout.
  profile=$(printf '%s\n' "${profiles[@]}" \
    | gum choose --height=12 --header="$header") || return 1

  # Cancelling out of gum leaves this empty.
  [[ -n "$profile" ]] || return 1

  print -r -- "$profile"
}

function aws_login() {
  local profile
  profile=$(_aws_choose_profile "$1" "Log in to which AWS profile?") || return $?

  aws login --profile "$profile"
}

function aws_get_caller_identity() {
  local profile
  profile=$(_aws_choose_profile "$1" "Whoami on which AWS profile?") || return $?

  aws sts get-caller-identity --query Arn --output text --profile "$profile"
}
