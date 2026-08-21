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

# Walk from profile to object entirely through pickers - gum for the profile
# and the s3:// path, fzf for the object - then dump that object to stdout.
#
#   aws_fetch_blob
#   aws_fetch_blob | jq .          # stdout stays clean, both pickers use the tty
#   aws_fetch_blob --pbcopy        # object goes to the clipboard, not stdout
#
# The typed path decides what happens next: a prefix opens the fzf list of
# everything under it, while a path that names an object is fetched straight
# away. Every step is a prompt. Picking the key from a live listing means it is
# byte-exact, so the NFC/NFD retry the old fetch-blob script needed is gone.
function aws_fetch_blob() {
  local to_clipboard=0
  while (($#)); do
    case "$1" in
      --pbcopy)
        to_clipboard=1
        shift
        ;;
      *)
        echo "Usage: aws_fetch_blob [--pbcopy]   (every other step is a prompt)" >&2
        return 2
        ;;
    esac
  done

  _check_fzf_cmd || return 1
  _check_gum_cmd || return 1

  if ((to_clipboard)) && ! command -v pbcopy > /dev/null 2>&1; then
    echo "aws_fetch_blob --pbcopy requires 'pbcopy'." >&2
    return 127
  fi

  local profile
  profile=$(_aws_choose_profile "" "Fetch from which AWS profile?") || return $?

  # One prompt carries both the bucket and the path, so this is where a pasted
  # s3:// URL goes - a prefix to search or a full object key to fetch outright.
  local location
  location=$(gum input \
    --header="s3://bucket/prefix or s3://bucket/key" \
    --placeholder="s3://my-bucket/path/to/objects/") || return 1

  # Cancelling out of gum, or submitting nothing, leaves this empty.
  [[ -n "$location" ]] || return 1

  # The scheme is optional so a bare `bucket/prefix` paste works too. Split on
  # the first slash: bucket before it, prefix after (empty for a bare bucket).
  location="${location#s3://}"
  local bucket="${location%%/*}"
  local prefix=""
  [[ "$location" == */* ]] && prefix="${location#*/}"

  if [[ -z "$bucket" ]]; then
    echo "Error: no bucket in that path." >&2
    return 2
  fi

  echo "Looking up s3://$bucket/$prefix ..." >&2

  # list-objects-v2 has no delimiter here, so this walks the whole subtree, and
  # the CLI's built-in pagination keeps going past 1000 keys. `Contents[].[Key]`
  # wraps each key in its own row so --output text emits one key per line
  # instead of a single tab-joined blob - keys with spaces survive that.
  local -a keys
  keys=(${(f)"$(aws s3api list-objects-v2 \
    --profile "$profile" \
    --bucket "$bucket" \
    --prefix "$prefix" \
    --query 'Contents[].[Key]' \
    --output text)"}) || return 1

  # A prefix that matches nothing yields the literal string "None".
  if ((${#keys} == 0)) || [[ ${#keys} -eq 1 && "${keys[1]}" == "None" ]]; then
    echo "No objects under s3://$bucket/$prefix" >&2
    return 1
  fi

  local key=""

  # If what was typed is itself one of the returned keys then it names an
  # object, not a prefix, so skip the picker and fetch it. A trailing slash is
  # always treated as a prefix: consoles create 0-byte `folder/` marker
  # objects, and matching one of those would fetch nothing instead of listing
  # what is inside. (Ie) is an exact-string index lookup, 0 when absent.
  if [[ -n "$prefix" && "$prefix" != */ ]] && ((${keys[(Ie)$prefix]})); then
    key="$prefix"
    echo "Exact object, fetching s3://$bucket/$key" >&2
  else
    # fzf draws on the tty rather than stdout, so only the picked key is
    # captured. --no-preview overrides the FZF_DEFAULT_OPTS preview, which
    # would otherwise try to bat these keys as local paths.
    key=$(printf '%s\n' "${keys[@]}" \
      | fzf --no-preview \
        --prompt="s3://$bucket/ > " \
        --header="${#keys} objects under ${prefix:-/}") || return 1

    # Cancelling out of fzf leaves this empty.
    [[ -n "$key" ]] || return 1
  fi

  if ((to_clipboard)); then
    # Staging in a temp file rather than piping into pbcopy means a failed
    # download cannot wipe the clipboard with an empty string, and it keeps the
    # object's bytes exactly as stored. --only-show-errors suppresses the
    # progress line cp would otherwise write.
    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/aws_fetch_blob.XXXXXX") || return 1

    if ! aws s3 cp --only-show-errors \
      --profile "$profile" "s3://$bucket/$key" "$tmp"; then
      rm -f -- "$tmp"
      return 1
    fi

    pbcopy < "$tmp"
    local rc=$?
    rm -f -- "$tmp"

    ((rc == 0)) && echo "Copied s3://$bucket/$key to the clipboard." >&2
    return $rc
  fi

  aws s3 cp --profile "$profile" "s3://$bucket/$key" -
}
