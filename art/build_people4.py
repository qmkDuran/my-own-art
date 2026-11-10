"""4-direction standing people (Rev 7:9) from the PixelLab rotations, finished by hand:
game/art/people/pNN.png - 3 rows (down, up, left; right = mirrored) x 4 cols (idle, breathe, palm-left, palm-right),
and out/people4_sheet_3x.png."""
import os, sys
from PIL import Image
sys.path.insert(0, 'art')
from common import FRAME, C, OUT, quant, feet_to, breathe, sway

D = 'game/art/people/'
PEOPLE = [0, 1, 2, 5, 6, 7, 9, 10, 14, 15]   # 4 (the headscarf picture) removed at the user's request
SWAY_PX = 4


def person_sheet(idx):
    sh = Image.new('RGBA', (FRAME * 4, FRAME * 3))
    for r, d in enumerate(('south', 'north', 'west')):
        base = feet_to(quant(Image.open(f'art/raw/ch_p{idx:02d}_rot_{d}.png')))
        frames = [base, breathe(base), sway(base, -SWAY_PX) or base, sway(base, SWAY_PX) or base]
        for c, f in enumerate(frames): sh.alpha_composite(f, (c * FRAME, r * FRAME))
    sh.save(D + f'p{idx:02d}.png')
    return sh


BUBBLE = ["..XXXXXXXXX..", ".XWWWWWWWWWX.", "XWWWWWWWWWWWX", "XWWOWWOWWOWWX", "XWWWWWWWWWWWX",
          ".XWWWWWWWWWX.", "..XXXWXXXXX..", "....XWX......", ".....X......."]


def speech_bubble():
    """The small speech bubble shown over someone who is speaking a verse."""
    im = Image.new('RGBA', (13, 9)); p = im.load()
    cols = {'X': OUT, 'W': C('ffffff'), 'O': C('9babb2')}
    for y, row in enumerate(BUBBLE):
        for x, ch in enumerate(row):
            if ch != '.': p[x, y] = cols[ch]
    im.save(D + 'bubble.png')


def delivery_sheet(sheets):
    o = Image.new('RGBA', (FRAME * 4 * 4 + 24, ((len(sheets) + 3) // 4) * (FRAME * 3 + 8)), (234, 226, 196, 255))
    for k, s in enumerate(sheets): o.alpha_composite(s, ((k % 4) * (FRAME * 4 + 8), (k // 4) * (FRAME * 3 + 8)))
    o.resize((o.width * 3, o.height * 3), Image.NEAREST).save('out/people4_sheet_3x.png')


if __name__ == '__main__':
    speech_bubble()
    delivery_sheet([person_sheet(i) for i in PEOPLE if os.path.exists(f'art/raw/ch_p{i:02d}_rot_west.png')])
    print('people ok')
