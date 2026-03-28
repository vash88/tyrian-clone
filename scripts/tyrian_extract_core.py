from __future__ import annotations

import math
import struct
from pathlib import Path

from PIL import Image, ImageDraw


CELL_WIDTH = 12
CELL_HEIGHT = 14
SHEET9_COLUMNS = 19
CRYPT_KEY = (204, 129, 63, 255, 71, 19, 25, 62, 1, 99)


def repo_root_from_script(script_path: str | Path) -> Path:
    return Path(script_path).resolve().parents[1]


def decrypt_pascal_bytes(data: bytes) -> str:
    buffer = bytearray(data)
    if not buffer:
        return ""

    for index in range(len(buffer) - 1, -1, -1):
        buffer[index] ^= CRYPT_KEY[index % len(CRYPT_KEY)]
        if index > 0:
            buffer[index] ^= buffer[index - 1]

    return bytes(buffer).decode("latin1", "replace")


def read_encrypted_pascal_strings(path: Path) -> list[str]:
    data = path.read_bytes()
    cursor = 0
    strings: list[str] = []

    while cursor < len(data):
        length = data[cursor]
        cursor += 1
        strings.append(decrypt_pascal_bytes(data[cursor:cursor + length]))
        cursor += length

    return strings


def load_palette(path: Path, palette_index: int) -> list[tuple[int, int, int]]:
    raw = path.read_bytes()
    palette_size = 256 * 3
    palette_count = len(raw) // palette_size
    if palette_index < 0 or palette_index >= palette_count:
        raise ValueError(f"palette_index {palette_index} outside 0..{palette_count - 1}")

    start = palette_index * palette_size
    palette = []
    for index in range(256):
            r, g, b = raw[start + index * 3:start + index * 3 + 3]
            palette.append(((r << 2) | (r >> 4), (g << 2) | (g >> 4), (b << 2) | (b >> 4)))
    return palette


def load_all_palettes(path: Path) -> list[list[tuple[int, int, int]]]:
    raw = path.read_bytes()
    palette_size = 256 * 3
    palette_count = len(raw) // palette_size
    return [load_palette(path, index) for index in range(palette_count)]


def load_section_blob(path: Path, section_number: int) -> bytes:
    with path.open("rb") as handle:
        section_count = struct.unpack("<H", handle.read(2))[0]
        positions = list(struct.unpack(f"<{section_count}i", handle.read(section_count * 4)))
        handle.seek(0, 2)
        positions.append(handle.tell())

        start = positions[section_number - 1]
        end = positions[section_number]
        handle.seek(start)
        return handle.read(end - start)


def load_blob(path: Path) -> bytes:
    return path.read_bytes()


def decode_offsets(blob: bytes) -> list[int]:
    first_offset = struct.unpack_from("<H", blob, 0)[0]
    if first_offset % 2 != 0:
        raise ValueError(f"unexpected first offset {first_offset}")

    count = first_offset // 2
    offsets = [struct.unpack_from("<H", blob, index * 2)[0] for index in range(count)]
    if offsets != sorted(offsets):
        raise ValueError("sprite offsets are not sorted")
    return offsets


def decode_sprite_table(blob: bytes) -> list[dict[str, object]]:
    count = struct.unpack_from("<H", blob, 0)[0]
    cursor = 2
    sprites: list[dict[str, object]] = []

    for index in range(count):
        populated = bool(blob[cursor])
        cursor += 1

        if not populated:
            sprites.append(
                {
                    "index": index,
                    "populated": False,
                    "width": 0,
                    "height": 0,
                    "size": 0,
                    "dataOffset": None,
                    "data": b"",
                }
            )
            continue

        width, height, size = struct.unpack_from("<HHH", blob, cursor)
        cursor += 6
        data = blob[cursor:cursor + size]
        sprites.append(
            {
                "index": index,
                "populated": True,
                "width": width,
                "height": height,
                "size": size,
                "dataOffset": cursor,
                "data": data,
            }
        )
        cursor += size

    return sprites


def decode_sprite_image(
    data: bytes,
    *,
    width: int,
    height: int,
    palette: list[tuple[int, int, int]],
) -> Image.Image:
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    out = image.load()

    x = 0
    y = 0
    cursor = 0

    while cursor < len(data) and y < height:
        token = data[cursor]
        cursor += 1

        if token == 255:
            if cursor >= len(data):
                break
            x += data[cursor]
            cursor += 1
        elif token == 254:
            x = 0
            y += 1
        elif token == 253:
            x += 1
        else:
            if 0 <= x < width and 0 <= y < height:
                r, g, b = palette[token]
                out[x, y] = (r, g, b, 255)
            x += 1

        if x >= width:
            x = 0
            y += 1

    return image


def decode_cell(
    blob: bytes,
    offset: int,
    *,
    cell_width: int = CELL_WIDTH,
    cell_height: int = CELL_HEIGHT,
) -> list[list[int | None]]:
    pixels: list[list[int | None]] = [[None for _ in range(cell_width)] for _ in range(cell_height)]
    x = 0
    y = 0
    cursor = offset

    while cursor < len(blob):
        token = blob[cursor]
        cursor += 1
        if token == 0x0F:
            break

        skip = token & 0x0F
        fill = (token >> 4) & 0x0F
        x += skip

        if fill == 0:
            y += 1
            x -= cell_width
            if y >= cell_height:
                break
            continue

        for _ in range(fill):
            if 0 <= x < cell_width and 0 <= y < cell_height:
                pixels[y][x] = blob[cursor]
            cursor += 1
            x += 1

    return pixels


def raw_indexed_image(
    pixels: bytes,
    *,
    width: int,
    height: int,
    transparent_zero: bool = True,
) -> Image.Image:
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    out = image.load()

    for y in range(height):
        for x in range(width):
            value = pixels[y * width + x]
            if transparent_zero and value == 0:
                continue
            out[x, y] = (value, value, value, 255)

    return image


def indexed_bytes_to_palette_image(
    pixels: bytes,
    *,
    width: int,
    height: int,
    palette: list[tuple[int, int, int]],
    transparent_zero: bool = True,
) -> Image.Image:
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    out = image.load()

    for y in range(height):
        for x in range(width):
            value = pixels[y * width + x]
            if transparent_zero and value == 0:
                continue
            r, g, b = palette[value]
            out[x, y] = (r, g, b, 255)

    return image


def pixels_to_image(
    pixels: list[list[int | None]],
    palette: list[tuple[int, int, int]],
) -> Image.Image:
    image = Image.new("RGBA", (len(pixels[0]), len(pixels)), (0, 0, 0, 0))
    out = image.load()
    for y, row in enumerate(pixels):
        for x, value in enumerate(row):
            if value is None:
                continue
            r, g, b = palette[value]
            out[x, y] = (r, g, b, 255)
    return image


def alpha_bounds(image: Image.Image) -> dict[str, int] | None:
    bbox = image.getbbox()
    if bbox is None:
        return None
    left, top, right, bottom = bbox
    return {
        "x": left,
        "y": top,
        "width": right - left,
        "height": bottom - top,
    }


def save_contact_sheet(
    images: list[tuple[str, Image.Image]],
    out_path: Path,
    *,
    columns: int,
    label_height: int = 18,
    cell_padding: int = 10,
    background: tuple[int, int, int, int] = (12, 15, 20, 255),
) -> None:
    if not images:
        return

    tile_width = max(image.width for _, image in images) + cell_padding * 2
    tile_height = max(image.height for _, image in images) + label_height + cell_padding * 2
    rows = math.ceil(len(images) / columns)

    sheet = Image.new("RGBA", (columns * tile_width, rows * tile_height), background)
    draw = ImageDraw.Draw(sheet)

    for index, (label, image) in enumerate(images):
        col = index % columns
        row = index // columns
        x = col * tile_width
        y = row * tile_height
        draw.rectangle(
            (
                x + cell_padding - 1,
                y + label_height + cell_padding - 1,
                x + cell_padding + image.width,
                y + label_height + cell_padding + image.height,
            ),
            outline=(180, 65, 65, 255),
            width=1,
        )
        sheet.alpha_composite(image, (x + cell_padding, y + label_height + cell_padding))
        draw.text((x + cell_padding, y + 2), label, fill=(220, 225, 235, 255))

    sheet.save(out_path)


def save_uniform_atlas(
    images: list[tuple[str, Image.Image]],
    out_path: Path,
    *,
    columns: int,
) -> tuple[dict[str, object], dict[str, dict[str, int]]]:
    if not images:
        raise ValueError("cannot build atlas from empty image list")

    sprite_width = max(image.width for _, image in images)
    sprite_height = max(image.height for _, image in images)
    rows = math.ceil(len(images) / columns)

    atlas = Image.new("RGBA", (columns * sprite_width, rows * sprite_height), (0, 0, 0, 0))
    frames: dict[str, dict[str, int]] = {}

    for index, (label, image) in enumerate(images):
        col = index % columns
        row = index // columns
        x = col * sprite_width
        y = row * sprite_height
        atlas.alpha_composite(image, (x, y))
        frames[label] = {
            "x": x,
            "y": y,
            "width": image.width,
            "height": image.height,
        }

    atlas.save(out_path)
    return (
        {
            "width": atlas.width,
            "height": atlas.height,
            "spriteWidth": sprite_width,
            "spriteHeight": sprite_height,
            "columns": columns,
        },
        frames,
    )


def save_packed_strip_atlas(
    images: list[tuple[str, Image.Image]],
    out_path: Path,
    *,
    padding: int = 0,
) -> tuple[dict[str, object], dict[str, dict[str, int]]]:
    if not images:
        raise ValueError("cannot build atlas from empty image list")

    atlas_width = sum(image.width for _, image in images)
    if len(images) > 1:
        atlas_width += padding * (len(images) - 1)
    atlas_height = max(image.height for _, image in images)

    atlas = Image.new("RGBA", (atlas_width, atlas_height), (0, 0, 0, 0))
    frames: dict[str, dict[str, int]] = {}
    cursor_x = 0

    for label, image in images:
        atlas.alpha_composite(image, (cursor_x, 0))
        frames[label] = {
            "x": cursor_x,
            "y": 0,
            "width": image.width,
            "height": image.height,
        }
        cursor_x += image.width + padding

    atlas.save(out_path)
    return (
        {
            "width": atlas.width,
            "height": atlas.height,
            "layout": "packed-strip",
            "padding": padding,
        },
        frames,
    )
