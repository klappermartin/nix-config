from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

import pytest


def git(*args: str) -> None:
    subprocess.run(["git", *args], check=True, capture_output=True, text=True)


def oss_ref(*args: str, env: dict[str, str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [os.environ["OSS_REF_BIN"], *args], env=env, check=check, capture_output=True, text=True
    )


@pytest.fixture
def environment(tmp_path: Path) -> dict[str, object]:
    project = tmp_path / "projects" / "app with spaces"
    metadata = project / "node_modules" / "@fixture" / "library" / "package.json"
    metadata.parent.mkdir(parents=True)
    upstream = tmp_path / "upstream"
    git("init", "-q", str(upstream))
    git("-C", str(upstream), "config", "user.email", "test@example.invalid")
    git("-C", str(upstream), "config", "user.name", "Test")
    (upstream / "source.txt").write_text("first\n")
    git("-C", str(upstream), "add", "source.txt")
    git("-C", str(upstream), "commit", "-qm", "first")
    git("-C", str(upstream), "tag", "library@1.0.0")
    (upstream / "source.txt").write_text("second\n")
    git("-C", str(upstream), "commit", "-am", "second")
    git("-C", str(upstream), "tag", "library@1.1.0")
    metadata.write_text(json.dumps({"name": "@fixture/library", "version": "1.0.0"}))
    manifest = project / ".oss-references.json"
    manifest.write_text(
        json.dumps(
            {
                "references": {
                    "library": {
                        "package": "@fixture/library",
                        "repository": str(upstream),
                        "ref": "library@{version}",
                        "path": "repos/library",
                    }
                }
            }
        )
    )
    env = os.environ | {
        "OSS_REFERENCES_ROOT": str(tmp_path / "store"),
        "OSS_REFERENCES_CONSUMER_ROOTS": str(tmp_path / "projects"),
        "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_CONFIG_GLOBAL": os.devnull,
        "GIT_TERMINAL_PROMPT": "0",
    }
    return {"project": project, "manifest": manifest, "metadata": metadata, "env": env}


def test_sync_check_upgrade_and_dirty_checkout(environment: dict[str, object]) -> None:
    env = environment["env"]
    project = environment["project"]
    manifest = environment["manifest"]
    metadata = environment["metadata"]
    assert isinstance(env, dict) and isinstance(project, Path) and isinstance(manifest, Path) and isinstance(metadata, Path)

    assert oss_ref("check", str(manifest), env=env, check=False).returncode == 1
    oss_ref("sync", str(manifest), env=env)
    oss_ref("check", str(manifest), env=env)
    target = (project / "repos/library").resolve()
    assert (target / "source.txt").read_text() == "first\n"

    metadata.write_text(json.dumps({"name": "@fixture/library", "version": "1.1.0"}))
    assert oss_ref("check", str(manifest), env=env, check=False).returncode == 1
    oss_ref("sync", str(manifest), env=env)
    target = (project / "repos/library").resolve()
    assert (target / "source.txt").read_text() == "second\n"

    git("-C", str(target), "config", "remote.origin.url", "wrong-repository")
    assert oss_ref("check", str(manifest), env=env, check=False).returncode == 1
    assert oss_ref("sync", str(manifest), env=env, check=False).returncode == 1
    git("-C", str(target), "config", "remote.origin.url", str(Path(str(environment["project"])).parents[1] / "upstream"))

    (target / "source.txt").write_text("edited\n")
    assert oss_ref("check", str(manifest), env=env, check=False).returncode == 1
    assert oss_ref("sync", str(manifest), env=env, check=False).returncode == 1


def test_sync_preserves_real_directories_and_last_working_link(environment: dict[str, object]) -> None:
    env = environment["env"]
    project = environment["project"]
    manifest = environment["manifest"]
    metadata = environment["metadata"]
    assert isinstance(env, dict) and isinstance(project, Path) and isinstance(manifest, Path) and isinstance(metadata, Path)
    oss_ref("sync", str(manifest), env=env)
    destination = project / "repos/library"
    old_target = destination.resolve()
    destination.unlink()
    destination.mkdir()
    keep = destination / "keep.txt"
    keep.write_text("keep\n")
    assert oss_ref("sync", str(manifest), env=env, check=False).returncode == 1
    assert keep.read_text() == "keep\n"
    keep.unlink()
    destination.rmdir()
    oss_ref("sync", str(manifest), env=env)
    metadata.write_text(json.dumps({"name": "@fixture/library", "version": "9.9.9"}))
    assert oss_ref("sync", str(manifest), env=env, check=False).returncode == 1
    assert destination.resolve() == old_target


def test_manifest_path_escape_is_rejected(environment: dict[str, object]) -> None:
    env = environment["env"]
    manifest = environment["manifest"]
    assert isinstance(env, dict) and isinstance(manifest, Path)
    data = json.loads(manifest.read_text())
    data["references"]["library"]["path"] = "../outside"
    manifest.write_text(json.dumps(data))
    assert oss_ref("sync", str(manifest), env=env, check=False).returncode == 2


def test_prune_keeps_broken_links_into_store(environment: dict[str, object]) -> None:
    env = environment["env"]
    assert isinstance(env, dict)
    root = Path(env["OSS_REFERENCES_ROOT"])
    projects = Path(env["OSS_REFERENCES_CONSUMER_ROOTS"])
    protected = root / "protected@1"
    relative = root / "relative@1"
    aliased = root / "aliased@1"
    orphan = root / "orphan@1"
    protected.mkdir(parents=True)
    relative.mkdir()
    aliased.mkdir()
    orphan.mkdir()
    link = projects / "other/repos/link"
    link.parent.mkdir(parents=True)
    link.symlink_to(protected / "missing")
    relative_link = projects / "relative/repos/link"
    relative_link.parent.mkdir(parents=True)
    relative_link.symlink_to("../../../store/relative@1")
    alias = root.parent / "alias-target"
    alias.symlink_to(aliased, target_is_directory=True)
    aliased_link = projects / "aliased/repos/link"
    aliased_link.parent.mkdir(parents=True)
    aliased_link.symlink_to(alias, target_is_directory=True)
    result = oss_ref("prune", "--dry-run", env=env)
    assert "orphan@1  orphan" in result.stdout
    assert "protected@1" not in result.stdout
    assert "relative@1" not in result.stdout
    assert "aliased@1" not in result.stdout
    oss_ref("prune", "--yes", env=env)
    assert protected.is_dir()
    assert relative.is_dir()
    assert aliased.is_dir()
    assert not orphan.exists()
