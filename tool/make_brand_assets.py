"""Generates placeholder brand artwork (app icon + splash mark) in assets/branding/.
A white cross on the LOGOS violet gradient, matching the in-app logo.
Replace these PNGs with designer artwork and re-run the icon/splash generators.

Usage: python3 tool/make_brand_assets.py
"""
import os
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'branding')
TOP, BOTTOM = (0x8B, 0x5C, 0xF6), (0x5B, 0x21, 0xB6)  # LogosColors purple gradient

def gradient(size):
    img = Image.new('RGB', (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM))
    return img

def cross(size, color=(255, 255, 255, 255), scale=0.46):
    """Latin cross with rounded ends, centred, `scale` = height / canvas."""
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    h = size * scale
    w = h * 0.62
    t = h * 0.15  # bar thickness
    cx, cy = size / 2, size / 2
    top, bottom = cy - h / 2, cy + h / 2
    bar_y = top + h * 0.30
    r = t / 2
    d.rounded_rectangle([cx - t / 2, top, cx + t / 2, bottom], radius=r, fill=color)
    d.rounded_rectangle([cx - w / 2, bar_y - t / 2, cx + w / 2, bar_y + t / 2], radius=r, fill=color)
    return layer

os.makedirs(OUT, exist_ok=True)
S = 1024

# Full-bleed icon (iOS / legacy Android): gradient + soft-shadowed cross
icon = gradient(S).convert('RGBA')
shadow = cross(S, (40, 10, 90, 110)).filter(ImageFilter.GaussianBlur(18))
icon.alpha_composite(shadow, (0, 14))
icon.alpha_composite(cross(S))
icon.convert('RGB').save(os.path.join(OUT, 'app_icon.png'))

# Android adaptive icon foreground (cross only, inside the 66% safe zone)
cross(S, scale=0.40).save(os.path.join(OUT, 'app_icon_foreground.png'))

# Splash mark: rounded gradient tile with cross, transparent surroundings
tile = Image.new('RGBA', (S, S), (0, 0, 0, 0))
mask = Image.new('L', (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([112, 112, S - 112, S - 112], radius=200, fill=255)
tile.paste(gradient(S).convert('RGBA'), (0, 0), mask)
tile.alpha_composite(cross(S, scale=0.36))
tile.save(os.path.join(OUT, 'splash_mark.png'))
print('wrote', sorted(os.listdir(OUT)))
