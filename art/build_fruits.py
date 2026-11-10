"""Twelve crops of the tree of life (Rev 22:2: "bearing twelve crops of fruit, yielding its fruit every month").
Scripture does not name the twelve fruits, so they are drawn as twelve different fruits and never named in the game.
Hand-drawn by code, 16x16 each, Resurrect 64 colours: game/art/fruits.png (12 frames, January..December) and
out/fruits_3x.png."""
import sys
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
from common import C, OUT

S = 16
LEAF = ('165a4c', '239063', '91db69')
STEM = '6e2727'
# shape, (dark, mid, light), leaf?
CROPS = [('round', ('b33831', 'e83b3b', 'f68181'), True),        # 1  red round fruit
         ('cluster', ('6b3e75', '905ea9', 'a884f3'), True),      # 2  purple cluster
         ('tear', ('6b3e75', '905ea9', 'eaaded'), False),        # 3  violet teardrop
         ('crown', ('9e4539', 'b33831', 'ea4f36'), False),       # 4  crowned red fruit
         ('round', ('f79617', 'f9c22b', 'fbff86'), True),        # 5  golden round fruit
         ('cluster_small', ('6e2727', '9e4539', 'cd683d'), False),  # 6  brown cluster
         ('oval_pair', ('547e64', '92a984', 'cddf6c'), True),    # 7  green ovals
         ('pear', ('a2a947', 'd5e04b', 'fbff86'), True),         # 8  yellow-green pear shape
         ('berries', ('b33831', 'e83b3b', 'f68181'), True),      # 9  red berry pair
         ('round', ('e6904e', 'f57d4a', 'fca790'), True),        # 10 apricot-orange round
         ('tear', ('323353', '484a77', '4d9be6'), True),         # 11 blue-violet plum
         ('round_small', ('0b8a8f', '30e1b9', '8ff8e2'), True)]  # 12 sea-green round


def disc(a, cx, cy, r, ramp):
    d, m, l = (C(c) for c in ramp)
    for y in range(S):
        for x in range(S):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            if dx * dx + dy * dy <= r * r:
                lit = dx + dy < -r * 0.6
                shade = dx + dy > r * 0.7
                a[y, x] = l if lit else (d if shade else m)


def ellipse(a, cx, cy, rx, ry, ramp):
    d, m, l = (C(c) for c in ramp)
    for y in range(S):
        for x in range(S):
            dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1:
                a[y, x] = l if dx + dy < -0.7 else (d if dx + dy > 0.6 else m)


def fruit(shape, ramp, leaf):
    a = np.zeros((S, S, 4), np.uint8)
    if shape == 'round': disc(a, 8, 9.5, 5.2, ramp)
    elif shape == 'round_small': disc(a, 8, 10, 4.2, ramp)
    elif shape == 'cluster':
        for cx, cy in ((6, 6), (10, 6), (8, 8.5), (5, 9.5), (11, 9.5), (8, 12), (6.5, 14), (9.5, 14)):
            disc(a, cx, cy, 2.1, ramp)
    elif shape == 'cluster_small':
        for cx, cy in ((6, 8), (10, 8), (8, 11), (6, 13), (10, 13)): ellipse(a, cx, cy, 1.6, 2.4, ramp)
    elif shape == 'tear':
        ellipse(a, 8, 10.5, 4.6, 4.6, ramp); ellipse(a, 8, 6.5, 2.6, 3.0, ramp)
    elif shape == 'crown':
        disc(a, 8, 10, 5.2, ramp)
        for x, y in ((6, 3), (6, 4), (7, 4), (8, 2), (8, 3), (8, 4), (9, 4), (10, 3), (10, 4)): a[y, x] = C(ramp[0] if y < 4 else ramp[1])
    elif shape == 'oval_pair':
        ellipse(a, 6, 10, 2.6, 3.8, ramp); ellipse(a, 10.5, 9.5, 2.6, 3.8, ramp)
    elif shape == 'pear':
        disc(a, 8, 11, 4.4, ramp); ellipse(a, 8, 6.5, 2.4, 2.8, ramp)
    elif shape == 'berries':
        disc(a, 5.5, 11.5, 3.0, ramp); disc(a, 10.5, 11.5, 3.0, ramp)
        for k in range(5): a[6 + k, 5 + k // 2] = C(STEM); a[6 + k, 10 - k // 2] = C(STEM)
    top = min(y for y in range(S) if a[y, :, 3].any())
    if shape not in ('berries', 'crown', 'cluster'):
        a[top - 1, 8] = C(STEM); a[top - 2, 8] = C(STEM)
    if leaf and shape != 'cluster':
        y = max(1, top - 2)
        for x, c in ((9, 1), (10, 2), (11, 1), (10, 0)): a[y - (1 if x == 10 else 0) + (1 if c == 0 else 0), x] = C(LEAF[c])
    if shape == 'cluster':
        a[3, 8] = C(STEM); a[2, 9] = C(LEAF[1]); a[2, 10] = C(LEAF[2]); a[3, 10] = C(LEAF[0])
    out = a.copy()                                               # 1 px outline
    m = a[..., 3] > 0
    e = np.zeros_like(m); e[1:] |= m[:-1]; e[:-1] |= m[1:]; e[:, 1:] |= m[:, :-1]; e[:, :-1] |= m[:, 1:]
    out[e & ~m] = C('2e222f')
    return out


def main():
    sheet = np.concatenate([fruit(*c) for c in CROPS], 1)
    Image.fromarray(sheet).save('game/art/fruits.png')
    big = Image.fromarray(sheet).resize((S * 12 * 3, S * 3), Image.NEAREST)
    bg = Image.new('RGBA', big.size, (35, 144, 99, 255)); bg.alpha_composite(big); bg.save('out/fruits_3x.png')
    print('fruits ok')


if __name__ == '__main__':
    main()
