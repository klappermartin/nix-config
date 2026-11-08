---
name: security-review
description: "Reviews a bounded code or change scope for concrete security flaws, with attack paths, evidence, and safe verification. Use for authentication, authorization, input handling, secrets, filesystem, subprocess, network, dependency, or configuration changes."
argument-hint: "[file, directory, diff, or PR scope]"
---

# Security Review

This is the budget-conscious, single-session adaptation of Oh My OpenAgent's `security-review`
alias for its team-mode `security-research` workflow. It reviews one bounded target at a time;
it does not launch a vulnerability-hunting team unless the user explicitly asks and approves the
additional cost.

## Project environment first

Run tests and verification using the active project's declared environment. In a repository with
`devenv.nix` or `devenv.yaml`, use `devenv shell <command>`. If a required tool is absent, use
an ephemeral `nix shell` with the exact package set. Do not use global installers or alter the
project's dependencies merely to perform this review.

## Scope and safety

If the user supplies a file, directory, diff, or PR, review only that target. Otherwise review
the current branch diff against its merge base. Gather the changed files, relevant callers, and
their tests before drawing conclusions.

Never run destructive exploits or target real third-party systems. Use local fixtures, toy
payloads, dry runs, or static evidence. Do not report a vulnerability without an attack path.

## Review workflow

1. Map trust boundaries: external input, identity and authorization decisions, secrets, data
   stores, filesystem access, subprocesses, network clients, deserialization, dependencies, and
   configuration.
2. Trace attacker-controlled values to security-sensitive sinks. Check injection, path traversal,
   SSRF, unsafe redirects, insecure deserialization, permission bypasses, secret exposure, and
   unsafe archive or file handling as applicable.
3. Confirm each candidate with a safe, concrete reproduction or evidence path. Reject generic
   hardening suggestions that lack a reachable attack path and meaningful impact.
4. Run the smallest relevant regression or validation command through the project environment.
5. Report only actionable findings; distinguish untested residual risk from a verified flaw.

## Evidence standard

Use CWE for weakness classification and OWASP ASVS/WSTG for the relevant control and test
methodology. For each finding, provide the affected file and symbol, attacker capability,
preconditions, attack path, impact, safe proof, smallest remediation, and regression check.

## Output

```markdown
## Security Review Result

### Verdict
PASS | PASS WITH FINDINGS | BLOCK

### Scope
- Target:
- Base/diff:
- Commands run:

### Findings
| Severity | Title | CWE | Attack path | Evidence | Fix |
|----------|-------|-----|-------------|----------|-----|

### Residual Risk
- Untested surface and reason.
```

Lead with blocking findings. Mark a result `PASS` only when no verified findings remain; do not
equate an incomplete review with proof of safety.
