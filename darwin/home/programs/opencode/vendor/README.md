# Standalone utility snapshots

These assets preserve the utilities already used by plain OpenCode while removing
the plugin/tarball dependency. They are not a copy of the orchestration runtime.
Each asset records its source and license locally; the table includes both the
original package snapshot and later individually vendored skills.

Source snapshot: `oh-my-openagent` npm release **4.19.4**, unpacked NAR hash
`sha256-UVs08W8azRuGgj58WCuctrn2ASnQyFG473/ecIeHIxY=`.
Original archive: <https://registry.npmjs.org/oh-my-openagent/-/oh-my-openagent-4.19.4.tgz>.

| Local path | Original path | License |
| --- | --- | --- |
| `lsp-tools-mcp/cli.mjs` | `packages/lsp-tools-mcp/dist/cli.js` | MIT; retained in `lsp-tools-mcp/LICENSE` |
| `skills/ast-grep/` | `packages/shared-skills/skills/ast-grep/` | MIT; retained in its `LICENSE` |
| `skills/data-scientist/` | `packages/shared-skills/skills/data-scientist/` at `8af3fae` | upstream Sustainable Use License; retained as `skills/oh-my-openagent-LICENSE.md` |
| `skills/eval-integrity/` | `packages/shared-skills/skills/eval-integrity/` at `8af3fae` | upstream Sustainable Use License; retained as `skills/oh-my-openagent-LICENSE.md` |
| `skills/git-master/` | `packages/shared-skills/skills/git-master/` | upstream Sustainable Use License, retained as `LICENSE.upstream.md` |
| `skills/lsp-setup/` | `packages/shared-skills/skills/lsp-setup/` | upstream Sustainable Use License, retained as `LICENSE.upstream.md` |
| `skills/remove-ai-slops/` | `packages/shared-skills/skills/remove-ai-slops/` | upstream Sustainable Use License; retained as `skills/oh-my-openagent-LICENSE.md` |
| `skills/security-review/` | local single-session adaptation of upstream `security-review` at `8af3fae` | upstream Sustainable Use License; retained as `skills/oh-my-openagent-LICENSE.md` |
| `skills/visual-qa/` | `packages/shared-skills/skills/visual-qa/` | upstream Sustainable Use License, retained as `LICENSE.upstream.md` |

The LSP file is an unmodified, self-contained ESM bundle, renamed `.mjs` so Node
does not need the parent package manifest. It imports Node built-ins only and
does not require the old monorepo, plugin, or node_modules. Historical source-path
comments and protocol identifiers inside it are upstream provenance.
Its independent upstream is <https://github.com/code-yeongyu/lsp-tools-mcp>;
the AST skill also has an independent upstream at
<https://github.com/code-yeongyu/ast-grep-skill>.

Local modifications: the LSP skill uses the installed MCP server for verification
instead of requiring monorepo source, and its discovery paths match this
configuration. The Git and visual QA instructions use available native tools
rather than plugin-specific agents or missing monorepo capture scripts. The data
scientist and remove-ai-slops skills are amended for devenv-first execution; the
security review is a bounded single-session adaptation rather than upstream's
Team Mode workflow.

For updates, review the standalone upstream or a new utility snapshot, retain
licenses, and update this provenance record. Do not reintroduce a plugin installer
or a runtime fetch. Run `nix flake check --no-build`, build the Darwin system, and smoke-test MCP
initialization, tool listing, and diagnostics before switching. Treat generated
`cli.mjs` as a snapshot rather than hand-editing bundled code.
