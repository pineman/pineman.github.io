#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LINKS_FILE = REPO_ROOT / "notes" / "links.md"
LINK_LINE_RE = re.compile(r"^\*\s+(\S+)")
HEADER_RE = re.compile(r"^#\s+(.+)")


@dataclass(frozen=True)
class LinkEntry:
    url: str
    key: str
    line_number: int
    section: str | None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Find duplicate links in notes/links.md.",
    )
    parser.add_argument(
        "path",
        nargs="?",
        default=DEFAULT_LINKS_FILE,
        type=Path,
        help=f"Path to the links markdown file (default: {DEFAULT_LINKS_FILE})",
    )
    parser.add_argument(
        "--mode",
        choices=("exact", "normalized"),
        default="exact",
        help=(
            "How to compare URLs. 'exact' uses the URL as written. "
            "'normalized' lowercases scheme/host, strips fragments, trims "
            "non-root trailing slashes, and drops utm_* query params."
        ),
    )
    parser.add_argument(
        "--fail-on-dupes",
        action="store_true",
        help="Exit with status 1 when duplicates are found.",
    )
    return parser.parse_args()


def is_url(value: str) -> bool:
    parts = urlsplit(value)
    return parts.scheme in {"http", "https"} and bool(parts.netloc)


def normalize_url(url: str) -> str:
    parts = urlsplit(url)
    path = parts.path or "/"
    if path != "/":
        path = path.rstrip("/")
        if not path:
            path = "/"

    query_pairs = [
        (key, value)
        for key, value in parse_qsl(parts.query, keep_blank_values=True)
        if not key.lower().startswith("utm_")
    ]
    query = urlencode(query_pairs, doseq=True)

    return urlunsplit((parts.scheme.lower(), parts.netloc.lower(), path, query, ""))


def parse_links(path: Path, mode: str) -> list[LinkEntry]:
    entries: list[LinkEntry] = []
    current_section: str | None = None

    for line_number, line in enumerate(path.read_text().splitlines(), start=1):
        header_match = HEADER_RE.match(line)
        if header_match:
            current_section = header_match.group(1)
            continue

        link_match = LINK_LINE_RE.match(line)
        if not link_match:
            continue

        url = link_match.group(1)
        if not is_url(url):
            continue

        key = normalize_url(url) if mode == "normalized" else url
        entries.append(
            LinkEntry(
                url=url,
                key=key,
                line_number=line_number,
                section=current_section,
            )
        )

    return entries


def find_duplicates(entries: list[LinkEntry]) -> dict[str, list[LinkEntry]]:
    grouped: dict[str, list[LinkEntry]] = defaultdict(list)
    for entry in entries:
        grouped[entry.key].append(entry)
    return {key: value for key, value in grouped.items() if len(value) > 1}


def print_duplicates(path: Path, duplicates: dict[str, list[LinkEntry]], mode: str) -> None:
    if not duplicates:
        print(f"No duplicate links found in {path} (mode: {mode}).")
        return

    duplicate_groups = sorted(
        duplicates.items(),
        key=lambda item: (-len(item[1]), item[0]),
    )
    repeated_entries = sum(len(entries) - 1 for _, entries in duplicate_groups)

    print(
        f"Found {len(duplicate_groups)} duplicate groups "
        f"({repeated_entries} repeated entries) in {path} (mode: {mode})."
    )
    print()

    for key, entries in duplicate_groups:
        print(f"{len(entries)}x {key}")
        for entry in entries:
            section = entry.section or "unknown section"
            print(f"  line {entry.line_number:>4} [{section}] {entry.url}")
        print()


def main() -> int:
    args = parse_args()
    path = args.path.expanduser().resolve()

    if not path.exists():
        print(f"File not found: {path}", file=sys.stderr)
        return 2

    entries = parse_links(path, args.mode)
    duplicates = find_duplicates(entries)
    print_duplicates(path, duplicates, args.mode)

    if duplicates and args.fail_on_dupes:
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
