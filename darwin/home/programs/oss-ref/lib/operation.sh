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
