---
name: data-scientist
description: "Processes and analyzes data with resident-kernel engines (DuckDB, Polars) and one-shot tools. Use for CSV/parquet/JSON analysis, group-by/join/aggregation, time series, distributions, cleaning, or plotting a dataset."
---

# Data Scientist: Hybrid-Engine Data Processing

Answer data questions through the cheapest engine and surface that can prove the answer, and
decide where the computation should live before touching the data.

## Project environment first

Never install Python, `uv`, or data packages globally to run this skill. Resolve an execution
environment in this order:

1. Use the interpreter and tools already on `PATH` when they belong to the active project
   environment.
2. In a repository with `devenv.nix` or `devenv.yaml`, run commands through its declared
   environment, for example `devenv shell python3 path/to/script.py` or
   `devenv shell uv run path/to/script.py`.
3. If the project environment lacks a required tool or library, run the required command in an
   ephemeral `nix shell`. For Python data work, use `nix shell nixpkgs#python3
   nixpkgs#python3Packages.duckdb nixpkgs#python3Packages.polars
   nixpkgs#python3Packages.pyarrow nixpkgs#python3Packages.numpy --command python3 ...`.
   This does not install anything globally or modify the project.

Do not automatically use `uv --with`, `uv tool install`, `pip install`, or either `setup-uv`
script. The environment rule takes precedence over installer and one-shot examples in this
skill's references.

## Execution surfaces: resident kernel first

A persistent REPL/eval kernel (many harnesses expose one for JavaScript and Python) is the
default surface. Reason: each one-shot process pays roughly a second of spawn-plus-import
overhead and re-scans the input file, while a resident connection amortizes both — after a
one-time load, repeat queries return in milliseconds. Exploration is repeat queries, so this
difference dominates the session.

1. **JavaScript kernel (Bun)**: use it when the active project environment already provides
   `@duckdb/node-api`; dynamic-import it, connect once, query across cells.
2. **Python kernel**: the default Python surface when its project environment provides the
   needed libraries. Use DuckDB/Polars/Arrow directly; use the Nix fallback rather than
   injecting missing packages into a user cache.
3. **Project-provided uv lane** (`devenv shell uv run ...`): isolation for a heavy or
   crash-prone one-shot that should not take the kernel down.
4. **No kernel**: run a declared project command through devenv, batching several questions per
   process. If no project environment declares a suitable engine, use the Nix fallback above.

Per-surface patterns and pitfalls: read `references/execution-surfaces.md` before first use.

## Engine selection

- **DuckDB** for SQL-shaped work: direct file queries, joins, aggregation, subqueries,
  window functions. It queries CSV/Parquet/JSON in place without loading, spills to disk
  past its memory limit, and reads remote files with the same syntax.
- **Polars** when the pipeline is DataFrame-shaped: expression-chain transforms, reshapes,
  streaming datasets past RAM — provided by the active Python environment.
  Read `references/polars-lane.md` — the current 1.x API differs from widely-memorized
  older spellings.
- **numpy** when numeric work goes beyond SQL/DataFrame aggregation: statistical tests,
  linear algebra, FFT, random sampling.
- **matplotlib** for charts in a kernel, a file or a document; a chart shown inline beside a
  reply is drawn in HTML instead. Read `references/visualization.md` first either way; it
  carries the quality bar, the inline case and a mandatory visual check.

Performance folklore ("X is Nx faster at filtering") varies with data shape, cardinality,
and hardware. When the engine choice materially matters, measure on the actual data instead
of trusting remembered multipliers.

## Placement: decide where the computation lives

Probe before you compute — one cell: file size, free RAM, and (when unclear) a row count via
a direct scan. Then place the work:

- **Load into memory** when the working set stays within roughly a quarter of free RAM AND
  the session will run repeated queries: `CREATE TABLE t AS SELECT ...` (or a collected
  DataFrame) once, then iterate. One scan up front converts every later query from a file
  re-scan into milliseconds.
- **Query in place / stream** when the question is single-pass, or the data exceeds RAM:
  DuckDB reads files directly (`FROM 'data.csv'`); past RAM, cap DuckDB's memory and let it
  spill, or use Polars' streaming engine in the Python kernel. NEVER load a larger-than-RAM
  dataset fully into memory — swapping stalls the whole machine, while streaming merely
  takes longer.
- **Query remotely, in place** when the data lives elsewhere: DuckDB reads http(s)/S3
  Parquet and CSV with projection and predicate pushdown, so fetch the columns and rows the
  question needs, never the whole file. When data sits in a database, run the aggregation
  there in its own SQL and pull back the result rows, never a table dump. When data sits on
  another machine you can execute on, ship the query to the data and return the small
  result. Rule: result much smaller than data — move the query; repeated local iteration
  planned — move a pruned copy of the data once.

Sizing heuristics and recipes: `references/placement.md`.

## Hard rules

- **NEVER use pandas.** DuckDB and Polars beat it decisively on every workload this skill
  covers, and the environments this skill assumes do not ship it — `.df()` on a DuckDB
  result raises unless pandas is installed; convert with `.pl()` via Arrow instead.
- Excel files are not read directly: export to CSV or Parquet first.

## Output contract

Answer the question; report row counts and timing for anything heavy; then stop — no bonus
charts, no extra exploration passes beyond what the question needed. Chart when asked, or
when the answer is a shape (trend, distribution, comparison) that prose cannot carry — then
follow `references/visualization.md` including its visual QA step.

## References

| Read | When |
| --- | --- |
| `references/execution-surfaces.md` | before the first query on any surface: kernel patterns, one-shot recipes, escalation rules |
| `references/polars-lane.md` | DataFrame-shaped pipeline or data past RAM: current API, Arrow handoff, package sets |
| `references/placement.md` | before heavy or remote work: sizing probe, memory limits, remote reads |
| `references/visualization.md` | before any chart: type selection, quality bar, CJK fonts, visual QA |
| `references/uv-setup.md` | an explicitly approved ad-hoc uv environment |

## CLI fallback

When no kernel or REPL surface exists, run `quick-query.py` through the declared project
environment or an ephemeral Nix environment containing `python3`, `duckdb`, `polars`, `pyarrow`,
`numpy`, `typer`, and `rich`. The CLI supports CSV, Parquet, JSON, NDJSON.
