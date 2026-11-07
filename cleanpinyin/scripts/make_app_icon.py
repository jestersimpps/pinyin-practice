#!/usr/bin/env python3
"""Draw the EchoLingo app icon: a white speech bubble with the language's character and orange echo waves.

Every app in the series shares the bubble, blush and echo waves; only the background colour and character change.

Usage: make_app_icon.py <character> <hex colour> <output.png> [--font path] [--index n] [--variation name]

  make_app_icon.py 中 075056 AppIcon.png
  make_app_icon.py あ 283482 AppIcon.png
  make_app_icon.py 한 70286C AppIcon.png --font /System/Library/Fonts/AppleSDGothicNeo.ttc --index 6
  make_app_icon.py ñ B22438 AppIcon.png --font /System/Library/Fonts/SFNSRounded.ttf --index 0 --variation Bold
"""
import argparse
import math

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
SUPERSAMPLE = 4
ORANGE = (255, 91, 4)
BUBBLE = (250, 250, 246)
BLUSH = (255, 170, 150)
DEFAULT_FONT = "/System/Library/Fonts/Hiragino Sans GB.ttc"
DEFAULT_FONT_INDEX = 2  # Hiragino Sans GB W6


def scaled(value: float) -> float:
    return value * SUPERSAMPLE


def echo_arc(draw: ImageDraw.ImageDraw, cx: float, cy: float, radius: float, half_angle: float, width: float) -> None:
    draw.arc([cx - radius, cy - radius, cx + radius, cy + radius], start=-half_angle, end=half_angle, fill=ORANGE, width=int(width))
    for angle in (-half_angle, half_angle):
        middle = radius - width / 2
        x = cx + middle * math.cos(math.radians(angle))
        y = cy + middle * math.sin(math.radians(angle))
        draw.ellipse([x - width / 2, y - width / 2, x + width / 2, y + width / 2], fill=ORANGE)


def draw_icon(character: str, background: tuple[int, int, int], font: ImageFont.FreeTypeFont) -> Image.Image:
    canvas = scaled(SIZE)
    image = Image.new("RGB", (int(canvas), int(canvas)), background)
    draw = ImageDraw.Draw(image)

    left, top, right, bottom = scaled(150), scaled(250), scaled(660), scaled(690)
    cx, cy = (left + right) / 2, (top + bottom) / 2
    for radius, width in ((350, 40), (430, 34), (510, 28)):
        echo_arc(draw, cx, cy, scaled(radius), 30, scaled(width))

    draw.rounded_rectangle([left, top, right, bottom], radius=scaled(190), fill=BUBBLE)
    draw.polygon([(scaled(215), scaled(610)), (scaled(345), scaled(670)), (scaled(170), scaled(810))], fill=BUBBLE)

    box = draw.textbbox((0, 0), character, font=font)
    width, height = box[2] - box[0], box[3] - box[1]
    draw.text((cx - width / 2 - box[0], cy - height / 2 - box[1] - scaled(18)), character, font=font, fill=background)

    for x in (cx - scaled(178), cx + scaled(178)):
        draw.ellipse([x - scaled(36), cy + scaled(118), x + scaled(36), cy + scaled(150)], fill=BLUSH)

    return image.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    parser = argparse.ArgumentParser(description="Draw an EchoLingo app icon")
    parser.add_argument("character")
    parser.add_argument("colour", help="background colour as hex, e.g. 075056")
    parser.add_argument("output")
    parser.add_argument("--font", default=DEFAULT_FONT)
    parser.add_argument("--index", type=int, default=DEFAULT_FONT_INDEX)
    parser.add_argument("--variation", help="named variation for variable fonts, e.g. Bold")
    args = parser.parse_args()

    background = tuple(int(args.colour.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
    font = ImageFont.truetype(args.font, int(scaled(320)), index=args.index)
    if args.variation:
        font.set_variation_by_name(args.variation)
    draw_icon(args.character, background, font).save(args.output)


if __name__ == "__main__":
    main()
