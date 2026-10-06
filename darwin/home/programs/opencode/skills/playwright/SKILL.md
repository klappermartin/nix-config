---
name: playwright
description: Use for browser automation, web UI verification, screenshots, console/network inspection, Playwright test authoring, and manual browser QA. Trigger for browser tasks, visual checks, end-to-end flows, UI debugging, screenshots, page interaction, and anything requiring a real rendered web page.
---

# Playwright Browser QA

Use this skill whenever the task requires interacting with, testing, or verifying a browser-rendered surface. Do not substitute `curl` or static source inspection for behavior that depends on JavaScript, layout, cookies, local storage, viewport size, browser APIs, or user interaction.

## Workflow

1. Identify the exact URL, command, or local dev server needed to render the page.
2. Launch or reuse the app in the narrowest way that exercises the requested flow.
3. Drive the page with Playwright tooling: navigate, click, type, wait for visible states, inspect console errors, and capture screenshots when visual evidence matters.
4. For regressions, reproduce the failure first, then verify the fix with the same flow.
5. Report what was actually observed: URL, viewport, key interactions, console/network issues, screenshots or traces when produced, and any remaining risk.

## Commands

Prefer project-local Playwright when present:

```bash
npx playwright test
npx playwright test --headed
npx playwright codegen http://localhost:3000
npx playwright show-trace trace.zip
```

If the project has no Playwright setup and a quick script is enough, create a temporary script outside the repo or in an approved scratch location, run it, then remove it unless the user asked to keep it.

## Guardrails

- Do not commit screenshots, traces, videos, or generated reports unless the user explicitly asks.
- Do not leave dev servers, browser processes, or temporary test artifacts running.
- Do not log secrets, cookies, auth headers, or private page data.
- If authentication is required, ask before using or changing any real account state.
- For visual fidelity or screenshot diff work, pair this with the `visual-qa` skill.
