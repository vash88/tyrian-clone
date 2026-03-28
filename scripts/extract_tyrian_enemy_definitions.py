#!/usr/bin/env python3

from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image

from tyrian_extract_core import repo_root_from_script, save_contact_sheet


SHAPE_FILE_MAP = [
    "2", "4", "7", "8", "A", "B", "C", "D", "E", "F",
    "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
    "Q", "R", "S", "T", "U", "5", "#", "V", "0", "@",
    "3", "^", "5", "9",
]


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    item_data_path = repo_root / "references/tyrian21-extracted/item-data/episode1-item-data.json"
    enemy_banks_path = repo_root / "references/tyrian21-extracted/enemy-banks/metadata.json"
    enemy_banks_root = repo_root / "references/tyrian21-extracted/enemy-banks"
    out_dir = repo_root / "references/tyrian21-extracted/enemy-definitions"

    if out_dir.exists():
        shutil.rmtree(out_dir)

    families_dir = out_dir / "families"
    families_dir.mkdir(parents=True, exist_ok=True)

    item_data = json.loads(item_data_path.read_text())
    enemy_banks = json.loads(enemy_banks_path.read_text())

    bank_lookup = {bank["name"]: bank for bank in enemy_banks["banks"]}
    bank_frame_lookup = {
        bank["name"]: {frame["index"]: frame for frame in bank["sprites"]}
        for bank in enemy_banks["banks"]
    }

    definitions: list[dict[str, object]] = []

    for enemy in item_data["enemies"]:
        if enemy["index"] == 0:
            continue

        shape_bank = int(enemy["shapeBank"])
        bank_name = None
        bank_char = None
        if shape_bank > 0 and shape_bank <= len(SHAPE_FILE_MAP):
            bank_char = SHAPE_FILE_MAP[shape_bank - 1]
            bank_name = f"newsh{bank_char.lower()}"

        frame_indices = []
        seen = set()
        for frame in enemy["eGraphic"]:
            frame = int(frame)
            if frame <= 0 or frame in seen:
                continue
            seen.add(frame)
            frame_indices.append(frame)

        frame_refs = []
        preview_images = []
        if bank_name in bank_frame_lookup:
            bank_frames = bank_frame_lookup[bank_name]
            for frame_index in frame_indices:
                frame_meta = bank_frames.get(frame_index)
                if frame_meta is None:
                    continue
                frame_id = frame_meta["id"]
                raw_path = enemy_banks_root / "raw" / bank_name / f"{frame_id}.png"
                if raw_path.exists():
                    with Image.open(raw_path) as image:
                        preview_images.append((f"{frame_index}", image.convert("RGBA")))

                frame_refs.append(
                    {
                        "index": frame_index,
                        "id": frame_meta["id"],
                        "sourceBounds": frame_meta["sourceBounds"],
                        "trimmedSize": frame_meta["trimmedSize"],
                        "frame": frame_meta["frame"],
                    }
                )

        family_contact_sheet = None
        if preview_images:
            family_contact_path = families_dir / f"enemy-{enemy['index']:03d}.png"
            save_contact_sheet(preview_images, family_contact_path, columns=min(5, len(preview_images)))
            family_contact_sheet = {
                "path": f"families/{family_contact_path.name}",
            }

        definitions.append(
            {
                "index": enemy["index"],
                "shapeBank": shape_bank,
                "shapeFileChar": bank_char,
                "bankName": bank_name,
                "armor": enemy["armor"],
                "size": enemy["eSize"],
                "value": enemy["value"],
                "animate": enemy["animate"],
                "ani": enemy["ani"],
                "explosionType": enemy["explosionType"],
                "enemyDie": enemy["eEnemyDie"],
                "launchType": enemy["eLaunchType"],
                "frameIndices": frame_indices,
                "frameRefs": frame_refs,
                "familyContactSheet": family_contact_sheet,
            }
        )

    metadata = {
        "source": {
            "itemData": str(item_data_path),
            "enemyBanks": str(enemy_banks_path),
        },
        "shapeFileMap": SHAPE_FILE_MAP,
        "definitions": definitions,
    }

    out_path = out_dir / "metadata.json"
    out_path.write_text(json.dumps(metadata, indent=2))
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
