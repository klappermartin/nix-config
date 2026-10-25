#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly ROOT="${OSS_REFERENCES_ROOT:-$HOME/code/others/oss-references}"
readonly CONSUMER_ROOTS="${OSS_REFERENCES_CONSUMER_ROOTS:-$HOME/code}"

# Operations share a lock so add cannot publish a clone while prune scans.
# A lock left by SIGKILL must be inspected and removed manually, never timed out.
begin_operation() {
  mkdir -p "$ROOT"
  root=$(realpath -e -- "$ROOT")
  lock_dir="$root/.lock"
  if ! mkdir "$lock_dir" 2>/dev/null; then
    log_err "another operation is running (or left a stale lock): $lock_dir"
    return 1
  fi
  workdir=""
  trap '[[ -z "$workdir" ]] || rm -rf -- "$workdir"; rm -f -- "$lock_dir/pid"; rmdir -- "$lock_dir"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  printf '%s\n' "$$" > "$lock_dir/pid"
  mkdir -p "$root/.partial"
  workdir=$(mktemp -d "$root/.partial/operation.XXXXXX")
}

consumer_roots() {
  local consumer canonical
  roots=()
  # read avoids pathname expansion and preserves spaces in root names.
  if [[ "$CONSUMER_ROOTS" == :* || "$CONSUMER_ROOTS" == *: || "$CONSUMER_ROOTS" == *::* ]]; then
    log_err "consumer roots must not contain empty entries"
    return 1
  fi
  IFS=: read -r -a roots <<< "$CONSUMER_ROOTS"
  [[ ${#roots[@]} -gt 0 ]] || { log_err "no consumer roots configured"; return 1; }
  for consumer in "${roots[@]}"; do
    [[ -d "$consumer" && -r "$consumer" && -x "$consumer" ]] || {
      log_err "consumer root is missing or unreadable: $consumer"
      return 1
    }
    canonical=$(realpath -e -- "$consumer") || return 1
    [[ "$canonical" != "$root" && "$canonical" != "$root/"* ]] || {
      log_err "consumer roots must be outside the references store: $consumer"
      return 1
    }
  done
}

sanitize_version() {
  echo "$1" | tr '/' '-' | tr -cs 'A-Za-z0-9._+-' '-' | sed -E 's/-+/-/g; s/^-|-$//g'
}

derive_slug() {
  basename "$1" .git
}

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

cmd_help() {
  cat <<'HELP'
Usage: oss-ref <subcommand> [args]

Subcommands:
  add <git-url> <version> <symlink-path>   Clone <git-url>@<version> under the references root and symlink from <symlink-path>.
  prune [--yes|--dry-run] [--min-age <dur>] [-v]   Remove reference clones with no incoming symlinks under configured consumer roots.
  list                                            List all versioned clones under the references root.
  help                                            Show this message.

Environment:
  OSS_REFERENCES_ROOT          Root directory for clones. Default: $HOME/code/others/oss-references
  OSS_REFERENCES_CONSUMER_ROOTS Colon-separated roots the pruner scans for incoming symlinks. Default: $HOME/code
HELP
}

cmd_list() {
  find "$ROOT" -mindepth 1 -maxdepth 1 -type d -name '*@*' -exec basename {} \; 2>/dev/null | sort
}

cmd_add() (
  [[ $# -eq 3 ]] || { log_err "usage: oss-ref add <git-url> <version> <symlink-path>"; exit 2; }
  local url="$1" version="$2" symlink_path="$3"

  local root lock_dir workdir
  begin_operation
  local -a roots
  consumer_roots

  # Resolve the parent, not the final symlink (which may already point at a clone).
  local parent destination consumer canonical in_scope=0
  parent=$(realpath -m -- "$(dirname -- "$symlink_path")")
  destination="$parent/$(basename -- "$symlink_path")"
  for consumer in "${roots[@]}"; do
    canonical=$(realpath -e -- "$consumer")
    if [[ "$parent" == "$canonical" || "$parent" == "$canonical/"* ]]; then
      # find does not descend through intermediate directory symlinks. Require
      # the lexical path inside this root to match the resolved path as well.
      local lexical
      lexical=$(realpath -ms -- "$symlink_path")
      if [[ "$lexical" == "$destination" ]]; then in_scope=1; fi
    fi
  done
  if [[ $in_scope -eq 0 || "$destination" == "$root" || "$destination" == "$root/"* ]]; then
    log_err "consumer must be a discoverable path under a configured consumer root: $symlink_path"
    exit 1
  fi
  if [[ -e "$destination" && ! -L "$destination" ]]; then
    log_err "refusing to replace a real file or directory: $destination"
    exit 1
  fi

  local slug version_safe target
  slug=$(derive_slug "$url")
  version_safe=$(sanitize_version "$version")
  [[ -n "$slug" && -n "$version_safe" && "$version" != -* ]] || {
    log_err "invalid repository slug or version"; exit 2;
  }
  target="$root/$slug@$version_safe"

  if [[ -e "$target" || -L "$target" ]]; then
    local origin expected actual recorded_version
    origin=$(git -C "$target" config --get remote.origin.url) || exit 1
    expected=$(git -C "$target" rev-parse --verify "$version^{commit}") || exit 1
    actual=$(git -C "$target" rev-parse HEAD) || exit 1
    recorded_version=$(git -C "$target" config --get oss-ref.version || true)
    if [[ -L "$target" || "$origin" != "$url" || "$expected" != "$actual" ||
          ( -n "$recorded_version" && "$recorded_version" != "$version" ) ]]; then
      log_err "existing clone does not match requested repository/version: $target"
      exit 1
    fi
    echo "Reusing: $target"
  else
    local staging="$workdir/clone" diagnostics="$workdir/clone.log"
    if ! git clone --depth=1 --branch "$version" -- "$url" "$staging" 2>"$diagnostics"; then
      if grep -qiE 'Remote branch .* not found|no such ref|Could not find remote branch' "$diagnostics"; then
        rm -rf -- "$staging"
        if ! git clone --filter=blob:none -- "$url" "$staging" 2>>"$diagnostics" ||
           ! git -C "$staging" checkout --detach "$version" 2>>"$diagnostics"; then
          cat "$diagnostics" >&2
          exit 1
        fi
      else
        cat "$diagnostics" >&2
        exit 1
      fi
    fi
    git -C "$staging" config oss-ref.version "$version"
    mv -T -- "$staging" "$target"
    echo "Created: $target"
  fi

  if ! mkdir -p -- "$parent" || ! ln -sfnT -- "$target" "$destination"; then
    log_err "clone retained at $target; fix the consumer path and retry add"
    exit 1
  fi
  echo "Symlink: $destination -> $target"
)

cmd_prune() (
  local assume_yes=0 dry_run=0 min_age_min=0 verbose=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes)      assume_yes=1; shift ;;
      --dry-run)  dry_run=1; shift ;;
      --min-age)
        [[ $# -ge 2 ]] || { log_err "usage: --min-age requires a value"; exit 2; }
        local age_arg="$2"; shift 2
        if [[ ! "$age_arg" =~ ^[0-9]+[dhm]$ ]]; then
          log_err "usage: --min-age format: Nd, Nh, Nm"
          exit 2
        fi
        case "$age_arg" in
          *d) min_age_min=$(( 10#${age_arg%d} * 1440 )) ;;
          *h) min_age_min=$(( 10#${age_arg%h} * 60 )) ;;
          *m) min_age_min=$(( 10#${age_arg%m} )) ;;
        esac
        ;;
      -v)         verbose=1; shift ;;
      *)          log_err "usage: oss-ref prune [--yes|--dry-run] [--min-age <dur>] [-v]"; exit 2 ;;
    esac
  done

  # Missing root is not an error
  if [[ ! -d "$ROOT" ]]; then
    echo "nothing to prune (root missing: $ROOT)"
    exit 0
  fi

  local root lock_dir workdir
  begin_operation
  local -a candidates=() roots=() eligible=()
  consumer_roots
  # Check find's status before consuming its output: process substitution hides errors.
  find "$root" -mindepth 1 -maxdepth 1 -type d -name '*@*' -print0 > "$workdir/candidates"
  mapfile -d '' -t candidates < "$workdir/candidates"

  # Non-tty guard: refuse interactive prompt on non-tty stdin
  if [[ $dry_run -eq 0 && $assume_yes -eq 0 && ! -t 0 ]]; then
    log_err "refusing to prompt on non-tty; pass --yes or --dry-run"
    exit 2
  fi

  # A failed or incomplete scan must never be interpreted as absence of consumers.
  local -A referenced=()
  local consumer_root canonical link resolved relative clone unresolved
  for consumer_root in "${roots[@]}"; do
    log_info "Scanning: $consumer_root"
    canonical=$(realpath -e -- "$consumer_root")
    if ! find "$canonical" -path "$root" -prune -o -type l -print0 > "$workdir/links"; then
      log_err "incomplete consumer scan; refusing to prune: $consumer_root"
      exit 1
    fi
    while IFS= read -r -d '' link; do
      # -m retains broken descendant links as references too; loops/errors abort.
      resolved=$(realpath -m -- "$link") || {
        log_err "cannot resolve consumer link; refusing to prune: $link"; exit 1;
      }
      # GNU realpath -m can return success for a loop, treating its unresolved
      # components as missing. Any symlink left in the result means resolution
      # was incomplete (including loops in an intermediate path component).
      unresolved=$resolved
      while [[ -n "$unresolved" && "$unresolved" != / ]]; do
        if [[ -L "$unresolved" ]]; then
          log_err "unresolved consumer symlink; refusing to prune: $link"
          exit 1
        fi
        unresolved=${unresolved%/*}
      done
      if [[ "$resolved" == "$root/"* ]]; then
        relative=${resolved#"$root/"}
        clone=${relative%%/*}
        referenced["$root/$clone"]=1
      fi
    done < "$workdir/links"
  done

  if [[ ${#candidates[@]} -eq 0 ]]; then
    echo "nothing to prune"
    exit 0
  fi

  # Finish all discovery/stat checks before deleting anything.
  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -n "${referenced[$candidate]+x}" ]]; then
      continue  # still referenced
    fi

    # Check min-age
    if [[ "$min_age_min" -gt 0 ]]; then
      local mtime_min
      mtime_min=$(stat -c '%Y' -- "$candidate") || exit 1
      local now_s
      now_s=$(date +%s)
      local age_min=$(( (now_s - mtime_min) / 60 ))
      if [[ "$age_min" -lt "$min_age_min" ]]; then
        log_info "Keeping (too new): $(basename "$candidate")"
        continue
      fi
    fi

    eligible+=("$candidate")
  done

  local pruned=0
  for candidate in "${eligible[@]}"; do
    if [[ "$dry_run" -eq 1 ]]; then
      echo "$(basename "$candidate")  orphan"
      continue
    fi

    if [[ "$assume_yes" -eq 1 ]]; then
      rm -rf -- "$candidate"
      echo "Pruned: $(basename "$candidate")"
      pruned=$(( pruned + 1 ))
    else
      if confirm "Delete orphan $(basename "$candidate")?" 1; then
        rm -rf -- "$candidate"
        echo "Pruned: $(basename "$candidate")"
        pruned=$(( pruned + 1 ))
      fi
    fi
  done

  if [[ "$dry_run" -eq 0 && "$pruned" -eq 0 ]]; then
    echo "nothing to prune"
  fi
)

[[ "${BASH_SOURCE[0]}" == "${0}" ]] || return 0

case "${1:-}" in
  add) shift; cmd_add "$@" ;;
  prune) shift; cmd_prune "$@" ;;
  list) shift; cmd_list "$@" ;;
  help|--help|-h) cmd_help; exit 0 ;;
  '') cmd_help; exit 0 ;;
  *) log_err "usage: oss-ref <add|prune|list|help>"; exit 2 ;;
esac
