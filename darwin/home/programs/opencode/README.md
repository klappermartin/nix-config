# OpenCode

Home Manager installs one OpenCode V2 command, the Anthropic authentication
plugin, explicit MCP servers, the native librarian agent, and five native skills.
There is no alternate V1/plugin profile or profile-switching command.

## Package and state

`opencodeV2Version` and its hash pin the signed darwin-arm64 npm binary. The
wrapper supplies Nix ripgrep and disables self-update. Both MacBook hosts use
this package; another architecture needs a matching upstream binary and hash.

Keep `OPENCODE_DB=opencode-v2.db`: this is the existing V2 session/authentication
database, not an obsolete profile setting. Removing it would select a different
database. Authentication, sessions, caches, and historical databases are runtime
state and are not managed or deleted by this configuration.

OpenCode runs sessions in a shared background service. After changing wrapper
environment or MCP configuration, restart it outside an active session:

```sh
opencode service restart
opencode mcp list
```

The cleanup removes the previously managed plugin profiles and config fragments.
On activation, the old mutable `~/.omo/omo.jsonc` selection is moved to
`~/.local/state/home-manager/retired-config/omo.jsonc` (numbered backups on conflict).
Historical project notes and plugin caches are not active configuration and are
left on disk.

## Independent tools and skills

- MCP: Codegraph, Context7, grep.app, LSP, Exa web search, Linear, and local Figma.
- Native agent: `librarian`; OpenCode supplies the built-in exploration agent.
- Native skills: `ast-grep`, `git-master`, `lsp-setup`, `visual-qa`, and the local
  `playwright` skill.

The LSP CLI and four shared skills are local snapshots under `vendor/`, with
provenance and licenses. They do not fetch, install, or load the orchestration
plugin. See [`vendor/README.md`](vendor/README.md) for their update procedure.

`lsp-tools-mcp` invokes the self-contained CLI with an explicit Nix Node runtime.
It reads user settings from `~/.config/opencode/lsp.json` and project settings from
`.opencode/lsp.json`. Installation decisions remain at
`~/.config/opencode/lsp-install-decisions.json`. Language-server executables must
be installed separately (usually through the project's Nix development shell).
The `lsp-setup` skill documents language-specific choices; verify through the
MCP diagnostics tool rather than an old plugin checkout.

## Codegraph

`codegraphVersion` and its hash pin the prebuilt darwin-arm64 bundle. The main
npm package is only a launcher. The Nix wrapper disables telemetry and the bundle
patch extends default directory skips with `.devenv/` and `devenv/`.

Indexing is opt-in: run `codegraph init` at the root of a repository you want
indexed. Existing indexes sync automatically. Avoid indexing aggregate folders
such as `~/code`: Codegraph discovers ancestor indexes and can otherwise index
the same projects more than once.

For pinned Codegraph 1.6.2, tools can be exposed without a default index; use
`projectPath` for an indexed project. Tool visibility alone is not an opt-in check.
`codegraph.json` is optional configuration at the index root, not an enable flag
or a global configuration file. Use its `exclude` list when exclusions must take
precedence over `.gitignore` negations.

After initializing a project, add `.codegraph/` to its `.git/info/exclude`.
See the upstream [configuration](https://colbymchenry.github.io/codegraph/getting-started/configuration/)
and [MCP](https://colbymchenry.github.io/codegraph/reference/mcp-server/) documentation.
