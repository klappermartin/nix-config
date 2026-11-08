# Read package metadata directly, including packages that do not export package.json.
# Do not execute project JavaScript or infer installed versions from semver ranges.
installed_version() {
  local directory="$1" package="$2" metadata
  while :; do
    metadata="$directory/node_modules/$package/package.json"
    if [[ -f "$metadata" ]]; then
      jq -er --arg package "$package" '
        select(.name == $package) | .version |
        select(type == "string") |
        select(test("^[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.-]+)?(\\+[0-9A-Za-z.-]+)?$"))
      ' "$metadata"
      return
    fi
    [[ "$directory" != / ]] || break
    directory=$(dirname -- "$directory")
  done
  return 1
}

reference_matches() {
  local url="$1" ref="$2" destination="$3" target origin expected actual recorded
  target="$(realpath -m -- "$ROOT")/$(derive_slug "$url")@$(sanitize_version "$ref")"
  [[ -L "$destination" && -d "$target" && ! -L "$target" ]] || return 1
  [[ "$(realpath -e -- "$destination")" == "$target" ]] || return 1
  [[ -d "$target/.git" ]] || return 1
  origin=$(git -C "$target" config --get remote.origin.url) || return 1
  expected=$(git -C "$target" rev-parse --verify "$ref^{commit}") || return 1
  actual=$(git -C "$target" rev-parse HEAD) || return 1
  recorded=$(git -C "$target" config --get oss-ref.version || true)
  [[ "$origin" == "$url" && "$expected" == "$actual" &&
     ( -z "$recorded" || "$recorded" == "$ref" ) ]] || return 1
  # A correct HEAD with edited tracked files is not a version-matched reference.
  local changes
  changes=$(git --no-optional-locks -C "$target" status --porcelain --untracked-files=no) || return 1
  [[ -z "$changes" ]]
}
