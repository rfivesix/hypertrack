#!/usr/bin/env python3
"""
Generate polished store screenshot images from raw Android/iOS screenshots.

Expected folder structure next to this script (or under --root):
  android/
    *.png
  ios/
    *.png

Optional config file:
  screenshot_titles.json

If no config exists, built-in title defaults are used for known Train Libre
screenshots.

Usage:
  python generate_store_screenshots.py
  python generate_store_screenshots.py --root .
  python generate_store_screenshots.py --size 1242x2208
  python generate_store_screenshots.py --background '#C6D38B'
  python generate_store_screenshots.py --scale 0.84

Outputs:
  store_output/android/*.png
  store_output/ios/*.png
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, Iterable, Tuple

from PIL import Image, ImageColor, ImageDraw, ImageFilter, ImageFont

DEFAULT_SIZE = (1242, 2208)
DEFAULT_BG = "#C6D38B"
DEFAULT_TEXT = "#FFFFFF"
DEFAULT_SCREENSHOT_SCALE = 0.84
SUPPORTED_EXTS = {".png", ".jpg", ".jpeg", ".webp"}

DEFAULT_TITLES: Dict[str, str] = {
    # iOS screenshots
    "ios_diary": "Track workouts, nutrition, weight and more",
    "ios_recovery_tracker": "Use recovery, pulse, and sleep insights",
    "ios_measurements": "Track body metrics over time",
    "ios_data": "Your data stays under your control",
    "ios_ai": "Log meals with photo and text",
    "ios_nutrition": "Get adaptive nutrition guidance",
    "ios_running_workout": "Run workouts exercise by exercise",
    # common Android names if later added
    "android_diary": "Track workouts, nutrition, weight and more",
    "android_recovery_tracker": "Use recovery, pulse, and sleep insights",
    "android_measurements": "Track body metrics over time",
    "android_data": "Your data stays under your control",
    "android_ai": "Log meals with photo and text",
    "android_nutrition": "Get adaptive nutrition guidance",
    "android_running_workout": "Run workouts exercise by exercise",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="Project root containing android/ and ios/")
    parser.add_argument("--config", type=Path, default=None, help="Optional screenshot_titles.json path")
    parser.add_argument("--size", default=f"{DEFAULT_SIZE[0]}x{DEFAULT_SIZE[1]}", help="Output size, e.g. 1242x2208")
    parser.add_argument("--background", default=DEFAULT_BG, help="Canvas background color")
    parser.add_argument("--text-color", default=DEFAULT_TEXT, help="Headline color")
    parser.add_argument("--scale", type=float, default=DEFAULT_SCREENSHOT_SCALE, help="Max screenshot height ratio, e.g. 0.84")
    parser.add_argument("--output", type=Path, default=None, help="Output directory (default: <root>/store_output)")
    return parser.parse_args()


def parse_size(spec: str) -> Tuple[int, int]:
    try:
        w, h = spec.lower().split("x", 1)
        return int(w), int(h)
    except Exception as exc:
        raise SystemExit(f"Invalid --size '{spec}', expected WIDTHxHEIGHT") from exc


def load_config(path: Path | None) -> dict:
    if path is None:
        return {}
    if not path.exists():
        raise SystemExit(f"Config not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def find_font(preferred: Iterable[str], size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for name in preferred:
        try:
            return ImageFont.truetype(name, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def fit_text(draw: ImageDraw.ImageDraw, text: str, max_width: int, font_names: Iterable[str], max_size: int, min_size: int = 36) -> Tuple[ImageFont.ImageFont, list[str]]:
    for size in range(max_size, min_size - 1, -2):
        font = find_font(font_names, size)
        wrapped = wrap_text(draw, text, font, max_width)
        widths = [draw.textbbox((0, 0), line, font=font)[2] for line in wrapped]
        if widths and max(widths) <= max_width and len(wrapped) <= 3:
            return font, wrapped
    font = find_font(font_names, min_size)
    return font, wrap_text(draw, text, font, max_width)


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, max_width: int) -> list[str]:
    words = text.split()
    if not words:
        return [""]
    lines: list[str] = []
    current = words[0]
    for word in words[1:]:
        candidate = f"{current} {word}"
        bbox = draw.textbbox((0, 0), candidate, font=font)
        if bbox[2] <= max_width:
            current = candidate
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def rounded_mask(size: Tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def add_shadow(base: Image.Image, box: Tuple[int, int, int, int], radius: int = 28, offset: Tuple[int, int] = (0, 22), opacity: int = 105) -> None:
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    x0, y0, x1, y1 = box
    ox, oy = offset
    draw.rounded_rectangle((x0 + ox, y0 + oy, x1 + ox, y1 + oy), radius=radius, fill=(0, 0, 0, opacity))
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    base.alpha_composite(shadow)


def compose_image(screenshot_path: Path, out_path: Path, title: str, size: Tuple[int, int], bg: str, text_color: str, screenshot_scale: float) -> None:
    canvas = Image.new("RGBA", size, ImageColor.getrgb(bg) + (255,))
    draw = ImageDraw.Draw(canvas)
    width, height = size

    title_max_width = int(width * 0.82)
    title_font, title_lines = fit_text(
        draw,
        title,
        title_max_width,
        font_names=["Georgia Bold", "Georgia", "DejaVuSerif-Bold.ttf", "DejaVuSerif.ttf"],
        max_size=int(width * 0.055),
        min_size=36,
    )

    top_margin = int(height * 0.05)
    line_gap = int(title_font.size * 0.18) if hasattr(title_font, "size") else 10
    title_height = 0
    for line in title_lines:
        bbox = draw.textbbox((0, 0), line, font=title_font)
        title_height += (bbox[3] - bbox[1])
    title_height += line_gap * (len(title_lines) - 1)

    y = top_margin
    for line in title_lines:
        bbox = draw.textbbox((0, 0), line, font=title_font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
        draw.text(((width - text_w) / 2, y), line, font=title_font, fill=text_color)
        y += text_h + line_gap

    screenshot = Image.open(screenshot_path).convert("RGBA")
    max_h = int(height * screenshot_scale)
    max_w = int(width * 0.80)
    scale = min(max_w / screenshot.width, max_h / screenshot.height)
    new_size = (max(1, int(screenshot.width * scale)), max(1, int(screenshot.height * scale)))
    screenshot = screenshot.resize(new_size, Image.Resampling.LANCZOS)

    radius = max(24, int(min(new_size) * 0.06))
    mask = rounded_mask(new_size, radius)
    rounded = Image.new("RGBA", new_size, (0, 0, 0, 0))
    rounded.paste(screenshot, (0, 0), mask)

    shot_x = (width - new_size[0]) // 2
    available_top = top_margin + title_height + int(height * 0.03)
    shot_y = max(available_top, (height - new_size[1]) // 2 + int(height * 0.035))
    box = (shot_x, shot_y, shot_x + new_size[0], shot_y + new_size[1])
    add_shadow(canvas, box, radius=radius)
    canvas.alpha_composite(rounded, (shot_x, shot_y))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out_path, quality=95)


def infer_title(stem: str) -> str:
    if stem in DEFAULT_TITLES:
        return DEFAULT_TITLES[stem]
    stem = stem.replace("_", " ").replace("-", " ")
    return stem.title()


def main() -> None:
    args = parse_args()
    size = parse_size(args.size)
    config_path = args.config or (args.root / "screenshot_titles.json")
    config = load_config(config_path) if config_path.exists() else {}
    titles: Dict[str, str] = {**DEFAULT_TITLES, **config.get("titles", {})}
    defaults = config.get("defaults", {})
    bg = defaults.get("background", args.background)
    text_color = defaults.get("text_color", args.text_color)
    screenshot_scale = float(defaults.get("screenshot_scale", args.scale))
    output_root = args.output or (args.root / "store_output")

    found_any = False
    for platform in ("android", "ios"):
        src_dir = args.root / platform
        if not src_dir.exists():
            continue
        for path in sorted(src_dir.iterdir()):
            if path.is_file() and path.suffix.lower() in SUPPORTED_EXTS:
                found_any = True
                title = titles.get(path.stem, infer_title(path.stem))
                out_path = output_root / platform / path.name
                compose_image(path, out_path, title, size, bg, text_color, screenshot_scale)
                print(f"Generated: {out_path.relative_to(output_root.parent)}")

    if not found_any:
        raise SystemExit("No screenshots found in ./android or ./ios")


if __name__ == "__main__":
    main()
