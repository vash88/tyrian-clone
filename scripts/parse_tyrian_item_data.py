#!/usr/bin/env python3

from __future__ import annotations

import json
import struct
from pathlib import Path

from tyrian_extract_core import repo_root_from_script


def read_pascal_name(blob: bytes, cursor: int) -> tuple[str, int]:
    name_len = blob[cursor]
    cursor += 1
    raw = blob[cursor:cursor + 30]
    cursor += 30
    return raw[: min(name_len, 30)].decode("latin1", errors="replace").rstrip("\x00"), cursor


def read_struct(fmt: str, blob: bytes, cursor: int) -> tuple[tuple[object, ...], int]:
    size = struct.calcsize(fmt)
    return struct.unpack_from(fmt, blob, cursor), cursor + size


def main() -> None:
    repo_root = repo_root_from_script(__file__)
    source_path = repo_root / "references/tyrian21/tyrian.hdt"
    out_dir = repo_root / "references/tyrian21-extracted/item-data"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "episode1-item-data.json"

    blob = source_path.read_bytes()
    episode1_data_loc = struct.unpack_from("<i", blob, 0)[0]
    cursor = episode1_data_loc
    counts = struct.unpack_from("<7H", blob, cursor)
    cursor += 14

    weapon_count, port_count, power_count, ship_count, option_count, shield_count, enemy_count = counts

    weapons: list[dict[str, object]] = []
    for index in range(weapon_count + 1):
        (drain, shotrepeat, multi, weapani, max_frames, tx, ty, aim), cursor = read_struct(
            "<HBBHBBBB", blob, cursor
        )
        attack, cursor = read_struct("<8B", blob, cursor)
        delay, cursor = read_struct("<8B", blob, cursor)
        sx, cursor = read_struct("<8b", blob, cursor)
        sy, cursor = read_struct("<8b", blob, cursor)
        bx, cursor = read_struct("<8b", blob, cursor)
        by, cursor = read_struct("<8b", blob, cursor)
        sg, cursor = read_struct("<8H", blob, cursor)
        (acceleration, accelerationx, circlesize, sound, trail, shipblastfilter), cursor = read_struct(
            "<bbBBBB", blob, cursor
        )
        weapons.append(
            {
                "index": index,
                "drain": drain,
                "shotRepeat": shotrepeat,
                "multi": multi,
                "weapAni": weapani,
                "max": max_frames,
                "tx": tx,
                "ty": ty,
                "aim": aim,
                "attack": list(attack),
                "delay": list(delay),
                "sx": list(sx),
                "sy": list(sy),
                "bx": list(bx),
                "by": list(by),
                "sg": list(sg),
                "acceleration": acceleration,
                "accelerationX": accelerationx,
                "circleSize": circlesize,
                "sound": sound,
                "trail": trail,
                "shipBlastFilter": shipblastfilter,
            }
        )

    weapon_ports: list[dict[str, object]] = []
    for index in range(port_count + 1):
        name, cursor = read_pascal_name(blob, cursor)
        (opnum,), cursor = read_struct("<B", blob, cursor)
        op_a, cursor = read_struct("<11H", blob, cursor)
        op_b, cursor = read_struct("<11H", blob, cursor)
        (cost, itemgraphic, poweruse), cursor = read_struct("<HHH", blob, cursor)
        weapon_ports.append(
            {
                "index": index,
                "name": name,
                "opnum": opnum,
                "op": [list(op_a), list(op_b)],
                "cost": cost,
                "itemGraphic": itemgraphic,
                "powerUse": poweruse,
            }
        )

    specials: list[dict[str, object]] = []
    for index in range(46 + 1):
        name, cursor = read_pascal_name(blob, cursor)
        (itemgraphic, pwr, stype, wpn), cursor = read_struct("<HBBH", blob, cursor)
        specials.append(
            {
                "index": index,
                "name": name,
                "itemGraphic": itemgraphic,
                "pwr": pwr,
                "sType": stype,
                "wpn": wpn,
            }
        )

    generators: list[dict[str, object]] = []
    for index in range(power_count + 1):
        name, cursor = read_pascal_name(blob, cursor)
        (itemgraphic, power, speed, cost), cursor = read_struct("<HBbH", blob, cursor)
        generators.append(
            {
                "index": index,
                "name": name,
                "itemGraphic": itemgraphic,
                "power": power,
                "speed": speed,
                "cost": cost,
            }
        )

    ships: list[dict[str, object]] = []
    for index in range(ship_count + 1):
        name, cursor = read_pascal_name(blob, cursor)
        (shipgraphic, itemgraphic, ani, spd, dmg, cost, bigshipgraphic), cursor = read_struct(
            "<HHBbBHB",
            blob,
            cursor,
        )
        ships.append(
            {
                "index": index,
                "name": name,
                "shipGraphic": shipgraphic,
                "itemGraphic": itemgraphic,
                "ani": ani,
                "spd": spd,
                "dmg": dmg,
                "cost": cost,
                "bigShipGraphic": bigshipgraphic,
            }
        )

    options: list[dict[str, object]] = []
    for index in range(option_count + 1):
        name, cursor = read_pascal_name(blob, cursor)
        (pwr, itemgraphic, cost, tr, option, opspd, ani), cursor = read_struct("<BHHBBbB", blob, cursor)
        gr, cursor = read_struct("<20H", blob, cursor)
        (wport, wpnum, ammo, stop_raw, icongr), cursor = read_struct("<BHBBB", blob, cursor)
        options.append(
            {
                "index": index,
                "name": name,
                "pwr": pwr,
                "itemGraphic": itemgraphic,
                "cost": cost,
                "tr": tr,
                "option": option,
                "opSpd": opspd,
                "ani": ani,
                "gr": list(gr),
                "wPort": wport,
                "wpNum": wpnum,
                "ammo": ammo,
                "stop": bool(stop_raw),
                "iconGr": icongr,
            }
        )

    shields: list[dict[str, object]] = []
    for index in range(shield_count + 1):
        name, cursor = read_pascal_name(blob, cursor)
        (tpwr, mpwr, itemgraphic, cost), cursor = read_struct("<BBHH", blob, cursor)
        shields.append(
            {
                "index": index,
                "name": name,
                "tPwr": tpwr,
                "mPwr": mpwr,
                "itemGraphic": itemgraphic,
                "cost": cost,
            }
        )

    enemies: list[dict[str, object]] = []
    for index in range(enemy_count + 1):
        (ani,), cursor = read_struct("<B", blob, cursor)
        tur, cursor = read_struct("<3B", blob, cursor)
        freq, cursor = read_struct("<3B", blob, cursor)
        (xmove, ymove, xaccel, yaccel, xcaccel, ycaccel), cursor = read_struct("<6b", blob, cursor)
        (startx, starty, startxc, startyc), cursor = read_struct("<hhbb", blob, cursor)
        (armor, esize), cursor = read_struct("<BB", blob, cursor)
        egraphic, cursor = read_struct("<20H", blob, cursor)
        (explosiontype, animate, shapebank, xrev, yrev, dgr, dlevel, dani, elaunchfreq, elaunchtype, value, eenemydie), cursor = read_struct(
            "<BBBbbHbbBHhH",
            blob,
            cursor,
        )
        enemies.append(
            {
                "index": index,
                "ani": ani,
                "tur": list(tur),
                "freq": list(freq),
                "xMove": xmove,
                "yMove": ymove,
                "xAccel": xaccel,
                "yAccel": yaccel,
                "xcAccel": xcaccel,
                "ycAccel": ycaccel,
                "startX": startx,
                "startY": starty,
                "startXC": startxc,
                "startYC": startyc,
                "armor": armor,
                "eSize": esize,
                "eGraphic": list(egraphic),
                "explosionType": explosiontype,
                "animate": animate,
                "shapeBank": shapebank,
                "xRev": xrev,
                "yRev": yrev,
                "dgr": dgr,
                "dLevel": dlevel,
                "dAni": dani,
                "eLaunchFreq": elaunchfreq,
                "eLaunchType": elaunchtype,
                "value": value,
                "eEnemyDie": eenemydie,
            }
        )

    data = {
        "source": str(source_path),
        "episode1DataOffset": episode1_data_loc,
        "counts": {
            "weapons": weapon_count,
            "weaponPorts": port_count,
            "generators": power_count,
            "ships": ship_count,
            "options": option_count,
            "shields": shield_count,
            "enemies": enemy_count,
            "specials": 46,
        },
        "weapons": weapons,
        "weaponPorts": weapon_ports,
        "specials": specials,
        "generators": generators,
        "ships": ships,
        "options": options,
        "shields": shields,
        "enemies": enemies,
    }

    out_path.write_text(json.dumps(data, indent=2))
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
