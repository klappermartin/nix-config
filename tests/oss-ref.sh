#!/usr/bin/env bash
set -euo pipefail

scratch=$(mktemp -d "${TMPDIR:-/tmp}/oss-ref-test.XXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
source_root=$(realpath -e -- "${OSS_REF_SOURCE_ROOT:-$(dirname -- "$0")/..}")

if [[ $# -gt 0 ]]; then
  script=$(realpath -e -- "$1")
else
  script="$scratch/oss-ref.sh"
  cat \
    "$source_root/darwin/home/programs/oss-ref/lib/config.sh" \
    "$source_root/darwin/home/programs/oss-ref/lib/log.sh" \
    "$source_root/darwin/home/programs/oss-ref/lib/paths.sh" \
    "$source_root/darwin/home/programs/oss-ref/lib/operation.sh" \
    "$source_root/darwin/home/programs/oss-ref/lib/consumers.sh" \
    "$source_root/darwin/home/programs/oss-ref/lib/git.sh" \
    "$source_root/darwin/home/programs/oss-ref/commands/list.sh" \
    "$source_root/darwin/home/programs/oss-ref/commands/add.sh" \
    "$source_root/darwin/home/programs/oss-ref/commands/manifest.sh" \
    "$source_root/darwin/home/programs/oss-ref/commands/prune.sh" \
    "$source_root/darwin/home/programs/oss-ref/main.sh" > "$script"
fi
export HOME="$scratch/home"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_TERMINAL_PROMPT=0
export OSS_REFERENCES_ROOT="$scratch/store"
export OSS_REFERENCES_CONSUMER_ROOTS="$scratch/projects"
mkdir -p "$HOME" "$scratch/projects/app with spaces/node_modules/@fixture/library"
project="$scratch/projects/app with spaces"
upstream="$scratch/upstream"
manifest="$project/.oss-references.json"
metadata="$project/node_modules/@fixture/library/package.json"

fail() { echo "FAIL: $*" >&2; exit 1; }
expect_failure() {
  local expected=$1 status=0
  shift
  "$@" > "$scratch/failure.log" 2>&1 || status=$?
  if [[ "$status" -ne "$expected" ]]; then
    cat "$scratch/failure.log" >&2
    fail "expected exit $expected, got $status: $*"
  fi
}
run() { bash "$script" "$@"; }
installed() {
  jq -n --arg version "$1" '{name: "@fixture/library", version: $version}' > "$metadata"
}
write_manifest() {
  jq -n --arg repository "$upstream" '{references: {
    library: {package: "@fixture/library", repository: $repository,
      ref: "library@{version}", path: "repos/library"}
  }}' > "$manifest"
}

git init -q "$upstream"
git -C "$upstream" config user.email test@example.invalid
git -C "$upstream" config user.name Test
git -C "$upstream" config commit.gpgsign false
echo first > "$upstream/source.txt"
git -C "$upstream" add source.txt
git -C "$upstream" commit -qm first
git -C "$upstream" tag library@1.0.0
echo second > "$upstream/source.txt"
git -C "$upstream" commit -qam second
git -C "$upstream" tag library@1.1.0
installed 1.0.0
write_manifest

# check is read-only, even when the references store does not exist.
expect_failure 1 run check "$manifest"
[[ ! -e "$OSS_REFERENCES_ROOT" ]] || fail "check created the store"
run sync "$manifest"
run check "$manifest"
old_target=$(realpath -e "$project/repos/library")
[[ "$(cat "$project/repos/library/source.txt")" == first ]] || fail "wrong initial version"

# Same-version sync reuses the checkout and the default manifest works from cwd.
(cd "$project"; run sync; run check)
[[ "$(realpath -e "$project/repos/library")" == "$old_target" ]] || fail "sync was not idempotent"
mkdir -p "$scratch/projects/other/repos"
ln -s "$old_target" "$scratch/projects/other/repos/library"

# An installed-version change is detected; sync preserves another project's pin.
installed 1.1.0
expect_failure 1 run check "$manifest"
grep -q 'STALE library: installed 1.1.0' "$scratch/failure.log"
run sync "$manifest"
run check "$manifest"
new_target=$(realpath -e "$project/repos/library")
[[ "$new_target" != "$old_target" ]] || fail "upgrade did not repoint the link"
[[ "$(cat "$project/repos/library/source.txt")" == second ]] || fail "wrong upgraded version"
[[ "$(cat "$scratch/projects/other/repos/library/source.txt")" == first ]] || fail "changed another project"

# Checkout verification must inspect origin, commit, metadata, and tracked files.
git -C "$new_target" config remote.origin.url wrong-repository
expect_failure 1 run check "$manifest"
expect_failure 1 run sync "$manifest"
git -C "$new_target" config remote.origin.url "$upstream"
git -C "$new_target" checkout -q --detach library@1.0.0
expect_failure 1 run check "$manifest"
git -C "$new_target" checkout -q --detach library@1.1.0
git -C "$new_target" config oss-ref.version library@1.0.0
expect_failure 1 run check "$manifest"
git -C "$new_target" config oss-ref.version library@1.1.0
echo edited > "$new_target/source.txt"
expect_failure 1 run check "$manifest"
expect_failure 1 run sync "$manifest"
[[ "$(cat "$new_target/source.txt")" == edited ]] || fail "sync overwrote edits"
git -C "$new_target" restore source.txt
run check "$manifest"

# Missing tags must not fall back to main or replace the last working reference.
installed 9.9.9
expect_failure 1 run sync "$manifest"
[[ "$(realpath -e "$project/repos/library")" == "$new_target" ]] || fail "missing tag replaced link"
[[ ! -e "$OSS_REFERENCES_ROOT/.lock" ]] || fail "failed sync left a lock"
installed 1.1.0

# Broken links are reported and repaired; real files/directories are preserved.
ln -sfnT "$scratch/missing" "$project/repos/library"
expect_failure 1 run check "$manifest"
run sync "$manifest"
rm "$project/repos/library"
mkdir "$project/repos/library"
echo keep > "$project/repos/library/keep.txt"
expect_failure 1 run sync "$manifest"
[[ -f "$project/repos/library/keep.txt" ]] || fail "sync replaced a real directory"
rm -r "$project/repos/library"
run sync "$manifest"

# Resolve hoisted scoped dependencies from an explicitly selected nested manifest.
mkdir -p "$project/packages/child"
cp "$manifest" "$project/packages/child/.oss-references.json"
run sync "$project/packages/child/.oss-references.json"
run check "$project/packages/child/.oss-references.json"
[[ "$(realpath -e "$project/packages/child/repos/library")" == "$new_target" ]] || fail "hoisting failed"

# Reject missing/invalid installs and malformed manifests before touching links.
mv "$metadata" "$metadata.saved"
expect_failure 1 run sync "$manifest"
mv "$metadata.saved" "$metadata"
echo '{"name":"@fixture/library","version":"^1.1.0"}' > "$metadata"
expect_failure 1 run check "$manifest"
installed 1.1.0
cp "$manifest" "$scratch/good.json"
for expression in \
  '.references.library.path = "../outside"' \
  '.references.library.path = "/absolute"' \
  '.references.library.path = "."' \
  '.references.library.ref = "main"' \
  '.references.library.package = "../escape"' \
  '.references.library.path = "repos/line\nbreak"' \
  '.references.library.typo = true' \
  '.references.duplicate = .references.library'; do
  jq "$expression" "$scratch/good.json" > "$manifest"
  expect_failure 2 run sync "$manifest"
done
echo '{invalid' > "$manifest"
expect_failure 2 run check "$manifest"
cp "$scratch/good.json" "$manifest"
expect_failure 2 run check "$manifest" extra
expect_failure 2 run sync "$scratch/absent.json"

# Intermediate links cannot escape the project, even into a valid consumer root.
ln -s "$scratch/projects/other" "$project/escape"
jq '.references.library.path = "escape/library"' "$scratch/good.json" > "$manifest"
expect_failure 2 run sync "$manifest"
cp "$scratch/good.json" "$manifest"

# Read all installed versions before starting a sync with multiple entries.
installed 1.0.0
jq '.references.missing = {package:"not-installed", repository:"unused", ref:"v{version}", path:"repos/missing"}' \
  "$scratch/good.json" > "$manifest"
expect_failure 1 run sync "$manifest"
[[ "$(realpath -e "$project/repos/library")" == "$new_target" ]] || fail "partial sync before package validation"
installed 1.1.0
cp "$scratch/good.json" "$manifest"

# Prune discovery is per store entry: links created by hand still protect their
# clone even when relative, broken, pointing at a descendant, or going through
# an alias that does not contain the clone name. Only the unlinked clone goes.
mkdir -p \
  "$OSS_REFERENCES_ROOT/orphan@1" \
  "$OSS_REFERENCES_ROOT/relative@1" \
  "$OSS_REFERENCES_ROOT/descendant@1/sub" \
  "$OSS_REFERENCES_ROOT/broken@1" \
  "$OSS_REFERENCES_ROOT/aliased@1" \
  "$OSS_REFERENCES_ROOT/odd[1]@1"
mkdir -p \
  "$scratch/projects/relative/repos" \
  "$scratch/projects/descendant/repos" \
  "$scratch/projects/broken/repos" \
  "$scratch/projects/aliased/repos" \
  "$scratch/projects/odd/repos"
ln -s "../../../store/relative@1" "$scratch/projects/relative/repos/link"
ln -s "$OSS_REFERENCES_ROOT/descendant@1/sub" "$scratch/projects/descendant/repos/link"
ln -s "$OSS_REFERENCES_ROOT/broken@1/missing" "$scratch/projects/broken/repos/link"
ln -s "$OSS_REFERENCES_ROOT/aliased@1" "$scratch/alias-target"
ln -s "$scratch/alias-target" "$scratch/projects/aliased/repos/link"
ln -s "$OSS_REFERENCES_ROOT/odd[1]@1" "$scratch/projects/odd/repos/link"

run prune --dry-run > "$scratch/prune.out"
grep -qx 'orphan@1  orphan' "$scratch/prune.out" || fail "orphan was not reported"
for protected in relative@1 descendant@1 broken@1 aliased@1 'odd[1]@1'; do
  grep -qF "$protected" "$scratch/prune.out" && fail "$protected was reported as orphan"
done
run prune --yes
[[ ! -e "$OSS_REFERENCES_ROOT/orphan@1" ]] || fail "prune kept the orphan"
for protected in relative@1 descendant@1 broken@1 aliased@1 'odd[1]@1'; do
  [[ -d "$OSS_REFERENCES_ROOT/$protected" ]] || fail "prune removed $protected"
done

# Existing add/prune behavior still respects consumers and the shared lock.
mkdir "$OSS_REFERENCES_ROOT/.lock"
expect_failure 1 run sync "$manifest"
rmdir "$OSS_REFERENCES_ROOT/.lock"
run prune --yes
[[ -d "$old_target" && -d "$new_target" ]] || fail "prune removed referenced versions"
run check "$manifest"
echo "PASS: oss-ref sync/check integration tests"
