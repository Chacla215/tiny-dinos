#!/usr/bin/env python3
"""Render Ep1's two ALLOWED text overlays as transparent PNGs.

Iron rule 1: the ONLY on-screen text in an episode is the hook card and a
time signpost. No narration captions, no beat labels. Do not add cards here
to cover a missing beat — generate the beat instead.
"""
import sys
from PIL import Image, ImageDraw, ImageFont

W, H = 720, 1280
FONT = "assets/fonts/Jersey25.ttf"
OUT = sys.argv[1] if len(sys.argv) > 1 else "wip/ep1/cards"

YELLOW = (255, 214, 51, 255)
WHITE = (255, 255, 255, 255)


def draw_outlined(d, xy, text, font, fill, outline=6):
    x, y = xy
    for dx in range(-outline, outline + 1):
        for dy in range(-outline, outline + 1):
            if dx * dx + dy * dy <= outline * outline:
                d.text((x + dx, y + dy), text, font=font, fill=(0, 0, 0, 235))
    d.text((x, y), text, font=font, fill=fill)


def centered(d, y, text, font, fill, outline=6):
    w = d.textbbox((0, 0), text, font=font)[2]
    draw_outlined(d, ((W - w) // 2, y), text, font, fill, outline)


def hook_card(path):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(FONT, 88)
    centered(d, 124, "NOBODY TOUCHES", f, WHITE)
    centered(d, 206, "THE LEAF.", f, YELLOW)
    img.save(path)


def signpost_card(path):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(FONT, 60)
    centered(d, 96, "12 SECONDS EARLIER", f, WHITE, outline=4)
    img.save(path)


if __name__ == "__main__":
    hook_card(f"{OUT}/hook.png")
    signpost_card(f"{OUT}/signpost.png")
    print("cards written to", OUT)
