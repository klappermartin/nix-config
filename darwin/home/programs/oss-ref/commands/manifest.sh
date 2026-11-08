cmd_manifest() (
  local mode="$1"
  shift
  [[ $# -le 1 && "${1:-}" != -* ]] || {
    log_err "usage: oss-ref $mode [manifest]"; exit 2;
  }
  local manifest project entries
  manifest=$(realpath -e -- "${1:-.oss-references.json}") || {
    log_err "manifest not found: ${1:-.oss-references.json}"; exit 2;
  }
  project=$(dirname -- "$manifest")
  # Reject typos, control characters and escaping paths before making any changes.
  entries=$(jq -er '
    def text: type == "string" and length > 0 and (test("[\\x00-\\x1f\\x7f]") | not);
    def entry:
      type == "object" and keys == ["package", "path", "ref", "repository"] and
      all(.[]; text) and
      (.package | test("^(@[a-z0-9][a-z0-9._-]*/)?[a-z0-9][a-z0-9._-]*$")) and
      (.ref | contains("{version}")) and
      (.path | test("^/|(^|/)\\.\\.(/|$)") | not);
    if type == "object" and keys == ["references"] and
       (.references | type == "object" and length > 0 and
         all(to_entries[]; (.key | text) and (.value | entry)))
    then .references | to_entries[] |
      [.key, .value.package, .value.repository, .value.ref, .value.path] | join("\t")
    else error("expected references with package, repository, ref containing {version}, and a relative path")
    end
  ' "$manifest") || { log_err "invalid manifest: $manifest"; exit 2; }

  local -a names=() versions=() urls=() refs=() destinations=()
  local name package url template path version ref destination parent previous
  while IFS=$'\t' read -r name package url template path; do
    version=$(installed_version "$project" "$package") || {
      log_err "$name: cannot read installed version of $package; install dependencies first"; exit 1;
    }
    ref=${template//\{version\}/$version}
    git check-ref-format "refs/tags/$ref" >/dev/null || {
      log_err "$name: invalid Git ref: $ref"; exit 2;
    }
    # Resolve intermediate symlinks but not the final reference symlink.
    parent=$(realpath -m -- "$project/$(dirname -- "$path")")
    destination="$parent/$(basename -- "$path")"
    [[ "$destination" == "$project/"* && "$(basename -- "$path")" != . ]] || {
      log_err "$name: reference path must stay inside the project: $path"; exit 2;
    }
    for previous in "${destinations[@]}"; do
      [[ "$destination" != "$previous" && "$destination" != "$previous/"* &&
         "$previous" != "$destination/"* ]] || {
        log_err "$name: overlapping reference paths: $path"; exit 2;
      }
    done
    names+=("$name")
    versions+=("$version")
    urls+=("$url")
    refs+=("$ref")
    destinations+=("$destination")
  done <<< "$entries"

  local index failed=0
  for index in "${!names[@]}"; do
    name=${names[$index]}
    version=${versions[$index]}
    url=${urls[$index]}
    ref=${refs[$index]}
    destination=${destinations[$index]}
    if [[ "$mode" == sync ]]; then
      echo "Syncing $name: installed $version -> $ref"
      # Keep add's locking, origin/version validation and consumer-scope checks.
      cmd_add "$url" "$ref" "$destination"
    fi
    if reference_matches "$url" "$ref" "$destination" 2>/dev/null; then
      echo "OK $name: installed $version -> $ref"
    else
      log_err "STALE $name: installed $version expects $ref at $destination"
      failed=1
    fi
  done
  if [[ "$failed" -ne 0 ]]; then
    log_err "Run oss-ref sync to refresh missing/stale links; inspect conflicting or modified checkouts before retrying."
  fi
  exit "$failed"
)
