"""The new earth outside the city (Isa 11, 35, 55, 65; Rev 21:1, 24-26) as a 1920x1080 land (2x2 screens, shown
whole by the 1x overview zoom). Hand-composed from PixelLab pieces. Writes game/art/earth/: ebg.png, sprites,
layout.json (positions/collision used by game/scripts/scenes/earth.gd)."""
import json, math, os, random, sys
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
from common import C, OUT, dith, quant, erode_ground, snap_rgb, keep_main
from upscale import upscale
from wall import WALL_BOTTOM, GATE_PASSAGE_FROM_LEFT, draw_sky, add_city_top

D = 'game/art/earth/'; os.makedirs(D, exist_ok=True)
W, H = 1920, 1080
GATE_CX = 960
GATE_X = GATE_CX - GATE_PASSAGE_FROM_LEFT
PASSAGE = [GATE_CX - 20, GATE_CX + 20]
ROAD_W, ROAD_E = 650, 650                       # the cross road (west / east of the main path)
random.seed(11)
GROUND = ['239063', '1ebc73', '91db69', '165a4c', '547e64', '374e4a', '676633', 'a2a947', 'cddf6c', '92a984', 'b2ba90', 'd5e04b', '313638']

# ================================================================== where everything stands (feet / base positions)
HOUSES = [('cottage_a', 'house2x_00', 190, 618, 190), ('frame', 'frame2x_00', 480, 618, 480), ('gable_b', 'house2x_02', 770, 618, 776),
          ('cottage_c', 'house2x_03', 1200, 618, 1200), ('gable_d', 'house2x_01', 1500, 618, 1506)]   # name, src, x, base y, door x
VINE_ROWS = [[1150, 760], [1150, 850], [1150, 940], [1150, 1030]]
VINE_SEGMENTS = 5
HAY = [720, 930]
ANIMALS = [['leopard', 380, 760], ['kid', 420, 766], ['wolf', 600, 790], ['lamb', 640, 796],
           ['calf', 360, 960], ['younglion', 400, 966], ['ox', 668, 936], ['lion', 772, 934],
           ['cow', 500, 1044], ['bear', 568, 1040]]
TREES = [['ftree2', 80, 300], ['ftree1', 1090, 300], ['ftree2', 1880, 560], ['ftree1', 880, 1040], ['ftree2', 1880, 1000],
         ['ftree1', 1700, 300]]


def ground_and_light(bg, px):
    """Meadow tiles everywhere below the wall, with the city's light spilling over the ground by the wall (Rev 21:24)."""
    grass = [Image.open(f'art/raw/tA_{i:02d}.png').convert('RGBA') for i in (8, 9, 12)]
    for ty in range(WALL_BOTTOM // 32, H // 32 + 1):
        for tx in range(W // 32):
            bg.paste(random.choice(grass), (tx * 32, ty * 32))
    for y in range(WALL_BOTTOM, WALL_BOTTOM + 40):
        for x in range(W):
            if dith(x, y) < (1 - (y - WALL_BOTTOM) / 40) * 0.5:
                px[x, y] = C('91db69') if dith(x + 1, y) < 0.5 else C('cddf6c')


def disc_line(mask, pts, r):
    for cx, cy in pts:
        for y in range(max(0, int(cy - r)), min(H, int(cy + r) + 1)):
            dx = math.sqrt(max(0, r * r - (y - cy) ** 2))
            x0, x1 = max(0, int(cx - dx)), max(0, min(W, int(cx + dx) + 1))
            if x1 > x0: mask[y, x0:x1] = True


def path_mask():
    """Main path from the gate to the south edge, the cross road, and a short path from every door to the road."""
    m = np.zeros((H, W), bool)
    disc_line(m, [(GATE_CX + 12 * math.sin((y - WALL_BOTTOM) / 90.0), y) for y in range(WALL_BOTTOM, H + 1)], 19)
    disc_line(m, [(x, ROAD_W + 6 * math.sin(x / 45.0)) for x in range(0, GATE_CX)], 15)
    disc_line(m, [(x, ROAD_E + 5 * math.sin(x / 40.0)) for x in range(GATE_CX, W + 1)], 15)
    for _, _, _, base, door_x in HOUSES:
        m[base - 14:ROAD_W, door_x - 7:door_x + 8] = True
    return m


def stream_mask(paths):
    """A stream (no sea, Rev 21:1; streams in the desert, Isa 35:6) from the west edge to the south edge."""
    s = np.zeros((H, W), bool)
    pts = []
    for k in range(600):
        t = k / 599
        pts.append((-10 + 260 * t, 700 + 380 * t ** 1.3 + 10 * math.sin(t * 8)))
    for (cx, cy), k in zip(pts, range(600)):
        disc_line(s, [(cx, cy)], 18 + 3 * math.sin(k / 60))
    return s & ~paths


def paint_path(px, m):
    rnd = np.random.default_rng(3)
    noise = rnd.random((H, W)) < 0.25
    for y in range(WALL_BOTTOM, H):
        for x in range(W):
            if not m[y, x]: continue
            border = not (m[y - 1, x] and m[min(H - 1, y + 1), x] and m[y, max(0, x - 1)] and m[y, min(W - 1, x + 1)])
            if border and noise[y, x]: continue
            n = dith(x, y)
            col = 'e6904e' if n < 0.08 else ('fbb954' if n < 0.55 else 'f9c22b')   # warm sandy earth
            if (x * 7 + y * 13) % 97 == 0: col = 'c7dcd0'                         # pebbles
            px[x, y] = C(col)
    for y in range(WALL_BOTTOM + 1, H - 1):                                       # darker grass rim along the path
        for x in range(1, W - 1):
            if not m[y, x] and (m[y - 1, x] or m[y + 1, x] or m[y, x - 1] or m[y, x + 1]) and dith(x, y) < 0.5:
                px[x, y] = C('239063')


def paint_stream(px, s):
    for y in range(WALL_BOTTOM, H):
        for x in range(W):
            if not s[y, x]: continue
            edge = not (s[y - 1, x] and s[min(H - 1, y + 1), x] and s[y, max(0, x - 1)] and s[y, min(W - 1, x + 1)])
            if edge: px[x, y] = C('9babb2') if dith(x, y) < 0.6 else C('c7dcd0')   # pebbly bank
            else: px[x, y] = C('4d9be6') if not s[y - 2, x] else (C('8fd3ff') if dith(x, y) > 0.2 else C('ffffff'))


FLOW = [('f04f78', 'ed8099'), ('c32454', 'f04f78'), ('ffffff', 'fbff86'), ('f9c22b', 'fbff86'), ('a884f3', 'eaaded'), ('ea4f36', 'f68181')]


def paint_flowers(px, blocked):
    """The desert shall blossom as the rose (Isa 35:1): rose patches and scattered blossoms."""
    def flower(x, y, c1, c2):
        for dx, dy, c in ((0, -1, c2), (-1, 0, c1), (1, 0, c1), (0, 1, c1), (0, 0, 'fbff86' if c1 != 'f9c22b' else 'f79617')):
            X, Y = x + dx, y + dy
            if 0 <= X < W and WALL_BOTTOM + 4 <= Y < H and not blocked[Y, X]: px[X, Y] = C(c)
    for _ in range(120):
        cx, cy = random.randint(10, W - 10), random.randint(WALL_BOTTOM + 30, H - 6)
        c1, c2 = random.choice(FLOW[:2] if random.random() < 0.6 else FLOW)
        for _ in range(random.randint(4, 9)):
            flower(cx + random.randint(-14, 14), cy + random.randint(-7, 7), c1, c2)
    for _ in range(520):
        c1, c2 = random.choice(FLOW)
        flower(random.randint(4, W - 4), random.randint(WALL_BOTTOM + 20, H - 3), c1, c2)


def contact_shadows(px, m, spots):
    """Soft dithered shadows so buildings and the hay sit on the ground."""
    for sx, sy, sw in spots:
        for y in range(sy - 8, sy + 5):
            for x in range(sx - sw // 2, sx + sw // 2):
                if 0 <= x < W and 0 <= y < H and ((x - sx) / (sw / 2)) ** 2 + ((y - sy + 2) / 7) ** 2 <= 1 \
                        and not m[y, x] and dith(x, y) < 0.55:
                    px[x, y] = C('165a4c')


# ================================================================== sprites
def save(im, name): im.save(D + name + '.png'); return im


def animal(src, flip=False):
    im = erode_ground(quant(Image.open(f'art/raw/{src}.png')), GROUND)
    if flip: im = im.transpose(Image.FLIP_LEFT_RIGHT)
    b = im.getbbox(); return im.crop((0, 0, im.width, b[3] + 1))


def two_frames(im, head_left, head_frac=0.42, dy=1):
    """Frame 0 as is, frame 1: the head end lowered (grazing/breathing)."""
    a = np.array(im); h, w = a.shape[:2]
    b = a.copy(); cut = int(w * head_frac)
    for x in (range(0, cut) if head_left else range(w - cut, w)):
        col = a[:, x].copy(); b[:, x] = 0; b[dy:, x] = col[:h - dy]
    strip = Image.new('RGBA', (w * 2, h)); strip.alpha_composite(im, (0, 0)); strip.alpha_composite(Image.fromarray(b), (w, 0))
    return strip


def build_animals():
    """A animals face left, B animals face right (as generated). Isa 11:6-7; 65:25."""
    sizes = {}
    for name, src, flip, head_left, eat in (
            ('lion', 'animA_00', False, True, True), ('ox', 'animA_05', True, False, True),
            ('wolf', 'animA_15', True, False, False), ('lamb', 'animB_00', True, True, False),
            ('leopard', 'animA_14', False, True, False), ('kid', 'animB_02', True, True, False),
            ('calf', 'animB_12', False, False, False), ('younglion', 'animB_14', True, True, False),
            ('bear', 'animA_01', False, True, True), ('cow', 'animA_10', True, False, True)):
        im = animal(src, flip)
        save(two_frames(im, head_left, 0.42 if eat else 0.35, 2 if eat else 1), 'an_' + name)
        sizes[name] = {'w': im.width, 'h': im.height}
    return sizes


def build_hay():
    """A proper straw stack the lion and the ox eat from together (Isa 65:25)."""
    HW, HH = 64, 32
    hay = Image.new('RGBA', (HW, HH)); hp_ = hay.load()
    cxh, base = HW / 2, HH - 4
    def in_pile(x, y):
        return ((x - cxh) / 27.0) ** 2 + ((y - base) / 22.0) ** 2 <= 1 and y <= base + 1
    for y in range(HH):
        for x in range(HW):
            if in_pile(x, y):
                edge = not (in_pile(x - 1, y) and in_pile(x + 1, y) and in_pile(x, y - 1))
                band = (int(y + 0.6 * abs(x - cxh) * 0.3) + (x // 3)) % 5
                light = (x - cxh) < 6 and y < base - 8
                col = 'fbff86' if (light and band < 2) else ('f9c22b' if band < 3 else ('f79617' if band < 4 else 'e6904e'))
                hp_[x, y] = OUT if edge else C(col)
    for _ in range(40):
        x = random.randint(8, HW - 12); y = random.randint(base - 18, base - 2)
        if not in_pile(x, y): continue
        dx = random.choice((-1, 1))
        for t in range(4):
            X, Y = x + dx * t, y - (t // 2)
            if in_pile(X, Y) and hp_[X, Y][:3] != OUT[:3]: hp_[X, Y] = C('fbff86' if t < 2 else 'f9c22b')
    for _ in range(14):
        x = random.choice(list(range(1, 8)) + list(range(HW - 9, HW - 2))) if random.random() < 0.6 else random.randint(4, HW - 6)
        y = random.randint(base + 1, HH - 1)
        for t in range(3):
            X = min(HW - 1, x + t)
            if hay.getpixel((X, y))[3] == 0: hp_[X, y] = C('f9c22b' if t else 'fbff86')
    save(hay, 'hay')


def build_houses():
    """Houses at true scale (Isa 65:21): Scale2x of the straight-front generations, so a door is a little taller than a man."""
    sizes = {}
    for name, src, *_ in HOUSES:
        im = erode_ground(quant(Image.open(f'art/raw/{src}.png')), GROUND, 120)
        im = upscale(im.crop(im.getbbox()))
        im = im.crop(im.getbbox())
        save(im, name); sizes[name] = im.size
    return sizes


VINE_RAISE = 16            # rows of trunk and post added by hand: the trellis stands ~1.2x a person's height
VINE_TRUNK_BAND = (46, 51) # rows of bare trunks and posts that are repeated


def build_vines():
    """A straight-front trellis row (matches the straight-front houses), raised by hand to ~1.2x a person's height."""
    v = erode_ground(quant(Image.open('art/raw/vines_00.png')), GROUND, 53)
    a = np.array(v.crop(v.getbbox()))
    t0, t1 = VINE_TRUNK_BAND
    band = a[t0:t1]
    reps = [band[k % len(band)] for k in range(VINE_RAISE)]
    a = np.concatenate([a[:t1], np.stack(reps), a[t1:]], 0)
    save(keep_main(Image.fromarray(a), 0.01), 'vines')   # drop stray ground specks


LEAF = {C(c)[:3] for c in ('1ebc73', '239063', '165a4c', '91db69')}


def field_tree(src):
    """The fruit trees with fruit recoloured to leaves, 8 sway frames: the trees of the field clap their hands (Isa 55:12)."""
    a = np.array(Image.open(src).convert('RGBA'))
    keep = LEAF | {C(c)[:3] for c in ('2e222f', '313638', '374e4a', '547e64', '92a984', 'cddf6c', '0b5e65', '0b8a8f', '1ebc73',
                                       'ab947a', '966c6c', '4c3e24', '676633', '3e3546', '625565', '8ff8e2', '30e1b9', 'b2ba90', 'a2a947')}
    for y in range(0, 88):
        for x in range(a.shape[1]):
            if a[y, x, 3] and tuple(a[y, x, :3]) not in keep:
                a[y, x, :3] = C('239063' if (x + y) % 3 else '1ebc73')[:3]
    frames = []
    for amp in (0, 1.5, 2.5, 1.5, 0, -1.5, -2.5, -1.5):
        b = np.zeros_like(a)
        for y in range(a.shape[0]):
            dx = int(round(amp * max(0.0, (88 - y) / 88)))          # canopy moves, trunk stays rooted
            if dx >= 0: b[y, dx:] = a[y, :a.shape[1] - dx]
            else: b[y, :dx] = a[y, -dx:]
        frames.append(b)
    return Image.fromarray(np.concatenate(frames, 1))


def pixel_sprite(rows, palette):
    w = max(len(r) for r in rows)
    im = Image.new('RGBA', (w, len(rows))); p = im.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != '.': p[x, y] = C(palette[ch])
    return im


def build_props():
    save(field_tree('game/art/tree1.png'), 'ftree1'); save(field_tree('game/art/tree2.png'), 'ftree2')
    ham = ["...XXX..........", "...XOX..........", "...XOX..XXXXX...", "XXXXOXXXXGGGXXXX", "XGGGGGGXXGGGXOOO", "XXXXXXXXXXXXXXXX"]
    save(pixel_sprite(ham, {'X': '2e222f', 'O': '966c6c', 'G': '9babb2'}), 'hammer')   # 2 frames: raised, struck
    bask = ["..XXXXXXX..", ".XPpPpPpPX.", "XPpPPpPpPpX", "XOOOOOOOOOX", "XoOoOoOoOoX", ".XOOOOOOOX.", "..XXXXXXX.."]
    save(pixel_sprite(bask, {'X': '2e222f', 'P': '6b3e75', 'p': '905ea9', 'O': 'cd683d', 'o': '9e4539'}), 'basket')


def stream_rects(s):
    """Stream collision: one box per 6-px band of rows, matching the drawn water."""
    rects = []
    for y0 in range(WALL_BOTTOM, H, 6):
        xs = np.nonzero(s[y0:y0 + 6].any(0))[0]
        if len(xs) and xs.max() - xs.min() > 6: rects.append([int(xs.min()) + 3, y0, int(xs.max() - xs.min()) - 5, 6])
    return rects


def main():
    bg = Image.new('RGBA', (W, H)); px = bg.load()
    draw_sky(px, W)
    ground_and_light(bg, px)
    paths = path_mask(); water = stream_mask(paths)
    paint_path(px, paths); paint_stream(px, water)
    paint_flowers(px, paths | water)
    house_sizes = build_houses()
    contact_shadows(px, paths, [(x, base, int(house_sizes[n][0] * 0.9)) for n, _, x, base, _ in HOUSES] + [(HAY[0], HAY[1], 60)])
    add_city_top(bg, GATE_X)
    snap_rgb(bg).save(D + 'ebg.png')
    np.save(D + '_path.npy', paths); np.save(D + '_stream.npy', water)
    sizes = build_animals(); build_hay(); build_vines(); build_props()
    layout = {
        'map_size': [W, H], 'gate_x': GATE_X, 'wall_bottom': WALL_BOTTOM, 'passage': PASSAGE,
        'houses': [[n, x, base] for n, _, x, base, _ in HOUSES],
        'vine_rows': VINE_ROWS, 'vine_segments': VINE_SEGMENTS, 'hay': HAY,
        'animals': ANIMALS, 'trees': TREES, 'animals_size': sizes, 'stream_rects': stream_rects(water),
    }
    json.dump(layout, open(D + 'layout.json', 'w'), indent=1)
    print('earth ok', house_sizes)


if __name__ == '__main__':
    main()
