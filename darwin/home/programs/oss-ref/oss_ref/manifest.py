from __future__ import annotations

import json
import re
from pathlib import Path
from typing import cast

from .errors import OssRefError, ValidationError
from .models import Reference, ResolvedReference

_PACKAGE = re.compile(r"^(?:@[a-z0-9][a-z0-9._-]*/)?[a-z0-9][a-z0-9._-]*$")
_VERSION = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$")
_CONTROL = re.compile(r"[\x00-\x1f\x7f]")


def _text(value: object, field: str) -> str:
    if not isinstance(value, str) or not value or _CONTROL.search(value):
        raise ValidationError(f"{field} must be a non-empty text value")
    return value


def _object_map(value: object, field: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise ValidationError(f"{field} must be an object")
    object_map = cast(dict[object, object], value)
    if not all(isinstance(key, str) for key in object_map):
        raise ValidationError(f"{field} must be an object")
    return cast(dict[str, object], object_map)


def read_manifest(path: Path) -> tuple[Path, tuple[Reference, ...]]:
    try:
        raw = cast(object, json.loads(path.read_text()))
    except (OSError, json.JSONDecodeError) as error:
        raise ValidationError(f"invalid manifest: {path}: {error}") from error
    document = _object_map(raw, "manifest")
    if set(document) != {"references"}:
        raise ValidationError("expected a references object")
    reference_entries = _object_map(document["references"], "references")

    references: list[Reference] = []
    for name, raw_entry in reference_entries.items():
        name = _text(name, "reference name")
        entry = _object_map(raw_entry, name)
        if set(entry) != {"package", "repository", "ref", "path"}:
            raise ValidationError(f"{name}: expected package, repository, ref, and path")
        package = _text(entry["package"], f"{name}.package")
        repository = _text(entry["repository"], f"{name}.repository")
        template = _text(entry["ref"], f"{name}.ref")
        raw_path = _text(entry["path"], f"{name}.path")
        relative_path = Path(raw_path)
        if not _PACKAGE.fullmatch(package):
            raise ValidationError(f"{name}: invalid package name")
        if "{version}" not in template:
            raise ValidationError(f"{name}: ref must contain {{version}}")
        if relative_path.is_absolute() or ".." in relative_path.parts or raw_path == ".":
            raise ValidationError(f"{name}: reference path must be relative and stay inside the project")
        references.append(Reference(name, package, repository, template, relative_path))
    if not references:
        raise ValidationError("references must not be empty")
    return path.parent.resolve(), tuple(references)


def installed_version(project: Path, package: str) -> str:
    for directory in (project, *project.parents):
        metadata = directory / "node_modules" / package / "package.json"
        if not metadata.is_file():
            continue
        try:
            raw = cast(object, json.loads(metadata.read_text()))
        except (OSError, json.JSONDecodeError) as error:
            raise OssRefError(f"cannot read installed metadata for {package}: {error}") from error
        metadata_values = _object_map(raw, f"installed metadata for {package}")
        version = metadata_values.get("version") if metadata_values.get("name") == package else None
        if isinstance(version, str) and _VERSION.fullmatch(version):
            return version
        raise OssRefError(f"cannot read installed version of {package}; install dependencies first")
    raise OssRefError(f"cannot read installed version of {package}; install dependencies first")


def resolve_references(manifest: Path) -> tuple[ResolvedReference, ...]:
    project, references = read_manifest(manifest)
    resolved: list[ResolvedReference] = []
    for reference in references:
        version = installed_version(project, reference.package)
        ref = reference.ref_template.replace("{version}", version)
        destination = (project / reference.relative_path).absolute()
        try:
            _ = destination.parent.resolve().relative_to(project)
        except ValueError as error:
            raise ValidationError(f"{reference.name}: reference path escapes project") from error
        if any(
            destination == existing.destination
            or destination in existing.destination.parents
            or existing.destination in destination.parents
            for existing in resolved
        ):
            raise ValidationError(f"{reference.name}: overlapping reference path")
        resolved.append(ResolvedReference(reference, version, ref, destination))
    return tuple(resolved)
