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
# Escape fnmatch(3) metacharacters so a literal path can be used as a find
# -lname pattern.
fnmatch_escape() {
  printf '%s' "$1" | sed 's/[][\\*?]/\\&/g'
}

# Record the clone referenced by each consumer symlink in the caller's
# `referenced` array. "named" is the inverted fast path: patterns are built from
# store entries, so only links whose stored target names a clone are
# canonicalized. "all" resolves every link and is the safety fallback for any
# candidate that the fast path could not confirm.
scan_consumer_links() {
  local mode="$1" candidate name escaped_candidate escaped_name
  local consumer_root canonical link resolved unresolved relative clone
  local -a match=()

  if [[ "$mode" == named ]]; then
    match=(-false)
    for candidate in "${candidates[@]}"; do
      name=$(basename -- "$candidate")
      escaped_candidate=$(fnmatch_escape "$candidate")
      escaped_name=$(fnmatch_escape "$name")
      match+=(
        -o -lname "$escaped_candidate"
        -o -lname "$escaped_candidate/*"
        -o -lname "*$escaped_name"
        -o -lname "*$escaped_name/*"
      )
    done
  fi

  for consumer_root in "${roots[@]}"; do
    log_info "Scanning ($mode): $consumer_root"
    canonical=$(realpath -e -- "$consumer_root") || return 2
    if [[ "$mode" == named ]]; then
      if ! find "$canonical" -path "$root" -prune -o -type l \
        \( "${match[@]}" \) -print0 > "$workdir/links"; then
        log_err "incomplete consumer scan; refusing to prune: $consumer_root"
        return 2
      fi
    elif ! find "$canonical" -path "$root" -prune -o -type l -print0 > "$workdir/links"; then
      log_err "incomplete consumer scan; refusing to prune: $consumer_root"
      return 2
    fi
    while IFS= read -r -d '' link; do
      resolved=$(realpath -m -- "$link") || {
        log_err "cannot resolve consumer link; refusing to prune: $link"
        return 2
      }
      # An unresolved component means the link may still point into the store.
      unresolved=$resolved
      while [[ -n "$unresolved" && "$unresolved" != / ]]; do
        if [[ -L "$unresolved" ]]; then
          log_err "unresolved consumer symlink; refusing to prune: $link"
          return 2
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
}
