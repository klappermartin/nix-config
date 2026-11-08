from __future__ import annotations

import sys
from pathlib import Path

from .errors import OssRefError, UsageError
from .manifest import resolve_references
from .models import Settings
from .store import add_reference, clone_path, verify_clone


def manifest_path(argument: str | None) -> Path:
    path = Path(argument or ".oss-references.json")
    if not path.is_file():
        raise UsageError(f"manifest not found: {path}")
    return path.resolve()


def sync(settings: Settings, manifest: Path) -> None:
    for resolved in resolve_references(manifest):
        print(f"Syncing {resolved.reference.name}: installed {resolved.version} -> {resolved.ref}")
        target = add_reference(settings, resolved.reference.repository, resolved.ref, resolved.destination)
        if not verify_clone(target, resolved.reference.repository, resolved.ref, clean=True):
            raise OssRefError(f"reference checkout is modified: {target}")


def check(settings: Settings, manifest: Path) -> None:
    failures = 0
    for resolved in resolve_references(manifest):
        target = clone_path(settings.root.resolve(), resolved.reference.repository, resolved.ref)
        matches = False
        try:
            matches = resolved.destination.is_symlink() and resolved.destination.resolve() == target and verify_clone(
                target, resolved.reference.repository, resolved.ref, clean=True
            )
        except (OSError, RuntimeError):
            matches = False
        if matches:
            print(f"OK {resolved.reference.name}: installed {resolved.version} -> {resolved.ref}")
        else:
            print(
                f"[oss-ref] ERROR: STALE {resolved.reference.name}: installed {resolved.version} expects {resolved.ref} at {resolved.destination}",
                file=sys.stderr,
            )
            failures += 1
    if failures:
        raise OssRefError("Run oss-ref sync to refresh missing/stale links; inspect conflicting or modified checkouts before retrying.")
