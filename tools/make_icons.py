#!/usr/bin/env python3
"""Regenerates the icons (png/ico/icns):  python3 tools/make_icons.py   (requires Pillow)"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = 1024
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle((64, 64, S - 64, S - 64), radius=210, fill=(30, 33, 48, 255))
d.rounded_rectangle((64, 64, S - 64, S - 64), radius=210, outline=(94, 124, 255, 255), width=18)
font = None
for f in ("DejaVuSans-Bold.ttf", "Arial Bold.ttf", "arialbd.ttf", "Helvetica.ttc"):
    try:
        font = ImageFont.truetype(f, 520)
        break
    except OSError:
        pass
font = font or ImageFont.load_default()
d.text((S // 2, S // 2 - 40), "Mx", font=font, fill=(236, 238, 250, 255), anchor="mm")
d.rounded_rectangle((250, 760, S - 250, 800), radius=20, fill=(94, 124, 255, 255))

os.makedirs(os.path.join(ROOT, "resources", "icons"), exist_ok=True)
img.resize((512, 512), Image.LANCZOS).save(os.path.join(ROOT, "resources", "icons", "mixdown.png"))
img.save(os.path.join(ROOT, "packaging", "windows", "mixdown.ico"),
         sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
img.save(os.path.join(ROOT, "packaging", "macos", "mixdown.icns"))
print("icons ok")
