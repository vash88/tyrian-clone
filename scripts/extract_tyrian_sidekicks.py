#!/usr/bin/env python3

from __future__ import annotations

import json
import shutil
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


def compose_2x2(cells: dict[int, Image.Image], index: int) -> Image.Image:
    image = Image.new("RGBA", (CELL_WIDTH * 2, CELL_HEIGHT * 2), (0, 0, 0, 0))
    image.alpha_composite(cells[index], (0, 0))
    image.alpha_composite(cells[index + 1], (CELL_WIDTH, 0))
    image.alpha_composite(cells[index + SHEET9_COLUMNS], (0, CELL_HEIGHT))
    image.alpha_composite(cells[index + SHEET9_COLUMNS + 1], (CELL_WIDTH, CELL_HEIGHT))
    return image


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    item_data_path = repo_root / "references/tyrian21-extracted/item-data/episode1-item-data.json"
    shp_path = repo_root / "references/tyrian21/tyrian.shp"
    palette_path = repo_root / "references/tyrian21/palette.dat"
    out_dir = repo_root / "references/tyrian21-extracted/sidekicks"

    if out_dir.exists():
        shutil.rmtree(out_dir)

    raw_dir = out_dir / "raw"
    atlases_dir = out_dir / "atlases"
    for directory in (out_dir, raw_dir, atlases_dir):
        directory.mkdir(parents=True, exist_ok=True)

    if not item_data_path.exists():
        raise FileNotFoundError(f"missing parsed item data: {item_data_path}")

    palette = load_palette(palette_path, 0)
    item_data = json.loads(item_data_path.read_text())

    blob9 = load_section_blob(shp_path, 9)
    offsets9 = decode_offsets(blob9)
    sprite9 = {
        index: pixels_to_image(decode_cell(blob9, offset), palette)
        for index, offset in enumerate(offsets9, start=1)
    }

    blob10 = load_section_blob(shp_path, 10)
    offsets10 = decode_offsets(blob10)
    sprite10 = {
        index: pixels_to_image(decode_cell(blob10, offset), palette)
        for index, offset in enumerate(offsets10, start=1)
    }

    atlas_images: list[tuple[str, object]] = []
    semantic_options: list[dict[str, object]] = []

    for option in item_data["options"]:
        if option["index"] == 0:
            continue
        if not option["name"] and option["itemGraphic"] == 0 and option["wPort"] == 0:
            continue

        render_mode = "sprite2x2-sheet10" if option["tr"] in (1, 2) else "sprite2-sheet9"
        option_frames = []

        max_anim_frames = max(int(option["ani"]), 1)
        for animation_frame in range(max_anim_frames):
            base_index = int(option["gr"][animation_frame])
            if base_index <= 0:
                continue

            for charge in range(int(option["pwr"]) + 1):
                source_index = base_index + charge
                if render_mode == "sprite2x2-sheet10":
                    if (
                        source_index not in sprite10
                        or source_index + 1 not in sprite10
                        or source_index + SHEET9_COLUMNS not in sprite10
                        or source_index + SHEET9_COLUMNS + 1 not in sprite10
                    ):
                        continue
                    image = compose_2x2(sprite10, source_index)
                    source = {
                        "sheet": 10,
                        "section": 10,
                        "index": source_index,
                        "composite": True,
                    }
                else:
                    if source_index not in sprite9:
                        continue
                    image = sprite9[source_index]
                    source = {
                        "sheet": 9,
                        "section": 9,
                        "index": source_index,
                        "composite": False,
                    }

                identifier = f"option-{option['index']:02d}-anim-{animation_frame:02d}-charge-{charge:02d}"
                image.save(raw_dir / f"{identifier}.png")
                atlas_images.append((identifier, image))
                option_frames.append(
                    {
                        "id": identifier,
                        "animationFrame": animation_frame,
                        "charge": charge,
                        "source": source,
                        "bounds": alpha_bounds(image),
                    }
                )

        semantic_options.append(
            {
                "index": option["index"],
                "name": option["name"],
                "chargeStages": option["pwr"],
                "renderMode": render_mode,
                "tr": option["tr"],
                "option": option["option"],
                "ani": option["ani"],
                "wPort": option["wPort"],
                "wpNum": option["wpNum"],
                "ammo": option["ammo"],
                "iconGraphic": option["iconGr"],
                "shopGraphic": option["itemGraphic"],
                "frames": option_frames,
            }
        )

    atlas_path = atlases_dir / "sidekicks-atlas.png"
    contact_path = atlases_dir / "sidekicks-contact-sheet.png"
    atlas_meta, atlas_frames = save_uniform_atlas(atlas_images, atlas_path, columns=8)
    save_contact_sheet(atlas_images, contact_path, columns=8)

    for option in semantic_options:
        for frame in option["frames"]:
            frame["frame"] = atlas_frames[frame["id"]]

    metadata = {
        "source": {
            "itemData": str(item_data_path),
            "shp": str(shp_path),
            "palette": str(palette_path),
            "paletteIndex": 0,
        },
        "atlas": {
            **atlas_meta,
            "path": f"atlases/{atlas_path.name}",
        },
        "contactSheet": {
            "path": f"atlases/{contact_path.name}",
        },
        "options": semantic_options,
    }

    out_path = out_dir / "metadata.json"
    out_path.write_text(json.dumps(metadata, indent=2))
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
