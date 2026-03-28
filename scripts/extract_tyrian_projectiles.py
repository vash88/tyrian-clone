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
    load_palette,
    load_section_blob,
    pixels_to_image,
    repo_root_from_script,
    save_contact_sheet,
    save_uniform_atlas,
)


PROJECTILE_SECTIONS = {
    8: "projectiles-a",
    12: "projectiles-b",
}


def projectile_ref(sprite_value: int) -> dict[str, object] | None:
    if sprite_value <= 0 or sprite_value >= 60000:
        return None

    effect_band = 0
    frame_value = sprite_value
    if frame_value > 1000:
        effect_band = frame_value // 1000
        frame_value = frame_value % 1000

    if frame_value > 500:
        return {
            "sheet": 12,
            "section": 12,
            "index": frame_value - 500,
            "effectBand": effect_band,
            "sourceValue": sprite_value,
        }

    return {
        "sheet": 8,
        "section": 8,
        "index": frame_value,
        "effectBand": effect_band,
        "sourceValue": sprite_value,
    }


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    palette_path = repo_root / "references/tyrian21/palette.dat"
    shp_path = repo_root / "references/tyrian21/tyrian.shp"
    item_data_path = repo_root / "references/tyrian21-extracted/item-data/episode1-item-data.json"
    out_dir = repo_root / "references/tyrian21-extracted/projectiles"

    if out_dir.exists():
        shutil.rmtree(out_dir)

    raw_dir = out_dir / "raw"
    trimmed_dir = out_dir / "trimmed"
    atlases_dir = out_dir / "atlases"
    for directory in (out_dir, raw_dir, trimmed_dir, atlases_dir):
        directory.mkdir(parents=True, exist_ok=True)

    if not item_data_path.exists():
        raise FileNotFoundError(f"missing parsed item data: {item_data_path}")

    item_data = json.loads(item_data_path.read_text())
    palette = load_palette(palette_path, 0)
    section_sprite_ids: dict[int, set[int]] = {8: set(), 12: set()}
    section_frames: dict[int, list[dict[str, object]]] = {}

    for section, name in PROJECTILE_SECTIONS.items():
        section_key = f"{section:02d}-{name}"
        section_raw_dir = raw_dir / section_key
        section_trimmed_dir = trimmed_dir / section_key
        section_raw_dir.mkdir(parents=True, exist_ok=True)
        section_trimmed_dir.mkdir(parents=True, exist_ok=True)

        blob = load_section_blob(shp_path, section)
        offsets = decode_offsets(blob)

        atlas_images: list[tuple[str, object]] = []
        entries: list[dict[str, object]] = []

        for index, offset in enumerate(offsets, start=1):
            identifier = f"{section_key}-{index:03d}"
            image = pixels_to_image(decode_cell(blob, offset), palette)
            bbox = image.getbbox()
            trimmed = image.crop(bbox) if bbox else image.copy()

            image.save(section_raw_dir / f"{identifier}.png")
            trimmed.save(section_trimmed_dir / f"{identifier}.png")

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
            atlas_images.append((identifier, trimmed))

        atlas_path = atlases_dir / f"{section_key}-atlas.png"
        contact_path = atlases_dir / f"{section_key}-contact-sheet.png"
        atlas_meta, atlas_frames = save_uniform_atlas(atlas_images, atlas_path, columns=16)
        save_contact_sheet(atlas_images, contact_path, columns=16)

        for entry in entries:
            entry["frame"] = atlas_frames[entry["id"]]

        section_frames[section] = entries

    weapon_semantics: list[dict[str, object]] = []
    for weapon in item_data["weapons"]:
        refs = []
        for sequence_index, sprite_value in enumerate(weapon["sg"], start=1):
            ref = projectile_ref(int(sprite_value))
            if ref is None:
                continue
            section_sprite_ids[ref["section"]].add(ref["index"])
            refs.append(
                {
                    "sequenceIndex": sequence_index,
                    **ref,
                }
            )
        weapon_semantics.append(
            {
                "index": weapon["index"],
                "shotRepeat": weapon["shotRepeat"],
                "multi": weapon["multi"],
                "weapAni": weapon["weapAni"],
                "max": weapon["max"],
                "trail": weapon["trail"],
                "references": refs,
            }
        )

    semantic_frames = {
        str(section): sorted(section_sprite_ids[section])
        for section in PROJECTILE_SECTIONS
    }

    metadata = {
        "source": {
            "shp": str(shp_path),
            "palette": str(palette_path),
            "paletteIndex": 0,
            "itemData": str(item_data_path),
        },
        "sections": {
            str(section): {
                "name": PROJECTILE_SECTIONS[section],
                "atlas": {
                    "path": f"atlases/{section:02d}-{PROJECTILE_SECTIONS[section]}-atlas.png",
                },
                "contactSheet": {
                    "path": f"atlases/{section:02d}-{PROJECTILE_SECTIONS[section]}-contact-sheet.png",
                },
                "frames": section_frames[section],
            }
            for section in PROJECTILE_SECTIONS
        },
        "semanticFrames": semantic_frames,
        "weapons": weapon_semantics,
    }

    out_path = out_dir / "metadata.json"
    out_path.write_text(json.dumps(metadata, indent=2))
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
