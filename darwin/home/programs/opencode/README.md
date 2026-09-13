# OpenCode and Oh My OpenAgent

Home Manager installs OpenCode, declares its plugins and MCP servers, and installs
the three OMO profiles into `~/.omo`. The JSONC files were imported from the active
canonical configuration directory, not the older copies in `~/.config/opencode`.
Edit these repository files to change profiles, then rebuild.

Plugins are downloaded by OpenCode at startup. `oh-my-openagent@latest` preserves
the existing stable-release tracking in both OpenCode and its TUI configuration.

Use `activate-oh-my-openagent-profile.sh openai`, `anthropic`, or `opencode-go`
(`go` is an alias) to select a profile. `status` reports the active configuration;
`default` restores a writable copy of the unified anthropic profile. The command
is on PATH and remains available at its old location under `~/.config/opencode`.
New sessions load the selected profile; existing sessions retain their settings.

Profile files are managed symlinks. The active `~/.omo/omo.jsonc` remains mutable
and is initialized only when absent, so rebuilds preserve the current selection.
When using `default`, rerun it after rebuilding to refresh its copied contents.
OMO also reads this shared configuration for Codex; its existing `[codex]` sections
are preserved.

The existing Home Manager `.backup` policy backs up replaced unmanaged files on
first activation. Authentication, caches, node_modules, old profiles, and historical
backups are not imported. No credentials belong in these tracked files.
