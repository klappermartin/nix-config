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
