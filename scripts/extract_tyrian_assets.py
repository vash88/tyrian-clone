#!/usr/bin/env python3

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Canonical entrypoint for extracting Tyrian gameplay assets."
    )
    parser.add_argument(
        "target",
        choices=("all", "manifest", "items", "levels", "level-enemies", "ships", "pickups", "ui", "enemies", "enemy-definitions", "tiles", "projectiles", "sidekicks"),
        nargs="?",
        default="all",
        help="Asset family to extract",
    )
    return parser.parse_args()


def run_script(script_name: str) -> None:
    script_path = Path(__file__).resolve().parent / script_name
    subprocess.run([sys.executable, str(script_path)], check=True)


def main() -> None:
    args = parse_args()

    if args.target in ("all", "manifest"):
        run_script("build_tyrian_source_manifest.py")

    if args.target in ("all", "items"):
        run_script("parse_tyrian_item_data.py")

    if args.target in ("all", "levels"):
        run_script("extract_tyrian_level_usage.py")

    if args.target in ("all", "level-enemies"):
        run_script("extract_tyrian_level_enemy_usage.py")

    if args.target in ("all", "ships"):
        run_script("extract_tyrian_sprite_sheet9.py")

    if args.target in ("all", "pickups"):
        run_script("extract_tyrian_pickup_atlas.py")

    if args.target in ("all", "ui"):
        run_script("extract_tyrian_sprite_tables.py")

    if args.target in ("all", "enemies"):
        run_script("extract_tyrian_enemy_banks.py")

    if args.target in ("all", "enemy-definitions"):
        run_script("extract_tyrian_enemy_definitions.py")

    if args.target in ("all", "tiles"):
        run_script("extract_tyrian_tilesets.py")

    if args.target in ("all", "projectiles"):
        run_script("extract_tyrian_projectiles.py")

    if args.target in ("all", "sidekicks"):
        run_script("extract_tyrian_sidekicks.py")


if __name__ == "__main__":
    main()
