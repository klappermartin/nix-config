#!/usr/bin/env bash
set -euo pipefail

default=$(git defaultBranch)
git rev-parse --verify "refs/heads/$default" >/dev/null
current=$(git symbolic-ref --quiet --short HEAD || true)
# Do not hide enumeration failures behind process substitution. Git ref names
# cannot contain tabs or newlines; worktreepath also protects other worktrees.
branches=$(git for-each-ref --merged="refs/heads/$default" \
  --format='%(refname:strip=2)%09%(worktreepath)' refs/heads/)
while IFS=$'\t' read -r branch worktree; do
  [[ -n "$branch" ]] || continue
  [[ "$branch" != "$default" && "$branch" != "$current" && -z "$worktree" ]] || continue
  git branch -d -- "$branch"
done <<< "$branches"
git remote prune origin
