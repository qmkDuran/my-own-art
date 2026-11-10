"""The city district below the garden heart (John 14:2; Rev 21:21, 24-26): the great street of gold running west to the
throne's light, dwellings with pearl doors on the street, a jasper balustrade over the city lying in light.
World layout: the garden is room (0,0); the district is rooms (0,1) and (1,1), i.e. x 0..1920, y 540..1080.
Writes game/art/district/: dbg.png (1920x540, drawn at world y 540), dwellings, gifts, bearer sheets,
layout.json; new residents (skin-shifted people) go to game/art/people/pNN.png."""
import json, os, random, sys
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
from common import C, OUT, H, dith, quant, snap_rgb, keep_main, FRAME
from upscale import upscale
from skin import skin_mask, skin_colours, shift_colour
from wall import STONES

D = 'game/art/district/'; os.makedirs(D, exist_ok=True)
W, HT = 1920, 540
OY = 540                                   # world y of the district's top edge
STREET = (250, 350)                        # great street, local y range
GARDEN_STREET = (432, 528)                 # the garden's north-south street comes down here
BALUSTRADE_Y = 412
HAZE_Y = 430
DWELLINGS = [('home_a', 'mansion_01', 230, 232), ('home_b', 'mansion_03', 740, 232),
             ('home_c', 'mansion_02', 1200, 232), ('home_d', 'mansion_00', 1660, 232)]   # name, src, centre x, base (local)
GIFTS = [('gift_chest', 'gifts_03'), ('gift_jar', 'gifts_17'), ('gift_fruit', 'gifts_27'),
         ('gift_cloth', 'gifts_33'), ('gift_incense', 'gifts_41'), ('gift_gems', 'gifts_63')]
SKIN_RAMP = ['fdcbb0', 'fca790', 'e6904e', 'cd683d', '9e4539', '6e2727']
random.seed(21)


YARD_BORDER = (238, 246)                   # low jasper border along the north side of the great street
SOUTH_BORDER = (355, 362)                  # and along its south side, in front of the terrace garden
SOUTH_GAPS = [(280, 320), (940, 980), (1600, 1640)]   # openings to the terrace and its view
FRUIT_TREES = [('fruit_tree_a', 'tree1', 0.6, 968, 206), ('fruit_tree_b', 'tree2', 0.55, 1432, 206),
               ('fruit_tree_a', 'tree1', 0.6, 1862, 206), ('fruit_tree_b', 'tree2', 0.55, 46, 206)]   # name, src, scale, x, base
FLOWER_BEDS = [(398, 150, 18, 60), (566, 150, 18, 60), (968, 226, 70, 6), (1432, 226, 64, 6), (1862, 226, 50, 6),
               (46, 226, 40, 6)]          # centre x, centre y, half width, half height (local)


def tiles(bg, names, y0, y1, x0=0, x1=W):
    """Same 32 px tile fill as the garden (art/build_scene.py), so textures continue across the screen seam."""
    ims = [Image.open(f'art/raw/tA_{i:02d}.png').convert('RGBA') for i in names]
    region = Image.new('RGBA', (W, HT))
    for ty in range(0, HT, 32):
        for tx in range(0, W, 32):
            region.paste(random.choice(ims), (tx, ty))
    bg.paste(region.crop((x0, y0, x1, y1)), (x0, y0))


LIGHTER = {H(a): C(b) for a, b in (('e6904e', 'f79617'), ('f79617', 'f9c22b'), ('f9c22b', 'fbb954'), ('fbb954', 'fbff86'), ('fbff86', 'ffffff'))}


def gardens(bg, px):
    """The yards are gardens: the garden's grass, with the garden's gold street continuing south between them."""
    tiles(bg, (8, 9, 12), 0, YARD_BORDER[0])
    tiles(bg, (8, 9, 12), SOUTH_BORDER[1], BALUSTRADE_Y)
    x0, x1 = GARDEN_STREET
    tiles(bg, (1, 1, 1, 1, 2), 0, YARD_BORDER[1], x0, x1)
    for y in range(0, YARD_BORDER[1]):
        for x in range(x0, x1):
            u = (x + int((y + OY) * 0.75)) % 211
            if (u < 9 or 15 <= u < 18) and px[x, y][:3] in LIGHTER: px[x, y] = LIGHTER[px[x, y][:3]]
        for xe in (x0 - 3, x1):                    # the garden street's edge bands, as in the garden
            px[xe, y] = OUT; px[xe + 1, y] = C('f9c22b'); px[xe + 2, y] = OUT


def street(px):
    """The great street: pure gold like transparent glass (Rev 21:21): bright, smooth, with long soft reflections,
    and jasper curbs set with gems."""
    y0, y1 = STREET
    for y in range(y0, y1):
        t = (y - y0) / (y1 - y0)
        for x in range(W):
            d = dith(x, y)
            col = 'fbff86'
            if d < 0.18 + 0.25 * t: col = 'fbb954'               # a touch deeper towards the near curb
            u = (x + int(y * 1.6)) % 173                          # long diagonal glints on the glass
            if u < 3: col = 'ffffff'
            elif u < 7 and d < 0.6: col = 'ffffff'
            if (x % 96 == 0 or (y - y0) % 50 == 0) and d < 0.5: col = 'f9c22b'   # faint joints, glassy not tiled
            px[x, y] = C(col)
    for yc in (y0 - 4, y1):
        for x in range(W):
            for k, col in enumerate((OUT, C('ffffff'), C('c7dcd0'), C('9babb2'), OUT)):
                px[x, yc + k] = col
        for gx in range(16, W, 64):
            d, m, l = (C(c) for c in STONES[(gx // 64) % 12])
            for dx, dy, col in ((0, 1, l), (1, 1, m), (0, 2, m), (1, 2, d)):
                px[gx + dx, yc + dy] = col


def low_border(px, y0, y1, gaps):
    """A low jasper garden border (top face + front face), open where walks and streets pass."""
    for x in range(W):
        if any(g0 <= x < g1 for g0, g1 in gaps): continue
        edge = any(x in (g0 - 1, g1) for g0, g1 in gaps)
        for k, y in enumerate(range(y0, y1)):
            col = (OUT, C('ffffff'), C('c7dcd0'), C('c7dcd0'), C('9babb2'), C('7f708a'), C('7f708a'), OUT)[k]
            px[x, y] = OUT if edge else col


def door_steps_and_walks(px, sizes):
    """Pearl steps at each door and a pearl walk across the garden to the great street; contact shadows ground the houses."""
    for name, _, cx, base in DWELLINGS:
        sw = int(sizes[name][0] * 0.94)
        for y in range(base - 4, base + 6):                       # soft shadow on the grass at the house's foot
            for x in range(cx - sw // 2, cx + sw // 2):
                if ((x - cx) / (sw / 2)) ** 2 + ((y - base) / 6) ** 2 <= 1 and dith(x, y) < 0.6:
                    px[x, y] = C('165a4c')
        for y in range(base + 6, YARD_BORDER[1]):                 # the walk
            for x in range(cx - 14, cx + 15):
                edge = x in (cx - 14, cx + 14)
                px[x, y] = OUT if edge else (C('c7dcd0') if (y + x // 10) % 6 == 0 else C('ffffff'))
        for k in range(3):                                        # three steps, widening downwards
            hw, y = 18 + 2 * k, base + 2 * k
            for x in range(cx - hw, cx + hw + 1):
                side = x in (cx - hw, cx + hw)
                px[x, y] = OUT if side else C('ffffff')          # tread
                px[x, y + 1] = OUT if side else C('9babb2')      # riser
            if k == 2:
                for x in range(cx - hw, cx + hw + 1): px[x, y + 2] = OUT


FLOW = [('f04f78', 'ed8099'), ('c32454', 'f04f78'), ('ffffff', 'fbff86'), ('f9c22b', 'fbff86'), ('a884f3', 'eaaded'), ('ea4f36', 'f68181')]


def flowers(px, blocked):
    """Flower beds in the yards and along the terrace garden."""
    def flower(x, y, c1, c2):
        for dx, dy, c in ((0, -1, c2), (-1, 0, c1), (1, 0, c1), (0, 1, c1), (0, 0, 'fbff86' if c1 != 'f9c22b' else 'f79617')):
            X, Y = x + dx, y + dy
            if 0 <= X < W and 0 <= Y < HT and not blocked[Y, X]: px[X, Y] = C(c)
    for cx, cy, hw, hh in FLOWER_BEDS:                              # a few rose clusters per bed, one colour each
        for _ in range(max(2, hw * hh // 180)):
            c1, c2 = random.choice(FLOW[:2] if random.random() < 0.6 else FLOW)
            ox, oy = cx + random.randint(-hw, hw), cy + random.randint(-hh, hh)
            for _ in range(9):
                flower(ox + random.randint(-6, 6), oy + random.randint(-3, 3), c1, c2)
    for x0 in range(20, W, 120):                                   # terrace garden: rose clusters along the border
        c1, c2 = random.choice(FLOW[:2] if random.random() < 0.6 else FLOW)
        oy = random.randint(SOUTH_BORDER[1] + 12, BALUSTRADE_Y - 14)
        for _ in range(10):
            flower(x0 + random.randint(-9, 9), oy + random.randint(-3, 3), c1, c2)


def terrace_walk(px, g0, g1):
    """A short pearl walk through each opening of the south border to the balustrade."""
    for y in range(SOUTH_BORDER[1] + 1, BALUSTRADE_Y - 3):           # pale jasper flagstones, like the riverside path
        row = y - SOUTH_BORDER[1] - 1
        for x in range(g0, g1):
            if x in (g0, g1 - 1): col = '239063'
            elif (x - g0 + (8 if (row // 10) % 2 else 0)) % 16 == 0 or row % 10 == 0: col = '9babb2'
            else: col = 'c7dcd0' if dith(x, y) < 0.85 else '92a984'
            px[x, y] = C(col)


def fruit_tree(src, scale):
    """A small fruit tree: the tree-of-life art reduced (box filter, palette snap) and re-outlined."""
    im = Image.open(f'game/art/{src}.png').convert('RGBA'); im = im.crop(im.getbbox())
    q = np.array(quant(im.resize((round(im.width * scale), round(im.height * scale)), Image.BOX)))
    out = np.zeros((q.shape[0] + 2, q.shape[1] + 2, 4), np.uint8); out[1:-1, 1:-1] = q
    a = out[..., 3] > 0; e = np.zeros_like(a)
    e[1:] |= a[:-1]; e[:-1] |= a[1:]; e[:, 1:] |= a[:, :-1]; e[:, :-1] |= a[:, 1:]
    out[e & ~a] = list(OUT[:3]) + [255]
    return Image.fromarray(out)


def distant_city(px):
    """Beyond the balustrade the city goes on and on (Rev 21:16): rows of jasper halls, gold domes and towers,
    the far rows small and pale up by the horizon light, the near rows larger below (Rev 21:23)."""
    rng = random.Random(16)
    top_limit = BALUSTRADE_Y + 18
    rows = [  # base y (local), scale, wall light/shade, roof light/shade, windows, outline, gap range
        (462, 0.4, ('ffffff', 'fbff86'), ('fbff86', 'fbb954'), 'fbff86', 'fbff86', (0, 8)),
        (482, 0.55, ('ffffff', 'c7dcd0'), ('fbff86', 'fbb954'), 'fbb954', 'c7dcd0', (4, 18)),
        (508, 0.75, ('ffffff', 'c7dcd0'), ('fbb954', 'f9c22b'), 'f9c22b', '9babb2', (10, 36)),
        (546, 1.0, ('c7dcd0', '9babb2'), ('f9c22b', 'f79617'), 'fbff86', '7f708a', (26, 64)),
    ]

    def put(x, y, c):
        if 0 <= x < W and top_limit <= y < HT: px[x, y] = C(c)

    for base, sc, wall, roof, win, line, gap in rows:             # far rows first; nearer rows hide their feet
        x = rng.randint(-30, 10)
        while x < W:
            kind = rng.choice(('hall', 'hall', 'dome', 'tower'))
            w = int({'hall': rng.randint(34, 60), 'dome': rng.randint(26, 40), 'tower': rng.randint(12, 18)}[kind] * sc)
            h = int({'hall': rng.randint(20, 30), 'dome': rng.randint(18, 26), 'tower': rng.randint(46, 66)}[kind] * sc)
            top = base - h
            for yy in range(top, HT):                                  # walls (down to the edge): lit left, shaded right
                for xx in range(x, x + w):
                    c = wall[1] if xx >= x + int(w * 0.7) else wall[0]
                    wy, wx = (yy - top) % max(5, int(9 * sc)), (xx - x) % max(4, int(7 * sc))
                    if 2 <= wy <= 2 + max(1, int(2 * sc)) and wx == max(2, int(3 * sc)) and x + 2 < xx < x + w - 3: c = win
                    if xx in (x, x + w - 1) or yy == top: c = line
                    put(xx, yy, c)
            cx = x + w / 2
            if kind == 'hall':                                         # low pitched gold roof
                rh = max(3, int(w * 0.22))
                for k in range(rh):
                    half = w / 2 + 1 - (rh - 1 - k) * (w / 2) / rh * 0.9
                    for xx in range(int(cx - half), int(cx + half) + 1):
                        put(xx, top - rh + k, roof[1] if xx > cx else roof[0])
                    put(int(cx - half) - 1, top - rh + k, line); put(int(cx + half) + 1, top - rh + k, line)
            elif kind == 'dome':                                       # gold dome on a drum
                r = w * 0.38
                for k in range(int(r) + 1):
                    half = (r * r - (r - k) ** 2) ** 0.5
                    for xx in range(int(cx - half), int(cx + half) + 1):
                        put(xx, top - int(r) + k, roof[1] if xx > cx + half * 0.2 else roof[0])
                put(int(cx), top - int(r) - 1, roof[0]); put(int(cx), top - int(r) - 2, 'ffffff')
            else:                                                      # tower with a gold spire
                rh = max(4, int(w * 1.1))
                for k in range(rh):
                    half = (k + 1) * (w / 2) / rh
                    for xx in range(int(cx - half), int(cx + half) + 1):
                        put(xx, top - rh + k, roof[1] if xx > cx else roof[0])
            x += w + rng.randint(int(gap[0] * sc), int(gap[1] * sc) + 1)
        for y in range(top_limit, HT):                                 # light over the rows behind, before nearer ones
            t = 1 - (y - top_limit) / (HT - top_limit)
            for x in range(W):
                if dith(x, y) < 0.12 * t: px[x, y] = C('ffffff')


def balustrade(px):
    """The jasper balustrade with gem posts at the terrace edge."""
    y0 = BALUSTRADE_Y
    for y in range(y0 + 18, HT):                                  # the light behind everything
        for x in range(W):
            px[x, y] = C('ffffff') if dith(x, y) < 0.6 else C('fbff86')
    distant_city(px)
    for x in range(W):
        for k, col in enumerate((OUT, C('ffffff'), C('c7dcd0'), C('c7dcd0'), C('9babb2'), OUT)):
            px[x, y0 + k] = col
        for k, col in enumerate((OUT, C('9babb2'), C('7f708a'), OUT)):
            px[x, y0 + 14 + k] = col
    for i, px0 in enumerate(range(8, W, 40)):                        # posts, each capped with a gem
        d, m, l = (C(c) for c in STONES[i % 12])
        for y in range(y0 - 3, y0 + 18):
            for x in range(px0, px0 + 7):
                edge = x in (px0, px0 + 6) or y in (y0 - 3, y0 + 17)
                px[x, y] = OUT if edge else (C('ffffff') if x < px0 + 3 else C('c7dcd0'))
        for dx, dy, col in ((2, -1, l), (3, -1, m), (4, -1, d), (3, -2, l)):
            px[px0 + dx, y0 + dy] = col


def dwellings():
    sizes = {}
    for name, src, *_ in DWELLINGS:
        im = quant(Image.open(f'art/raw/{src}.png'))
        im = upscale(im.crop(im.getbbox()))
        im = im.crop(im.getbbox())
        im.save(D + name + '.png'); sizes[name] = im.size
    return sizes


def gifts():
    out = {}
    for name, src in GIFTS:
        g = keep_main(quant(Image.open(f'art/raw/{src}.png')), 0.2)
        g = g.crop(g.getbbox()); g.save(D + name + '.png'); out[name] = g
    return out


def shift_skin(sheet, steps, source):
    """A new individual from an existing one: every skin pixel of `source` (art/skin.py) moved `steps` along the skin
    ladder (palette only), so the new person still has exactly one skin ramp."""
    a = np.array(sheet)
    m = skin_mask(a, skin_colours(source))
    src = a.copy()
    for c in {tuple(int(v) for v in p) for p in src[m][:, :3]}:
        a[m & (src[..., :3] == c).all(-1), :3] = shift_colour(c, steps)
    return Image.fromarray(a)


GIFT_BOXES = {}   # bearer -> [x0, y0, x1, y1] of the carried gift per walk frame (for tools/check_skin.py)


def bearer_sheet(walker, steps, gift, name=None):
    """A gift bearer: the walker's west walk with the gift carried before the chest; hero.png layout (all rows = side)."""
    src = shift_skin(Image.open(f'game/art/people/{walker}.png').convert('RGBA'), steps, walker)
    frames = []
    for i in range(8):
        f = src.crop((i * FRAME, 5 * FRAME, (i + 1) * FRAME, 6 * FRAME))
        b = f.getbbox()
        g = Image.new('RGBA', (FRAME, FRAME)); g.alpha_composite(f)
        gx, gy = max(0, b[0] - gift.width // 2 + 2), b[1] + 33 - gift.height // 2
        g.alpha_composite(gift, (gx, gy))   # carried before the chest
        if name: GIFT_BOXES.setdefault(name, []).append([gx, gy, gx + gift.width, gy + gift.height])
        frames.append(g)
    sh = Image.new('RGBA', (FRAME * 8, FRAME * 6))
    for r in range(6):
        row = frames if r in (3, 4, 5) else [frames[0]] * 4
        for i, f in enumerate(row): sh.alpha_composite(f, (i * FRAME, r * FRAME))
    return sh


RESIDENTS = [('p31', 'p01', 3), ('p32', 'p15', 3), ('p33', 'p05', -2), ('p34', 'p07', 1), ('p35', 'p10', -2)]
BEARERS = [('bearer_a', 'walkerA', 3, 'gift_chest'), ('bearer_b', 'walkerB', -2, 'gift_jar'),
           ('bearer_c', 'walkerA', -1, 'gift_fruit'), ('bearer_d', 'walkerB', 2, 'gift_cloth'),
           ('bearer_e', 'walkerA', 1, 'gift_incense'), ('bearer_f', 'walkerB', -1, 'gift_gems')]


MUSICIANS = [('p36', 'p05', 1, 'lyre'), ('p37', 'p07', -1, 'timbrel')]   # Ps 150:3-4, in a garden yard
INSTRUMENTS = {   # o outline, g gold, d deep gold, s string/skin highlight, b brown wood
    'lyre': ['g.....g',
             'gg...gg',
             '.g...g.',
             '.gdddg.',
             '.gs.sg.',
             '.gs.sg.',
             '.gs.sg.',
             '.gs.sg.',
             '..gdg..',
             '...g...'],
    'timbrel': ['.bbbb.',
                'bssssb',
                'bssssb',
                'bssssb',
                'bssssb',
                '.bbbb.'],
}
INSTR_COL = {'g': 'f9c22b', 'd': 'f79617', 's': 'fbff86', 'b': '9e4539'}


def instrument_sheet(src, steps, kind, source_name):
    a = np.array(shift_skin(Image.open(f'game/art/people/{src}.png').convert('RGBA'), steps, source_name))
    pat = INSTRUMENTS[kind]
    h, w = len(pat), len(pat[0])
    for r, view in ((2, 'side'), (0, 'front')):
        for c in range(4):
            f = a[r * 64:(r + 1) * 64, c * 64:(c + 1) * 64]
            sk = skin_mask(f, skin_colours('p00') | skin_colours('p05'))
            ys, xs = np.nonzero(f[..., 3])
            mid = (ys.min() + ys.max()) // 2
            hy, hx = np.nonzero(sk[mid - 4:mid + 10])      # the hands: skin pixels around the middle of the figure
            if not len(hy): continue
            cy, cx = int(hy.mean()) + mid - 4, int(hx.mean())
            x0 = cx - (w - 1 if view == 'side' else w // 2)            # side view: held out in front (to the left)
            y0 = cy - h + 3
            for yy in range(-1, h + 1):
                for xx in range(-1, w + 1):
                    inside = 0 <= yy < h and 0 <= xx < w and pat[yy][xx] != '.'
                    near = any(0 <= yy + dy < h and 0 <= xx + dx < w and pat[yy + dy][xx + dx] != '.'
                               for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)))
                    X, Y = x0 + xx, y0 + yy
                    if not (0 <= X < 64 and 0 <= Y < 64) or sk[Y, X]: continue
                    if inside:
                        ch = pat[yy][xx]
                        if ch == 's' and c % 2 == 1 and yy % 2: ch = 'g'            # strings shimmer
                        f[Y, X, :3] = C(INSTR_COL[ch])[:3]; f[Y, X, 3] = 255
                    elif near and not f[Y, X, 3]:
                        f[Y, X, :3] = OUT[:3]; f[Y, X, 3] = 255
    return Image.fromarray(a)


def people(gift_imgs):
    for new, src, steps, kind in MUSICIANS:
        instrument_sheet(src, steps, kind, src).save('game/art/people/' + new + '.png')
    for new, old, steps in RESIDENTS:
        shift_skin(Image.open(f'game/art/people/{old}.png').convert('RGBA'), steps, old).save('game/art/people/' + new + '.png')
    for name, walker, steps, gift in BEARERS:
        bearer_sheet(walker, steps, gift_imgs[gift], name).save(D + name + '.png')


def main():
    bg = Image.new('RGBA', (W, HT)); px = bg.load()
    gardens(bg, px); street(px)
    sizes = dwellings()
    walks = [(cx - 14, cx + 15) for _, _, cx, _ in DWELLINGS]
    low_border(px, YARD_BORDER[0], YARD_BORDER[1], walks + [(GARDEN_STREET[0] - 3, GARDEN_STREET[1] + 3)])
    low_border(px, SOUTH_BORDER[0], SOUTH_BORDER[1] + 1, SOUTH_GAPS)
    door_steps_and_walks(px, sizes)
    trees = []
    for name, src, sc, x, base in FRUIT_TREES:
        t = fruit_tree(src, sc); t.save(D + name + '.png'); trees.append([name, x, OY + base])
    blocked = np.zeros((HT, W), bool)
    for _, _, cx, base in DWELLINGS: blocked[:, cx - 16:cx + 17] |= np.arange(HT)[:, None] >= base - 2
    blocked[YARD_BORDER[0]:SOUTH_BORDER[1] + 1] = True
    for g0, g1 in SOUTH_GAPS: blocked[SOUTH_BORDER[1]:BALUSTRADE_Y, g0 - 4:g1 + 4] = True
    for g0, g1 in SOUTH_GAPS: terrace_walk(px, g0, g1)
    blocked[:, GARDEN_STREET[0] - 3:GARDEN_STREET[1] + 3] = True
    flowers(px, blocked)
    balustrade(px)
    snap_rgb(bg).save(D + 'dbg.png')
    people(gifts())
    layout = {
        'origin_y': OY, 'size': [W, HT], 'street': [OY + STREET[0], OY + STREET[1]], 'balustrade_y': OY + BALUSTRADE_Y,
        'dwellings': [[n, cx, OY + base, sizes[n][0]] for n, _, cx, base in DWELLINGS],
        'fruit_trees': trees,
        'yard_border': [OY + YARD_BORDER[0], OY + YARD_BORDER[1]], 'south_border': [OY + SOUTH_BORDER[0], OY + SOUTH_BORDER[1] + 1],
        'north_gaps': [[cx - 14, cx + 15] for _, _, cx, _ in DWELLINGS] + [[GARDEN_STREET[0] - 3, GARDEN_STREET[1] + 3]],
        'south_gaps': SOUTH_GAPS,
        'gift_boxes': GIFT_BOXES,
    }
    json.dump(layout, open(D + 'layout.json', 'w'), indent=1)
    print('district ok', sizes)


if __name__ == '__main__':
    main()
