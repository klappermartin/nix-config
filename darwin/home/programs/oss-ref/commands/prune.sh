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

  if [[ ${#candidates[@]} -eq 0 ]]; then
    echo "nothing to prune"
    exit 0
  fi

  # Discovery is driven by the reference store: each candidate is checked for
  # incoming consumer links. A failed or incomplete scan must never be
  # interpreted as absence of consumers.
  local -A referenced=()
  local -a unresolved_candidates=()
  local candidate
  if ! scan_consumer_links named; then
    exit 1
  fi
  for candidate in "${candidates[@]}"; do
    [[ -n "${referenced[$candidate]+x}" ]] || unresolved_candidates+=("$candidate")
  done

  # The name filter is an optimization, not the safety boundary. Anything it
  # could not confirm gets a full canonical scan before it can be pruned.
  if [[ ${#unresolved_candidates[@]} -gt 0 ]]; then
    if ! scan_consumer_links all; then
      exit 1
    fi
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
