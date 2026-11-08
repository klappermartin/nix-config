#!/usr/bin/env bash
set -euo pipefail

root=${1:?repository root is required}

# Shared agents and commands must inherit the active session model. A model
# pinned in either frontmatter would bypass the user's normal selection (and
# requires separate policy review for work repositories).
for directory in \
  "$root/darwin/home/programs/opencode/agents" \
  "$root/darwin/home/programs/opencode/commands"; do
  [[ -d $directory ]] || continue

  if grep -RInE '^[[:space:]]*model:[[:space:]]*[^[:space:]#]' "$directory"; then
    echo 'OpenCode agents and commands must not pin a model.' >&2
    exit 1
  fi
done

# Keep Nix-defined agents and commands model-neutral as well. This catches a
# future `model = "provider/model";` in the shared OpenCode module.
if grep -RInE '(^|[[:space:].])model[[:space:]]*=' \
  "$root/darwin/home/programs/opencode"/*.nix \
  "$root/darwin/home/programs/opencode"/*/*.nix 2>/dev/null; then
  echo 'Shared Nix OpenCode agents and commands must not pin a model.' >&2
  exit 1
fi
