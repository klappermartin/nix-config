# OpenCode and Oh My OpenAgent

Home Manager installs OpenCode, declares its plugins and MCP servers, and installs
the three OMO profiles into `~/.omo`. The JSONC files were imported from the active
canonical configuration directory, not the older copies in `~/.config/opencode`.
Edit these repository files to change profiles, then rebuild.

The existing Home Manager `.backup` policy backs up replaced unmanaged files on
first activation. Authentication, caches, node_modules, old profiles, and historical
backups are not imported. No credentials belong in these tracked files.

## Two profiles

`opencode` runs lite on OpenCode V2: the Anthropic auth plugin, explicitly
declared MCP servers, native subagents, and selected native skills. It does not
load the oh-my-openagent plugin. `opencode-omo` is a wrapper that runs OpenCode V1
with oh-my-openagent on top of exactly that configuration. omo is a V1 plugin, and
V1 plugins do not run in V2.

V1 comes from nixpkgs. nixpkgs does not package V2, so `opencodeV2Version` in
`default.nix` pins the signed binary from npm; update its hash whenever you bump
it. The wrapper turns off V2's self-update, as nixpkgs does for V1.

Both versions read `~/.config/opencode`, but they share no sessions. V2 keeps its
own database, `opencode-v2.db`, next to V1's `opencode.db` (see below), stores
credentials in it, and caches plugins under `~/.cache/opencode/npm` rather than
`packages`. V2 imports `auth.json` on first start; after that each version signs
in separately. V1 sessions stay reachable under `opencode-omo`.

V2 runs sessions in a background service that its terminal clients share
(`opencode service status`, `stop`, `restart`). The first client starts it, so the
service inherits the wrapper's environment. After changing that environment,
run `opencode service restart`. After a version bump, the next `opencode` start
replaces the old service by itself.

## Why V2 has its own database

Pointed at `opencode.db`, V2 migrates it in place: it clears V1's event log, adds
its own tables, and copies every V1 session into them once, in the background.
Sessions created afterwards still do not cross over in either direction, so
sharing buys a one-time import at the cost of rewriting a large live database.
`OPENCODE_DB` in the V2 wrapper avoids that. To import V1 history anyway, back up
`opencode.db`, remove `OPENCODE_DB`, rebuild, and restart the service.

## Why the split runs this way around

OpenCode concatenates and de-duplicates plugins across every config source, so an
extra config file can only add a plugin, never remove one. The lite profile must
therefore be the one declared in `opencode.json`, with `omo.json` and
`omo-tui.json` opting back in; `opencode-omo` points `OPENCODE_CONFIG` and
`OPENCODE_TUI_CONFIG` at them.

The Anthropic auth plugin has one release line per OpenCode version, and neither
loads in the other version. V2 reads both its own `plugins` key and V1's `plugin`
key, while V1 skips `plugins` with a warning in its log. `opencode.json`
therefore declares only the 2.x line, under `plugins`, and `omo.json` declares
the 1.x line under `plugin`.

Leaving omo out of `opencode.json` also protects the lite profile. omo's TUI
self-heal resolves `XDG_CONFIG_HOME/opencode`, looks for itself in that
directory's `opencode.json`, and bails out when it is absent, so it can no longer
rewrite the managed `tui.json`. That file is declared with an empty plugin list to
replace the copy omo had already clobbered.

`opencode --pure` is not an alternative: it skips every external plugin, local
files included, so it would drop the Anthropic auth plugin too.

## Profiles

Use `activate-oh-my-openagent-profile.sh openai`, `anthropic`, or `opencode-go`
(`go` is an alias) to select a profile. `status` reports the active configuration;
`default` restores a writable copy of the unified anthropic profile. The command
is on PATH and remains available at its old location under `~/.config/opencode`.
New sessions load the selected profile; existing sessions retain their settings.

Profile files are managed symlinks. The active `~/.omo/omo.jsonc` remains mutable
and is initialized only when absent, so rebuilds preserve the current selection.
When using `default`, rerun it after rebuilding to refresh its copied contents.
OMO also reads this shared configuration for Codex; its existing `[codex]` sections
are preserved. Selecting a profile affects `opencode-omo` only, since the lite
profile never loads omo.

## Lite profile OMO-equivalent assets

Some OMO-shipped assets are useful without the OMO runtime plugin, so the lite
profile declares native equivalents:

- MCP servers: `codegraph`, `context7`, `grep_app`, `lsp`, and `websearch`, in
  addition to the local Linear and Figma entries.
- Native subagent: `librarian`. OpenCode's built-in `explore` already covers
  codebase search.
- Native skills: `ast-grep`, `git-master`, `lsp-setup`, `visual-qa`, and a local
  `playwright` skill. The OMO-sourced skills come from the pinned
  oh-my-openagent tarball.

`omoPluginVersion` in `default.nix` pins the OMO plugin, and the same tarball
provides the OMO-sourced skills and the `lsp` MCP CLI. Update its hash whenever
you bump it.

When running `opencode-omo`, same-named MCP entries from the lite config override
OMO's built-in MCP definitions. The `librarian` name is safe: OMO protects its own
compiled agents and ignores colliding user agent files.

## Codegraph

`codegraph` runs from the prebuilt darwin-arm64 bundle, pinned by
`codegraphVersion` and its hash; the main npm package is only a launcher for it.
The `codegraph` command is on PATH with telemetry and update checks turned off.

The lite profile has no OMO auto-init, so index a project once with
`codegraph init` (or by opening it under `opencode-omo`); until then the
codegraph tools have nothing to query. The index lives in `.codegraph/`, whose
own `.gitignore` hides everything except itself, so after a manual init add
`.codegraph/` to `.git/info/exclude` as OMO's auto-init does. `opencode-omo`
sets `OMO_CODEGRAPH_BIN`, so OMO's auto-init uses the same binary instead of
provisioning its own copy under `~/.omo/codegraph`.
