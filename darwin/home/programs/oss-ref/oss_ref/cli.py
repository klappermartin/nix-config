from __future__ import annotations

import argparse
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import Protocol, cast

from .errors import OssRefError
from .prune import prune
from .references import check, manifest_path, sync
from .store import add_reference, settings_from_environment


class AddArguments(Protocol):
    git_url: str
    version: str
    symlink_path: Path


class ManifestArguments(Protocol):
    manifest: str | None


class PruneArguments(Protocol):
    yes: bool
    dry_run: bool
    min_age: str | None
    verbose: bool


def parser() -> argparse.ArgumentParser:
    command_parser = argparse.ArgumentParser(
        prog="oss-ref", description="Manage version-pinned open-source source references."
    )
    commands = command_parser.add_subparsers(dest="command")

    add = commands.add_parser("add", help="Clone a reference and create a consumer symlink.")
    _ = add.add_argument("git_url")
    _ = add.add_argument("version")
    _ = add.add_argument("symlink_path", type=Path)

    for name, help_text in (("sync", "Sync references to installed npm package versions."), ("check", "Check references.")):
        manifest = commands.add_parser(name, help=help_text)
        _ = manifest.add_argument("manifest", nargs="?")

    prune_parser = commands.add_parser("prune", help="Remove unreferenced clones.")
    prune_group = prune_parser.add_mutually_exclusive_group()
    _ = prune_group.add_argument("--yes", action="store_true")
    _ = prune_group.add_argument("--dry-run", action="store_true")
    _ = prune_parser.add_argument("--min-age")
    _ = prune_parser.add_argument("-v", "--verbose", action="store_true")
    _ = commands.add_parser("list", help="List stored clones.")
    return command_parser


def main(argv: Sequence[str] | None = None) -> int:
    command_parser = parser()
    parsed = command_parser.parse_args(argv)
    command = cast(str | None, parsed.command)
    if command is None:
        command_parser.print_help()
        return 0
    try:
        settings = settings_from_environment(validate_consumer_roots=command != "list")
        if command == "add":
            add = cast(AddArguments, cast(object, parsed))
            _ = add_reference(settings, add.git_url, add.version, add.symlink_path)
        elif command == "sync":
            manifest = cast(ManifestArguments, cast(object, parsed))
            sync(settings, manifest_path(manifest.manifest))
        elif command == "check":
            manifest = cast(ManifestArguments, cast(object, parsed))
            check(settings, manifest_path(manifest.manifest))
        elif command == "prune":
            prune_arguments = cast(PruneArguments, cast(object, parsed))
            prune(
                settings,
                yes=prune_arguments.yes,
                dry_run=prune_arguments.dry_run,
                min_age=prune_arguments.min_age,
                verbose=prune_arguments.verbose,
            )
        elif command == "list" and settings.root.is_dir():
            for clone in sorted(path.name for path in settings.root.iterdir() if path.is_dir() and "@" in path.name):
                print(clone)
        return 0
    except OssRefError as error:
        print(f"[oss-ref] ERROR: {error}", file=sys.stderr)
        return error.exit_code


if __name__ == "__main__":
    raise SystemExit(main())
