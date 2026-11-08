# Execution surfaces

How to run the engines on each surface, and when to escalate between them.

> **Standalone OpenCode policy:** use the active project's declared environment first. In a
> devenv project, prefix commands in this page with `devenv shell`. When it lacks a required
> tool, use an ephemeral `nix shell` with the exact package set instead of installing anything
> globally. Do not run the bundled dependency installers or `uv --with` automatically.

## Persistent kernel, JavaScript (Bun)

Use this only when the active project environment already declares `@duckdb/node-api`. The
bundled installer is for explicitly approved ad-hoc environments, not routine skill use:

```bash
bash scripts/ensure-js-deps.sh          # run from the skill directory
```

In the kernel — top-level `require` may not exist, dynamic import always works:

```js
const { DuckDBInstance } = await import("<printed path>");
const db = await DuckDBInstance.create(":memory:");
const conn = await db.connect();
const reader = await conn.runAndReadAll("SELECT category, SUM(v) AS total FROM 'data.csv' GROUP BY 1");
reader.getRowObjects();                  // array of plain row objects
```

- The connection and any tables created live across cells — connect once per session, reuse.
- COUNT/SUM over integer columns return BigInt; convert (`Number(x)` or `String(x)`) before
  `JSON.stringify`, which throws on BigInt.
- Bun builtins cover ingest gaps with zero installs: `Bun.JSONL.parse`, `Bun.JSON5.parse`,
  `Bun.XML.parse`, `Bun.TOML.parse`, `Bun.Archive` for tarballs.
- nodejs-polars is NOT part of this skill's toolkit: its API lags the Python release by
  major versions (option objects that work in Python throw napi type errors). Polars work
  belongs to the Python kernel (below).

## Persistent kernel, Python (the default Python surface)

When DuckDB, NumPy, Matplotlib, Polars, or PyArrow are declared in the active environment,
import and use them directly. Do not inject missing packages into a user cache during routine
skill use; use an ephemeral Nix environment with the required Python packages instead. The
following installer example is only for an explicitly approved persistent setup:

```python
import subprocess, sys
site = subprocess.run(["bash", "scripts/ensure-py-deps.sh", sys.executable],
                      capture_output=True, text=True, check=True).stdout.strip()
sys.path.insert(0, site)
import polars as pl
import pyarrow
```

- The install goes to a user cache keyed to the kernel's interpreter version; the
  interpreter itself is never mutated (it is frequently an externally-managed system
  Python, and mutating it breaks other tools).
- After injection the whole Python stack is resident: `duckdb.sql(...).pl()` hands off via
  Arrow, `duckdb.register(name, df)` goes the other way, and Polars lazy pipelines run
  in-kernel across cells.
- `duckdb.sql("SELECT ... FROM 'data.csv'")` queries files in place; without the injection,
  keep results in DuckDB or fetch plain Python values (`.fetchall()`).
- matplotlib figures render natively in kernels that display rich output; also save a PNG so
  the artifact survives the session.

## uv lane (explicit ad-hoc fallback and isolation)

```bash
uv run --with duckdb --with polars --with pyarrow --with numpy python -c "<code>"
```

- Reach for it only with explicit approval when there is no kernel, or when a heavy, crash-prone one-shot should not
  run inside (and possibly take down) the kernel.
- Include exactly the packages the code imports, plus pyarrow whenever `.pl()` is used.
- Each invocation pays process spawn plus imports (roughly 0.3s warm) and re-reads its inputs —
  fine for one-shots, wasteful for exploration loops.
- Past a few lines, a temp file beats `-c` quoting: write the script, `uv run script.py`.

## No kernel at all

Use project-declared engines, one process per batch of questions. In a devenv project, run the
command as `devenv shell <command>`:

```bash
bun -e '<the JavaScript kernel pattern above>'         # DuckDB via @duckdb/node-api
uv run --with duckdb python -c "<sql via duckdb.sql>"  # DuckDB via Python
uv run scripts/quick-query.py data.csv "SELECT ..."    # zero-code CLI fallback
```

## Escalation rules

Start on the resident kernel. Move a step down when a concrete need appears:

- polars/pyarrow missing from the kernel — use an ephemeral Nix environment with those
  packages. Do not inject them into a user cache.
- Crash-prone or memory-hungry one-shot that should not take the kernel down — uv lane.
- No kernel on this harness — one-shot recipes above.
- Data lives remotely or exceeds local RAM — read `placement.md` and move the query, not
  the data.
