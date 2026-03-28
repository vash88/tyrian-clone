#!/usr/bin/env python3

from __future__ import annotations

import json
import shutil
from pathlib import Path

from tyrian_extract_core import (
    alpha_bounds,
    indexed_bytes_to_palette_image,
    load_all_palettes,
    raw_indexed_image,
    repo_root_from_script,
    save_contact_sheet,
    save_uniform_atlas,
)


TILE_WIDTH = 24
TILE_HEIGHT = 28
TILE_COUNT = 600


def decode_tileset(path: Path) -> list[dict[str, object]]:
    blob = path.read_bytes()
    cursor = 0
    tiles: list[dict[str, object]] = []

    for index in range(1, TILE_COUNT + 1):
        populated = bool(blob[cursor])
        cursor += 1
        if populated:
            pixels = blob[cursor:cursor + TILE_WIDTH * TILE_HEIGHT]
            cursor += TILE_WIDTH * TILE_HEIGHT
        else:
            pixels = bytes(TILE_WIDTH * TILE_HEIGHT)

        tiles.append(
            {
                "index": index,
                "populated": populated,
                "pixels": pixels,
            }
        )

    return tiles


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    source_dir = repo_root / "references/tyrian21"
    palette_path = source_dir / "palette.dat"
    out_dir = repo_root / "references/tyrian21-extracted/tilesets"

    if out_dir.exists():
        shutil.rmtree(out_dir)

    raw_dir = out_dir / "raw"
    atlases_dir = out_dir / "atlases"
    palette_dir = out_dir / "palette-previews"
    for directory in (out_dir, raw_dir, atlases_dir, palette_dir):
        directory.mkdir(parents=True, exist_ok=True)

    tileset_files = sorted(source_dir.glob("shapes*.dat"))
    palettes = load_all_palettes(palette_path)
    tilesets_metadata: list[dict[str, object]] = []

    for tileset_file in tileset_files:
        tileset_key = tileset_file.stem
        tileset_raw_dir = raw_dir / tileset_key
        tileset_raw_dir.mkdir(parents=True, exist_ok=True)

        entries: list[dict[str, object]] = []
        atlas_images: list[tuple[str, object]] = []
        populated_tiles: list[tuple[str, bytes]] = []

        for tile in decode_tileset(tileset_file):
            identifier = f"{tileset_key}-{tile['index']:03d}"
            image = raw_indexed_image(
                tile["pixels"],
                width=TILE_WIDTH,
                height=TILE_HEIGHT,
                transparent_zero=True,
            )
            image.save(tileset_raw_dir / f"{identifier}.png")

            entry = {
                "id": identifier,
                "index": tile["index"],
                "populated": tile["populated"],
                "sourceTile": {
                    "width": TILE_WIDTH,
                    "height": TILE_HEIGHT,
                },
                "sourceBounds": alpha_bounds(image),
            }
            entries.append(entry)
            if tile["populated"]:
                atlas_images.append((identifier, image))
                populated_tiles.append((identifier, tile["pixels"]))

        atlas_path = atlases_dir / f"{tileset_key}-atlas.png"
        contact_path = atlases_dir / f"{tileset_key}-contact-sheet.png"
        atlas_metadata, atlas_frames = save_uniform_atlas(atlas_images, atlas_path, columns=12)
        save_contact_sheet(atlas_images, contact_path, columns=12)

        palette_variants = []
        for palette_index, palette in enumerate(palettes):
            variant_images = [
                (
                    identifier,
                    indexed_bytes_to_palette_image(
                        pixels,
                        width=TILE_WIDTH,
                        height=TILE_HEIGHT,
                        palette=palette,
                        transparent_zero=True,
                    ),
                )
                for identifier, pixels in populated_tiles
            ]
            variant_atlas_path = palette_dir / f"{tileset_key}-palette-{palette_index:02d}-atlas.png"
            variant_meta, _ = save_uniform_atlas(variant_images, variant_atlas_path, columns=12)
            palette_variants.append(
                {
                    "paletteIndex": palette_index,
                    "path": f"palette-previews/{variant_atlas_path.name}",
                    **variant_meta,
                }
            )

        for entry in entries:
            if entry["populated"]:
                entry["frame"] = atlas_frames[entry["id"]]

        tilesets_metadata.append(
            {
                "name": tileset_key,
                "path": str(tileset_file),
                "tileCount": len(entries),
                "populatedTileCount": sum(1 for entry in entries if entry["populated"]),
                "atlas": {
                    **atlas_metadata,
                    "path": f"atlases/{atlas_path.name}",
                    "previewMode": "grayscale-by-palette-index",
                },
                "paletteVariants": palette_variants,
                "contactSheet": {"path": f"atlases/{contact_path.name}"},
                "tiles": entries,
            }
        )

    metadata = {
        "source": {
            "directory": str(source_dir),
            "palette": str(palette_path),
        },
        "format": "tile-set",
        "previewMode": "grayscale-by-palette-index",
        "notes": [
            "Tiles are extracted as raw indexed values from shapes*.dat.",
            "Reference output includes grayscale indexed previews plus one atlas per palette in palette.dat.",
            "Level-specific palette selection still needs separate gameplay-context mapping.",
        ],
        "tilesets": tilesets_metadata,
    }

    metadata_path = out_dir / "metadata.json"
    metadata_path.write_text(json.dumps(metadata, indent=2))
    print(f"Wrote {metadata_path}")


if __name__ == "__main__":
    main()
