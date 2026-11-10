#!/usr/bin/env python3
"""Placeryのカラーアセット(ライト/ダーク)を Assets.xcassets に生成する。"""

import json
import pathlib

ASSETS = pathlib.Path(__file__).resolve().parent.parent / "Placery" / "Assets.xcassets"

COLORS = {
    "Background": ("F1EEE7", "131412"),
    "Surface": ("FFFFFF", "1F2123"),
    "Field": ("F7F5F0", "252726"),
    "Ink": ("26241F", "EDEBE4"),
    "InkSoft": ("6E6A5F", "9B968A"),
    "Line": ("E7E3D8", "32332F"),
    "Moss": ("435C46", "7FA084"),
    "MossDeep": ("2F4331", "9DBB9E"),
    "MossTint": ("E4EBE1", "26302A"),
    "Lock": ("A8A296", "6C6A63"),
    "LockTint": ("EFEDE6", "24251F"),
    "WarnInk": ("7E5518", "E3BC7C"),
    "WarnBackground": ("F7EBD6", "2E2619"),
    "WarnLine": ("E6D2AC", "4A3D25"),
    "AccentColor": ("435C46", "7FA084"),
}


def components(hex_value):
    return {
        "alpha": "1.000",
        "red": f"0x{hex_value[0:2]}",
        "green": f"0x{hex_value[2:4]}",
        "blue": f"0x{hex_value[4:6]}",
    }


def color_entry(hex_value, dark=False):
    entry = {
        "color": {"color-space": "srgb", "components": components(hex_value)},
        "idiom": "universal",
    }
    if dark:
        entry["appearances"] = [{"appearance": "luminosity", "value": "dark"}]
    return entry


def write(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


info = {"author": "xcode", "version": 1}

write(ASSETS / "Contents.json", {"info": info})
write(ASSETS / "AppIcon.appiconset" / "Contents.json",
      {"images": [{"idiom": "universal", "platform": "ios", "size": "1024x1024"}], "info": info})

for name, (light, dark) in COLORS.items():
    write(
        ASSETS / f"{name}.colorset" / "Contents.json",
        {"colors": [color_entry(light), color_entry(dark, dark=True)], "info": info},
    )

print(f"generated {len(COLORS)} colorsets in {ASSETS}")
