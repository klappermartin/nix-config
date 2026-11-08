# OpenCode

Home Manager installs OpenCode V2, MCP executables, the TypeScript language
server, and a small baseline of skills.

## MCP scope

| Scope | Servers |
| --- | --- |
| Global | Codebase Memory, Codegraph, Context7, grep.app, LSP, Exa web search, Linear, local Figma |
| Installed, enabled only by projects | `mcp-nixos`, `firefox-devtools-mcp` |

Installing a server does not enable it. Global configuration lives in
`~/.config/opencode/opencode.json`; project connections belong in the project's
`.opencode/opencode.json` or `opencode.jsonc`. OpenCode applies the configuration
for each project even though clients share a background service.

For example, a web project can opt in to the NixOS and Firefox MCPs with:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "nixos": { "type": "local", "command": ["mcp-nixos"] },
      "firefox": { "type": "local", "command": ["firefox-devtools-mcp"] }
    }
  }
}
```

The OpenCode wrapper puts these executables on the background service's PATH.
A project definition replaces the entire same-named global server object; include
all its required fields. Add `disabled: true` to a complete definition to keep a
server disconnected. Linear uses its remote MCP endpoint; Figma connects to the
local desktop MCP endpoint at `http://127.0.0.1:3845/mcp`.

The Firefox wrapper selects Firefox Developer Edition and enables page script
evaluation/debugging. Firefox launches on the first browser tool call, using a
temporary automation profile. MCP-NixOS provides package, Home Manager, and
nix-darwin option lookup.

## Skills and language servers

The existing Nix-managed skills are `ast-grep`, `git-master`, `lsp-setup`,
`visual-qa`, `playwright`, and `oss-reference`. The first four and the standalone
LSP CLI are snapshots under [`vendor/`](vendor/README.md); `playwright` is local,
and `oss-reference` comes from the repository-level [`skills/`](../../../../skills/)
directory.

Personal skills in `~/.agents/skills/` and `~/.claude/skills/` are managed outside
this repository. Project skills belong in `.agents/skills/` or `.opencode/skills/`.
OpenCode discovers them automatically and loads their instructions on demand.
Use one owner per installed skill path.

The LSP bridge reads user settings from `~/.config/opencode/lsp.json` and project
settings from `.opencode/lsp.json`. TypeScript/JavaScript tooling is supplied by
Nix; the language server prefers workspace TypeScript and has a compatible
fallback. Other language-server executables must be available in the environment
of the LSP process. These bridge settings are separate from OpenCode's native
LSP configuration.

## Versions and service

OpenCode, Codegraph, Codebase Memory, Firefox DevTools, MCP-NixOS, and the
TypeScript language server follow the flake's nixpkgs revision. The OpenCode
wrapper disables self-update.

Keep `OPENCODE_DB=opencode.db`: it selects the unified session/authentication
database. Credentials, sessions, and caches are runtime state, outside this repo.

After rebuilding changes to the executable or wrapper environment, restart the
service outside an active session:

```sh
opencode service restart
opencode mcp list
```

Opening a different project does not require restarting the server or manually
switching its configured MCPs and skills.

## Codegraph

Codegraph follows nixpkgs and runs with telemetry disabled.

Run `codegraph init` once at each repository root you want indexed. Existing
indexes sync automatically. Avoid initializing aggregate directories like `~/code`,
because ancestor indexes are discoverable. Keep `.codegraph/` out of Git, for
example using `.git/info/exclude`.

`codegraph.json` is optional index configuration, not an enable switch. Use its
`exclude` list for additional exclusions. See the upstream
[configuration](https://colbymchenry.github.io/codegraph/getting-started/configuration/)
and [MCP](https://colbymchenry.github.io/codegraph/reference/mcp-server/) documentation.
