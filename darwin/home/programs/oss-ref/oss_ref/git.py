from __future__ import annotations

import subprocess
from collections.abc import Sequence
from pathlib import Path

from .errors import OssRefError


def run_git(args: Sequence[str], *, cwd: Path | None = None, capture: bool = False) -> str:
    completed = subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=False,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    if completed.returncode != 0:
        details = (completed.stderr or "").strip()
        raise OssRefError(details or f"git {' '.join(args)} failed")
    return (completed.stdout or "").strip()


def clone_at_ref(repository: str, ref: str, destination: Path) -> None:
    try:
        _ = run_git(["clone", "--depth=1", "--branch", ref, "--", repository, str(destination)])
    except OssRefError:
        if destination.exists():
            # The staging directory is private to the caller.
            import shutil

            shutil.rmtree(destination)
        _ = run_git(["clone", "--filter=blob:none", "--", repository, str(destination)])
        _ = run_git(["checkout", "--detach", ref], cwd=destination)
