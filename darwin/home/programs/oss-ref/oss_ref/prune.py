from __future__ import annotations

import os
import shutil
import sys
import time
from pathlib import Path

from .errors import OssRefError, UsageError
from .models import Settings
from .store import operation


def _referenced_clones(root: Path, consumer_roots: tuple[Path, ...], *, verbose: bool) -> set[Path]:
    referenced: set[Path] = set()
    for consumer in consumer_roots:
        def scan_error(error: OSError, consumer_root: Path = consumer) -> None:
            raise OssRefError(f"incomplete consumer scan; refusing to prune: {consumer_root}: {error}") from error

        try:
            if verbose:
                print(f"[oss-ref] Scanning: {consumer}", file=sys.stderr)
            for directory, directories, files in os.walk(consumer, followlinks=False, onerror=scan_error):
                for name in (*directories, *files):
                    link = Path(directory) / name
                    if not link.is_symlink():
                        continue
                    try:
                        resolved = link.resolve(strict=False)
                    except RuntimeError as error:
                        raise OssRefError(f"cannot resolve consumer link; refusing to prune: {link}") from error
                    try:
                        relative = resolved.relative_to(root)
                    except ValueError:
                        continue
                    if relative.parts:
                        referenced.add(root / relative.parts[0])
        except OSError as error:
            raise OssRefError(f"incomplete consumer scan; refusing to prune: {consumer}: {error}") from error
    return referenced


def _minutes(value: str) -> int:
    if len(value) < 2 or value[-1] not in "dhm" or not value[:-1].isdigit():
        raise UsageError("--min-age format: Nd, Nh, Nm")
    multiplier = {"d": 1440, "h": 60, "m": 1}[value[-1]]
    return int(value[:-1]) * multiplier


def prune(settings: Settings, *, yes: bool, dry_run: bool, min_age: str | None, verbose: bool) -> None:
    if not settings.root.is_dir():
        print(f"nothing to prune (root missing: {settings.root})")
        return
    if not dry_run and not yes and not sys.stdin.isatty():
        raise UsageError("refusing to prompt on non-tty; pass --yes or --dry-run")
    minimum = _minutes(min_age) if min_age else 0
    with operation(settings) as (root, _workdir):
        candidates = sorted(path for path in root.iterdir() if path.is_dir() and not path.is_symlink() and "@" in path.name)
        referenced = _referenced_clones(root, settings.consumer_roots, verbose=verbose)
        eligible = [
            candidate
            for candidate in candidates
            if candidate not in referenced and (minimum == 0 or (time.time() - candidate.stat().st_mtime) / 60 >= minimum)
        ]
        pruned = 0
        for candidate in eligible:
            if dry_run:
                print(f"{candidate.name}  orphan")
                continue
            if not yes:
                answer = input(f"Delete orphan {candidate.name}? [y/N] ")
                if answer.lower() not in {"y", "yes"}:
                    continue
            shutil.rmtree(candidate)
            print(f"Pruned: {candidate.name}")
            pruned += 1
        if not dry_run and pruned == 0:
            print("nothing to prune")
