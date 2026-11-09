#!/usr/bin/env python3
"""Draws the app icon (a sage axolotl companion) and writes
the Windows .ico, the macOS app icons, the Linux icon and the web icons. Run from the app folder:
    python3 tool/make_icons.py
Needs Pillow. The output files are committed; this script is how they were made."""
from pathlib import Path

from PIL import Image, ImageDraw

GREEN = (82, 123, 98, 255)
LIGHT = (164, 242, 224, 255)
WHITE = (255, 255, 255, 255)


def icon(size: int, maskable: bool = False, margin: float = 0.0) -> Image.Image:
    scale = 4  # draw large, then shrink for smooth edges
    s = size * scale
    if margin:
        inner = icon(round(size * (1 - 2 * margin)))
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        off = (size - inner.width) // 2
        canvas.paste(inner, (off, off), inner)
        return canvas
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if maskable:
        d.rectangle([0, 0, s, s], fill=GREEN)
        inset = s * 0.18
    else:
        r = s * 0.22
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=r, fill=GREEN)
        inset = s * 0.0
    # A friendly axolotl face with a sprout: the app's original companion.
    def box(x0,y0,x1,y1): return (int(x0*s),int(y0*s),int(x1*s),int(y1*s))
    mint=(175,216,188,255); gill=(121,175,145,255); dark=(40,61,51,255)
    for side in (-1,1):
        for y in (.36,.47,.58):
            x=.5+side*.28
            d.line([(int((.5+side*.22)*s),int(.47*s)),(int(x*s),int(y*s))],fill=gill,width=int(.065*s))
            d.ellipse(box(x-.035,y-.035,x+.035,y+.035),fill=gill)
    d.rounded_rectangle(box(.25,.28,.75,.75),radius=int(.19*s),fill=mint)
    for x in (.37,.63):
        d.ellipse(box(x-.023,.46,x+.023,.52),fill=dark)
        d.ellipse(box(x-.012,.465,x+.002,.479),fill=WHITE)
    d.arc(box(.45,.51,.55,.60),0,180,fill=dark,width=int(.014*s))
    for x in (.33,.67): d.ellipse(box(x-.04,.56,x+.04,.60),fill=(232,164,160,255))
    d.ellipse(box(.37,.13,.52,.29),fill=(218,230,195,255))
    d.ellipse(box(.49,.12,.64,.25),fill=(218,230,195,255))
    d.line([(int(.5*s),int(.22*s)),(int(.5*s),int(.33*s))],fill=(218,230,195,255),width=int(.026*s))
    return img.resize((size, size), Image.LANCZOS)


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
