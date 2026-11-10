"""The zone: a ruined suburb at night (2x2 screens, 1920x1080), built from Project R's exterior art (art/ext/, read-only
copies), darkened and ruined by hand. One source of truth: this script writes the ground image, the prop sprites AND
game/data/zone.json (props with footprints, lights, fires, packs, prayers, captions). Run from heaven/arpg/.

Layout (y): north row of houses (fronts on the main street) | sidewalk | main street | sidewalk | back fences and
backyards of the south row | south row of smaller houses and the store (fronts on the lower street) | sidewalk |
lower street | sidewalk. A side street joins the two streets on the east, with a corner lot on each side."""
import json, os, random, sys
import numpy as np
from PIL import Image
HEAVEN = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
sys.path.insert(0, os.path.join(HEAVEN, 'art'))
from common import C, H, quant, keep_main, dith   # noqa: E402

EXT = 'art/ext/'
G = 'game/art/zone/'
W, HT = 1920, 1080
SIDE_N = (468, 500); ROAD = (500, 596); SIDE_S = (596, 628)                  # main street
SIDE_N2 = (905, 937); ROAD2 = (937, 1033); SIDE_S2 = (1033, 1065)           # lower street
CROSS = (1504, 1600)                                                       # side street (x), main street -> lower street
random.seed(11)

# [art, x, base y, footprint w, footprint h]
NORTH_ROW = [['house_a', 200, 470, 290, 60], ['house_b', 560, 470, 290, 60], ['house_b_m', 920, 470, 290, 60],
             ['house_a_m', 1280, 470, 290, 60]]
SOUTH_ROW = [['house_c', 190, 905, 310, 56], ['store', 540, 905, 220, 50], ['house_c_m', 860, 905, 310, 56],
             ['house_c_dark', 1290, 905, 310, 56]]
CARS = [['car_wreck_burned', 700, 586, 96, 30], ['car_wreck', 1180, 576, 96, 30], ['van', 1240, 1010, 96, 30],
        ['suv_red', 1700, 470, 96, 30], ['car_wreck', 330, 1015, 96, 30]]
FIRES = [[700, 560], [1340, 700], [1560, 1000]]                            # the wreck, a back yard, the side street
LIGHTS = [[380, 330, 1.0, 'lamp', True], [1100, 330, 1.0, 'lamp', False], [700, 760, 0.8, 'flicker', True],
          [1650, 760, 1.0, 'lamp', True]]                                    # x, y, energy, kind, pole drawn


def tile(name): return Image.open(EXT + f'tiles/outdoor/{name}.png').convert('RGBA')


def darken(im, k):
    a = np.array(im).astype(float); a[..., :3] *= k
    return quant(Image.fromarray(a.clip(0, 255).astype(np.uint8)))


def mirror(im): return im.transpose(Image.FLIP_LEFT_RIGHT)


def street(bg, y0, y1, x0=0, x1=W):
    road = [tile('road_0')] * 6 + [tile('road_crack'), tile('road_patch')]
    for tx in range(x0, x1, 32):
        for ty in range(y0, y1, 32): bg.alpha_composite(random.choice(road), (tx, ty))


def sidewalk_h(bg, y, x0=0, x1=W):
    for tx in range(x0, x1, 32): bg.alpha_composite(tile('sidewalk_0' if tx % 96 else 'sidewalk_1'), (tx, y))


def ground():
    bg = Image.new('RGBA', (W, HT))
    grass = [tile('grass_0'), tile('grass_1'), tile('grass_2')]
    for ty in range(0, HT, 32):
        for tx in range(0, W, 32):
            bg.alpha_composite(random.choice(grass), (tx, ty))
    street(bg, *ROAD); street(bg, *ROAD2); street(bg, SIDE_S[1], SIDE_N2[0], *CROSS)
    for y in (SIDE_N[0], SIDE_S[0], SIDE_N2[0], SIDE_S2[0]): sidewalk_h(bg, y)
    for ty in range(SIDE_S[1], SIDE_N2[0], 32):
        bg.alpha_composite(tile('sidewalk_0'), (CROSS[0] - 32, ty)); bg.alpha_composite(tile('sidewalk_0'), (CROSS[1], ty))
    for tx in range(CROSS[0], CROSS[1], 32):                     # the side street runs through both sidewalks
        street(bg, SIDE_S[0], SIDE_S[1], tx, tx + 32); street(bg, SIDE_N2[0], SIDE_N2[1], tx, tx + 32)
    for y0, y1 in (ROAD, ROAD2):
        for tx in range(64, W, 96):
            if not CROSS[0] - 32 <= tx < CROSS[1]: bg.alpha_composite(tile('road_line_h'), (tx, (y0 + y1) // 2 - 16))
    for x in (CROSS[0] - 64, CROSS[1] + 16):                     # crosswalks at the junction
        for ty in range(ROAD[0], ROAD[1], 32): bg.alpha_composite(tile('road_crosswalk'), (x, ty))
    px = bg.load()
    for fx, fy in FIRES + [[c[1], c[2] - 10] for c in CARS]:     # scorch and rubble grouped where things burned or crashed
        scorch(px, fx, fy + 14, random.randint(26, 40))
    for _ in range(10):                                          # loose debris along the curbs
        x = random.randint(20, W - 20); y = random.choice((SIDE_N[1] + 3, SIDE_S[0] - 4, SIDE_N2[1] + 3, SIDE_S2[0] - 4))
        rubble(px, x, y, 6)
    bg.save(G + 'ground.png')


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
    for n, im in out.items(): im.save(G + n + '.png')


def fence_run(art, x0, x1, base, gaps=()):
    return [[art, x + 16, base, 32, 10] for x in range(x0, x1, 32) if not any(g0 <= x < g1 for g0, g1 in gaps)]


def layout():
    items = NORTH_ROW + SOUTH_ROW + CARS
    items += fence_run('fence_picket_broken', 16, 1470, 664, gaps=((360, 420), (1000, 1064)))   # back fences, broken
    items += fence_run('fence_chainlink', 1632, 1920, 660) + fence_run('fence_picket', 1632, 1920, 300, gaps=((1700, 1764),))
    items += [['hedge', 380, 470, 56, 14], ['hedge', 740, 470, 56, 14], ['hedge', 1100, 470, 56, 14],
              ['tree_dead', 1840, 430, 26, 12], ['tree_dead', 1780, 860, 26, 12], ['tree_dead', 40, 1072, 26, 12],
              ['mailbox', 330, 476, 14, 8], ['trash_can', 1120, 905, 22, 10], ['recycling_bin', 1150, 905, 22, 10],
              ['hydrant', 1470, 506, 12, 8], ['for_sale_sign', 1660, 860, 14, 8], ['trash_can', 1350, 690, 22, 10]]
    for x, y, _, _, pole in LIGHTS:
        if pole: items.append(['streetlight', x, y + 170, 10, 8])
    return items


ZONE = {
    '_doc': 'Written by art/build_zone.py (edit there). props: [art, x, base y, footprint w, footprint h]; colliders [x,y,w,h];'
            ' lights [x, y, energy, kind]; packs and prayers are gameplay positions; zones: [x,y,w,h,verse key] captions.',
    'size': [W, HT], 'player_start': [760, 548], 'night': [0.3, 0.31, 0.48],
    'colliders': [[-40, -40, 40, 1160], [W, -40, 40, 1160], [-40, -40, 2000, 100], [-40, HT, 2000, 40]],
    'packs': [
        {'at': [400, 548], 'kinds': ['swarmer', 'swarmer', 'swarmer', 'swarmer']},
        {'at': [1020, 548], 'kinds': ['caster', 'swarmer', 'swarmer', 'swarmer']},
        {'at': [1420, 560], 'kinds': ['brute', 'swarmer', 'swarmer']},
        {'at': [320, 985], 'kinds': ['swarmer', 'swarmer', 'caster', 'swarmer']},
        {'at': [900, 985], 'kinds': ['brute', 'caster']},
        {'at': [1552, 780], 'kinds': ['caster', 'swarmer', 'swarmer', 'swarmer']},
        {'at': [1700, 220], 'kinds': ['swarmer', 'swarmer', 'swarmer']},
        {'at': [1800, 740], 'kinds': ['brute', 'swarmer', 'swarmer']},
    ],
    'respawn_seconds': 22, 'respawn_min_distance': 380,
    'prayers': [
        {'at': [540, 985], 'person': 'res://art/people/pray_a.png', 'wave': ['swarmer', 'swarmer', 'swarmer', 'caster']},
        {'at': [1740, 380], 'person': 'res://art/people/pray_b.png', 'wave': ['brute', 'swarmer', 'swarmer', 'swarmer']},
        {'at': [1730, 790], 'person': 'res://art/people/pray_c.png', 'wave': ['caster', 'caster', 'swarmer', 'swarmer', 'swarmer']},
    ],
    'prayer_radius': 70,
    'final_pack': {'at': [1100, 548], 'kinds': ['brute', 'caster', 'caster', 'swarmer', 'swarmer', 'swarmer']},
    'zones': [[0, 0, W, 468, 'terror_night'], [0, 468, W, 160, 'struggle'], [0, 628, W, 452, 'guard_ways']],
}


def main():
    os.makedirs(G, exist_ok=True)
    ground(); props()
    z = dict(ZONE)
    z['props'] = layout()
    z['lights'] = [[x, y, e, k] for x, y, e, k, _ in LIGHTS] + [[fx, fy, 1.0, 'fire'] for fx, fy in FIRES]
    z['fires'] = FIRES
    json.dump(z, open('game/data/zone.json', 'w'), indent=1)
    print('zone ok', len(z['props']), 'props')


if __name__ == '__main__':
    main()
