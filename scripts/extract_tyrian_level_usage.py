#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import shutil
import struct
from collections import Counter
from pathlib import Path

from tyrian_extract_core import read_encrypted_pascal_strings, repo_root_from_script


LAYER_DIMENSIONS = (
    {"width": 14, "height": 300},
    {"width": 14, "height": 600},
    {"width": 15, "height": 600},
)

LEVEL_COMMAND_RE = re.compile(
    r"^\]L\[\s*(?P<section>\d+)\s+(?P<next>\d+)\s+(?P<name>.{9})\s*(?P<song>\d+)\s+(?P<lvl>\d+)(?P<flags>.*)$"
)
SECTION_HEADER_RE = re.compile(r"^\*+\s*(?P<section>\d+)")


def parse_level_positions(path: Path) -> list[int]:
    blob = path.read_bytes()
    level_count = struct.unpack_from("<H", blob, 0)[0]
    return list(struct.unpack_from(f"<{level_count}i", blob, 2))


def parse_level_record(path: Path, lvl_file_num: int) -> dict[str, object]:
    blob = path.read_bytes()
    level_count = struct.unpack_from("<H", blob, 0)[0]
    positions = list(struct.unpack_from(f"<{level_count}i", blob, 2))

    position_index = (lvl_file_num - 1) * 2
    if position_index < 0 or position_index >= len(positions):
        raise ValueError(
            f"{path.name} lvlFileNum {lvl_file_num} maps to position index {position_index}, "
            f"but file only contains {len(positions)} offsets"
        )

    cursor = positions[position_index]
    record_offset = cursor

    map_file_char = chr(blob[cursor])
    cursor += 1
    shape_file_char = chr(blob[cursor])
    cursor += 1

    map_x, map_x2, map_x3 = struct.unpack_from("<HHH", blob, cursor)
    cursor += 6

    level_enemy_max = struct.unpack_from("<H", blob, cursor)[0]
    cursor += 2
    level_enemy = list(struct.unpack_from(f"<{level_enemy_max}H", blob, cursor))
    cursor += level_enemy_max * 2

    max_event = struct.unpack_from("<H", blob, cursor)[0]
    cursor += 2

    events = []
    event_types: Counter[int] = Counter()
    for _ in range(max_event):
        event_time = struct.unpack_from("<H", blob, cursor)[0]
        cursor += 2
        event_type = blob[cursor]
        cursor += 1
        event_dat, event_dat2 = struct.unpack_from("<hh", blob, cursor)
        cursor += 4
        event_dat3 = struct.unpack_from("<b", blob, cursor)[0]
        cursor += 1
        event_dat5 = struct.unpack_from("<b", blob, cursor)[0]
        cursor += 1
        event_dat6 = struct.unpack_from("<b", blob, cursor)[0]
        cursor += 1
        event_dat4 = blob[cursor]
        cursor += 1

        event_types[event_type] += 1
        events.append(
            {
                "eventTime": event_time,
                "eventType": event_type,
                "eventDat": event_dat,
                "eventDat2": event_dat2,
                "eventDat3": event_dat3,
                "eventDat4": event_dat4,
                "eventDat5": event_dat5,
                "eventDat6": event_dat6,
            }
        )

    map_shape_lookup = []
    for _ in range(3):
        table = list(struct.unpack_from("<128H", blob, cursor))
        cursor += 256
        map_shape_lookup.append(table)

    layers = []
    for layer_index, dimensions in enumerate(LAYER_DIMENSIONS):
        width = dimensions["width"]
        height = dimensions["height"]
        size = width * height
        cells = list(blob[cursor:cursor + size])
        cursor += size

        used_map_indices = sorted({value for value in cells if value != 0})
        used_shape_ids = sorted(
            {
                map_shape_lookup[layer_index][value]
                for value in used_map_indices
                if value < len(map_shape_lookup[layer_index]) and map_shape_lookup[layer_index][value] != 0
            }
        )

        layers.append(
            {
                "layer": layer_index + 1,
                "width": width,
                "height": height,
                "usedMapIndices": used_map_indices,
                "usedShapeIds": used_shape_ids,
            }
        )

    return {
        "lvlFileNum": lvl_file_num,
        "positionIndex": position_index,
        "offset": record_offset,
        "recordLength": cursor - record_offset,
        "mapFileChar": map_file_char,
        "shapeFileChar": shape_file_char,
        "shapeFileName": f"shapes{shape_file_char.lower()}.dat",
        "mapX": map_x,
        "mapX2": map_x2,
        "mapX3": map_x3,
        "levelEnemyMax": level_enemy_max,
        "levelEnemy": level_enemy,
        "uniqueEnemies": sorted({enemy for enemy in level_enemy if enemy != 0}),
        "maxEvent": max_event,
        "eventTypeCounts": dict(sorted(event_types.items())),
        "events": events,
        "mapShapeLookup": map_shape_lookup,
        "layers": layers,
    }


def parse_level_command(raw: str) -> dict[str, object] | None:
    match = LEVEL_COMMAND_RE.match(raw)
    if match is None:
        return None

    flags = match.group("flags")
    return {
        "raw": raw,
        "scriptSectionTarget": int(match.group("section")),
        "nextSection": int(match.group("next")),
        "levelName": match.group("name").rstrip(),
        "levelSong": int(match.group("song")),
        "lvlFileNum": int(match.group("lvl")),
        "bonusLevelCurrent": "$" in flags[1:] if flags else False,
        "normalBonusLevelCurrent": flags.startswith("$"),
        "flags": flags,
    }


def parse_levels_dat(path: Path, lvl_path: Path) -> dict[str, object]:
    strings = read_encrypted_pascal_strings(path)

    sections: list[dict[str, object]] = []
    current_section: dict[str, object] | None = None
    playable_levels: list[dict[str, object]] = []

    for string_index, raw in enumerate(strings):
        if raw.startswith("**"):
            section_number = len(sections) + 1
            header_match = SECTION_HEADER_RE.match(raw)
            if header_match is not None:
                section_number = int(header_match.group("section"))

            current_section = {
                "sectionNumber": section_number,
                "header": raw,
                "stringIndex": string_index,
                "commands": [],
                "playableLevels": [],
            }
            sections.append(current_section)
            continue

        if current_section is None:
            current_section = {
                "sectionNumber": 0,
                "header": "Preamble",
                "stringIndex": 0,
                "commands": [],
                "playableLevels": [],
            }
            sections.append(current_section)

        command_entry: dict[str, object] = {"raw": raw, "stringIndex": string_index}
        level_command = parse_level_command(raw)
        if level_command is not None:
            level_record = parse_level_record(lvl_path, int(level_command["lvlFileNum"]))
            entry = {
                **level_command,
                "sourceSection": current_section["sectionNumber"],
                "stringIndex": string_index,
                "levelRecord": level_record,
            }
            current_section["playableLevels"].append(entry)
            playable_levels.append(entry)
            command_entry["kind"] = "level"
            command_entry["level"] = {
                "levelName": entry["levelName"],
                "lvlFileNum": entry["lvlFileNum"],
                "shapeFileName": level_record["shapeFileName"],
            }
        elif raw.startswith("]J"):
            command_entry["kind"] = "jump"
        elif raw.startswith("]"):
            command_entry["kind"] = "directive"
        else:
            command_entry["kind"] = "text"

        current_section["commands"].append(command_entry)

    return {
        "levelsDatPath": str(path),
        "lvlPath": str(lvl_path),
        "sections": sections,
        "playableLevels": playable_levels,
        "playableLevelCount": len(playable_levels),
        "uniqueLvlFileNums": sorted({level["lvlFileNum"] for level in playable_levels}),
    }


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    source_dir = repo_root / "references/tyrian21"
    out_dir = repo_root / "references/tyrian21-extracted/level-usage"

    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    episodes = []
    for levels_dat in sorted(source_dir.glob("levels?.dat")):
        episode_number = int(levels_dat.stem[-1])
        lvl_path = source_dir / f"tyrian{episode_number}.lvl"
        if not lvl_path.exists():
            continue

        episodes.append(
            {
                "episode": episode_number,
                **parse_levels_dat(levels_dat, lvl_path),
            }
        )

    metadata = {
        "sourceDirectory": str(source_dir),
        "episodes": episodes,
    }

    out_path = out_dir / "metadata.json"
    out_path.write_text(json.dumps(metadata, indent=2))
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
