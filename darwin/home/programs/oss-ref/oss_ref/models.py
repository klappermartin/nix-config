from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Reference:
    name: str
    package: str
    repository: str
    ref_template: str
    relative_path: Path


@dataclass(frozen=True)
class ResolvedReference:
    reference: Reference
    version: str
    ref: str
    destination: Path


@dataclass(frozen=True)
class Settings:
    root: Path
    consumer_roots: tuple[Path, ...]
