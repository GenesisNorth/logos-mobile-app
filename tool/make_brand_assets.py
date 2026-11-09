"""Brand artwork for the "Organic" design system → assets/branding/.

Terracotta ground with the design's signature soft circles, and a cream
Caprasimo "L" with a sage seed. Run, then regenerate icons & splash:
  python3 tool/make_brand_assets.py
  dart run flutter_launcher_icons && dart run flutter_native_splash:create
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'assets', 'branding')
FONT = os.path.join(ROOT, 'assets', 'google_fonts', 'Caprasimo-Regular.ttf')
A700, A600, A500 = (0x8C, 0x49, 0x1A), (0xB2, 0x62, 0x2D), (0xD6, 0x7F, 0x48)
CREAM, SAGE = (0xF9, 0xF4, 0xED), (0x8F, 0xA0, 0x73)
S = 1024

def mark(size, scale=1.0, color=CREAM):
    """Cream "L" with a sage seed, centred, on transparency."""
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    font = ImageFont.truetype(FONT, int(size * 0.62 * scale))
    box = d.textbbox((0, 0), 'L', font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    x, y = (size - w) / 2 - box[0] - size * 0.04 * scale, (size - h) / 2 - box[1]
    d.text((x, y), 'L', font=font, fill=color + (255,))
    r = size * 0.075 * scale
    cx, cy = x + box[0] + w + r * 1.35, y + box[1] + h - r
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=SAGE + (255,))
    return layer

def ground(size):
    img = Image.new('RGBA', (size, size), A700 + (255,))
    d = ImageDraw.Draw(img)
    big = size * 0.78
    d.ellipse([size - big * 0.62, -big * 0.38, size + big * 0.38, big * 0.62], fill=A600 + (255,))
    s = size * 0.11
    d.ellipse([size * 0.66, size * 0.24, size * 0.66 + s, size * 0.24 + s], fill=A500 + (255,))
    return img

os.makedirs(OUT, exist_ok=True)
icon = ground(S)
shadow = mark(S, color=(40, 15, 0)).filter(ImageFilter.GaussianBlur(14))
icon.alpha_composite(Image.eval(shadow, lambda v: v) , (0, 10))
icon.alpha_composite(mark(S))
icon.convert('RGB').save(os.path.join(OUT, 'app_icon.png'))

mark(S, scale=0.72).save(os.path.join(OUT, 'app_icon_foreground.png'))

tile = Image.new('RGBA', (S, S), (0, 0, 0, 0))
m = Image.new('L', (S, S), 0)
ImageDraw.Draw(m).rounded_rectangle([140, 140, S - 140, S - 140], radius=190, fill=255)
g = ground(S - 280).resize((S - 280, S - 280))
inner = Image.new('RGBA', (S, S), (0, 0, 0, 0)); inner.paste(g, (140, 140))
tile.paste(inner, (0, 0), m)
tile.alpha_composite(mark(S, scale=0.7))
tile.save(os.path.join(OUT, 'splash_mark.png'))
print('ok')
