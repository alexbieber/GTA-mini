#!/usr/bin/env python3
"""Bake photoscanned wall textures into city facades with window grids."""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path("/Users/ambarsingh/Desktop/gta/assets/pbr")
OUT = ROOT / "facades"
SIZE = 2048


def load_rgb(path: Path, size: int = SIZE) -> Image.Image:
    img = Image.open(path).convert("RGB")
    tiled = Image.new("RGB", (size, size))
    src = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    for y in range(0, size, src.height):
        for x in range(0, size, src.width):
            tiled.paste(src, (x, y))
    return tiled


def load_gray(path: Path, size: int = SIZE) -> Image.Image:
    return load_rgb(path, size).convert("L")


def window_glass(w: int, h: int, night: bool, lit: bool, seed: int) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGB", (w, h))
    px = img.load()
    if lit:
        base = (rng.randint(210, 255), rng.randint(170, 210), rng.randint(90, 130))
    elif night:
        base = (rng.randint(18, 32), rng.randint(24, 40), rng.randint(36, 52))
    else:
        # Daytime glass: muted sky reflection, not candy tiles
        base = (rng.randint(88, 108), rng.randint(102, 118), rng.randint(112, 128))
    for y in range(h):
        t = y / max(h - 1, 1)
        shade = 1.08 - t * 0.28 + rng.random() * 0.04
        r = int(min(255, base[0] * shade))
        g = int(min(255, base[1] * shade))
        b = int(min(255, base[2] * shade))
        for x in range(w):
            edge = 1.0
            if x < 2 or x >= w - 2 or y < 2 or y >= h - 2:
                edge = 0.72
            n = 0.94 + ((x * 13 + y * 7 + seed) % 9) * 0.008
            px[x, y] = (int(r * edge * n), int(g * edge * n), int(b * edge * n))
    if rng.random() < 0.35 and not lit:
        # blinds
        draw = ImageDraw.Draw(img)
        step = max(3, h // 10)
        for y in range(4, h - 4, step):
            draw.line((2, y, w - 3, y), fill=(40, 38, 34), width=1)
    if rng.random() < 0.18:
        # curtain
        draw = ImageDraw.Draw(img)
        col = (48, 36, 32) if night and not lit else (90, 70, 58)
        draw.rectangle((2, 2, w // 3, h - 3), fill=col)
    return img


def bake(
    name: str,
    wall_id: str,
    cols: int,
    rows: int,
    margin: float,
    gap: float,
    lit_chance: float,
    frame: tuple[int, int, int],
    sill: bool,
    tint: tuple[float, float, float] | None = None,
) -> None:
    wall = load_rgb(ROOT / wall_id / f"{wall_id}_diff_1k.jpg")
    nor = load_rgb(ROOT / wall_id / f"{wall_id}_nor_1k.jpg")
    rough = load_gray(ROOT / wall_id / f"{wall_id}_rough_1k.jpg")
    if tint:
        wpx = wall.load()
        for y in range(SIZE):
            for x in range(SIZE):
                r, g, b = wpx[x, y]
                wpx[x, y] = (
                    int(min(255, r * tint[0])),
                    int(min(255, g * tint[1])),
                    int(min(255, b * tint[2])),
                )

    albedo = wall.copy()
    emit = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    rough_out = rough.convert("RGB")
    nor_out = nor.copy()

    draw_a = ImageDraw.Draw(albedo)
    draw_e = ImageDraw.Draw(emit)
    draw_r = ImageDraw.Draw(rough_out)
    rng = random.Random(hash(name) & 0xFFFFFFFF)

    mx = int(SIZE * margin)
    my = int(SIZE * (margin + 0.02))
    usable_w = SIZE - mx * 2
    usable_h = SIZE - my * 2
    cell_w = usable_w / cols
    cell_h = usable_h / rows
    pad_x = int(cell_w * gap)
    pad_y = int(cell_h * (gap + 0.08))

    for j in range(rows):
        for i in range(cols):
            x0 = int(mx + i * cell_w + pad_x)
            y0 = int(my + j * cell_h + pad_y)
            x1 = int(mx + (i + 1) * cell_w - pad_x)
            y1 = int(my + (j + 1) * cell_h - pad_y)
            if x1 - x0 < 12 or y1 - y0 < 16:
                continue
            lit = rng.random() < lit_chance
            glass = window_glass(x1 - x0, y1 - y0, False, False, rng.randint(0, 10_000))
            albedo.paste(glass, (x0, y0))
            # frame
            draw_a.rectangle((x0 - 3, y0 - 3, x1 + 2, y1 + 2), outline=frame, width=3)
            if sill:
                draw_a.rectangle((x0 - 5, y1 + 1, x1 + 4, y1 + 6), fill=tuple(min(255, c + 18) for c in frame))
            # mullion
            if x1 - x0 > 40:
                mxid = (x0 + x1) // 2
                draw_a.line((mxid, y0, mxid, y1), fill=frame, width=2)
            draw_r.rectangle((x0, y0, x1, y1), fill=(28, 28, 28))
            if lit:
                draw_e.rectangle((x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill=(255, 196, 110))
            else:
                draw_e.rectangle((x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill=(8, 10, 16))
            # flatten normals in glass
            ng = Image.new("RGB", (x1 - x0, y1 - y0), (128, 128, 255))
            nor_out.paste(ng, (x0, y0))

    # dirt / streaks
    albedo = ImageEnhance.Contrast(albedo).enhance(1.08)
    albedo = ImageEnhance.Color(albedo).enhance(1.05)
    albedo = albedo.filter(ImageFilter.GaussianBlur(radius=0.4))

    OUT.mkdir(parents=True, exist_ok=True)
    albedo.save(OUT / f"{name}_diff.png", optimize=True)
    emit.save(OUT / f"{name}_emit.png", optimize=True)
    rough_out.convert("L").save(OUT / f"{name}_rough.png", optimize=True)
    nor_out.save(OUT / f"{name}_nor.png", optimize=True)
    print("baked", name)


def bake_office() -> None:
    """Glass curtain wall over concrete."""
    wall = load_rgb(ROOT / "cracked_concrete_wall" / "cracked_concrete_wall_diff_1k.jpg")
    albedo = Image.new("RGB", (SIZE, SIZE), (48, 56, 64))
    emit = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    rough = Image.new("L", (SIZE, SIZE), 30)
    nor = Image.new("RGB", (SIZE, SIZE), (128, 128, 255))
    draw_a = ImageDraw.Draw(albedo)
    draw_e = ImageDraw.Draw(emit)
    rng = random.Random(77)
    cols, rows = 6, 9
    albedo.paste(wall.resize((SIZE, SIZE), Image.Resampling.LANCZOS))
    for j in range(rows):
        for i in range(cols):
            x0 = int(i * SIZE / cols) + 8
            y0 = int(j * SIZE / rows) + 8
            x1 = int((i + 1) * SIZE / cols) - 8
            y1 = int((j + 1) * SIZE / rows) - 8
            lit = rng.random() < 0.22
            glass = window_glass(x1 - x0, y1 - y0, False, False, rng.randint(0, 9999))
            albedo.paste(glass, (x0, y0))
            if lit:
                draw_e.rectangle((x0, y0, x1, y1), fill=(255, 210, 140))
    for i in range(cols + 1):
        x = int(i * SIZE / cols)
        draw_a.rectangle((x - 5, 0, x + 5, SIZE), fill=(58, 62, 68))
    for j in range(rows + 1):
        y = int(j * SIZE / rows)
        draw_a.rectangle((0, y - 4, SIZE, y + 4), fill=(52, 56, 62))
    # mix a little concrete at the base band
    base = wall.resize((SIZE, 180), Image.Resampling.LANCZOS)
    albedo.paste(base, (0, SIZE - 180))
    albedo.save(OUT / "office_diff.png", optimize=True)
    emit.save(OUT / "office_emit.png", optimize=True)
    rough.save(OUT / "office_rough.png", optimize=True)
    nor.save(OUT / "office_nor.png", optimize=True)
    print("baked office")


def bake_warehouse() -> None:
    metal = load_rgb(ROOT / "metal_plate" / "metal_plate_diff_1k.jpg")
    albedo = metal.copy()
    emit = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    rough = load_gray(ROOT / "metal_plate" / "metal_plate_rough_1k.jpg")
    nor = load_rgb(ROOT / "metal_plate" / "metal_plate_nor_1k.jpg")
    draw_a = ImageDraw.Draw(albedo)
    draw_e = ImageDraw.Draw(emit)
    draw_r = ImageDraw.Draw(rough.convert("RGB"))
    rng = random.Random(19)
    for i, x0 in enumerate((220, 820, 1420)):
        y0, x1, y1 = 480, x0 + 380, 980
        lit = rng.random() < 0.2
        glass = window_glass(x1 - x0, y1 - y0, False, False, 300 + i)
        albedo.paste(glass, (x0, y0))
        draw_a.rectangle((x0 - 6, y0 - 6, x1 + 5, y1 + 5), outline=(40, 44, 48), width=6)
        if lit:
            draw_e.rectangle((x0, y0, x1, y1), fill=(255, 180, 80))
    OUT.mkdir(parents=True, exist_ok=True)
    albedo.save(OUT / "warehouse_diff.png", optimize=True)
    emit.save(OUT / "warehouse_emit.png", optimize=True)
    rough.save(OUT / "warehouse_rough.png", optimize=True)
    nor.save(OUT / "warehouse_nor.png", optimize=True)
    print("baked warehouse")
    _ = draw_r


def bake_road() -> None:
    asp = load_rgb(ROOT / "asphalt_01" / "asphalt_01_diff_1k.jpg")
    img = asp.copy()
    draw = ImageDraw.Draw(img)
    # edge lines
    draw.rectangle((70, 0, 110, SIZE), fill=(214, 214, 208))
    draw.rectangle((SIZE - 110, 0, SIZE - 70, SIZE), fill=(214, 214, 208))
    # center dashes
    x0, x1 = SIZE // 2 - 10, SIZE // 2 + 10
    for y in range(40, SIZE, 180):
        draw.rectangle((x0, y, x1, y + 90), fill=(232, 210, 92))
    img.save(OUT / "road_diff.png", optimize=True)
    load_gray(ROOT / "asphalt_01" / "asphalt_01_rough_1k.jpg").save(OUT / "road_rough.png")
    load_rgb(ROOT / "asphalt_01" / "asphalt_01_nor_1k.jpg").save(OUT / "road_nor.png")
    print("baked road")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    bake("brick", "red_brick", 5, 7, 0.06, 0.18, 0.38, (62, 48, 42), True)
    bake("brick_dark", "red_brick_03", 5, 8, 0.055, 0.16, 0.32, (48, 40, 36), True, (0.82, 0.78, 0.76))
    bake("concrete", "cracked_concrete_wall", 4, 8, 0.07, 0.2, 0.3, (88, 90, 94), True)
    bake("plaster", "painted_plaster_wall", 4, 6, 0.08, 0.22, 0.42, (92, 82, 70), True)
    bake_office()
    bake_warehouse()
    bake_road()


if __name__ == "__main__":
    main()
