---
description: Create a self-contained, redacted summary for continuing this work in a fresh OpenCode session.
---

# Handoff

Create a concise, self-contained handoff for a new OpenCode session.

First, use the current session history when it is available to copy the original user request and
any explicit constraints verbatim. Then inspect the current todo state, `git diff --stat`, and
`git status --porcelain`. Run project commands only through the active project environment; in a
repository with `devenv.nix` or `devenv.yaml`, use `devenv shell <command>`. Do not install tools
or packages globally to create this summary.

Never include credentials, API keys, tokens, private URLs, or other secrets. Use workspace-relative
paths and include at most ten key files.

Return exactly this plain-text structure:

HANDOFF CONTEXT
===============

USER REQUESTS (AS-IS)
---------------------
- Exact verbatim top-level user requests, or "Unavailable from session history."

GOAL
----
One sentence describing the next objective.

WORK COMPLETED
--------------
- First-person summary of completed work and material decisions.

CURRENT STATE
-------------
- Repository, test, environment, and uncommitted-change status.

PENDING TASKS
-------------
- Remaining work, blockers, and current todo state.

KEY FILES
---------
- workspace/relative/path - why it matters

IMPORTANT DECISIONS
-------------------
- Decisions, trade-offs, and project conventions that remain relevant.

EXPLICIT CONSTRAINTS
--------------------
- Verbatim user or AGENTS.md constraints only; write "None" when absent.

CONTEXT FOR CONTINUATION
------------------------
- Warnings, gotchas, and the immediate next step.

After the summary, tell the user to open a new OpenCode session and paste it with their next task.
