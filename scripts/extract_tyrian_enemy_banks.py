#!/usr/bin/env python3

from __future__ import annotations

import json
import shutil
from pathlib import Path

from tyrian_extract_core import (
    CELL_HEIGHT,
    CELL_WIDTH,
    alpha_bounds,
    decode_cell,
    decode_offsets,
    load_blob,
    load_palette,
    pixels_to_image,
    repo_root_from_script,
    save_contact_sheet,
    save_uniform_atlas,
)


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    palette_path = repo_root / "references/tyrian21/palette.dat"
    source_dir = repo_root / "references/tyrian21"
    out_dir = repo_root / "references/tyrian21-extracted/enemy-banks"

    if out_dir.exists():
        shutil.rmtree(out_dir)

    raw_dir = out_dir / "raw"
    trimmed_dir = out_dir / "trimmed"
    atlases_dir = out_dir / "atlases"
    for directory in (out_dir, raw_dir, trimmed_dir, atlases_dir):
        directory.mkdir(parents=True, exist_ok=True)

    palette = load_palette(palette_path, 0)
    bank_files = sorted(source_dir.glob("newsh*.shp"))
    banks_metadata: list[dict[str, object]] = []

    for bank_file in bank_files:
        bank_key = bank_file.stem
        section_raw_dir = raw_dir / bank_key
        section_trimmed_dir = trimmed_dir / bank_key
        section_raw_dir.mkdir(parents=True, exist_ok=True)
        section_trimmed_dir.mkdir(parents=True, exist_ok=True)

        blob = load_blob(bank_file)
        offsets = decode_offsets(blob)
        entries: list[dict[str, object]] = []
        atlas_images: list[tuple[str, object]] = []
        raw_contact_images: list[tuple[str, object]] = []

        for index, offset in enumerate(offsets, start=1):
            identifier = f"{bank_key}-{index:03d}"
            image = pixels_to_image(decode_cell(blob, offset), palette)
            bbox = image.getbbox()
            trimmed = image.crop(bbox) if bbox else image.copy()

            image.save(section_raw_dir / f"{identifier}.png")
            trimmed.save(section_trimmed_dir / f"{identifier}.png")

            atlas_images.append((identifier, trimmed))
            raw_contact_images.append((str(index), image))
            entries.append(
                {
                    "id": identifier,
                    "index": index,
                    "offset": offset,
                    "sourceCell": {
                        "width": CELL_WIDTH,
                        "height": CELL_HEIGHT,
                    },
                    "sourceBounds": alpha_bounds(image),
                    "trimmedSize": {
                        "width": trimmed.width,
                        "height": trimmed.height,
                    },
                }
            )

        atlas_path = atlases_dir / f"{bank_key}-atlas.png"
        raw_contact_path = atlases_dir / f"{bank_key}-raw-contact-sheet.png"
        trimmed_contact_path = atlases_dir / f"{bank_key}-trimmed-contact-sheet.png"

        atlas_metadata, atlas_frames = save_uniform_atlas(atlas_images, atlas_path, columns=16)
        save_contact_sheet(raw_contact_images, raw_contact_path, columns=16)
        save_contact_sheet(atlas_images, trimmed_contact_path, columns=16)

        for entry in entries:
            entry["frame"] = atlas_frames[entry["id"]]

        banks_metadata.append(
            {
                "name": bank_key,
                "path": str(bank_file),
                "spriteCount": len(entries),
                "atlas": {
                    **atlas_metadata,
                    "path": f"atlases/{atlas_path.name}",
                },
                "rawContactSheet": {"path": f"atlases/{raw_contact_path.name}"},
                "trimmedContactSheet": {"path": f"atlases/{trimmed_contact_path.name}"},
                "sprites": entries,
            }
        )

    metadata = {
        "source": {
            "directory": str(source_dir),
            "palette": str(palette_path),
            "paletteIndex": 0,
        },
        "format": "sprite2",
        "banks": banks_metadata,
    }

    metadata_path = out_dir / "metadata.json"
    metadata_path.write_text(json.dumps(metadata, indent=2))
    print(f"Wrote {metadata_path}")


if __name__ == "__main__":
    main()
