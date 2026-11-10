"""Hero sheet game/art/hero.png (64x64 frames, 8 cols x 7 rows):
idle down/up/side (4), walk down/up/side (8), kneel down/up/side (1 each). Right = mirrored side.
Also writes out/character_sheet_3x.png."""
import glob, sys
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
from common import FRAME, FEET_ROW, H, quant, breathe, kneel

WEST_CROP = (14, 16, 78, 80)          # the skeleton-v3 west walk is a 96 px canvas
DIRS = (('south', 'down'), ('north', 'up'), ('west', 'left'))


def walk_frames(d):
    if d == 'west':
        fs = [Image.open(p).crop(WEST_CROP) for p in sorted(glob.glob('art/raw/anim/hero/walking-8-frames_1/west_*.png'))]
    else:
        fs = [Image.open(p) for p in sorted(glob.glob(f'art/raw/anim/hero/walking-8-frames/{d}_*.png'))]
    fs = [quant(f) for f in fs]
    dy = FEET_ROW - fs[0].getbbox()[3] + 1
    out = []
    for f in fs:
        g = Image.new('RGBA', (FRAME, FRAME)); g.alpha_composite(f, (0, dy)); out.append(g)
    return out


def fix_south(im):
    """The template walk shaded the robe olive and the palm teal: back to robe white and palm green."""
    a = np.array(im).copy(); h, w = a.shape[:2]
    robe = {H('ffffff'), H('c7dcd0')}
    for _ in range(3):
        b = a.copy()
        for y in range(h):
            for x in range(w):
                if a[y, x, 3] and tuple(a[y, x, :3]) == H('92a984'):
                    nb = [tuple(a[yy, xx, :3]) for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)) if 0 <= yy < h and 0 <= xx < w and a[yy, xx, 3]]
                    if any(n in robe for n in nb): b[y, x, :3] = H('c7dcd0')
        a = b
    for src, dst in (('0b5e65', '239063'), ('92a984', '1ebc73')):
        m = (a[..., 0] == H(src)[0]) & (a[..., 1] == H(src)[1]) & (a[..., 2] == H(src)[2]); a[m, :3] = H(dst)
    return Image.fromarray(a, 'RGBA')


def build_sheet():
    sheet = Image.new('RGBA', (FRAME * 8, FRAME * 7))
    for r, (d, _) in enumerate(DIRS):
        w = walk_frames(d)
        for i, f in enumerate([w[0], w[0], breathe(w[0]), breathe(w[0])]): sheet.alpha_composite(f, (i * FRAME, r * FRAME))
        for i, f in enumerate(w): sheet.alpha_composite(f, (i * FRAME, (r + 3) * FRAME))
    for r in (0, 3):
        sheet.paste(fix_south(sheet.crop((0, r * FRAME, FRAME * 8, r * FRAME + FRAME))), (0, r * FRAME))
    for i, (_, facing) in enumerate(DIRS):
        sheet.alpha_composite(kneel(sheet.crop((0, i * FRAME, FRAME, i * FRAME + FRAME)), facing), (i * FRAME, 6 * FRAME))
    return sheet


def delivery_sheet(sheet):
    order = [(0, 4, False), (1, 4, False), (2, 4, False), (2, 4, True), (3, 8, False), (4, 8, False), (5, 8, False), (5, 8, True)]
    lab = Image.new('RGBA', (FRAME * 8, FRAME * 8), (234, 226, 196, 255))
    for k, (r, c, flip) in enumerate(order):
        for i in range(c):
            f = sheet.crop((i * FRAME, r * FRAME, i * FRAME + FRAME, r * FRAME + FRAME))
            if flip: f = f.transpose(Image.FLIP_LEFT_RIGHT)
            lab.alpha_composite(f, (i * FRAME, k * FRAME))
    lab.resize((lab.width * 3, lab.height * 3), Image.NEAREST).save('out/character_sheet_3x.png')


if __name__ == '__main__':
    s = build_sheet()
    s.save('game/art/hero.png')
    delivery_sheet(s)
    print('hero ok')
