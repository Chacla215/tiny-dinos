#!/usr/bin/env python3
"""Bake the social account art — profile picture + YouTube channel banner.

The avatar is a Ralph head crop; the same square works for TikTok / Instagram
/ YouTube, which all crop to a circle, so it's composed circle-safe. The
banner extends the cast strip to YouTube's 2048x1152 with the cast held
inside the 1235x338 all-devices safe area.

    python3 scripts/tools/gen_social_brand.py

Writes assets/concept/brand/avatar/ :
    avatar_1024.png   master (upload this everywhere)
    avatar_400.png    YouTube channel icon size
    avatar_320.png    Instagram / TikTok size
    avatar_preview_circle.png   what it looks like cropped round
    yt_banner_2048.png          YouTube channel banner
"""
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "assets/concept/ralph/ralph_hero.png"
BANNER = ROOT / "assets/concept/brand/banner_cast.png"
OUT = ROOT / "assets/concept/brand/avatar"

# Head crop in source pixels (square, centred on Ralph's face).
CROP = (170, 45, 960, 835)
SIZE = 1024
KEY_TOL = 46          # flat-background flood-fill tolerance
HEAD_SCALE = 0.80     # head size inside the square (circle-safe)
HEAD_Y = 0.52         # head centre, fraction of height

# Brand background: sunny island sky -> warm sand, with a soft glow.
BG_TOP = (255, 214, 112)
BG_BOT = (247, 148, 74)
GLOW = (255, 246, 206)


def flood_key(img: Image.Image, tol: int) -> Image.Image:
    """Alpha-out the flat backdrop by flooding in from the border."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    seed = px[0, 0][:3]
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        r, g, b, _ = px[x, y]
        if abs(r - seed[0]) + abs(g - seed[1]) + abs(b - seed[2]) > tol:
            continue
        px[x, y] = (r, g, b, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                q.append((nx, ny))
    # Feather the cut edge so it doesn't read as a sticker.
    a = img.getchannel("A").filter(ImageFilter.GaussianBlur(1.2))
    img.putalpha(a)
    return img


def background(size: int) -> Image.Image:
    bg = Image.new("RGB", (size, size))
    d = ImageDraw.Draw(bg)
    for y in range(size):
        t = y / (size - 1)
        d.line(
            [(0, y), (size, y)],
            fill=tuple(round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOT)),
        )
    # Radial glow behind the head so the silhouette pops at 40px.
    glow = Image.new("L", (size, size), 0)
    g = ImageDraw.Draw(glow)
    r = size * 0.40
    cx, cy = size / 2, size * HEAD_Y
    g.ellipse([cx - r, cy - r, cx + r, cy + r], fill=190)
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.10))
    bg = Image.composite(Image.new("RGB", (size, size), GLOW), bg, glow)
    return bg


def yt_banner() -> Image.Image:
    """2048x1152 channel banner; cast held inside the 1235x338 safe area."""
    W, H = 2048, 1152
    strip = Image.open(BANNER).convert("RGB")
    strip = strip.resize((W, round(strip.height * W / strip.width)), Image.LANCZOS)
    # Fill the letterbox with the same art blown up and blurred — the strip's
    # edge rows run through the dinos, so stretching them would smear.
    src = Image.open(BANNER).convert("RGB")
    cover = src.resize((round(H * src.width / src.height), H), Image.LANCZOS)
    canvas = cover.crop(
        ((cover.width - W) // 2, 0, (cover.width - W) // 2 + W, H)
    ).filter(ImageFilter.GaussianBlur(H * 0.05))
    canvas.paste(strip, (0, (H - strip.height) // 2))
    return canvas


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    head = flood_key(Image.open(SRC).crop(CROP), KEY_TOL)
    head = head.crop(head.getbbox())

    target = round(SIZE * HEAD_SCALE)
    scale = target / max(head.size)
    head = head.resize(
        (round(head.width * scale), round(head.height * scale)), Image.LANCZOS
    )

    canvas = background(SIZE).convert("RGBA")
    # Contact shadow, then the head.
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sx = round(SIZE / 2 - head.width / 2)
    sy = round(SIZE * HEAD_Y - head.height / 2)
    shadow.paste((0, 0, 0, 90), (sx, sy + round(SIZE * 0.02)), head)
    canvas = Image.alpha_composite(
        canvas, shadow.filter(ImageFilter.GaussianBlur(SIZE * 0.012))
    )
    canvas.paste(head, (sx, sy), head)

    master = canvas.convert("RGB")
    master.save(OUT / "avatar_1024.png")
    for px in (400, 320):
        master.resize((px, px), Image.LANCZOS).save(OUT / f"avatar_{px}.png")

    # Circle preview — how every platform will actually show it.
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, SIZE - 1, SIZE - 1], fill=255)
    prev = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    prev.paste(master, (0, 0), mask)
    prev.save(OUT / "avatar_preview_circle.png")

    yt_banner().save(OUT / "yt_banner_2048.png")

    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
