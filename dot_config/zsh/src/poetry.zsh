#!/usr/bin/env zsh
# vim: filetype=zsh

# activate_poetry_env calls _check_fzf_cmd from functions.zsh, which init.zsh
# sources before this file.

# Poetry's virtualenvs dir, worked out the way Poetry does instead of asked of
# `poetry config`, which costs as much as `poetry env info` itself.
# virtualenvs.path in Poetry's config.toml is not read: no machine sets it.
function _poetry_venvs_dir() {
  if [[ -n ${POETRY_VIRTUALENVS_PATH:-} ]]; then
    print -r -- "$POETRY_VIRTUALENVS_PATH"
  elif [[ -n ${POETRY_CACHE_DIR:-} ]]; then
    print -r -- "$POETRY_CACHE_DIR/virtualenvs"
  elif [[ $OSTYPE == darwin* ]]; then
    print -r -- "$HOME/Library/Caches/pypoetry/virtualenvs"
  else
    print -r -- "${XDG_CACHE_HOME:-$HOME/.cache}/pypoetry/virtualenvs"
  fi
}

# The picker's rows for activate_poetry_env: $reply gets "<display>\t<path>"
# per env, the project's own one first and marked *, and $REPLY the fzf header.
# The envs are those in Poetry's virtualenvs dir, then every in-project .venv
# beside a pyproject.toml the scan below finds - where Poetry creates new envs
# now that dot_config/pypoetry sets in-project = true.
#
# Poetry is not run. Its rules are followed instead (EnvManager.get in
# poetry/utils/env/env_manager.py): the project is the nearest pyproject.toml
# upward, and its env is <root>/.venv when that is a directory, else
# <name>-<hash>-py<X.Y> in the virtualenvs dir. <hash> is the first 8
# characters of the urlsafe base64 SHA-256 of the root's real path; X.Y is the
# envs.toml pin (`poetry env use`), or else the version of the first `python`
# on PATH - run from here, so asdf's .tool-versions has its say, as it does
# for Poetry. One deliberate difference: with no pin, Poetry hands back
# whatever venv is already active, which made the `poetry env info` version of
# this re-activate the previous project's env. The active venv's bin is left
# out of PATH for the lookup instead.
#
# A cached env's name holds only a hash of its project's path, so those rows
# are labelled by hashing every project root under POETRY_ENV_SCAN_DIRS
# (default ~/workspace) and matching; the same roots are where the .venvs are
# looked for. All of the hashing, the TOML and pyvenv.cfg reading and the
# version check happen in one python call.
function _poetry_env_rows() {
  local venvs_dir root py d raw base minor star mark name label line
  local -a lookup_path scan_dirs out fields envs in_project names labels
  local -A owner venv_minor
  local -i width=0 i

  # tomllib is 3.11+; an older python just leaves the project unrecognised.
  local script='
import base64, hashlib, os, re, sys

def env_hash(d):
    d = os.path.normcase(os.path.realpath(d))
    return base64.urlsafe_b64encode(hashlib.sha256(d.encode()).digest()).decode()[:8]

def load(p):
    try:
        with open(p, "rb") as f:
            return tomllib.load(f)
    except (OSError, ValueError):
        return {}

# X.Y from pyvenv.cfg: virtualenv (what Poetry and uv use) writes version_info,
# the stdlib venv module writes version.
def venv_minor(venv):
    try:
        with open(os.path.join(venv, "pyvenv.cfg")) as f:
            cfg = {k.strip(): v.strip() for k, _, v in (l.partition("=") for l in f)}
    except OSError:
        return ""
    return ".".join((cfg.get("version_info") or cfg.get("version") or "").split(".")[:2])

try:
    import tomllib
except ImportError:
    tomllib = None

# Real paths throughout: fd reports roots as the scan dir spells them, while
# root arrives resolved, and one project reached both ways must stay one row.
venvs, root = sys.argv[1:]
scan = {os.path.realpath(os.path.dirname(p)) for p in sys.stdin.read().splitlines() if p}
if root:
    scan.add(root)
base, minor = "", "%d.%d" % sys.version_info[:2]
if root and tomllib:
    doc = load(os.path.join(root, "pyproject.toml"))
    name = (doc.get("project", {}).get("name")
            or doc.get("tool", {}).get("poetry", {}).get("name")
            or "non-package-mode")
    name = re.sub(r"[-_.]+", "-", name).lower()
    base = re.sub(r"[ $`!*@\"\\\r\n\t]", "_", name)[:42] + "-" + env_hash(root)
    minor = load(os.path.join(venvs, "envs.toml")).get(base, {}).get("minor", minor)
print(base)
print(minor)
for d in sorted(scan):
    print("L\t" + env_hash(d) + "\t" + d)
    venv = os.path.join(d, ".venv")
    if os.path.isdir(venv):
        print("V\t" + venv + "\t" + venv_minor(venv))
'

  venvs_dir=$(_poetry_venvs_dir)

  # Poetry climbs from the physical cwd, hence :A before walking up.
  root=${PWD:A}
  until [[ -f $root/pyproject.toml ]]; do
    [[ $root == / ]] && {
      root=''
      break
    }
    root=${root:h}
  done

  lookup_path=($path)
  [[ -n ${VIRTUAL_ENV:-} ]] && lookup_path=(${lookup_path:#$VIRTUAL_ENV/bin})
  for d in $lookup_path; do
    [[ -f $d/python && -x $d/python ]] && {
      py=$d/python
      break
    }
  done

  # fd feeds python through a pipe rather than an argument list so that the
  # two overlap: python starts up (~30ms through the asdf shim) while fd scans.
  for d in ${POETRY_ENV_SCAN_DIRS:-$HOME/workspace}; do
    [[ -d $d ]] && scan_dirs+=($d)
  done
  if [[ -n $py ]] && raw=$(
    { (($#scan_dirs && $+commands[fd])) && fd -t f -d 5 '^pyproject\.toml$' $scan_dirs; } \
      | "$py" -c "$script" "$venvs_dir" "$root" 2> /dev/null
  ); then
    out=("${(@f)raw}")
  fi
  # The rest is "L\t<hash>\t<root>" per project root, each followed by
  # "V\t<root>/.venv\t<X.Y>" when it has an in-project env.
  base=${out[1]:-} minor=${out[2]:-}
  for line in ${out[3,-1]}; do
    fields=("${(@ps:\t:)line}")
    case $fields[1] in
      L) owner[$fields[2]]=$fields[3] ;;
      V)
        in_project+=($fields[2])
        venv_minor[$fields[2]]=$fields[3]
        ;;
    esac
  done

  if [[ -n $root && ${(L)POETRY_VIRTUALENVS_IN_PROJECT:-} != (false|0) && -d $root/.venv ]]; then
    star=$root/.venv
  elif [[ -n $base && -d $venvs_dir/$base-py$minor ]]; then
    star=$venvs_dir/$base-py$minor
  fi

  envs=($venvs_dir/*(N/) $in_project)
  [[ -n $star ]] && envs=($star ${envs:#$star})

  # Every .venv has the same name, so it shows its version the way a cached
  # env's name does, and its project comes straight from its parent dir.
  for d in $envs; do
    if [[ ${d:t} == .venv ]]; then
      name=".venv${venv_minor[$d]:+ (py${venv_minor[$d]})}"
      label=${d:h}
    else
      # <name>-<hash>-py<X.Y>; the shortest -py* suffix is the version.
      line=${${d:t}%-py*}
      name=${d:t}
      label=${owner[${line[-8,-1]}]:-}
    fi
    names+=("$name")
    labels+=("$label")
    ((${#name} > width)) && width=${#name}
  done

  reply=()
  for ((i = 1; i <= $#envs; i++)); do
    mark=' '
    [[ ${envs[i]} == "$star" ]] && mark='*'
    printf -v line '%s %-*s  %s\t%s' "$mark" $width "${names[i]}" "${labels[i]:+${(D)labels[i]}}" "${envs[i]}"
    reply+=("$line")
  done

  if [[ -z $root ]]; then
    REPLY="no pyproject.toml above ${(D)PWD}"
  elif [[ -n $star ]]; then
    REPLY="* ${(D)root}"
  elif [[ -z $py ]]; then
    REPLY="${(D)root}: no python on PATH to tell which env is its"
  elif [[ -z $base ]]; then
    REPLY="${(D)root}: could not work out its env name (python >= 3.11 needed)"
  else
    REPLY="${(D)root} has no env yet: run poetry install"
  fi
  [[ -n ${VIRTUAL_ENV:-} ]] && REPLY+="  ·  active: ${VIRTUAL_ENV:t}"
  return 0
}

# activate_poetry_env [query]
#
# Pick any Poetry env - cached, or any project's in-project .venv - and activate
# it, wherever you are. The env the project here uses is marked * and comes
# first, so Enter alone activates it, in ~50ms rather than the ~1s `poetry env
# info` took. A query pre-fills the search and activates a lone match without
# asking. Ctrl-/ shows the env's pyvenv.cfg.
function activate_poetry_env() {
  _check_fzf_cmd || return 1

  local query=${1:-} pick venvs_dir

  _poetry_env_rows
  ((${#reply})) || {
    venvs_dir=$(_poetry_venvs_dir)
    print -u2 "activate_poetry_env: no Poetry envs in ${(D)venvs_dir}, and no .venv beside a pyproject.toml"
    return 1
  }

  # The rows are "<display>\t<path>": only the display is shown and searched,
  # and fzf's {2} is still the path.
  pick=$(print -rl -- $reply | fzf \
    --delimiter=$'\t' \
    --with-nth=1 \
    --no-multi \
    --prompt='poetry env> ' \
    --header="$REPLY" \
    --query="$query" \
    ${query:+--select-1} \
    --exit-0 \
    --preview='cat -- {2}/pyvenv.cfg' \
    --preview-window=hidden) || return
  pick=${pick#*$'\t'}

  [[ -r $pick/bin/activate ]] || {
    print -u2 "activate_poetry_env: ${(D)pick} has no bin/activate"
    return 1
  }

  source "$pick/bin/activate"
  print -r -- "Activated Poetry venv from ${(D)pick}"
}

function deactivate_poetry_env() {
  if [[ -z "$VIRTUAL_ENV" ]]; then
    echo "No Poetry venv is currently active."
    return 1
  fi

  local venv_path="$VIRTUAL_ENV"
  export PATH="$(echo "$PATH" | sed "s#$venv_path/bin:##")"
  unset VIRTUAL_ENV

  if type deactivate &> /dev/null; then
    deactivate 2> /dev/null
  fi

  echo "Deactivated Poetry venv ← $venv_path"
}
