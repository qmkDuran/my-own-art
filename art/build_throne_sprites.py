"""Throne-room sprites from the PixelLab outputs, finished by hand. Writes game/art/throne/*.png and out/throne_sprites_3x.png."""
import os, sys
from collections import deque
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
from common import H, OUTL, quant, recolor, strip_bg, keep_main, contact

OUTD = 'game/art/throne/'; os.makedirs(OUTD, exist_ok=True)


def save(im, name):
    im.save(OUTD + name + '.png'); return OUTD + name + '.png'


sheet = []
# ---------------------------------------------------------------- the four living creatures (Rev 4:6-8)
lion = quant(Image.open('art/raw/cr_lion_00.png'))
ox = strip_bg(quant(Image.open('art/raw/cr_ox_00.png')), {H('c7dcd0'), H('ffffff')})
ox = keep_main(ox, 0.05)
man = quant(Image.open('art/raw/cr_manB_01.png'))
# lighter olive skin so the creature is not mistaken for the player character
man = recolor(man, {'9e4539': 'e6904e', '6e2727': 'cd683d', '7a3045': '9e4539', '753c54': '9e4539', '45293f': '6e2727'})
def man_head(im):
    # Hand edit: clean-shaven, gold-white hair, luminous pale-gold skin, so he cannot be mistaken for the player.
    a = np.array(im); X0, X1, Y0, Y1 = 47, 66, 26, 46
    HEAD = {H(c) for c in ('2e222f', 'e6904e', 'cd683d', '9e4539', '6e2727', '966c6c')}
    def hc(y, x): return a[y, x, 3] and tuple(a[y, x, :3]) in HEAD
    out = a.copy()
    for y in range(Y0, Y1):
        for x in range(X0, X1):
            if not a[y, x, 3]: continue
            c = tuple(a[y, x, :3])
            interior = all(hc(y + dy, x + dx) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if c == OUTL and interior and y <= 34:          # hair -> gold-white
                out[y, x, :3] = H('ffffff') if (x + y) % 5 == 0 or y <= 28 else (H('fbff86') if y < 32 else H('f9c22b'))
            elif c == OUTL and interior and y >= 40:        # beard -> chin/cheek skin
                out[y, x, :3] = H('fdcbb0') if y < 43 else H('fbb954')
            elif c == H('966c6c'):
                out[y, x, :3] = H('fca790')
            elif c == H('e6904e'): out[y, x, :3] = H('fdcbb0')
            elif c == H('cd683d'): out[y, x, :3] = H('fbb954')
            elif c == H('9e4539'): out[y, x, :3] = H('e6904e')
            elif c == H('6e2727'): out[y, x, :3] = H('9e4539')
    SK = {H('e6904e'): H('fdcbb0'), H('cd683d'): H('fbb954'), H('9e4539'): H('e6904e'), H('6e2727'): H('9e4539'), H('966c6c'): H('fca790')}
    for y in range(Y1, a.shape[0]):           # hands and feet in the body's centre column
        for x in range(44, 70):
            if a[y, x, 3] and tuple(a[y, x, :3]) in SK: out[y, x, :3] = SK[tuple(a[y, x, :3])]
    return Image.fromarray(out)
man = man_head(man)
eagle = keep_main(quant(Image.open('art/raw/cr_eagle_02.png')), 0.05)
for n, im in (('lion', lion), ('ox', ox), ('man', man), ('eagle', eagle)):
    sheet.append(save(im, 'creature_' + n))

# ---------------------------------------------------------------- the Lamb (Rev 5:6): white, standing; a small muted mark only
lamb = quant(Image.open('art/raw/lamb_21.png'))
la = np.array(lamb)
for (x, y) in ((27, 30), (28, 30)):          # tiny mark on the breast, muted rose, no gore
    if la[y, x, 3]: la[y, x, :3] = H('cf657f')
lamb = Image.fromarray(la)
sheet.append(save(lamb, 'lamb'))

# ---------------------------------------------------------------- elders (Rev 4:4, 4:10, 5:8)
CROWN = {H(c) for c in ('f9c22b', 'fbff86', 'f79617', 'e6904e', 'fbb954', 'b33831', 'e83b3b', 'ea4f36')}
def elder_frames(src):
    e = quant(Image.open(src)); a = np.array(e); h, w = a.shape[:2]
    top = a[:, :, 3].nonzero()[0].min()
    # crown = everything right of the throne back and above the crown's lower band (boxes read off the pixels)
    cx0, band = CROWN_BOX[src]
    cmask = np.zeros((h, w), bool)
    cmask[:band + 1, cx0:] = a[:band + 1, cx0:, 3] > 0
    ys, xs = np.nonzero(cmask)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    crown_img = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
    crown_img[cmask[y0:y1, x0:x1]] = a[y0:y1, x0:x1][cmask[y0:y1, x0:x1]]
    # Rounded skull (hand-drawn): a dome of white hair over the head, drawn on every frame.
    # The crown is then set ON the dome, 2 px higher than before, so hair shows beneath its band.
    yb = band + 1                                     # first row of hair/face under the old crown band
    L = cx0 - 2
    R = max(x for x in range(cx0, min(w, cx0 + 24)) if a[yb, x, 3] and tuple(a[yb, x, :3]) == OUTL)
    xc, rx, ry = (L + R) / 2, (R - L) / 2, 7.0
    def inside(x, y): return y <= yb and ((x - xc) / rx) ** 2 + ((y - yb) / ry) ** 2 <= 1.0
    bare = a.copy(); bare[cmask] = (0, 0, 0, 0)
    for y in range(int(yb - ry) - 1, yb + 1):
        for x in range(L, R + 1):
            if not inside(x, y): continue
            edge = not all(inside(x + dx, y + dy) or y + dy > yb for dx, dy in ((1, 0), (-1, 0), (0, -1)))
            if edge: c = OUTL
            elif x > xc + rx * 0.55: c = H('c7dcd0')                      # shade away from the light
            elif y >= yb - 2 and x > xc and (x - L) % 3 == 0: c = H('c7dcd0')  # a few hair strands
            else: c = H('ffffff')
            bare[y, x] = (*c, 255)
    crowned = bare.copy()
    lift = 2
    for (yy, xx) in zip(*np.nonzero(cmask)):
        if yy - lift >= 0: crowned[yy - lift, xx] = a[yy, xx]
    # bow: the upper body (head dome included) sinks forward by 3 px
    seat = top + 30
    CUSH = {H('c7dcd0'), H('ffffff'), H('9babb2')}
    def bow(arr, d=3):
        b = arr.copy()
        region = np.zeros((h, w), bool)
        region[:seat, cx0 + 1:] = arr[:seat, cx0 + 1:, 3] > 0
        region[:yb + 1, L:cx0 + 1] = arr[:yb + 1, L:cx0 + 1, 3] > 0
        b[region] = (0, 0, 0, 0)
        for y in range(seat - 1, -1, -1):
            for x in range(L, w):
                if region[y, x] and y + d < h:
                    b[y + d, x] = arr[y, x]
        for x in range(L, w):                      # exposed throne cushion is refilled from the pixel above
            for y in range(seat):
                if region[y, x] and b[y, x, 3] == 0 and y > 0 and b[y - 1, x, 3] and tuple(b[y - 1, x, :3]) in CUSH:
                    b[y, x] = b[y - 1, x]
        return Image.fromarray(b)
    return (Image.fromarray(crowned), bow(crowned), Image.fromarray(bare), bow(bare),
            Image.fromarray(crown_img), (int(x0), int(y0) - lift))

CROWN_BOX = {'art/raw/elder_04.png': (27, 13), 'art/raw/elder_02.png': (26, 12), 'art/raw/elder_08.png': (26, 12)}
meta = []
for i, src in enumerate(('art/raw/elder_04.png', 'art/raw/elder_02.png', 'art/raw/elder_08.png')):
    sit, bowed, bare, bare_bow, crown, cpos = elder_frames(src)
    strip = Image.new('RGBA', (64 * 4, 64))
    for k, f in enumerate((sit, bowed, bare, bare_bow)): strip.alpha_composite(f, (k * 64, 0))
    sheet.append(save(strip, f'elder{i}'))
    sheet.append(save(crown, f'crown{i}'))
    meta.append(cpos)
open(OUTD + 'crown_pos.txt', 'w').write('\n'.join(f'{x},{y}' for x, y in meta))
print('crown positions', meta)

# ---------------------------------------------------------------- angels (Rev 5:11): halos removed, varied faces
angel_ids = [1, 3, 4, 8, 9, 16, 18, 20, 24, 26, 29, 34, 36, 40, 41, 44, 47, 48, 53, 59]
strip = Image.new('RGBA', (32 * len(angel_ids), 32))
for k, i in enumerate(angel_ids):
    im = keep_main(quant(Image.open(f'art/raw/angel_{i:02d}.png')), 0.3)
    strip.alpha_composite(im, (k * 32, 0))
sheet.append(save(strip, 'angels'))
open(OUTD + 'angels_count.txt', 'w').write(str(len(angel_ids)))

contact(sheet[:5], 'art/work/throne_sprites_a.png', scale=3, cols=5, bg=(234, 226, 196, 255))
contact(sheet[5:], 'art/work/throne_sprites_b.png', scale=3, cols=2, bg=(234, 226, 196, 255))
print('ok')
