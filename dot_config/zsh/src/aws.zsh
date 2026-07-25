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

function _ensure_aws_cli_param() {
  local profile="$1"
  local cmd_name="${2:-${FUNCNAME[1]}}"
  if [[ -z "$profile" ]]; then
    echo "Usage: ${cmd_name} <profile>" >&2
    return 2
  fi
  if ! command -v aws > /dev/null 2>&1; then
    echo "aws not found" >&2
    return 127
  fi
}

function aws_login() {
  _ensure_aws_cli_param "$1" || return $?
  aws --profile "$profile" login
}

function aws_get_caller_identity() {
  _ensure_aws_cli_param "$1" || return $?
  aws sts get-caller-identity --query Arn --output text --profile "$profile"
}
