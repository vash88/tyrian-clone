#!/usr/bin/env python3

from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image

from tyrian_extract_core import repo_root_from_script, save_contact_sheet


DIRECT_SPAWN_EVENT_TYPES = {6, 7, 10, 12, 15, 17, 18, 23, 32}


def load_preview_image(
    enemy_id: int,
    enemy_lookup: dict[int, dict[str, object]],
    enemy_banks_root: Path,
) -> Image.Image | None:
    definition = enemy_lookup.get(enemy_id)
    if definition is None:
        return None

    frame_refs = definition.get("frameRefs", [])
    if not frame_refs:
        return None

    first_ref = frame_refs[0]
    bank_name = definition.get("bankName")
    frame_id = first_ref.get("id")
    if not bank_name or not frame_id:
        return None

    image_path = enemy_banks_root / "raw" / bank_name / f"{frame_id}.png"
    if not image_path.exists():
        return None

    with Image.open(image_path) as image:
        return image.convert("RGBA")


def summarize_enemy(enemy_id: int, enemy_lookup: dict[int, dict[str, object]]) -> dict[str, object]:
    definition = enemy_lookup.get(enemy_id)
    if definition is None:
        return {
            "enemyId": enemy_id,
            "present": False,
        }

    return {
        "enemyId": enemy_id,
        "present": True,
        "bankName": definition.get("bankName"),
        "shapeBank": definition.get("shapeBank"),
        "armor": definition.get("armor"),
        "size": definition.get("size"),
        "value": definition.get("value"),
        "frameIndices": definition.get("frameIndices", []),
    }


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    level_usage_path = repo_root / "references/tyrian21-extracted/level-usage/metadata.json"
    enemy_definitions_path = repo_root / "references/tyrian21-extracted/enemy-definitions/metadata.json"
    enemy_banks_root = repo_root / "references/tyrian21-extracted/enemy-banks"
    out_dir = repo_root / "references/tyrian21-extracted/level-enemy-usage"

    if out_dir.exists():
        shutil.rmtree(out_dir)

    sheets_dir = out_dir / "contact-sheets"
    sheets_dir.mkdir(parents=True, exist_ok=True)

    level_usage = json.loads(level_usage_path.read_text())
    enemy_definitions = json.loads(enemy_definitions_path.read_text())
    enemy_lookup = {
        int(definition["index"]): definition
        for definition in enemy_definitions["definitions"]
    }

    episodes = []
    for episode in level_usage["episodes"]:
        playable_levels = []
        for level in episode["playableLevels"]:
            events = level["levelRecord"]["events"]
            spawn_events = [
                event for event in events
                if int(event["eventType"]) in DIRECT_SPAWN_EVENT_TYPES and int(event["eventDat"]) > 0
            ]
            spawned_enemy_ids = sorted({int(event["eventDat"]) for event in spawn_events})
            boss_links = sorted(
                {
                    int(value)
                    for event in events
                    if int(event["eventType"]) == 79
                    for value in (event["eventDat"], event["eventDat2"])
                    if int(value) > 0
                }
            )
            boss_enemy_ids = sorted(
                {
                    int(event["eventDat"])
                    for event in spawn_events
                    if int(event["eventDat4"]) in boss_links
                }
            )

            used_images = []
            for enemy_id in level["levelRecord"]["uniqueEnemies"]:
                preview = load_preview_image(int(enemy_id), enemy_lookup, enemy_banks_root)
                if preview is not None:
                    used_images.append((str(enemy_id), preview))

            boss_images = []
            for enemy_id in boss_enemy_ids:
                preview = load_preview_image(enemy_id, enemy_lookup, enemy_banks_root)
                if preview is not None:
                    boss_images.append((str(enemy_id), preview))

            safe_name = "".join(
                character.lower() if character.isalnum() else "-"
                for character in level["levelName"]
            ).strip("-")
            base_name = f"ep{episode['episode']}-lvl{int(level['lvlFileNum']):02d}-{safe_name or 'unnamed'}"

            used_contact_path = None
            if used_images:
                path = sheets_dir / f"{base_name}-used.png"
                save_contact_sheet(used_images, path, columns=min(8, len(used_images)))
                used_contact_path = f"contact-sheets/{path.name}"

            boss_contact_path = None
            if boss_images:
                path = sheets_dir / f"{base_name}-boss.png"
                save_contact_sheet(boss_images, path, columns=min(8, len(boss_images)))
                boss_contact_path = f"contact-sheets/{path.name}"

            playable_levels.append(
                {
                    "levelName": level["levelName"],
                    "lvlFileNum": level["lvlFileNum"],
                    "nextSection": level["nextSection"],
                    "shapeFileName": level["levelRecord"]["shapeFileName"],
                    "uniqueEnemyIds": level["levelRecord"]["uniqueEnemies"],
                    "spawnedEnemyIds": spawned_enemy_ids,
                    "bossLinkNumbers": boss_links,
                    "bossEnemyIds": boss_enemy_ids,
                    "usedEnemiesContactSheet": used_contact_path,
                    "bossEnemiesContactSheet": boss_contact_path,
                    "enemySummaries": [
                        summarize_enemy(int(enemy_id), enemy_lookup)
                        for enemy_id in level["levelRecord"]["uniqueEnemies"]
                    ],
                    "bossEnemySummaries": [
                        summarize_enemy(enemy_id, enemy_lookup)
                        for enemy_id in boss_enemy_ids
                    ],
                }
            )

        episodes.append(
            {
                "episode": episode["episode"],
                "levelsDatPath": episode["levelsDatPath"],
                "lvlPath": episode["lvlPath"],
                "playableLevels": playable_levels,
            }
        )

    metadata = {
        "source": {
            "levelUsage": str(level_usage_path),
            "enemyDefinitions": str(enemy_definitions_path),
            "enemyBanks": str(enemy_banks_root),
        },
        "directSpawnEventTypes": sorted(DIRECT_SPAWN_EVENT_TYPES),
        "episodes": episodes,
    }

    out_path = out_dir / "metadata.json"
    out_path.write_text(json.dumps(metadata, indent=2))
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
