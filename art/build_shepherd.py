"""The Shepherd by the river (Rev 7:17), after Rev 1:13-16 (NIV): robe reaching down to his feet, golden sash around his
chest, hair white like wool, feet "like bronze glowing in a furnace", face "like the sun shining in all its brilliance".
The face is painted as light by hand: no facial features are drawn. Writes game/art/people/shepherd.png in the people
layout (rows down/up/left, cols idle, breathe, idle, breathe) and out/shepherd_sheet_3x.png."""
import sys
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
from common import FRAME, H, quant, feet_to, breathe

SKIN = {H(c) for c in ('fdcbb0', 'fca790', 'f68181', 'e6904e')}
FACE_INNER = {H(c) for c in ('2e222f', '966c6c', 'ab947a', '6e2727', '9e4539', 'cd683d', '313638')}   # eyes, mouth, shading
LIGHT_RAMP = [H('ffffff'), H('ffffff'), H('fbff86'), H('fbff86'), H('f9c22b')]
BRONZE = {H('fdcbb0'): H('fbb954'), H('fca790'): H('f9c22b'), H('e6904e'): H('f79617'), H('ab947a'): H('e6904e'),
          H('966c6c'): H('cd683d'), H('9e4539'): H('cd683d')}
HEAD_ROWS = 22
FEET_ROWS = 5


def face_light(a):
    """Every skin pixel of the head, and the features between them, becomes light radiating from the face's centre."""
    ys = np.nonzero(a[..., 3])[0]; top = ys.min()
    head = np.zeros(a.shape[:2], bool)
    for y in range(top, top + HEAD_ROWS):
        xs = [x for x in range(FRAME) if a[y, x, 3] and tuple(a[y, x, :3]) in SKIN]
        if len(xs) < 2: continue
        for x in range(min(xs), max(xs) + 1):
            c = tuple(a[y, x, :3])
            if c in SKIN or c in FACE_INNER: head[y, x] = True
    if not head.any(): return a                                   # seen from behind: white hair only
    fy, fx = np.nonzero(head); cy, cx = fy.mean(), fx.mean()
    r = max(1.0, np.hypot(fy - cy, fx - cx).max())
    out = a.copy()
    for y, x in zip(fy, fx):
        k = min(len(LIGHT_RAMP) - 1, int(np.hypot(y - cy, x - cx) / r * len(LIGHT_RAMP)))
        out[y, x, :3] = LIGHT_RAMP[k]
    return out


def bronze_feet(a):
    ys = np.nonzero(a[..., 3])[0]; bot = ys.max()
    out = a.copy()
    for y in range(bot - FEET_ROWS + 1, bot + 1):
        for x in range(FRAME):
            c = tuple(a[y, x, :3])
            if a[y, x, 3] and c in BRONZE: out[y, x, :3] = BRONZE[c]
    return out


def frame(direction):
    """The left-facing row uses the east rotation mirrored: in the west rotation the staff crosses the face."""
    src = Image.open(f'art/raw/ch_shepherd_rot_{"east" if direction == "west" else direction}.png')
    if direction == 'west': src = src.transpose(Image.FLIP_LEFT_RIGHT)
    base = feet_to(quant(src))
    return Image.fromarray(bronze_feet(face_light(np.array(base))))


if __name__ == '__main__':
    sheet = Image.new('RGBA', (FRAME * 4, FRAME * 3))
    for r, d in enumerate(('south', 'north', 'west')):
        f = frame(d)
        for c, g in enumerate((f, breathe(f), f, breathe(f))):
            sheet.alpha_composite(g, (c * FRAME, r * FRAME))
    sheet.save('game/art/people/shepherd.png')
    bg = Image.new('RGBA', (FRAME * 4, FRAME), (160, 200, 140, 255))
    for c in range(3): bg.alpha_composite(sheet.crop((0, c * FRAME, FRAME, (c + 1) * FRAME)), (c * FRAME, 0))
    bg.alpha_composite(sheet.crop((0, 2 * FRAME, FRAME, 3 * FRAME)).transpose(Image.FLIP_LEFT_RIGHT), (3 * FRAME, 0))
    bg.resize((bg.width * 3, bg.height * 3), Image.NEAREST).save('out/shepherd_sheet_3x.png')
    print('shepherd ok')
