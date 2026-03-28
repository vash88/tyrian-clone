#!/usr/bin/env python3

from __future__ import annotations

import json
import struct
from pathlib import Path

from tyrian_extract_core import repo_root_from_script


def shp_section_count(path: Path) -> int:
    with path.open("rb") as handle:
        return struct.unpack("<H", handle.read(2))[0]


def file_size(path: Path) -> int:
    return path.stat().st_size


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    ref_dir = repo_root / "references/tyrian21"
    out_dir = repo_root / "references/tyrian21-extracted"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "source-manifest.json"

    tyrian_shp = ref_dir / "tyrian.shp"
    tyrianc_shp = ref_dir / "tyrianc.shp"
    palette_dat = ref_dir / "palette.dat"
    tyrian_pic = ref_dir / "tyrian.pic"
    tyrian_hdt = ref_dir / "tyrian.hdt"

    levels_dat = sorted(ref_dir.glob("levels?.dat"))
    level_lumps = sorted(ref_dir.glob("tyrian?.lvl"))
    enemy_shape_files = sorted(ref_dir.glob("newsh*.shp"))
    tileset_files = sorted(ref_dir.glob("shapes*.dat"))

    manifest = {
        "sourceRoot": str(ref_dir),
        "canonicalRules": {
            "formats": {
                "sprite": {
                    "description": "Variable-size sprite records with per-sprite width, height, and encoded pixel data.",
                    "fixedGrid": False,
                    "primaryDecoder": "load_sprites",
                },
                "sprite2": {
                    "description": "Compressed sprite sheet format with 12-pixel logical rows and index-addressed records.",
                    "fixedGrid": True,
                    "primaryDecoder": "JE_loadCompShapesB / blit_sprite2",
                    "cellWidth": 12,
                    "rowAdvanceHeight": 14,
                },
                "tile-set": {
                    "description": "Level tileset graphics used by stages.",
                    "fixedGrid": "unknown-from-current-pipeline",
                    "primaryDecoder": "shapes?.dat level tile loader",
                },
                "level-script": {
                    "description": "Episode routing and between-level scripting.",
                    "fixedGrid": False,
                    "primaryDecoder": "levels?.dat episode script loader",
                },
                "level-data": {
                    "description": "Level tilemaps and event/script data.",
                    "fixedGrid": False,
                    "primaryDecoder": "tyrian?.lvl loader",
                },
                "palette-backed-background": {
                    "description": "Background image that requires palette.dat for correct colors.",
                    "fixedGrid": False,
                    "primaryDecoder": "tyrian.pic + palette.dat",
                },
            }
        },
        "sources": {
            "tyrian.shp": {
                "path": str(tyrian_shp),
                "sizeBytes": file_size(tyrian_shp),
                "sectionCount": shp_section_count(tyrian_shp),
                "families": [
                    {
                        "name": "interface-fonts-and-ui-sprites",
                        "sections": [1, 2, 3, 4, 5, 6, 7],
                        "format": "sprite",
                        "notes": "Loaded through load_sprites; these are variable-size assets and must not be decoded as a fixed 12x14 grid.",
                    },
                    {
                        "name": "player-shots-a",
                        "sections": [8],
                        "format": "sprite2",
                        "notes": "Loaded as spriteSheet8.",
                    },
                    {
                        "name": "player-ships",
                        "sections": [9],
                        "format": "sprite2",
                        "notes": "Loaded as spriteSheet9; ships are composed as 2x2 groups of 12x14 sprite2 cells.",
                    },
                    {
                        "name": "powerups",
                        "sections": [10],
                        "format": "sprite2",
                        "notes": "Loaded as spriteSheet10.",
                    },
                    {
                        "name": "coins-datacubes-and-misc-pickups",
                        "sections": [11],
                        "format": "sprite2",
                        "notes": "Loaded as spriteSheet11.",
                    },
                    {
                        "name": "player-shots-b",
                        "sections": [12],
                        "format": "sprite2",
                        "notes": "Loaded as spriteSheet12.",
                    },
                ],
            },
            "tyrianc.shp": {
                "path": str(tyrianc_shp),
                "sizeBytes": file_size(tyrianc_shp),
                "sectionCount": shp_section_count(tyrianc_shp),
                "format": "same-structure-as-tyrian.shp",
                "notes": "Christmas variant of tyrian.shp.",
            },
            "newsh*.shp": {
                "fileCount": len(enemy_shape_files),
                "files": [
                    {
                        "name": path.name,
                        "path": str(path),
                        "sizeBytes": file_size(path),
                        "format": "sprite2",
                    }
                    for path in enemy_shape_files
                ],
                "notes": "Enemy graphics are loaded through JE_loadCompShapes and should be treated as sprite2 banks, not variable-size Sprite records.",
            },
            "shapes*.dat": {
                "fileCount": len(tileset_files),
                "files": [
                    {
                        "name": path.name,
                        "path": str(path),
                        "sizeBytes": file_size(path),
                        "format": "tile-set",
                    }
                    for path in tileset_files
                ],
                "notes": "Level tileset graphics. These need a dedicated extractor rather than the current sprite pipeline.",
            },
            "tyrian?.lvl": {
                "fileCount": len(level_lumps),
                "files": [
                    {
                        "name": path.name,
                        "path": str(path),
                        "sizeBytes": file_size(path),
                        "format": "level-data",
                    }
                    for path in level_lumps
                ],
                "notes": "Level tilemaps and level event/script data.",
            },
            "levels?.dat": {
                "fileCount": len(levels_dat),
                "files": [
                    {
                        "name": path.name,
                        "path": str(path),
                        "sizeBytes": file_size(path),
                        "format": "level-script",
                    }
                    for path in levels_dat
                ],
                "notes": "Episode routing, shops, planets, datacubes, text, and level flow.",
            },
            "tyrian.hdt": {
                "path": str(tyrian_hdt),
                "sizeBytes": file_size(tyrian_hdt),
                "format": "data-definitions",
                "notes": "Items, weapons, ships, options, shields, enemy definitions, and interface strings.",
            },
            "palette.dat": {
                "path": str(palette_dat),
                "sizeBytes": file_size(palette_dat),
                "format": "palette",
                "notes": "Color palettes used by palette-backed assets such as tyrian.pic.",
            },
            "tyrian.pic": {
                "path": str(tyrian_pic),
                "sizeBytes": file_size(tyrian_pic),
                "format": "palette-backed-background",
                "notes": "Fullscreen interface backgrounds that require palette.dat.",
            },
        },
        "extractionPolicy": {
            "noUniversalGrid": True,
            "rules": [
                "Only decode an asset family with a fixed-grid extractor when the source format is explicitly sprite2.",
                "Use variable-size Sprite extraction for tyrian.shp sections 1 through 7.",
                "Treat ships as composite sprite2 families built from spriteSheet9 rather than standalone source frames.",
                "Keep source-cell geometry, trimmed bounds, atlas frames, and source file offsets in metadata.",
                "Store full reference extraction output under references/tyrian21-extracted before curating any runtime subset.",
            ],
        },
    }

    out_path.write_text(json.dumps(manifest, indent=2))
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
