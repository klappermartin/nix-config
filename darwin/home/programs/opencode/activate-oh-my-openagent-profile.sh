#!/usr/bin/env bash
set -euo pipefail

OMO_DIR="$HOME/.omo"
ACTIVE_CONFIG="$OMO_DIR/omo.jsonc"

usage() {
  cat <<'USAGE'
Usage: activate-oh-my-openagent-profile.sh <default|anthropic|openai|opencode-go|go|status>

Switches the Oh My OpenAgent config used by new opencode starts.
Already-running opencode sessions keep the config they loaded at startup.
Active config: ~/.omo/omo.jsonc  (canonical path for oh-my-openagent 4.19.4+)

  default      Restore the unified config (all providers, runtime_fallback on).
               Copies ~/.omo/omo.anthropic.jsonc -> ~/.omo/omo.jsonc as a regular file.
  anthropic    Symlink ~/.omo/omo.jsonc -> omo.anthropic.jsonc  (= default, Claude-led)
  openai       Symlink ~/.omo/omo.jsonc -> omo.openai.jsonc     (GPT-led, no Claude primary)
  opencode-go  Symlink ~/.omo/omo.jsonc -> omo.opencode-go.jsonc (Kimi K3-led, no GPT/Claude primary)
  go           Alias for opencode-go
  status       Show what ~/.omo/omo.jsonc currently points to
USAGE
}

profile=${1:-}

case "$profile" in
  default)
    source="$OMO_DIR/omo.anthropic.jsonc"
    if [[ ! -f "$source" ]]; then
      echo "Missing source: $source" >&2
      exit 1
    fi
    rm -f "$ACTIVE_CONFIG"
    cp "$source" "$ACTIVE_CONFIG"
    chmod u+w "$ACTIVE_CONFIG"
    echo "Restored default config: $ACTIVE_CONFIG (regular file, all providers)"
    ;;
  go)
    profile="opencode-go"
    target="$OMO_DIR/omo.$profile.jsonc"
    if [[ ! -f "$target" ]]; then
      echo "Missing profile: $target" >&2
      exit 1
    fi
    tmp="$OMO_DIR/.omo.jsonc.tmp"
    ln -s "$(basename "$target")" "$tmp"
    mv -f "$tmp" "$ACTIVE_CONFIG"
    echo "Activated $profile profile: $ACTIVE_CONFIG -> $(basename "$target")"
    ;;
  anthropic|openai|opencode-go)
    target="$OMO_DIR/omo.$profile.jsonc"
    if [[ ! -f "$target" ]]; then
      echo "Missing profile: $target" >&2
      exit 1
    fi
    tmp="$OMO_DIR/.omo.jsonc.tmp"
    ln -s "$(basename "$target")" "$tmp"
    mv -f "$tmp" "$ACTIVE_CONFIG"
    echo "Activated $profile profile: $ACTIVE_CONFIG -> $(basename "$target")"
    ;;
  status)
    if [[ -L "$ACTIVE_CONFIG" ]]; then
      echo "$ACTIVE_CONFIG -> $(readlink "$ACTIVE_CONFIG")"
    elif [[ -f "$ACTIVE_CONFIG" ]]; then
      echo "$ACTIVE_CONFIG is a regular file (default/unified config)"
    else
      echo "$ACTIVE_CONFIG does not exist"
      exit 1
    fi
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
