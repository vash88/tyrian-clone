#!/usr/bin/env python3

from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image

from tyrian_extract_core import (
    CELL_HEIGHT,
    CELL_WIDTH,
    alpha_bounds,
    decode_cell,
    decode_offsets,
    load_palette,
    load_section_blob,
    pixels_to_image,
    repo_root_from_script,
    save_contact_sheet,
    save_packed_strip_atlas,
)


PICKUP_SECTIONS = (10, 11)
ALIAS_SECTION = "aliases"
ALIASES = {
    "credits-small": (11, 42),
    "front-power": (10, 79),
    "rear-power": (10, 81),
    "armor-repair": (11, 60),
    "shield-restore": (11, 47),
    "sidekick-ammo-small": (11, 140),
}


def sprite_id(section: int, index: int) -> str:
    return f"s{section}-{index:03d}"


def empty_sprite_metadata(
    *,
    identifier: str,
    section: int,
    index: int,
    offset: int,
) -> dict[str, object]:
    return {
        "id": identifier,
        "section": section,
        "index": index,
        "offset": offset,
        "sourceCell": {
            "width": CELL_WIDTH,
            "height": CELL_HEIGHT,
        },
        "sourceBounds": None,
        "trimmedSize": {
            "width": 0,
            "height": 0,
        },
    }


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    shp_path = repo_root / "references/tyrian21/tyrian.shp"
    palette_path = repo_root / "references/tyrian21/palette.dat"
    out_dir = repo_root / "references/tyrian21-extracted/pickups"

    if out_dir.exists():
        shutil.rmtree(out_dir)

    raw_dir = out_dir / "raw"
    trimmed_dir = out_dir / "trimmed"
    atlases_dir = out_dir / "atlases"
    aliases_dir = out_dir / "aliases"

    for directory in (out_dir, raw_dir, trimmed_dir, atlases_dir, aliases_dir):
        directory.mkdir(parents=True, exist_ok=True)

    palette = load_palette(palette_path, 0)
    all_entries: list[dict[str, object]] = []
    combined_trimmed_images: list[tuple[str, object]] = []
    section_metadata: dict[str, dict[str, object]] = {}

    for section in PICKUP_SECTIONS:
        section_key = str(section)
        section_raw_dir = raw_dir / f"section-{section}"
        section_trimmed_dir = trimmed_dir / f"section-{section}"
        section_raw_dir.mkdir(parents=True, exist_ok=True)
        section_trimmed_dir.mkdir(parents=True, exist_ok=True)

        blob = load_section_blob(shp_path, section)
        offsets = decode_offsets(blob)

        raw_images: list[tuple[str, object]] = []
        trimmed_images: list[tuple[str, object]] = []
        entries: list[dict[str, object]] = []

        for index, offset in enumerate(offsets, start=1):
            identifier = sprite_id(section, index)
            image = pixels_to_image(decode_cell(blob, offset), palette)
            bounds = alpha_bounds(image)
            bbox = image.getbbox()
            trimmed = image.crop(bbox) if bbox else image.copy()

            image.save(section_raw_dir / f"{identifier}.png")
            trimmed.save(section_trimmed_dir / f"{identifier}.png")

            entry = empty_sprite_metadata(
                identifier=identifier,
                section=section,
                index=index,
                offset=offset,
            )
            entry["sourceBounds"] = bounds
            entry["trimmedSize"] = {
                "width": trimmed.width,
                "height": trimmed.height,
            }

            entries.append(entry)
            raw_images.append((identifier, image))
            trimmed_images.append((identifier, trimmed))
            combined_trimmed_images.append((identifier, trimmed))

        raw_contact_sheet_path = atlases_dir / f"section-{section}-raw-contact-sheet.png"
        trimmed_contact_sheet_path = atlases_dir / f"section-{section}-trimmed-contact-sheet.png"
        atlas_path = atlases_dir / f"section-{section}-atlas.png"

        save_contact_sheet(raw_images, raw_contact_sheet_path, columns=16)
        save_contact_sheet(trimmed_images, trimmed_contact_sheet_path, columns=16)
        atlas_metadata, atlas_frames = save_packed_strip_atlas(trimmed_images, atlas_path, padding=1)

        for entry in entries:
            entry["sectionFrame"] = atlas_frames[entry["id"]]

        section_metadata[section_key] = {
            "spriteCount": len(entries),
            "rawContactSheet": {"path": f"atlases/{raw_contact_sheet_path.name}"},
            "trimmedContactSheet": {"path": f"atlases/{trimmed_contact_sheet_path.name}"},
            "atlas": {
                **atlas_metadata,
                "path": f"atlases/{atlas_path.name}",
                "sourceCellWidth": CELL_WIDTH,
                "sourceCellHeight": CELL_HEIGHT,
            },
        }
        all_entries.extend(entries)

    combined_atlas_path = atlases_dir / "all-pickups-atlas.png"
    combined_contact_sheet_path = atlases_dir / "all-pickups-trimmed-contact-sheet.png"
    combined_atlas_metadata, combined_atlas_frames = save_packed_strip_atlas(
        combined_trimmed_images,
        combined_atlas_path,
        padding=1,
    )
    save_contact_sheet(
        combined_trimmed_images,
        combined_contact_sheet_path,
        columns=16,
    )

    for entry in all_entries:
        entry["combinedFrame"] = combined_atlas_frames[entry["id"]]

    alias_images: list[tuple[str, object]] = []
    alias_entries: dict[str, dict[str, object]] = {}

    for alias, (section, index) in ALIASES.items():
        identifier = sprite_id(section, index)
        entry = next(item for item in all_entries if item["id"] == identifier)
        trimmed_path = trimmed_dir / f"section-{section}" / f"{identifier}.png"
        alias_target_path = aliases_dir / f"{alias}.png"
        shutil.copy2(trimmed_path, alias_target_path)

        with Image.open(trimmed_path) as alias_image:
            alias_images.append((alias, alias_image.convert("RGBA")))
        alias_entries[alias] = {
            "id": identifier,
            "section": section,
            "index": index,
            "sourceBounds": entry["sourceBounds"],
            "trimmedSize": entry["trimmedSize"],
        }

    alias_atlas_path = atlases_dir / "aliases-atlas.png"
    alias_contact_sheet_path = atlases_dir / "aliases-contact-sheet.png"
    alias_atlas_metadata, alias_frames = save_packed_strip_atlas(alias_images, alias_atlas_path, padding=1)
    save_contact_sheet(alias_images, alias_contact_sheet_path, columns=6)

    for alias, entry in alias_entries.items():
        entry["frame"] = alias_frames[alias]

    metadata = {
        "source": {
            "shp": str(shp_path),
            "palette": str(palette_path),
            "paletteIndex": 0,
        },
        "sections": section_metadata,
        "combinedAtlas": {
            **combined_atlas_metadata,
            "path": f"atlases/{combined_atlas_path.name}",
            "sourceCellWidth": CELL_WIDTH,
            "sourceCellHeight": CELL_HEIGHT,
        },
        "aliases": {
            "atlas": {
                **alias_atlas_metadata,
                "path": f"atlases/{alias_atlas_path.name}",
            },
            "contactSheet": {
                "path": f"atlases/{alias_contact_sheet_path.name}",
            },
            "sprites": alias_entries,
        },
        "sprites": all_entries,
    }

    metadata_path = out_dir / "metadata.json"
    metadata_path.write_text(json.dumps(metadata, indent=2))

    alias_metadata_path = out_dir / "pickup-metadata.json"
    alias_metadata_path.write_text(
        json.dumps(
            {
                "source": metadata["source"],
                "atlas": metadata["aliases"]["atlas"],
                "sprites": [
                    {
                        "name": alias,
                        **entry,
                    }
                    for alias, entry in alias_entries.items()
                ],
            },
            indent=2,
        )
    )

    print(f"Extracted {len(all_entries)} pickup sprites from sections {PICKUP_SECTIONS}")
    print(f"Wrote full pickup metadata to {metadata_path}")
    print(f"Wrote alias pickup metadata to {alias_metadata_path}")
    print(f"Wrote atlases and contact sheets to {atlases_dir}")


if __name__ == "__main__":
    main()
