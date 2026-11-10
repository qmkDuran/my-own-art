"""The zone at night, 3840x2160 (4x4 screens), built from Project R's exterior art (art/ext/, read-only copies),
darkened and ruined by hand, plus hand-drawn pieces (overpass, guardrails, crates, waystones, the rift). One source of
truth: this script writes the ground image, the minimap, the prop sprites AND game/data/zone.json. Run from heaven/arpg/.

Four regions, connected:
- Suburb (north-west): two rows of houses facing two streets, a side street, back fences and yards.
- Highway (north-east): the main street joins a four-lane highway with a median barrier, guardrails, a pile-up of
  wrecks and an overpass; a gap in the south guardrail leads down to the rift.
- Park (south-west): the side street becomes a dirt path into a dark park; woods along the edges.
- Rift (south-east): scorched ground split around a chasm with smoke rising from it (Rev 9:2): the final arena."""
import json, os, random, sys
import numpy as np
from PIL import Image
HEAVEN = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
sys.path.insert(0, os.path.join(HEAVEN, 'art'))
from common import C, H, quant, keep_main, dith   # noqa: E402
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import style   # noqa: E402

EXT = 'art/ext/'
G = 'game/art/zone/'
W, HT = 3840, 2160
SW, SH = 1920, 1080                                                        # the suburb block
SIDE_N = (468, 500); ROAD = (500, 596); SIDE_S = (596, 628)                  # main street
SIDE_N2 = (905, 937); ROAD2 = (937, 1033); SIDE_S2 = (1033, 1065)           # lower street
CROSS = (1504, 1600)                                                       # side street (x), main street -> lower street
random.seed(11)
# Step 2 style test: the left half of the suburb uses tiles and one house generated with Michael as the style reference
# (art/gen_world_test.py); the right half keeps the reused Project R art, for comparison. False restores the old art.
WORLD_TEST = True
TEST_X = 960                                                               # test tiles west of this x (suburb only)

# [art, x, base y, footprint w, footprint h]
# Houses at true scale (doors ~1.15 x Michael): three tall houses north, two bungalows and the store south.
NORTH_ROW = [['house_a', 290, 470, 440, 70], ['house_b', 830, 470, 440, 70], ['house_a_m', 1370, 470, 440, 70]]
SOUTH_ROW = [['house_c', 250, 905, 410, 62], ['store', 650, 905, 270, 56], ['house_c_m', 1060, 905, 410, 62]]
CARS = [['car_wreck_burned', 700, 586, 96, 30], ['car_wreck', 1180, 576, 96, 30], ['van', 1240, 1010, 96, 30],
        ['suv_red', 1700, 470, 96, 30], ['car_wreck', 330, 1015, 96, 30]]
FIRES = [[700, 560], [1340, 700], [1560, 1000]]                            # the wreck, a back yard, the side street
LIGHTS = [[380, 330, 0.5, 'flicker', True], [1100, 330, 0.0, 'lamp', False], [700, 760, 0.45, 'flicker', True],
          [1700, 760, 0.0, 'lamp', True]]                                    # x, y, energy, kind, pole drawn
# Highway (x >= HX): two carriageways with a median barrier, guardrails along both edges.
HX = 2048
LANES = ((360, 540), (560, 740))
MEDIAN = (540, 560)
RAIL_N, RAIL_S = 344, 748
RAIL_GAPS_N = ((2560, 2660),)
RAIL_GAPS_S = ((2420, 2520), (3300, 3420))                                 # to the verge (prayer) and down to the rift
MEDIAN_GAPS = ((2300, 2380), (2780, 2860), (3500, 3580))
OVERPASS = (2900, 3060, 220, 880)                                          # x0, x1, y0, y1 of the deck overhead
HWY_CARS = [['car_wreck', 2240, 470, 96, 30], ['car_wreck_burned', 2620, 640, 96, 30], ['van', 2840, 520, 96, 30],
            ['suv_red', 2990, 455, 96, 30], ['car_wreck', 3080, 700, 96, 30], ['car_wreck_burned', 3150, 600, 96, 30],
            ['van', 3560, 420, 96, 30], ['car_wreck', 3700, 690, 96, 30], ['car_wreck_burned', 2470, 880, 96, 30]]
# Park (y >= SH, x < SW): dirt paths, living and dead trees, hedges; woods along the edges.
PARK_PATHS = [[(1552, 1060), (1552, 1380), (1300, 1500), (900, 1520), (420, 1460), (220, 1300)],
              [(1300, 1500), (1500, 1620), (1920, 1640)], [(900, 1520), (860, 1820), (600, 1960)]]
# Rift (y >= SH, x >= SW): scorched ground and the chasm.
RIFT = (3000, 1700, 300, 140)                                              # centre x, y, radii
RIFT_PATH = [[(3360, 756), (3330, 1000), (3200, 1240), (3060, 1420)], [(1920, 1640), (2300, 1640), (2640, 1600)]]
FIRES_MORE = [[2620, 615], [3150, 575], [2470, 855], [1180, 1750], [2380, 1420], [2700, 1950], [3420, 1500],
              [3300, 1900], [2800, 1480]]


def tile(name): return Image.open(EXT + f'tiles/outdoor/{name}.png').convert('RGBA')


def darken(im, k):
    a = np.array(im).astype(float); a[..., :3] *= k
    return quant(Image.fromarray(a.clip(0, 255).astype(np.uint8)))


def mirror(im): return im.transpose(Image.FLIP_LEFT_RIGHT)


def street(bg, y0, y1, x0=0, x1=SW):
    road = [tile('road_0')] * 6 + [tile('road_crack'), tile('road_patch')]
    for tx in range(x0, x1, 32):
        for ty in range(y0, y1, 32): bg.alpha_composite(random.choice(road), (tx, ty))


def sidewalk_h(bg, y, x0=0, x1=SW):
    for tx in range(x0, x1, 32): bg.alpha_composite(tile('sidewalk_0' if tx % 96 else 'sidewalk_1'), (tx, y))


def ground():
    bg = Image.new('RGBA', (W, HT))
    grass = [tile('grass_0'), tile('grass_1'), tile('grass_2')]
    for ty in range(0, HT, 32):
        for tx in range(0, W, 32):
            bg.alpha_composite(random.choice(grass), (tx, ty))
    suburb(bg); highway(bg); park(bg); rift(bg)
    if WORLD_TEST: test_tiles(bg)
    px = bg.load()
    for fx, fy in FIRES + FIRES_MORE + [[c[1], c[2] - 10] for c in CARS + HWY_CARS]:   # scorch grouped where things burned
        scorch(px, fx, fy + 14, random.randint(26, 40))
    for _ in range(10):                                          # loose debris along the curbs
        x = random.randint(20, SW - 20); y = random.choice((SIDE_N[1] + 3, SIDE_S[0] - 4, SIDE_N2[1] + 3, SIDE_S2[0] - 4))
        rubble(px, x, y, 6)
    bg = style.to_world_palette(bg)
    bg.save(G + 'ground.png')
    mini = bg.resize((W // 24, HT // 24), Image.BOX)
    mini.save('game/art/ui/minimap.png')


def test_tiles(bg):
    """Repaint the suburb west of TEST_X with the generated tiles: asphalt cracks over a dark asphalt fill, the
    sidewalk slabs, and the lawn variants."""
    raw = os.path.join(HEAVEN, 'art', 'raw', 'arpg_test_tile_%d.png')
    t = lambda i: Image.open(raw % i).convert('RGBA')
    asphalt = [t(i) for i in (0, 1, 2, 5)]
    walk = [t(8), t(9)]
    lawn = [t(12), t(13), t(12), t(13), t(14)]
    rng = random.Random(4)
    fill = lambda c: Image.new('RGBA', (32, 32), C(c))
    for ty in range(0, SH, 32):                                   # lawn everywhere, then the bands on top
        for tx in range(0, TEST_X, 32):
            bg.paste(rng.choice(lawn), (tx, ty))
    for y0, y1 in (ROAD, ROAD2):
        for ty in range(y0, y1, 32):
            for tx in range(0, TEST_X, 32):
                tile_im = fill('3e3546'); tile_im.alpha_composite(rng.choice(asphalt)); bg.paste(tile_im, (tx, ty))
    for y in (SIDE_N[0], SIDE_S[0], SIDE_N2[0], SIDE_S2[0]):
        for tx in range(0, TEST_X, 32):
            tile_im = fill('9babb2'); tile_im.alpha_composite(rng.choice(walk)); bg.paste(tile_im, (tx, y))
    for y0, y1 in (ROAD, ROAD2):                                  # keep the lane markings
        for tx in range(64, TEST_X, 96): bg.alpha_composite(tile('road_line_h'), (tx, (y0 + y1) // 2 - 16))


def test_house():
    """The generated house (variant 02, straight front) at true scale: Scale2x twice (4x, door ~64 px ~1.1 x Michael),
    world palette, outline."""
    sys.path.insert(0, os.path.join(HEAVEN, 'art'))
    from upscale import upscale
    im = Image.open(os.path.join(HEAVEN, 'art', 'raw', 'arpg_test_house_02.png')).convert('RGBA')
    im = style.to_world_palette(im.crop(im.getbbox()))
    big = upscale(upscale(im))
    return style.outline(style.to_world_palette(big.crop(big.getbbox())))


def suburb(bg):
    street(bg, *ROAD); street(bg, *ROAD2); street(bg, SIDE_S[1], SIDE_N2[0], *CROSS)
    for y in (SIDE_N[0], SIDE_S[0], SIDE_N2[0], SIDE_S2[0]): sidewalk_h(bg, y)
    for ty in range(SIDE_S[1], SIDE_N2[0], 32):
        bg.alpha_composite(tile('sidewalk_0'), (CROSS[0] - 32, ty)); bg.alpha_composite(tile('sidewalk_0'), (CROSS[1], ty))
    for tx in range(CROSS[0], CROSS[1], 32):                     # the side street runs through both sidewalks
        street(bg, SIDE_S[0], SIDE_S[1], tx, tx + 32); street(bg, SIDE_N2[0], SIDE_N2[1], tx, tx + 32)
    for y0, y1 in (ROAD, ROAD2):
        for tx in range(64, SW, 96):
            if not CROSS[0] - 32 <= tx < CROSS[1]: bg.alpha_composite(tile('road_line_h'), (tx, (y0 + y1) // 2 - 16))
    for x in (CROSS[0] - 64, CROSS[1] + 16):                     # crosswalks at the junction
        for ty in range(ROAD[0], ROAD[1], 32): bg.alpha_composite(tile('road_crosswalk'), (x, ty))
    street(bg, SIDE_N[0], SIDE_S[1], SW, HX)                     # the main street runs on into the highway


def highway(bg):
    for y0, y1 in LANES:
        street(bg, y0, y1, HX, W)
        for tx in range(HX + 32, W, 128): bg.alpha_composite(tile('road_line_h'), (tx, (y0 + y1) // 2 - 16))
    px = bg.load()
    for x in range(HX, W):
        gap = any(g0 <= x < g1 for g0, g1 in MEDIAN_GAPS)
        for y in range(*MEDIAN):                                 # concrete median barrier
            if gap:
                px[x, y] = C('3e3546')
                continue
            k = y - MEDIAN[0]
            px[x, y] = C('2e222f') if k in (0, MEDIAN[1] - MEDIAN[0] - 1) else (C('c7dcd0') if k < 8 else C('7f708a'))
        for ry, gaps in ((RAIL_N, RAIL_GAPS_N), (RAIL_S, RAIL_GAPS_S)):   # metal guardrails on posts
            if any(g0 <= x < g1 for g0, g1 in gaps):
                continue
            for k in range(8):
                px[x, ry + k] = C('2e222f') if k in (0, 7) else (C('9babb2') if k < 4 else C('625565'))
            if x % 48 < 4:
                for k in range(8, 14): px[x, ry + k] = C('3e3546')
    for y in range(RAIL_N, RAIL_S + 8):                          # the barrier closing the highway's west end
        if not (SIDE_N[0] <= y < SIDE_S[1]):
            for x in range(HX - 8, HX):
                px[x, y] = C('2e222f') if x in (HX - 8, HX - 1) else C('7f708a')
    x0, x1, y0, y1 = OVERPASS                                    # the overpass casts a shadow band
    for y in range(y0, y1):
        for x in range(x0 - 10, x1 + 10):
            if dith(x, y) < 0.55: px[x, y] = C('2e222f') if dith(x + 1, y) < 0.5 else C('3e3546')


def value_noise(w, h, cell, seed):
    """Smooth noise in 0..1 (bilinear between random values on a coarse grid, smoothstepped)."""
    g = np.random.default_rng(seed).random((h // cell + 2, w // cell + 2))
    ys, xs = np.mgrid[0:h, 0:w] / cell
    x0, y0 = xs.astype(int), ys.astype(int)
    fx, fy = xs - x0, ys - y0
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    top = g[y0, x0] * (1 - fx) + g[y0, x0 + 1] * fx
    bot = g[y0 + 1, x0] * (1 - fx) + g[y0 + 1, x0 + 1] * fx
    return top * (1 - fy) + bot * fy


def paint_path(bg, pts, r, dirt=None):
    """A dirt path along a polyline (a disc stamped along each segment), with a darker rim."""
    dirt = dirt or tile('dirt')
    m = np.zeros((HT, W), bool)
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        n = int(max(abs(bx - ax), abs(by - ay)) / 4) + 1
        for i in range(n + 1):
            cx, cy = ax + (bx - ax) * i / n, ay + (by - ay) * i / n
            m[max(0, int(cy - r)):int(cy + r), max(0, int(cx - r)):int(cx + r)] |= True
    px = bg.load(); dp = dirt.load()
    ys, xs = np.nonzero(m)
    for y, x in zip(ys, xs):
        px[x, y] = dp[x % 32, y % 32]
    edge = m & ~np.roll(m, 2, 0) | m & ~np.roll(m, -2, 0) | m & ~np.roll(m, 2, 1) | m & ~np.roll(m, -2, 1)
    for y, x in zip(*np.nonzero(edge)):
        if dith(x, y) < 0.6: px[x, y] = C('4c3e24')


def park(bg):
    px = bg.load()
    for y in range(SH, HT):                                      # the park lies darker than the yards
        for x in range(0, SW):
            if dith(x, y) < 0.18: px[x, y] = C('165a4c')
    for pts in PARK_PATHS: paint_path(bg, pts, 26)


def rift(bg):
    px = bg.load()
    noise = value_noise(W - SW + 61, HT - SH + 61, 96, 3)
    for y in range(SH - 60, HT):                                 # ash ground, blending out of the grass at its edges
        for x in range(SW - 60, W):
            fade = min(1.0, (y - (SH - 60)) / 60.0, (x - (SW - 60)) / 60.0) if y < SH or x < SW else 1.0
            if y < SH and x < SW or dith(x, y) > fade:
                continue
            v = noise[y - SH + 60, x - SW + 60]
            c = '3e3546'
            if v < 0.3 and dith(x + 3, y) < 0.6: c = '2e222f'
            elif v > 0.75 and dith(x + 3, y) < 0.5: c = '45293f'
            if dith(x * 7 % 4 + y, x) < 0.04: c = '625565'
            px[x, y] = C(c)
    for pts in RIFT_PATH: paint_path(bg, pts, 28, darken(tile('dirt'), 0.55))
    cx, cy, rx, ry = RIFT
    rng = random.Random(9)
    for _ in range(14):                                          # cracks running out from the chasm
        a = rng.uniform(0, 2 * np.pi); x, y = cx + np.cos(a) * rx, cy + np.sin(a) * ry
        for i in range(rng.randint(80, 220)):
            a += rng.uniform(-0.3, 0.3); x += np.cos(a) * 1.5; y += np.sin(a) * 0.9
            if SW <= x < W - 1 and SH <= y < HT - 1:
                px[int(x), int(y)] = C('2e222f'); px[int(x) + 1, int(y)] = C('6e2727') if i % 7 == 0 else C('2e222f')
    for y in range(cy - ry - 10, cy + ry + 10):                  # the chasm: black depth, red-hot rim
        for x in range(cx - rx - 14, cx + rx + 14):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d < 0.75: px[x, y] = C('2e222f') if dith(x, y) < 0.9 else C('45293f')
            elif d < 0.9: px[x, y] = C('45293f') if dith(x, y) < 0.6 else C('2e222f')
            elif d < 1.0: px[x, y] = C('b33831') if dith(x, y) < 0.5 else C('6e2727')
            elif d < 1.12 and dith(x, y) < 0.5: px[x, y] = C('e83b3b') if dith(x + 1, y) < 0.3 else C('6e2727')


def scorch(px, cx, cy, r):
    for y in range(cy - r // 2, cy + r // 2):
        for x in range(cx - r, cx + r):
            if 0 <= x < W and 0 <= y < HT and ((x - cx) / r) ** 2 + ((y - cy) / (r / 2)) ** 2 < 1 and dith(x, y) < 0.5:
                px[x, y] = C('2e222f' if dith(x + 1, y) < 0.5 else '3e3546')
    rubble(px, cx, cy, r // 2)


def rubble(px, cx, cy, r):
    for _ in range(r):
        x, y = cx + random.randint(-r * 2, r * 2), cy + random.randint(-r // 2, r // 2)
        if 1 <= x < W - 2 and 1 <= y < HT - 1:
            px[x, y] = C('625565'); px[x + 1, y] = C('3e3546'); px[x, y - 1] = C('9babb2')


def dead_tree(im):
    """The suburb's tree in the time of distress: the crown is gone; the trunk stays and bare branches are drawn
    by hand (outlined, forking upward)."""
    a = np.array(quant(im)).astype(int)
    h, w = a.shape[:2]
    cut = int(h * 0.66)
    leaf = (a[..., 1] > a[..., 0] + 6) & (a[..., 3] > 0)
    a[leaf, 3] = 0
    a[:cut, :, 3] = 0
    trunk = [x for x in range(w) if a[h - 30, x, 3]]
    t0, t1 = (min(trunk) - 6, max(trunk) + 6) if trunk else (0, w)
    a[cut:h - 24, :t0, 3] = 0                                     # the low rim of the old crown
    a[cut:h - 24, t1:, 3] = 0
    out = Image.fromarray(a.astype(np.uint8)).copy()
    px = out.load()
    rng = random.Random(5)
    xs = [x for x in range(w) if a[cut + 2, x, 3]]
    cx = (min(xs) + max(xs)) // 2 if xs else w // 2

    def branch(x, y, ang, length, width):
        for i in range(length):
            x += np.cos(ang); y -= np.sin(ang)
            for d in range(-width, width + 1):
                X, Y = int(x) + d, int(y)
                if 0 <= X < w and 0 <= Y < h:
                    px[X, Y] = C('2e222f') if abs(d) == width else C('4c3e24' if d < 0 else '676633')
        if length > 10:
            for da in (-0.5, 0.45):
                branch(x, y, ang + da + rng.uniform(-0.15, 0.15), int(length * 0.62), max(1, width - 1))
    for ang, ln in ((1.25, 34), (1.9, 30), (1.55, 40), (0.9, 26), (2.25, 24)):
        branch(cx, cut + 4, ang, ln, 2)
    return keep_main(out, 0.1)


def props():
    b = lambda n: Image.open(EXT + f'buildings/{n}.png').convert('RGBA')
    p = lambda n: Image.open(EXT + f'props/{n}.png').convert('RGBA')
    out = {'house_a': darken(b('house_dunmore_night'), 0.9), 'house_b': darken(b('house_hale_night'), 0.9),
           'house_c': darken(b('house_okoro'), 0.72), 'store': darken(b('store_ridge_mart_dark'), 0.85)}
    out['house_a_m'] = mirror(darken(b('house_dunmore'), 0.62))           # a dark house: nobody home
    out['house_b_m'] = mirror(out['house_b'])
    out['house_c_m'] = mirror(out['house_c'])
    out['house_c_dark'] = darken(b('house_okoro'), 0.55)
    for n in ('car_wreck_burned', 'car_wreck', 'suv_red', 'van', 'streetlight', 'fence_picket_broken', 'fence_picket',
              'fence_chainlink', 'trash_can', 'hydrant', 'mailbox', 'recycling_bin', 'for_sale_sign', 'hedge', 'hedge_32'):
        out[n] = p(n)
    out['tree_dead'] = dead_tree(p('tree'))
    out['tree_dark'] = darken(p('tree'), 0.55)
    out['overpass'] = overpass()
    for n, (closed, opened) in {'crate': crate(False), 'lockbox': crate(True)}.items():
        out[n] = closed; out[n + '_open'] = opened
    out['waystone'], out['waystone_lit'] = waystone(False), waystone(True)
    out['store'] = store_roof_3q(out['store'])
    for n, im in out.items():
        im = to_style(n, im)
        im.save(G + n + '.png')
    if WORLD_TEST:
        test_house().save(G + 'house_test.png')


def to_style(name, im):
    """Michael is the reference: true scale, the world palette, a 1 px #2e222f outline."""
    base = name.replace('_m', '').replace('_dark', '')
    if base in style.PIECES:
        sc = style.PIECES[base][2]
        from fractions import Fraction
        f = Fraction(sc).limit_denominator(6)
        im = style.pixel_rescale(im, f.numerator, f.denominator)
    im = style.to_world_palette(im)
    if name not in ('overpass',):
        im = style.outline(im)
    return im


def store_roof_3q(im):
    """The store's flat roof was drawn straight down; seen from the 3/4 angle of the houses it is foreshortened:
    the roof rows (2..51) are halved and the parapet face kept."""
    a = np.array(im)
    roof = a[2:52][::2]
    out = np.concatenate([a[:2], roof, a[52:]], 0)
    return Image.fromarray(out)


def overpass():
    """The overpass deck seen from above: concrete with a dark lane line and parapets on both sides."""
    x0, x1, y0, y1 = OVERPASS
    w, h = x1 - x0, y1 - y0
    im = Image.new('RGBA', (w, h)); px = im.load()
    for y in range(h):
        for x in range(w):
            if x < 10 or x >= w - 10:
                c = '2e222f' if x in (0, w - 1) else ('c7dcd0' if x in (1, 2, w - 3, w - 2) else '9babb2')
            else:
                c = '7f708a' if dith(x, y) < 0.3 else '625565'
                if abs(x - w // 2) < 2 and (y // 24) % 2 == 0: c = 'f9c22b'
                if (y % 96) < 2: c = '3e3546'                       # expansion joints
            px[x, y] = C(c)
    return darken(im, 0.85)


def crate(metal):
    """A supply crate (wood) or a lockbox (metal, gold latch), closed and opened. 28x22."""
    def draw(opened):
        im = Image.new('RGBA', (28, 24)); px = im.load()
        body = ('7f708a', '625565', '9babb2') if metal else ('9e4539', '6e2727', 'cd683d')
        top = 6 if opened else 0
        for y in range(top, 24):
            for x in range(28):
                edge = x in (0, 27) or y in (top, 23)
                c = '2e222f' if edge else (body[2] if y < top + 4 else (body[1] if (x % 9 == 0 or y == 14) else body[0]))
                px[x, y] = C(c)
        if opened:
            for y in range(0, 6):
                for x in range(28):
                    px[x, y] = C('2e222f' if y in (0, 5) or x in (0, 27) else body[1])
            for x in range(4, 24):
                px[x, top + 2] = C('2e222f')
        else:
            for y in range(10, 15):
                for x in range(12, 16): px[x, y] = C('f9c22b' if metal else '4c3e24')
        return im
    return draw(False), draw(True)


def waystone(lit):
    """A plain standing stone that marks a way through (travel between found stones); a soft light when found."""
    im = Image.new('RGBA', (22, 44)); px = im.load()
    for y in range(44):
        half = 7 if y > 6 else 3 + y // 2
        for x in range(11 - half, 11 + half + 1):
            edge = x in (11 - half, 11 + half) or y == 0 or y == 43
            c = '2e222f' if edge else ('9babb2' if x < 11 else '7f708a')
            if lit and 14 <= y <= 30 and abs(x - 11) <= 1: c = 'fbff86' if y % 4 else 'f9c22b'
            px[x, y] = C(c)
    return im


def fence_run(art, x0, x1, base, gaps=()):
    w = Image.open(G + art + '.png').width - 2                        # the outline adds 1 px each side; pieces overlap it
    return [[art, x + w // 2, base, w, 10] for x in range(x0, x1, w) if not any(g0 <= x < g1 for g0, g1 in gaps)]


def layout():
    north = [list(h) for h in NORTH_ROW]
    if WORLD_TEST:
        north[0] = ['house_test', 290, 470, 470, 70]               # generated house beside the reused ones
    items = north + SOUTH_ROW + CARS
    items += fence_run('fence_picket_broken', 16, 1470, 664, gaps=((440, 540), (1000, 1064)))   # back fences, broken
    items += fence_run('fence_chainlink', 1632, 1920, 660) + fence_run('fence_picket', 1632, 1920, 300, gaps=((1700, 1764),))
    items += [['hedge', 560, 470, 56, 14], ['hedge', 1100, 470, 56, 14],
              ['tree_dead', 1840, 430, 26, 12], ['tree_dead', 1780, 860, 26, 12], ['tree_dead', 40, 1072, 26, 12],
              ['mailbox', 470, 478, 14, 8], ['trash_can', 1300, 905, 22, 10], ['recycling_bin', 1330, 905, 22, 10],
              ['hydrant', 1470, 506, 12, 8], ['for_sale_sign', 1660, 860, 14, 8], ['trash_can', 1350, 690, 22, 10]]
    for x, y, _, _, pole in LIGHTS:
        if pole: items.append(['streetlight', x, y + 170, 10, 8])
    items += HWY_CARS
    rng = random.Random(21)
    for x in range(HX + 60, W - 40, 150):                         # the embankment north of the highway
        if rng.random() < 0.6: items.append(['tree_dead', x + rng.randint(-30, 30), rng.randint(150, 320), 26, 12])
    for x in range(HX + 40, W - 40, 180):                         # the verge south of it
        if rng.random() < 0.45 and not 3260 < x < 3460: items.append(['tree_dead', x + rng.randint(-30, 30), rng.randint(960, 1040), 26, 12])
    items += fence_run('fence_chainlink', HX, 2400, 300) + fence_run('fence_chainlink', 3500, 3840, 300)
    for x in range(40, SW - 40, 120):                             # woods along the park's south edge
        items.append(['tree_dark' if rng.random() < 0.5 else 'tree_dead', x + rng.randint(-20, 20), rng.randint(2120, 2150), 26, 12])
    for y in range(1150, HT - 60, 120):                           # and its west edge
        items.append(['tree_dark' if rng.random() < 0.5 else 'tree_dead', rng.randint(30, 70), y, 26, 12])
    for y in range(1120, HT - 40, 110):                           # the treeline between park and rift, open at the path
        if not 1560 <= y <= 1740: items.append(['tree_dark' if rng.random() < 0.4 else 'tree_dead', SW + rng.randint(-20, 20), y, 26, 12])
    for x, y in ((700, 1250), (1150, 1300), (380, 1650), (1250, 1820), (640, 1640), (1600, 1900), (1000, 1980), (300, 1880),
                 (1700, 1200), (1820, 1420), (200, 1220), (1300, 1980), (560, 1800), (1750, 1780), (950, 1280)):
        items.append(['tree_dark' if (x + y) % 3 else 'tree_dead', x, y, 26, 12])
    items += [['hedge', 520, 1360, 56, 14], ['hedge', 1450, 1720, 56, 14], ['hedge_32', 860, 1700, 28, 12]]
    for x, y in ((2300, 1280), (2600, 2050), (3600, 1250), (3700, 1950), (2200, 1950)):   # burned stumps at the rift
        items.append(['tree_dead', x, y, 26, 12])
    return items


ZONE = {
    '_doc': 'Written by art/build_zone.py (edit there). props: [art, x, base y, footprint w, footprint h]; colliders [x,y,w,h];'
            ' lights [x, y, energy, kind]; packs and prayers are gameplay positions; zones: [x,y,w,h,verse key] captions;'
            ' chests [kind, x, y]; waystones [name, x, y]; overhead [art, x, y] drawn above everything.',
    'size': [W, HT], 'player_start': [760, 548], 'night': [0.17, 0.18, 0.3],
    'packs': [
        {'at': [400, 548], 'kinds': ['imp', 'imp', 'imp', 'cinder']},
        {'at': [1020, 548], 'kinds': ['locust', 'imp', 'imp', 'imp']},
        {'at': [1420, 560], 'kinds': ['brute', 'imp', 'imp']},
        {'at': [320, 985], 'kinds': ['imp', 'cinder', 'shade', 'imp']},
        {'at': [900, 985], 'kinds': ['brute', 'shade']},
        {'at': [1552, 780], 'kinds': ['caller', 'imp', 'imp']},
        {'at': [1700, 220], 'kinds': ['imp', 'imp', 'stalker']},
        {'at': [1800, 740], 'kinds': ['ravager', 'imp', 'imp']},
        {'at': [2250, 600], 'kinds': ['imp', 'imp', 'cinder', 'cinder', 'imp']},
        {'at': [2550, 450], 'kinds': ['ravager', 'shade', 'imp']},
        {'at': [2850, 660], 'kinds': ['locust', 'stalker', 'imp', 'imp']},
        {'at': [3200, 470], 'kinds': ['mauler', 'imp', 'imp', 'imp']},
        {'at': [3500, 640], 'kinds': ['caller', 'shade', 'imp']},
        {'at': [3700, 450], 'kinds': ['firehorse', 'imp', 'imp']},
        {'at': [2700, 200], 'kinds': ['imp', 'imp', 'imp', 'cinder']},
        {'at': [3300, 960], 'kinds': ['shade', 'shade', 'imp']},
        {'at': [1552, 1300], 'kinds': ['imp', 'imp', 'stalker']},
        {'at': [1100, 1500], 'kinds': ['brute', 'imp', 'imp', 'cinder']},
        {'at': [500, 1420], 'kinds': ['frog', 'imp', 'imp', 'cinder']},
        {'at': [300, 1750], 'kinds': ['mauler', 'imp', 'imp']},
        {'at': [800, 1880], 'kinds': ['shade', 'stalker', 'imp', 'imp']},
        {'at': [1500, 1680], 'kinds': ['ravager', 'cinder', 'cinder']},
        {'at': [2200, 1600], 'kinds': ['imp', 'imp', 'imp', 'imp', 'cinder']},
        {'at': [2550, 1350], 'kinds': ['frog', 'brute', 'imp']},
        {'at': [3500, 1400], 'kinds': ['firehorse', 'shade', 'imp']},
        {'at': [3550, 1900], 'kinds': ['locust', 'locust', 'shade']},
        {'at': [2500, 1950], 'kinds': ['ravager', 'imp', 'imp', 'imp']},
    ],
    'respawn_seconds': 30, 'respawn_min_distance': 700,
    'prayers': [
        {'at': [540, 985], 'person': 'res://art/people/pray_a.png', 'wave': ['imp', 'imp', 'imp', 'shade']},
        {'at': [2470, 960], 'person': 'res://art/people/pray_b.png', 'wave': ['brute', 'imp', 'imp', 'cinder']},
        {'at': [880, 1560], 'person': 'res://art/people/pray_c.png', 'wave': ['shade', 'caller', 'imp', 'imp', 'stalker']},
    ],
    'prayer_radius': 70,
    'final_pack': {'at': [3000, 1460], 'kinds': ['firehorse', 'locust', 'frog', 'shade', 'imp', 'imp', 'cinder']},
    'chests': [['lockbox', 420, 924],            # by the first house's garage door
               ['crate', 500, 690],              # by the store's back room door, behind it
               ['crate', 2775, 538],             # beside the wrecked van under the overpass
               ['crate', 600, 1372],             # an abandoned supply crate by the park hedge
               ['lockbox', 3640, 1262]],         # by a burned stump at the rift's edge
    'waystones': [['Main Street', 820, 640], ['Highway', 2240, 820], ['Park', 1480, 1440], ['The Rift', 2700, 1500]],
    'overhead': [['overpass', OVERPASS[0], OVERPASS[2]]],
    'zones': [[0, 0, SW, 468, 'terror_night'], [0, 468, SW, 160, 'struggle'], [0, 628, SW, 452, 'guard_ways'],
              [SW, 0, W - SW, SH, 'triumphed'], [0, SH, SW, HT - SH, 'pray_always'], [SW, SH, W - SW, HT - SH, 'abyss']],
}


def colliders():
    c = [[-40, -40, 40, HT + 80], [W, -40, 40, HT + 80], [-40, -40, W + 80, 100], [-40, HT, W + 80, 40]]
    for ry, gaps in ((RAIL_N, RAIL_GAPS_N), (RAIL_S, RAIL_GAPS_S)):   # guardrails with their gaps
        x = HX
        for g0, g1 in list(gaps) + [(W, W)]:
            c.append([x, ry, g0 - x, 10]); x = g1
    x = HX
    for g0, g1 in list(MEDIAN_GAPS) + [(W, W)]:
        c.append([x, MEDIAN[0] + 4, g0 - x, 12]); x = g1
    c += [[HX - 8, RAIL_N, 8, SIDE_N[0] - RAIL_N], [HX - 8, SIDE_S[1], 8, RAIL_S + 8 - SIDE_S[1]]]
    cx, cy, rx, ry = RIFT                                         # the chasm, as three stacked rects
    for k, f in ((0, 0.55), (1, 0.9), (2, 0.55)):
        hh = ry * 2 / 3
        y = cy - ry + k * hh
        c.append([cx - rx * f, y + 6, rx * 2 * f, hh - 6])
    return c


def main():
    os.makedirs(G, exist_ok=True)
    ground(); props()
    z = dict(ZONE)
    z['props'] = layout()
    z['colliders'] = colliders()
    z['lights'] = [[x, y, e, k] for x, y, e, k, _ in LIGHTS] + [[fx, fy, 1.3, 'fire'] for fx, fy in FIRES + FIRES_MORE] \
        + [[RIFT[0], RIFT[1], 2.0, 'rift']]
    z['fires'] = FIRES + FIRES_MORE
    z['rift'] = list(RIFT)
    json.dump(z, open('game/data/zone.json', 'w'), indent=1)
    print('zone ok', len(z['props']), 'props')


if __name__ == '__main__':
    main()
