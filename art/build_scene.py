"""Composes the static New Jerusalem screen from generated tiles/props plus hand-drawn pixel work.
Outputs into game/art/: bg.png, bridge.png, water_a.png, water_b.png, glow_throne.png, glow_gate.png, spark.png
Layout numbers are mirrored in game/data/city.json and game/scripts/city/city_layout.gd (keep in sync)."""
import random, sys
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
from common import C, OUT, snap_rgb, radial_glow
from wall import WALL_BOTTOM, WALL_H, WALL_TOP, draw_sky, add_city_top

W, H = 960, 540
N_BANK = (224, 272); RIVER = (272, 368); S_BANK = (368, 416)
STREET_X = (432, 528)
GATE_POS = (408, 9)
random.seed(7)


bg = Image.new('RGBA', (W, H))
px = bg.load()


draw_sky(px, W)

# ---------------------------------------------------------------- gold street everywhere below the wall
gold = [Image.open(f'art/raw/tA_{i:02d}.png').convert('RGBA') for i in (1, 2)]
grass = [Image.open(f'art/raw/tA_{i:02d}.png').convert('RGBA') for i in (8, 9, 12)]
for ty in range(WALL_BOTTOM // 32, H // 32 + 1):
    for tx in range(W // 32):
        bg.paste(gold[0] if random.random() < 0.8 else gold[1], (tx * 32, ty * 32))

LIGHTER = {C(a)[:3]: C(b) for a, b in (('e6904e', 'f79617'), ('f79617', 'f9c22b'), ('f9c22b', 'fbb954'), ('fbb954', 'fbff86'), ('fbff86', 'ffffff'), ('cd683d', 'e6904e'))}
def sheen(x, y):
    u = (x + int(y * 0.75)) % 211
    return u < 9 or 15 <= u < 18 or 120 <= u < 122
for y in range(WALL_BOTTOM, H):
    for x in range(W):
        if sheen(x, y):
            c = px[x, y][:3]
            if c in LIGHTER: px[x, y] = LIGHTER[c]

def grass_strip(y0, y1):
    strip = Image.new('RGBA', (W, y1 - y0))
    for ty in range(0, y1 - y0, 32):
        for tx in range(0, W, 32):
            strip.paste(random.choice(grass), (tx, ty))
    bg.paste(strip, (0, y0))
grass_strip(*N_BANK); grass_strip(*S_BANK)

# ---------------------------------------------------------------- river bed (crystal clear water base)
r0, r1 = RIVER
FACE = 7  # visible face of the north embankment
for y in range(r0, r1):
    for x in range(W):
        yy = y - r0
        b = ((x * 5 + y * 3) % 8) / 8  # ordered-ish dither value
        if yy < FACE:
            continue
        depth = yy - FACE
        if depth < 3: col = '4d9be6'
        elif depth < 10: col = '4d9be6' if b < (10 - depth) / 8 else '8fd3ff'
        elif yy > (r1 - r0) - 8: col = '8ff8e2' if b < ((yy - (r1 - r0 - 8)) / 8) else '8fd3ff'
        else: col = '8fd3ff'
        px[x, y] = C(col)
# north embankment face (jasper stone): lip + face with joints
for x in range(W):
    px[x, r0] = OUT
    px[x, r0 + 1] = C('ffffff')
    px[x, r0 + 2] = C('c7dcd0')
    for k in range(3, FACE - 1): px[x, r0 + k] = C('9babb2') if k < FACE - 2 else C('7f708a')
    px[x, r0 + FACE - 1] = OUT
    if x % 24 == 0:
        for k in range(3, FACE - 1): px[x, r0 + k] = C('7f708a')
# south embankment lip (seen from above)
for x in range(W):
    px[x, r1 - 3] = OUT; px[x, r1 - 2] = C('ffffff'); px[x, r1 - 1] = C('c7dcd0')
    px[x, r1] = C('9babb2')

# ---------------------------------------------------------------- planter curbs between gold street and grass banks
def curb_top(y):   # gold street above, grass below: we see the curb top
    for x in range(W):
        px[x, y] = OUT; px[x, y + 1] = C('fbff86'); px[x, y + 2] = C('f9c22b'); px[x, y + 3] = C('e6904e')
def curb_front(y):  # grass above, gold street below: we see the curb's south face
    for x in range(W):
        px[x, y - 4] = OUT; px[x, y - 3] = C('fbff86'); px[x, y - 2] = C('f9c22b'); px[x, y - 1] = C('f79617'); px[x, y] = OUT
curb_top(N_BANK[0]); curb_front(S_BANK[1])

# ---------------------------------------------------------------- street crossing the banks (gold, with planter ends)
sx0, sx1 = STREET_X
for ty in range(N_BANK[0] // 32, S_BANK[1] // 32 + 1):
    for tx in range(sx0 // 32, sx1 // 32):
        t = gold[0]
        for y in range(32):
            for x in range(32):
                X, Y = tx * 32 + x, ty * 32 + y
                if (N_BANK[0] <= Y < N_BANK[1] + 0) or (S_BANK[0] <= Y < S_BANK[1] + 1):
                    px[X, Y] = t.getpixel((x, y))
for (y0, y1) in (N_BANK, S_BANK):
    for y in range(y0, y1 + (1 if y0 == S_BANK[0] else 0)):
        px[sx0 - 1, y] = OUT; px[sx0 - 2, y] = C('f9c22b'); px[sx0 - 3, y] = OUT
        px[sx1, y] = OUT; px[sx1 + 1, y] = C('e6904e'); px[sx1 + 2, y] = OUT
# restore the gold street under where curb lines crossed the street
for y in (N_BANK[0], N_BANK[0] + 1, N_BANK[0] + 2, N_BANK[0] + 3, S_BANK[1] - 4, S_BANK[1] - 3, S_BANK[1] - 2, S_BANK[1] - 1, S_BANK[1]):
    for x in range(sx0, sx1):
        px[x, y] = gold[0].getpixel((x % 32, y % 32))

# ---------------------------------------------------------------- the wall of jasper and the gate of one pearl (art/wall.py)
add_city_top(bg, GATE_POS[0])

# ---------------------------------------------------------------- quantize check + save
snap_rgb(bg).save('game/art/bg.png')

# ---------------------------------------------------------------- bridge (separate sprite above the water layer)
BX0, BY0 = sx0 - 8, r0 - 4
br = Image.new('RGBA', (sx1 - sx0 + 20, r1 - r0 + 10))
bp = br.load()
def B(x, y, c):  # scene coords -> bridge image
    X, Y = x - BX0, y - BY0
    if 0 <= X < br.width and 0 <= Y < br.height: bp[X, Y] = c if isinstance(c, tuple) else C(c)
for y in range(r0, r1 + 1):
    for x in range(sx0, sx1):
        B(x, y, gold[0].getpixel((x % 32, y % 32)))
    # soft shadow on the water east of the bridge (light from top-left)
    for x in range(sx1, sx1 + 5):
        if r0 + FACE <= y < r1 - 3 and (x + y) % 2 == 0: B(x, y, '4d65b4')
def parapet(x0):
    for y in range(r0 - 2, r1 + 2):
        B(x0, y, OUT); B(x0 + 7, y, OUT)
        for x in range(x0 + 1, x0 + 7):
            B(x, y, 'fbff86' if x < x0 + 3 else ('f9c22b' if x < x0 + 6 else 'e6904e'))
    for x in range(x0, x0 + 8):
        B(x, r0 - 3, OUT); B(x, r1 + 2, 'f79617'); B(x, r1 + 3, 'f79617'); B(x, r1 + 4, OUT)
    # posts with pearl caps
    for py in list(range(r0, r1, 24)) + [r1 - 4]:
        for y in range(py - 3, py + 5):
            for x in range(x0 - 1, x0 + 9):
                edge = y in (py - 3, py + 4) or x in (x0 - 1, x0 + 8)
                B(x, y, OUT if edge else ('ffffff' if (y < py and x < x0 + 5) else ('c7dcd0' if y < py + 2 else 'eaaded')))
parapet(sx0); parapet(sx1 - 8)
br.save('game/art/bridge.png')
print('bridge origin', BX0, BY0, br.size)

def _glow(*args): return Image.fromarray(radial_glow(*args))


# ---------------------------------------------------------------- water ripple layers (tileable in x, flow to the right)
def ripples(seed, n, w=240, h=r1 - r0):
    rnd = random.Random(seed)
    im = Image.new('RGBA', (w, h)); p = im.load()
    for _ in range(n):
        x = rnd.randrange(w); y = rnd.randrange(FACE + 4, h - 5)
        L = rnd.choice((2, 3, 4, 5, 6))
        col = C('ffffff') if rnd.random() < 0.45 else C('8ff8e2')
        for k in range(L): p[(x + k) % w, y] = col
        if rnd.random() < 0.3: p[(x + L // 2) % w, y - 1] = C('ffffff')
    return im
ripples(11, 70).save('game/art/water_a.png')
ripples(23, 40).save('game/art/water_b.png')

# ---------------------------------------------------------------- glows (pixel-banded radial light, additive)

th = np.array(_glow(560, 480, 0, 240, 520, 300, 'fbff86', 150)).astype(float)
core = np.array(_glow(560, 480, 0, 240, 200, 110, 'ffffff', 255)).astype(float)
a1, a2 = th[..., 3:4] / 255, core[..., 3:4] / 255
out = np.zeros_like(th); out[..., 3:4] = 255 * (1 - (1 - a1) * (1 - a2))
out[..., :3] = (th[..., :3] * a1 + core[..., :3] * a2) / np.maximum(a1 + a2, 1e-6)
Image.fromarray(out.astype(np.uint8)).save('game/art/glow_throne.png')
_glow(200, 220, 100, 130, 100, 120, 'ffffff', 150).save('game/art/glow_gate.png')
sp = Image.new('RGBA', (3, 3)); spp = sp.load()
for (x, y) in ((1, 0), (0, 1), (1, 1), (2, 1), (1, 2)): spp[x, y] = (255, 255, 255, 255)
sp.save('game/art/spark.png')
print('done')
