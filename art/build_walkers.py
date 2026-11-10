"""The two walking people (Rev 7:9): game/art/people/walkerA.png, walkerB.png in the hero.png layout
(idle d/u/side x4, walk d/u/side x8, kneel d/u/side)."""
import glob, sys
from PIL import Image
sys.path.insert(0, 'art')
from common import FRAME, FEET_ROW, quant, breathe, kneel

OUTD = 'game/art/people/'
DIRS = (('south', 'down'), ('north', 'up'), ('west', 'left'))


def walk_frames(name, d):
    fs = [quant(Image.open(p)) for p in sorted(glob.glob(f'art/raw/anim/{name}/walking-8-frames/{d}_*.png'))]
    dy = FEET_ROW - fs[0].getbbox()[3] + 1
    out = []
    for f in fs:
        g = Image.new('RGBA', (FRAME, FRAME)); g.alpha_composite(f, (0, dy)); out.append(g)
    return out


def walker_sheet(name):
    sh = Image.new('RGBA', (FRAME * 8, FRAME * 7))
    for r, (d, facing) in enumerate(DIRS):
        w = walk_frames(name, d)
        for i, f in enumerate([w[0], w[0], breathe(w[0]), breathe(w[0])]): sh.alpha_composite(f, (i * FRAME, r * FRAME))
        for i, f in enumerate(w): sh.alpha_composite(f, (i * FRAME, (r + 3) * FRAME))
        sh.alpha_composite(kneel(w[0], facing), (r * FRAME, 6 * FRAME))
    sh.save(OUTD + f'{name}.png')


if __name__ == '__main__':
    for n in ('walkerA', 'walkerB'): walker_sheet(n)
    print('walkers ok')
