from __future__ import annotations

import os
import re
import shutil
import tempfile
from collections.abc import Generator
from contextlib import contextmanager, suppress
from pathlib import Path

from .errors import OssRefError, UsageError
from .git import clone_at_ref, run_git
from .models import Settings


def settings_from_environment(*, validate_consumer_roots: bool = True) -> Settings:
    root = Path(os.environ.get("OSS_REFERENCES_ROOT", "~/code/others/oss-references")).expanduser()
    raw_roots = os.environ.get("OSS_REFERENCES_CONSUMER_ROOTS", "~/code")
    if not raw_roots or raw_roots.startswith(":") or raw_roots.endswith(":") or "::" in raw_roots:
        raise OssRefError("consumer roots must not contain empty entries")
    roots: list[Path] = []
    for raw_root in raw_roots.split(":"):
        consumer_root = Path(raw_root).expanduser()
        if validate_consumer_roots and (
            not consumer_root.is_dir() or not os.access(consumer_root, os.R_OK | os.X_OK)
        ):
            raise OssRefError(f"consumer root is missing or unreadable: {consumer_root}")
        roots.append(consumer_root.resolve())
    return Settings(root, tuple(roots))


def sanitized_version(version: str) -> str:
    value = version.replace("/", "-")
    value = re.sub(r"[^A-Za-z0-9._+-]+", "-", value)
    return re.sub(r"-+", "-", value).strip("-")


def repository_slug(repository: str) -> str:
    return Path(repository.rstrip("/")).name.removesuffix(".git")


def clone_path(root: Path, repository: str, ref: str) -> Path:
    slug = repository_slug(repository)
    version = sanitized_version(ref)
    if not slug or not version or ref.startswith("-"):
        raise UsageError("invalid repository slug or version")
    return root / f"{slug}@{version}"


@contextmanager
def operation(settings: Settings) -> Generator[tuple[Path, Path], None, None]:
    settings.root.mkdir(parents=True, exist_ok=True)
    root = settings.root.resolve()
    if any(consumer == root or root in consumer.parents for consumer in settings.consumer_roots):
        raise OssRefError("consumer roots must be outside the references store")
    lock = root / ".lock"
    try:
        lock.mkdir()
    except FileExistsError as error:
        raise OssRefError(f"another operation is running (or left a stale lock): {lock}") from error
    workdir: Path | None = None
    try:
        _ = (lock / "pid").write_text(f"{os.getpid()}\n")
        partial = root / ".partial"
        partial.mkdir(exist_ok=True)
        workdir = Path(tempfile.mkdtemp(prefix="operation.", dir=partial))
        yield root, workdir
    finally:
        if workdir is not None:
            shutil.rmtree(workdir, ignore_errors=True)
        (lock / "pid").unlink(missing_ok=True)
        with suppress(OSError):
            lock.rmdir()


def verify_clone(target: Path, repository: str, ref: str, *, clean: bool) -> bool:
    if target.is_symlink() or not target.is_dir() or not (target / ".git").is_dir():
        return False
    try:
        origin = run_git(["config", "--get", "remote.origin.url"], cwd=target, capture=True)
        expected = run_git(["rev-parse", "--verify", f"{ref}^{{commit}}"], cwd=target, capture=True)
        actual = run_git(["rev-parse", "HEAD"], cwd=target, capture=True)
        try:
            recorded = run_git(["config", "--get", "oss-ref.version"], cwd=target, capture=True)
        except OssRefError:
            recorded = ""
    except OssRefError:
        return False
    if origin != repository or expected != actual or (recorded and recorded != ref):
        return False
    if not clean:
        return True
    try:
        return not run_git(
            ["--no-optional-locks", "status", "--porcelain", "--untracked-files=no"], cwd=target, capture=True
        )
    except OssRefError:
        return False


def add_reference(settings: Settings, repository: str, ref: str, destination: Path) -> Path:
    destination = destination.absolute()
    parent = destination.parent.resolve()
    if not any(parent == consumer or consumer in parent.parents for consumer in settings.consumer_roots):
        raise OssRefError(f"consumer must be under a configured consumer root: {destination}")
    if destination.exists() and not destination.is_symlink():
        raise OssRefError(f"refusing to replace a real file or directory: {destination}")

    with operation(settings) as (root, workdir):
        target = clone_path(root, repository, ref)
        if target.exists() or target.is_symlink():
            if not verify_clone(target, repository, ref, clean=False):
                raise OssRefError(f"existing clone does not match requested repository/version: {target}")
            print(f"Reusing: {target}")
        else:
            staging = workdir / "clone"
            clone_at_ref(repository, ref, staging)
            _ = run_git(["config", "oss-ref.version", ref], cwd=staging)
            _ = staging.replace(target)
            print(f"Created: {target}")

        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.is_symlink() or destination.exists():
            destination.unlink()
        destination.symlink_to(target, target_is_directory=True)
        print(f"Symlink: {destination} -> {target}")
        return target
