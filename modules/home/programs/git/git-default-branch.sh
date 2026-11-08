#!/usr/bin/env bash
set -euo pipefail

ref=$(git symbolic-ref --quiet refs/remotes/origin/HEAD) || {
  echo "origin/HEAD is unset; run git remoteSetHead first" >&2
  exit 1
}
case "$ref" in
  refs/remotes/origin/*) printf '%s\n' "${ref#refs/remotes/origin/}" ;;
  *) echo "unexpected origin/HEAD target: $ref" >&2; exit 1 ;;
esac
