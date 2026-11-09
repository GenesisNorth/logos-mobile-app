"""App Store / Play screenshots in the "Organic" design (design 3a–3f).

Inputs: real captures in store/screenshots/raw/ (status bar in demo mode, 9:41).
Output: store/screenshots/6.7in/*.png at 1290×2796.
Usage: python3 tool/make_store_screenshots.py
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), '..')
RAW = os.path.join(ROOT, 'store', 'screenshots', 'raw')
OUT = os.path.join(ROOT, 'store', 'screenshots', '6.7in')
FONTS = os.path.join(ROOT, 'assets', 'google_fonts')
W, H = 1290, 2796

def hexc(h):
    h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

SHOTS = [
    ('01-today', 'today', '8C491A', 'F9F4ED', 'One verse.\nFour days.', 'A slow weekly rhythm for dwelling in Scripture.', 'B2622D'),
    ('02-encounter', 'encounter_result', '2E2B25', 'F9F4ED', 'Meet the Word\nat dusk.', 'Then speak it aloud — it listens as you recite.', None),
    ('03-roots', 'roots', 'E1EECC', '272E1B', 'Dwell in the\noriginal\nwords.', 'Greek and Hebrew roots, one at a time.', None),
    ('04-stillness', 'stillness', '3D472B', 'F0FAE1', 'Sixty seconds\nof stillness.', 'Paced breath beneath a quiet soundscape.', None),
    ('05-exchange', 'exchange', 'EBDDC5', '201E1D', 'Lay your\nburden down.', 'Write it, hold, and receive the Word instead.', None),
    ('06-community', 'community', 'FFE1D0', '402310', 'Never pray\nalone.', 'Circles, pastors, and quiet rooms for lament.', None),
]

def rounded(img, r):
    m = Image.new('L', img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] + r], radius=r, fill=255)
    out = Image.new('RGBA', img.size); out.paste(img, (0, 0), m); return out

os.makedirs(OUT, exist_ok=True)
head = ImageFont.truetype(os.path.join(FONTS, 'Caprasimo-Regular.ttf'), 132)
sub = ImageFont.truetype(os.path.join(FONTS, 'Figtree-Regular.ttf'), 50)
for name, raw, bg, ink, title, line, decor in SHOTS:
    canvas = Image.new('RGBA', (W, H), hexc(bg) + (255,))
    d = ImageDraw.Draw(canvas)
    if decor:
        d.ellipse([W - 640, -380, W + 280, 540], fill=hexc(decor) + (255,))
    x, y = 110, 170
    d.multiline_text((x, y), title, font=head, fill=hexc(ink), spacing=4)
    tb = d.multiline_textbbox((x, y), title, font=head, spacing=4)
    # wrap subline to ~ 920px
    words, lines, cur = line.split(), [], ''
    for w_ in words:
        t = (cur + ' ' + w_).strip()
        if d.textlength(t, font=sub) > 960 and cur:
            lines.append(cur); cur = w_
        else:
            cur = t
    lines.append(cur)
    sy = tb[3] + 44
    for l in lines:
        d.text((x, sy), l, font=sub, fill=hexc(ink) + (230,)); sy += 70

    shot = Image.open(os.path.join(RAW, raw + '.png')).convert('RGBA')
    sw = 1000
    shot = shot.resize((sw, int(shot.height * sw / shot.width)), Image.LANCZOS)
    top = max(sy + 90, 900)
    shot = rounded(shot, 64)
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([(W - sw) // 2, top + 24, (W + sw) // 2, H + 200], radius=64, fill=(30, 20, 10, 90))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(36)))
    canvas.alpha_composite(shot, ((W - sw) // 2, top))
    edge = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(edge).rounded_rectangle([(W - sw) // 2 - 1, top - 1, (W + sw) // 2, H + 200], radius=65,
                                           outline=hexc(ink) + (46,), width=3)
    canvas.alpha_composite(edge)
    canvas.convert('RGB').save(os.path.join(OUT, name + '.png'), optimize=True)
    print('wrote', name)
