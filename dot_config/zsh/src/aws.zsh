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

function aws_login() {
  local profile="$1"
  if [[ -z "$profile" ]]; then
    echo "Usage: aws_login <profile>" >&2
    return 2
  fi
  if ! command -v aws >/dev/null 2>&1; then
    echo "aws not found" >&2
    return 127
  fi
  aws --profile "$profile" login
}
