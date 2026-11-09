#!/usr/bin/env python3
"""Packages the generated pink Aion axolotl master artwork into
the Windows .ico, the macOS app icons, the Linux icon and the web icons. Run from the app folder:
    python3 tool/make_icons.py
Needs Pillow. The output files are committed; this script is how they were made."""
from pathlib import Path

from PIL import Image

SOURCE = Path(__file__).resolve().parent.parent / 'assets/branding/aion-icon.png'


def icon(size: int, maskable: bool = False, margin: float = 0.0) -> Image.Image:
    """Package the generated Aion master artwork without redrawing it.

    Only platform size, safe-area padding and file format are changed here.
    """
    source = Image.open(SOURCE).convert('RGBA')
    inset = max(margin, 0.16 if maskable else 0.0)
    if inset:
        edge = round(size * (1 - 2 * inset))
        inner = source.resize((edge, edge), Image.Resampling.LANCZOS)
        background = (255, 240, 246, 255) if maskable else (0, 0, 0, 0)
        canvas = Image.new('RGBA', (size, size), background)
        offset = (size - edge) // 2
        canvas.alpha_composite(inner, (offset, offset))
        return canvas
    return source.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    sizes = [16, 24, 32, 48, 64, 128, 256]
    big = icon(256)
    big.save(root / "windows/runner/resources/app_icon.ico", sizes=[(n, n) for n in sizes])
    for density,n in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
        icon(n).save(root / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png")
    icon(16).save(root / "web/favicon.png")
    icon(192).save(root / "web/icons/Icon-192.png")
    icon(512).save(root / "web/icons/Icon-512.png")
    icon(192, maskable=True).save(root / "web/icons/Icon-maskable-192.png")
    # macOS icons leave a transparent margin like other Mac apps.
    mac = root / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for n in (16, 32, 64, 128, 256, 512, 1024):
        icon(n, margin=0.09).save(mac / f"app_icon_{n}.png")
    icon(256).save(root / "packaging/linux/reallife-rpg.png")
    icon(512, maskable=True).save(root / "web/icons/Icon-maskable-512.png")


if __name__ == "__main__":
    main()
