from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def _draw_status_bar(draw: ImageDraw.ImageDraw, width: int) -> None:
    ink = (36, 28, 23, 255)
    battery_green = (52, 199, 89, 255)

    draw.text((48, 34), "9:41", fill=ink, font=_font(34))

    island_width = 228
    island_height = 38
    island_x = (width - island_width) // 2
    draw.rounded_rectangle(
        (island_x, 24, island_x + island_width, 24 + island_height),
        radius=19,
        fill=(0, 0, 0, 255),
    )

    signal_right = width - 164
    base_y = 55
    for index, height in enumerate((10, 14, 18, 22)):
        x = signal_right + index * 8
        draw.rounded_rectangle(
            (x, base_y - height, x + 5, base_y),
            radius=2,
            fill=ink,
        )

    wifi_left = width - 124
    center_x = wifi_left + 15
    center_y = 49
    for radius in (15, 11, 7):
        draw.arc(
            (center_x - radius, center_y - radius, center_x + radius, center_y + radius),
            start=205,
            end=335,
            fill=ink,
            width=2,
        )
    draw.ellipse((center_x - 2, center_y + 5, center_x + 2, center_y + 9), fill=ink)

    battery_left = width - 82
    battery_top = 35
    battery_width = 28
    battery_height = 16
    draw.rounded_rectangle(
        (battery_left, battery_top, battery_left + battery_width, battery_top + battery_height),
        radius=4,
        outline=ink,
        width=2,
    )
    draw.rounded_rectangle(
        (
            battery_left + battery_width + 2,
            battery_top + 5,
            battery_left + battery_width + 5,
            battery_top + 11,
        ),
        radius=2,
        fill=ink,
    )
    draw.rounded_rectangle(
        (battery_left + 3, battery_top + 3, battery_left + battery_width - 5, battery_top + battery_height - 3),
        radius=3,
        fill=battery_green,
    )


def _draw_home_indicator(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    indicator_width = 134
    indicator_height = 5
    x = (width - indicator_width) // 2
    y = height - 14
    draw.rounded_rectangle(
        (x, y, x + indicator_width, y + indicator_height),
        radius=indicator_height // 2,
        fill=(36, 28, 23, 120),
    )


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: ios_fullscreen_postprocess.py <image-path>", file=sys.stderr)
        return 1

    image_path = Path(sys.argv[1])
    image = Image.open(image_path).convert("RGBA")
    draw = ImageDraw.Draw(image)
    width, height = image.size

    _draw_status_bar(draw, width)
    _draw_home_indicator(draw, width, height)

    image.save(image_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
