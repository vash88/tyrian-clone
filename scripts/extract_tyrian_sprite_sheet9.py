#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

from tyrian_extract_core import (
    CELL_HEIGHT,
    CELL_WIDTH,
    SHEET9_COLUMNS,
    alpha_bounds,
    decode_cell,
    decode_offsets,
    load_palette,
    load_section_blob,
    pixels_to_image,
    repo_root_from_script,
    save_contact_sheet,
    save_uniform_atlas,
)
SHIP_BANK_OFFSETS = (-4, -2, 0, 2, 4)
VALID_SHIP_BASE_INDICES = tuple(sorted({5, 43, 81, 119, 157, 195, 233, 271}))


@dataclass(frozen=True)
class KnownShip:
    name: str
    ship_graphic_index: int


KNOWN_SHIPS = [
    KnownShip(name="usp-talon", ship_graphic_index=233),
    KnownShip(name="usp-fang", ship_graphic_index=233),
    KnownShip(name="gencore-phoenix", ship_graphic_index=157),
    KnownShip(name="gencore-maelstrom", ship_graphic_index=157),
]


@dataclass(frozen=True)
class ShipFrame:
    ship_graphic_index: int
    index: int
    bank_offset: int


VALID_SHIP_FRAMES = tuple(
    ShipFrame(ship_graphic_index=base_index, index=base_index + bank_offset, bank_offset=bank_offset // 2)
    for base_index in VALID_SHIP_BASE_INDICES
    for bank_offset in SHIP_BANK_OFFSETS
    if base_index + bank_offset > 0
)


def parse_args() -> argparse.Namespace:
    repo_root = repo_root_from_script(__file__)
    parser = argparse.ArgumentParser(
        description="Extract original Tyrian spriteSheet9 assets from tyrian.shp."
    )
    parser.add_argument(
        "--shp",
        type=Path,
        default=repo_root / "references/tyrian21/tyrian.shp",
        help="Path to tyrian.shp",
    )
    parser.add_argument(
        "--palette",
        type=Path,
        default=repo_root / "references/tyrian21/palette.dat",
        help="Path to palette.dat",
    )
    parser.add_argument(
        "--palette-index",
        type=int,
        default=0,
        help="Palette index from palette.dat to use when rasterizing output PNGs",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=repo_root / "references/tyrian21-extracted/spriteSheet9",
        help="Output directory",
    )
    return parser.parse_args()

def compose_2x2(cells: dict[int, Image.Image], index: int) -> Image.Image:
    image = Image.new("RGBA", (CELL_WIDTH * 2, CELL_HEIGHT * 2), (0, 0, 0, 0))
    image.alpha_composite(cells[index], (0, 0))
    image.alpha_composite(cells[index + 1], (CELL_WIDTH, 0))
    image.alpha_composite(cells[index + SHEET9_COLUMNS], (0, CELL_HEIGHT))
    image.alpha_composite(cells[index + SHEET9_COLUMNS + 1], (CELL_WIDTH, CELL_HEIGHT))
    return image

def composite_metadata_entry(index: int, image: Image.Image) -> dict[str, object]:
    return {
        "index": index,
        "row": (index - 1) // SHEET9_COLUMNS,
        "column": (index - 1) % SHEET9_COLUMNS,
        "bounds": alpha_bounds(image),
    }


def main() -> None:
    args = parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    cells_dir = args.out / "cells"
    composites_dir = args.out / "composites"
    valid_composites_dir = args.out / "valid-composites"
    ships_dir = args.out / "ships"
    cells_dir.mkdir(parents=True, exist_ok=True)
    composites_dir.mkdir(parents=True, exist_ok=True)
    valid_composites_dir.mkdir(parents=True, exist_ok=True)
    ships_dir.mkdir(parents=True, exist_ok=True)

    palette = load_palette(args.palette, args.palette_index)
    blob = load_section_blob(args.shp, 9)
    offsets = decode_offsets(blob)

    cell_images: dict[int, Image.Image] = {}
    cell_metadata: list[dict[str, object]] = []
    for index, offset in enumerate(offsets, start=1):
        image = pixels_to_image(decode_cell(blob, offset), palette)
        cell_images[index] = image
        image.save(cells_dir / f"cell-{index:03d}.png")
        cell_metadata.append({
            "index": index,
            "offset": offset,
            "row": (index - 1) // SHEET9_COLUMNS,
            "column": (index - 1) % SHEET9_COLUMNS,
            "bounds": alpha_bounds(image),
        })

    composite_images: list[tuple[str, Image.Image]] = []
    all_composite_metadata: list[dict[str, object]] = []
    max_rows = len(offsets) // SHEET9_COLUMNS
    for row in range(max_rows - 1):
        for col in range(SHEET9_COLUMNS - 1):
            index = row * SHEET9_COLUMNS + col + 1
            image = compose_2x2(cell_images, index)
            image.save(composites_dir / f"composite-{index:03d}.png")
            composite_images.append((f"{index}", image))
            all_composite_metadata.append(composite_metadata_entry(index, image))

    valid_composite_metadata: list[dict[str, object]] = []
    valid_ship_images: list[tuple[str, Image.Image]] = []
    for ship_frame in VALID_SHIP_FRAMES:
        image = compose_2x2(cell_images, ship_frame.index)
        image.save(valid_composites_dir / f"composite-{ship_frame.index:03d}.png")
        valid_ship_images.append((f"{ship_frame.ship_graphic_index}:{ship_frame.bank_offset:+d}", image))
        entry = composite_metadata_entry(ship_frame.index, image)
        entry["shipGraphicIndex"] = ship_frame.ship_graphic_index
        entry["bankOffset"] = ship_frame.bank_offset
        valid_composite_metadata.append(entry)

    ship_atlas, ship_atlas_frames = save_uniform_atlas(
        [(f"composite-{entry['index']:03d}", compose_2x2(cell_images, entry["index"])) for entry in valid_composite_metadata],
        args.out / "ship-atlas.png",
        columns=5,
    )
    for entry in valid_composite_metadata:
        entry["frame"] = ship_atlas_frames[f"composite-{entry['index']:03d}"]

    named_ship_metadata: list[dict[str, object]] = []
    for ship in KNOWN_SHIPS:
        image = compose_2x2(cell_images, ship.ship_graphic_index)
        filename = f"{ship.name}-{ship.ship_graphic_index:03d}.png"
        image.save(ships_dir / filename)
        named_ship_metadata.append({
            "name": ship.name,
            "shipGraphicIndex": ship.ship_graphic_index,
            "bounds": alpha_bounds(image),
            "file": str((ships_dir / filename).relative_to(args.out)),
        })

    save_contact_sheet(
        [(f"{entry['index']:03d}", cell_images[entry["index"]]) for entry in cell_metadata],
        args.out / "spriteSheet9-cells-contact-sheet.png",
        columns=SHEET9_COLUMNS,
    )
    save_contact_sheet(
        composite_images,
        args.out / "spriteSheet9-composites-contact-sheet.png",
        columns=SHEET9_COLUMNS - 1,
    )
    save_contact_sheet(
        valid_ship_images,
        args.out / "spriteSheet9-valid-ship-frames-contact-sheet.png",
        columns=5,
    )
    save_contact_sheet(
        [(entry["name"], compose_2x2(cell_images, entry["shipGraphicIndex"])) for entry in named_ship_metadata],
        args.out / "spriteSheet9-known-ships-contact-sheet.png",
        columns=2,
    )

    metadata = {
        "source": {
            "shp": str(args.shp),
            "palette": str(args.palette),
            "paletteIndex": args.palette_index,
        },
        "sheet": {
            "name": "spriteSheet9",
            "cellWidth": CELL_WIDTH,
            "cellHeight": CELL_HEIGHT,
            "columns": SHEET9_COLUMNS,
            "cellCount": len(offsets),
            "compositeWidth": CELL_WIDTH * 2,
            "compositeHeight": CELL_HEIGHT * 2,
        },
        "atlas": ship_atlas,
        "cells": cell_metadata,
        "composites": valid_composite_metadata,
        "allComposites": all_composite_metadata,
        "knownShips": named_ship_metadata,
    }
    (args.out / "metadata.json").write_text(json.dumps(metadata, indent=2))

    print(f"Extracted {len(cell_metadata)} cells to {cells_dir}")
    print(f"Extracted {len(all_composite_metadata)} exploratory composites to {composites_dir}")
    print(f"Extracted {len(valid_composite_metadata)} valid ship-bank composites to {valid_composites_dir}")
    print(f"Wrote metadata to {args.out / 'metadata.json'}")


if __name__ == "__main__":
    main()
