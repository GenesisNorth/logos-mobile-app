"""Bundles the Google Fonts the app uses into assets/google_fonts/ so text renders
in the right typeface offline and on first launch (no runtime download).

Usage: python3 tool/fetch_fonts.py
Reads the font file hashes from the google_fonts package in ~/.pub-cache.
"""
import glob, os, re, urllib.request

PKG = sorted(glob.glob(os.path.expanduser('~/.pub-cache/hosted/pub.dev/google_fonts-6*')))[-1]
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'google_fonts')
WANT = {  # dart method -> (asset family prefix, [(weight, italic)])
    'inter': ('Inter', [(400, False), (500, False), (600, False), (700, False), (800, False)]),
    'sourceSerif4': ('SourceSerif4', [(400, False), (500, False), (600, False), (700, False), (400, True)]),
    'newsreader': ('Newsreader', [(400, True)]),
    'caveat': ('Caveat', [(400, False), (700, False)]),
}
NAMES = {400: 'Regular', 500: 'Medium', 600: 'SemiBold', 700: 'Bold', 800: 'ExtraBold'}

src = ''.join(open(f).read() for f in glob.glob(f'{PKG}/lib/src/google_fonts_parts/*.g.dart'))
os.makedirs(OUT, exist_ok=True)
for method, (family, variants) in WANT.items():
    start = src.index('static TextStyle ' + method + '({')
    end = src.find('static TextStyle ', start + 10)
    body = src[start:end if end != -1 else len(src)]
    pairs = re.findall(r'fontWeight: FontWeight\.w(\d+),\s*fontStyle: FontStyle\.(\w+),\s*\): GoogleFontsFile\(\s*\'([0-9a-f]{64})\'', body)
    table = {(int(w), s == 'italic'): h for w, s, h in pairs}
    for weight, italic in variants:
        h = table[(weight, italic)]
        name = NAMES[weight] if not italic else ('Italic' if weight == 400 else NAMES[weight] + 'Italic')
        path = os.path.join(OUT, f'{family}-{name}.ttf')
        if not os.path.exists(path):
            urllib.request.urlretrieve(f'https://fonts.gstatic.com/s/a/{h}.ttf', path)
        print('ok', os.path.basename(path))
