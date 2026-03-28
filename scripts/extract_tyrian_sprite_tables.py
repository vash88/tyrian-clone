#!/usr/bin/env python3

from __future__ import annotations

import json
import shutil
from pathlib import Path

from tyrian_extract_core import (
    alpha_bounds,
    decode_sprite_image,
    decode_sprite_table,
    load_palette,
    load_section_blob,
    repo_root_from_script,
    save_contact_sheet,
    save_uniform_atlas,
)


SPRITE_SECTIONS = {
    1: "fonts",
    2: "small-font",
    3: "tiny-font",
    4: "planets",
    5: "faces",
    6: "options-and-help",
    7: "weapon-and-extra-ui",
}


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    shp_path = repo_root / "references/tyrian21/tyrian.shp"
    palette_path = repo_root / "references/tyrian21/palette.dat"
    out_dir = repo_root / "references/tyrian21-extracted/tyrian-shp-sprites"

    if out_dir.exists():
        shutil.rmtree(out_dir)

    raw_dir = out_dir / "raw"
    trimmed_dir = out_dir / "trimmed"
    atlases_dir = out_dir / "atlases"
    for directory in (out_dir, raw_dir, trimmed_dir, atlases_dir):
        directory.mkdir(parents=True, exist_ok=True)

    palette = load_palette(palette_path, 0)
    section_metadata: dict[str, object] = {}

    for section, name in SPRITE_SECTIONS.items():
        section_key = f"{section:02d}-{name}"
        section_raw_dir = raw_dir / section_key
        section_trimmed_dir = trimmed_dir / section_key
        section_raw_dir.mkdir(parents=True, exist_ok=True)
        section_trimmed_dir.mkdir(parents=True, exist_ok=True)

        blob = load_section_blob(shp_path, section)
        sprites = decode_sprite_table(blob)

        atlas_images: list[tuple[str, object]] = []
        entries: list[dict[str, object]] = []

        for sprite in sprites:
            index = int(sprite["index"])
            identifier = f"{section_key}-{index:03d}"
            entry = {
                "id": identifier,
                "index": index,
                "populated": bool(sprite["populated"]),
                "width": int(sprite["width"]),
                "height": int(sprite["height"]),
                "size": int(sprite["size"]),
                "dataOffset": sprite["dataOffset"],
            }

            if not sprite["populated"]:
                entries.append(entry)
                continue

            image = decode_sprite_image(
                sprite["data"],
                width=int(sprite["width"]),
                height=int(sprite["height"]),
                palette=palette,
            )
            bbox = image.getbbox()
            trimmed = image.crop(bbox) if bbox else image.copy()

            image.save(section_raw_dir / f"{identifier}.png")
            trimmed.save(section_trimmed_dir / f"{identifier}.png")

            entry["bounds"] = alpha_bounds(image)
            entry["trimmedSize"] = {
                "width": trimmed.width,
                "height": trimmed.height,
            }

            atlas_images.append((identifier, trimmed))
            entries.append(entry)

        raw_contact_path = atlases_dir / f"{section_key}-raw-contact-sheet.png"
        trimmed_contact_path = atlases_dir / f"{section_key}-trimmed-contact-sheet.png"
        atlas_path = atlases_dir / f"{section_key}-atlas.png"

        if atlas_images:
            atlas_metadata, atlas_frames = save_uniform_atlas(
                atlas_images,
                atlas_path,
                columns=16,
            )
            for entry in entries:
                if entry["populated"]:
                    entry["frame"] = atlas_frames[entry["id"]]

            save_contact_sheet(
                [(label, image) for label, image in atlas_images],
                trimmed_contact_path,
                columns=16,
            )
        else:
            atlas_metadata = None

        raw_contact_images = []
        for entry in entries:
            if not entry["populated"]:
                continue
            raw_path = section_raw_dir / f"{entry['id']}.png"
            if raw_path.exists():
                from PIL import Image

                with Image.open(raw_path) as raw_image:
                    raw_contact_images.append((str(entry["index"]), raw_image.convert("RGBA")))

        if raw_contact_images:
            save_contact_sheet(raw_contact_images, raw_contact_path, columns=16)

        section_metadata[section_key] = {
            "section": section,
            "name": name,
            "spriteCount": len(entries),
            "populatedSpriteCount": sum(1 for entry in entries if entry["populated"]),
            "atlas": (
                {
                    **atlas_metadata,
                    "path": f"atlases/{atlas_path.name}",
                }
                if atlas_metadata is not None
                else None
            ),
            "rawContactSheet": (
                {"path": f"atlases/{raw_contact_path.name}"}
                if raw_contact_path.exists()
                else None
            ),
            "trimmedContactSheet": (
                {"path": f"atlases/{trimmed_contact_path.name}"}
                if trimmed_contact_path.exists()
                else None
            ),
            "sprites": entries,
        }

    metadata = {
        "source": {
            "shp": str(shp_path),
            "palette": str(palette_path),
            "paletteIndex": 0,
        },
        "format": "sprite",
        "sections": section_metadata,
    }

    metadata_path = out_dir / "metadata.json"
    metadata_path.write_text(json.dumps(metadata, indent=2))
    print(f"Wrote {metadata_path}")


if __name__ == "__main__":
    main()
