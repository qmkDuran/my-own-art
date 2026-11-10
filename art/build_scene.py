"""The garden heart of the New Jerusalem (Rev 22:1-2): the jasper wall and pearl gate, the gold street running south,
the river of the water of life flowing from the throne's light (left edge), wide grass banks where the trees of life
stand on either side of the river, a straight bridge where the street crosses, and a riverside walk to the light.
Outputs into game/art/: bg.png, bridge.png, water_a.png, water_b.png, glow_throne.png, glow_gate.png, spark.png.
Layout numbers are mirrored in game/data/city.json (keep in sync)."""
import random, sys
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
from common import C, OUT, H, dith, snap_rgb, radial_glow
from wall import WALL_BOTTOM, draw_sky, add_city_top

W, HT = 960, 540
N_BANK = (WALL_BOTTOM, 318)          # grass from the wall's foot to the river (trees of life, Rev 22:2)
RIVER = (318, 394)                   # embankment lip to embankment lip
S_BANK = (394, HT)                   # grass from the river to the district below
STREET = (432, 528)                  # the gold street (also the bridge deck)
EDGE = 3                             # width of the street's edge band (outline, gold, outline)
PATH = (300, 316)                    # riverside walk on the north bank, from the street west to the light
FACE = 7                             # visible face of the north embankment
PARAPET_W = 8
POSTS = 5                            # bridge posts per side, evenly spaced from bank to bank
GATE_X = 408
random.seed(7)


def tiles(bg, names, y0, y1, x0=0, x1=W):
    ims = [Image.open(f'art/raw/tA_{i:02d}.png').convert('RGBA') for i in names]
    region = Image.new('RGBA', (W, HT))
    for ty in range(0, HT, 32):
        for tx in range(0, W, 32):
            region.paste(random.choice(ims), (tx, ty))
    bg.paste(region.crop((x0, y0, x1, y1)), (x0, y0))


LIGHTER = {H(a): C(b) for a, b in (('e6904e', 'f79617'), ('f79617', 'f9c22b'), ('f9c22b', 'fbb954'), ('fbb954', 'fbff86'), ('fbff86', 'ffffff'))}


def gold_street(bg, px):
    """The gold street from the gate to the bottom edge, exactly STREET wide, with symmetric edge bands."""
    tiles(bg, (1, 1, 1, 1, 2), WALL_BOTTOM, HT, *STREET)
    for y in range(WALL_BOTTOM, HT):
        for x in range(*STREET):
            u = (x + int(y * 0.75)) % 211
            if (u < 9 or 15 <= u < 18) and px[x, y][:3] in LIGHTER: px[x, y] = LIGHTER[px[x, y][:3]]
        for xe in (STREET[0] - EDGE, STREET[1]):              # left band x 429..431, right band x 528..530
            px[xe, y] = OUT; px[xe + 1, y] = C('f9c22b'); px[xe + 2, y] = OUT


def river(px):
    r0, r1 = RIVER
    for y in range(r0 + FACE, r1):
        yy = y - r0; depth = yy - FACE
        for x in range(W):
            b = ((x * 5 + y * 3) % 8) / 8
            if depth < 3: col = '4d9be6'
            elif depth < 10: col = '4d9be6' if b < (10 - depth) / 8 else '8fd3ff'
            elif yy > (r1 - r0) - 8: col = '8ff8e2' if b < ((yy - (r1 - r0 - 8)) / 8) else '8fd3ff'
            else: col = '8fd3ff'
            px[x, y] = C(col)
    for x in range(W):                                        # north embankment: lip and jasper face with joints
        px[x, r0] = OUT; px[x, r0 + 1] = C('ffffff'); px[x, r0 + 2] = C('c7dcd0')
        for k in range(3, FACE - 1):
            px[x, r0 + k] = C('7f708a') if (x % 24 == 0 or k == FACE - 2) else C('9babb2')
        px[x, r0 + FACE - 1] = OUT
        px[x, r1 - 3] = OUT; px[x, r1 - 2] = C('ffffff'); px[x, r1 - 1] = C('c7dcd0')   # south lip (seen from above)


def riverside_path(px):
    """Pale jasper flagstones along the north bank, from the street to the light at the river's source."""
    y0, y1 = PATH
    for y in range(y0, y1):
        for x in range(0, STREET[0] - EDGE):
            row = y - y0
            stone = (x + (10 if row >= (y1 - y0) // 2 else 0)) % 20
            if row == 0: col = '239063'                        # grass shadow along the upper edge
            elif row == y1 - y0 - 1: col = '9babb2'
            elif stone == 0 or row == (y1 - y0) // 2: col = '9babb2'
            elif row <= 2 and stone < 12: col = 'ffffff'
            else: col = 'c7dcd0' if dith(x, y) < 0.85 else '92a984'
            px[x, y] = C(col)


def build_background():
    bg = Image.new('RGBA', (W, HT)); px = bg.load()
    draw_sky(px, W)
    tiles(bg, (8, 9, 12), N_BANK[0], HT)                      # grass everywhere below the wall ...
    river(px)                                                 # ... except the river
    riverside_path(px)
    gold_street(bg, px)                                       # ... and the gold street
    add_city_top(bg, GATE_X)
    snap_rgb(bg).save('game/art/bg.png')
    return bg


def parapet(img, x0, oy):
    """One bridge parapet from bank to bank (image coords: x0 = its left edge, oy = world y of the image top);
    posts with pearl caps evenly spaced."""
    p = img.load(); r0, r1 = RIVER
    ya, yb = r0 - 4 - oy, r1 + 4 - oy
    for y in range(ya, yb + 1):
        for x in range(x0, x0 + PARAPET_W):
            edge = x in (x0, x0 + PARAPET_W - 1) or y in (ya, yb)
            p[x, y] = OUT if edge else C('fbff86' if x < x0 + 3 else ('f9c22b' if x < x0 + 6 else 'e6904e'))
    for i in range(POSTS):
        py = ya + round(i * (yb - ya) / (POSTS - 1))
        for y in range(py - 3, py + 4):
            for x in range(x0 - 1, x0 + PARAPET_W + 1):
                edge = y in (py - 3, py + 3) or x in (x0 - 1, x0 + PARAPET_W)
                p[x, y] = OUT if edge else C('ffffff' if (y < py and x < x0 + 4) else ('c7dcd0' if y <= py else 'eaaded'))


def build_bridge(bg):
    """Deck exactly the street's width; the two parapets mirror each other and sit on the street's edge bands."""
    r0, r1 = RIVER
    ox, oy = STREET[0] - PARAPET_W - 1, r0 - 8
    br = Image.new('RGBA', (STREET[1] - STREET[0] + 2 * PARAPET_W + 2, r1 - r0 + 16))
    deck = bg.crop((STREET[0], WALL_BOTTOM, STREET[1], WALL_BOTTOM + (r1 - r0) + 8))   # same gold as the street
    br.paste(deck, (STREET[0] - ox, r0 - 4 - oy))
    half = Image.new('RGBA', br.size); parapet(half, 1, oy)
    mirror = half.transpose(Image.FLIP_LEFT_RIGHT)
    br.alpha_composite(half); br.alpha_composite(mirror)
    br.save('game/art/bridge.png')
    return ox, oy, br.size


def ripples(seed, n, w=240):
    rnd = random.Random(seed); h = RIVER[1] - RIVER[0]
    im = Image.new('RGBA', (w, h)); p = im.load()
    for _ in range(n):
        x = rnd.randrange(w); y = rnd.randrange(FACE + 4, h - 5)
        L = rnd.choice((2, 3, 4, 5, 6))
        col = C('ffffff') if rnd.random() < 0.45 else C('8ff8e2')
        for k in range(L): p[(x + k) % w, y] = col
        if rnd.random() < 0.3: p[(x + L // 2) % w, y - 1] = C('ffffff')
    return im


def glows():
    g = lambda *a: np.array(Image.fromarray(radial_glow(*a))).astype(float)
    th, core = g(560, 480, 0, 240, 520, 300, 'fbff86', 150), g(560, 480, 0, 240, 200, 110, 'ffffff', 255)
    a1, a2 = th[..., 3:4] / 255, core[..., 3:4] / 255
    out = np.zeros_like(th); out[..., 3:4] = 255 * (1 - (1 - a1) * (1 - a2))
    out[..., :3] = (th[..., :3] * a1 + core[..., :3] * a2) / np.maximum(a1 + a2, 1e-6)
    Image.fromarray(out.astype(np.uint8)).save('game/art/glow_throne.png')
    Image.fromarray(radial_glow(200, 220, 100, 130, 100, 120, 'ffffff', 150)).save('game/art/glow_gate.png')
    sp = Image.new('RGBA', (3, 3)); spp = sp.load()
    for (x, y) in ((1, 0), (0, 1), (1, 1), (2, 1), (1, 2)): spp[x, y] = (255, 255, 255, 255)
    sp.save('game/art/spark.png')


if __name__ == '__main__':
    bg = build_background()
    print('bridge origin/size', build_bridge(bg))
    ripples(11, 70).save('game/art/water_a.png'); ripples(23, 40).save('game/art/water_b.png')
    glows()
    print('garden ok')
