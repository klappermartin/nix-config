_log() {
  local level="$1" color="" reset=""
  shift

  if [[ -t 2 ]]; then
    reset=$'\033[0m'
    case "$level" in
      info) color=$'\033[32m' ;;
      warn) color=$'\033[33m' ;;
      error) color=$'\033[31m' ;;
    esac
  fi

  case "$level" in
    info) printf '%s[oss-ref] %s%s\n' "$color" "$*" "$reset" >&2 ;;
    warn) printf '%s[oss-ref] WARN: %s%s\n' "$color" "$*" "$reset" >&2 ;;
    error) printf '%s[oss-ref] ERROR: %s%s\n' "$color" "$*" "$reset" >&2 ;;
  esac
}

log_info() {
  [[ ${verbose:-0} -eq 1 ]] || return 0
  _log info "$*"
}

log_warn() {
  _log warn "$*"
}

log_err() {
  _log error "$*"
}

confirm() {
  local message="$1" default_no="${2:-1}" reply prompt

  [[ -t 0 ]] || return 1

  if [[ "$default_no" -eq 1 ]]; then
    prompt='[y/N]'
  else
    prompt='[Y/n]'
  fi

  printf '%s %s ' "$message" "$prompt" >&2
  IFS= read -r reply || return 1

  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    n|N|no|NO) return 1 ;;
    '') [[ "$default_no" -eq 0 ]] ;;
    *) return 1 ;;
  esac
}
