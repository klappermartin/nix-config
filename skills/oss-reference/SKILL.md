---
name: oss-reference
description: Clone versioned OSS repositories as shared references and manage them with add, prune, and list subcommands.
---

## Overview

`oss-ref` clones open-source repositories at a specific version into a shared references root, then creates a consumer-side symlink. This avoids duplicate clones across projects. The pruner removes orphaned references that no longer have incoming symlinks, and the list command shows everything currently stored.

## Usage

### add

**Signature:** `oss-ref add <git-url> <version> <symlink-path>`

Clones `<git-url>` at `<version>` into `$OSS_REFERENCES_ROOT/<slug>@<version>`, then symlinks it to `<symlink-path>`. The slug is derived from the URL basename with `.git` stripped. The version is sanitized: slashes become dashes, only `[A-Za-z0-9._+-]` is kept, and consecutive dashes are collapsed.

The clone is staged in a unique directory under `$ROOT/.partial/` and moved atomically to the final location. A shallow clone is attempted first; if the version is a SHA or an unknown ref, it falls back to a blobless clone followed by checkout. Failures print Git diagnostics.

Use a consumer path discoverable under a configured consumer root, without intermediate directory symlinks. Real files/directories are not replaced. Repeating `add` reuses an existing clone only after checking its origin and checked-out version; this also allows retrying after a consumer-link failure. Different repositories with the same slug are rejected rather than silently reused.

**Example:**

```bash
oss-ref add https://github.com/Effect-TS/effect.git v4-beta ~/code/my-project/repos/effect
```

**Exit codes:**

- `0` — success
- `1` — runtime error (clone failed, conflicting target, invalid consumer path, or another operation holds the lock)
- `2` — usage error (wrong number of arguments)

### prune

**Signature:** `oss-ref prune [--yes|--dry-run] [--min-age <dur>] [-v]`

Scans `$OSS_REFERENCES_ROOT` for directories matching `*@*` and checks whether any symlink under `$OSS_REFERENCES_CONSUMER_ROOTS` points to them or their descendants. Even broken links into a clone protect it. Missing/unreadable roots, discovery errors, and unresolvable symlink loops abort before deletion. Links inside the references store are not consumers. Unreferenced clones are candidates for deletion; `--min-age` skips directories modified more recently than the threshold.

**Example:**

```bash
oss-ref prune --yes --min-age 7d
```

**Exit codes:**

- `0` — success (or nothing to prune)
- `1` — runtime error
- `2` — usage error (invalid flag, missing value, or non-tty without `--yes`/`--dry-run`)

### list

**Signature:** `oss-ref list`

Lists all versioned clones under `$OSS_REFERENCES_ROOT`, sorted alphabetically.

**Example:**

```bash
oss-ref list
```

**Exit codes:**

- `0` — success (or empty list)
- `1` — runtime error
- `2` — usage error (not applicable for this subcommand)

## Filesystem layout

```
$OSS_REFERENCES_ROOT/
├── effect-ts@v4-beta/          # finished clone
├── .partial/
│   └── operation.XXXXXX/      # unique staging directory during an operation
├── .lock/pid                 # add/prune serialization; present only while running
└── ...

~/code/my-project/
└── repos/
    └── effect -> /Users/martin/code/others/oss-references/effect-ts@v4-beta
```

The `.partial/` directory holds in-progress work and is cleaned on normal exit or handled signals. Add/prune share an exclusive lock. If a process is killed abruptly, inspect `$ROOT/.lock/pid` and confirm that no operation is still running before removing the stale lock and abandoned partial work. Locks are never expired based on elapsed time.

## Safety model

`--min-age` measures directory mtime, not last use. The lock prevents this tool's add/prune operations from overlapping, but external filesystem changes are not locked. Keep consumers inside the configured scan scope; manually created consumers outside it cannot be discovered.

The launchd agent defaults to `oss-ref prune --dry-run --min-age 7d` weekly on Monday at 09:00. Audit existing consumers and its logs before enabling deletion with `services.oss-references-pruner.dryRun = false`. A seven-day age threshold is not a substitute for complete consumer discovery.

Run `oss-ref prune` manually when you know a project has been deleted or its symlinks removed, and you want to reclaim disk space immediately. Use `--dry-run` first to preview what would be removed.

## Migrating legacy clones

Any pre-existing unversioned directory under `$OSS_REFERENCES_ROOT` (for example, `effect-ts/`) is invisible to the pruner because it lacks the `@<version>` suffix. The pruner only considers directories matching `*@*`.

To migrate a legacy clone manually, rename it with a version suffix and update the consumer symlink:

```bash
mv effect-ts effect-ts@v4-beta-legacy
ln -sfn "$OSS_REFERENCES_ROOT/effect-ts@v4-beta-legacy" /path/to/consumer/repos/effect
```

This is a manual, one-off step. It is not automated.
