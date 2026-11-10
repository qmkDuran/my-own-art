"""Builds every sprite of the ARPG prototype from the PixelLab outputs (heaven/art/raw/arpg_*, anim/michael/) and the
Project R exterior art copied into arpg/art/ext/ (read-only source). No API calls. Run from heaven/arpg/:
    python3 art/build_arpg.py
Outputs go to game/art/: michael/, demons/, items/, people/, zone/ + review sheets in out/."""
import glob, json, os, random, sys
import numpy as np
from PIL import Image
HEAVEN = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
sys.path.insert(0, os.path.join(HEAVEN, 'art'))
from common import C, H, OUT, OUTL, quant, keep_main, dith   # noqa: E402

RAW = os.path.join(HEAVEN, 'art', 'raw') + '/'
G = 'game/art/'
F = 64
random.seed(7)


def save(im, path):
    os.makedirs(os.path.dirname(path), exist_ok=True); im.save(path); return im


def strip(frames):
    out = Image.new('RGBA', (F * len(frames), F))
    for i, f in enumerate(frames): out.alpha_composite(f, (i * F, 0))
    return out


def sheet(rows):
    w = max(len(r) for r in rows)
    out = Image.new('RGBA', (F * w, F * len(rows)))
    for y, r in enumerate(rows):
        for x, f in enumerate(r): out.alpha_composite(f, (x * F, y * F))
    return out


def load(p): return quant(Image.open(p).convert('RGBA'))


def mirror(im): return im.transpose(Image.FLIP_LEFT_RIGHT)


# ------------------------------------------------------------------ Michael (rows: down, up, left; right = mirrored left)
def michael():
    A = RAW + 'anim/michael/'
    rot = {d: load(RAW + f'ch_michael_rot_{d}.png') for d in ('south', 'north', 'west')}
    idle = [[rot[d], rot[d]] for d in ('south', 'north', 'west')]
    for row in idle:                                      # breathe: wings and shoulders rise 1 px
        a = np.array(row[0]); b = np.zeros_like(a); b[:-1] = a[1:]; b[48:] = a[48:]; row[1] = Image.fromarray(b)
    walk = [[load(p) for p in sorted(glob.glob(A + f'walking-8-frames/{d}_*.png'))] for d in ('south', 'north', 'west')]
    # the template's east walk recoloured a wing purple on some frames, so the side row is the west walk;
    # the west slash smeared the blade, so the side slash is the clean east slash mirrored
    slash = [[load(p) for p in sorted(glob.glob(A + f'slash/{d}_*.png'))] for d in ('south', 'north')]
    slash.append([mirror(load(p)) for p in sorted(glob.glob(A + 'slash/east_*.png'))])
    save(sheet(idle), G + 'michael/idle.png'); save(sheet(walk), G + 'michael/walk.png'); save(sheet(slash), G + 'michael/slash.png')
    return sheet([idle[0] + walk[0][:4] + slash[0][3:7]])


# ------------------------------------------------------------------ demons: rim light + hand animation
DEMONS = {'swarmer': 2, 'brute': 4, 'caster': 8}
RIM = {'swarmer': '905ea9', 'brute': 'b33831', 'caster': 'a884f3'}


def rim(im, col):
    """A 1 px coloured rim outside the dark outline so the shadows read against the night."""
    a = np.array(im); m = a[..., 3] > 0
    e = np.zeros_like(m); e[1:] |= m[:-1]; e[:-1] |= m[1:]; e[:, 1:] |= m[:, :-1]; e[:, :-1] |= m[:, 1:]
    a[e & ~m] = C(col)
    return Image.fromarray(a)


def shift(im, dx, dy, sx=1.0, sy=1.0):
    """Move (and squash/stretch about the feet) a frame by whole pixels."""
    if sx != 1.0 or sy != 1.0:
        bb = im.getbbox(); w, h = bb[2] - bb[0], bb[3] - bb[1]
        part = im.crop(bb).resize((max(1, round(w * sx)), max(1, round(h * sy))), Image.NEAREST)
        im = Image.new('RGBA', (F, F)); im.alpha_composite(part, ((F - part.width) // 2 + (bb[0] + bb[2] - F) // 2, bb[3] - part.height))
    out = Image.new('RGBA', (F, F)); out.alpha_composite(im, (dx, dy)); return out


def demons():
    out = {}
    for name, idx in DEMONS.items():
        base = keep_main(load(RAW + f'arpg_demon_{idx:02d}.png'), 0.2)
        bb = base.getbbox(); b = Image.new('RGBA', (F, F)); b.alpha_composite(base.crop(bb), ((F - (bb[2] - bb[0])) // 2, F - 2 - (bb[3] - bb[1])))
        base = rim(b, RIM[name])
        idle = [base, shift(base, 0, 1, 1.03, 0.97)]
        move = [shift(base, -1, 0), shift(base, 0, -1, 0.97, 1.03), shift(base, 1, 0), shift(base, 0, -1, 0.97, 1.03)]
        attack = [shift(base, 3, 1, 1.05, 0.95), shift(base, -6, 0, 0.92, 1.06), shift(base, -2, 0)]  # faces left: lunge left
        rows = [idle + [None] * 2, move, attack + [None]]
        save(sheet([[f for f in r if f is not None] for r in rows]), G + f'demons/{name}.png')
        out[name] = base
    return out


# ------------------------------------------------------------------ items: 8 slots x 8 icons (batch order)
ITEM_ROWS = ['belt', 'breastplate', 'feet', 'shield', 'helmet', 'sword', 'ring', 'amulet']


def items():
    atlas = Image.new('RGBA', (32 * 8, 32 * 8))
    for r, slot in enumerate(ITEM_ROWS):
        for c in range(8):
            im = keep_main(load(RAW + f'arpg_item_{r * 8 + c:02d}.png'), 0.2)
            atlas.alpha_composite(im, (c * 32, r * 32))
    save(atlas, G + 'items/icons.png')
    big = atlas.resize((atlas.width * 2, atlas.height * 2), Image.NEAREST)
    bg = Image.new('RGBA', big.size, (40, 36, 54, 255)); bg.alpha_composite(big); bg.save('out/item_icons_2x.png')


# ------------------------------------------------------------------ praying people (heaven people, everyday clothes)
ROBE = ['ffffff', 'c7dcd0', '9babb2', '7f708a']
CLOTHES = {'blue': ['4d9be6', '4d65b4', '484a77', '323353'], 'olive': ['a2a947', '676633', '4c3e24', '45293f'],
           'wine': ['cd683d', '9e4539', '6e2727', '45293f']}
PRAYERS = [('pray_a', 'p01', 'blue'), ('pray_b', 'p05', 'olive'), ('pray_c', 'p07', 'wine')]   # hands folded in prayer


def praying():
    for name, src, cl in PRAYERS:
        a = np.array(Image.open(os.path.join(HEAVEN, 'game/art/people', src + '.png')).convert('RGBA'))[0:64, 0:128]
        for i, rc in enumerate(ROBE):
            m = (a[..., :3] == H(rc)).all(-1) & (a[..., 3] > 0)
            a[m, :3] = H(CLOTHES[cl][i])
        save(Image.fromarray(a), G + f'people/{name}.png')


# ------------------------------------------------------------------ zone: 1920x1080 ruined suburb at night
EXT = 'art/ext/'
W, HT = 1920, 1080
ROAD = (500, 596)            # main street (y)
SIDE_N = (468, 500)          # north sidewalk
SIDE_S = (596, 628)          # south sidewalk
CROSS = (1504, 1600)         # side street (x), runs south from the main street


def tile(name): return Image.open(EXT + f'tiles/outdoor/{name}.png').convert('RGBA')


def ground():
    bg = Image.new('RGBA', (W, HT))
    grass = [tile(f'grass_{i}') for i in range(3)]
    for ty in range(0, HT, 32):
        for tx in range(0, W, 32):
            bg.alpha_composite(random.choice(grass), (tx, ty))
    road = [tile('road_0')] * 6 + [tile('road_crack'), tile('road_patch')]
    for tx in range(0, W, 32):
        for ty in range(ROAD[0], ROAD[1], 32): bg.alpha_composite(random.choice(road), (tx, ty))
        bg.alpha_composite(tile('sidewalk_0' if tx % 64 else 'sidewalk_1'), (tx, SIDE_N[0]))
        bg.alpha_composite(tile('sidewalk_0' if tx % 64 else 'sidewalk_1'), (tx, SIDE_S[0]))
    for ty in range(SIDE_S[1], HT, 32):
        for tx in range(CROSS[0], CROSS[1], 32): bg.alpha_composite(random.choice(road), (tx, ty))
        bg.alpha_composite(tile('sidewalk_0'), (CROSS[0] - 32, ty)); bg.alpha_composite(tile('sidewalk_0'), (CROSS[1], ty))
    for tx in range(CROSS[0], CROSS[1], 32):                     # the side street opens into the main street
        bg.alpha_composite(random.choice(road), (tx, SIDE_S[0]))
    for tx in range(64, W, 96): bg.alpha_composite(tile('road_line_h'), (tx, (ROAD[0] + ROAD[1]) // 2 - 16))
    px = bg.load()
    for _ in range(26):                                           # scorch marks and rubble (the time of distress, Dan 12:1)
        cx, cy, r = random.randint(40, W - 40), random.randint(ROAD[0] - 40, HT - 30), random.randint(10, 26)
        for y in range(cy - r, cy + r):
            for x in range(cx - r * 2, cx + r * 2):
                if 0 <= x < W and 0 <= y < HT and ((x - cx) / (2 * r)) ** 2 + ((y - cy) / r) ** 2 < 1 and dith(x, y) < 0.45:
                    px[x, y] = C('2e222f' if dith(x + 1, y) < 0.5 else '3e3546')
        for _ in range(12):
            x, y = cx + random.randint(-2 * r, 2 * r), cy + random.randint(-r, r)
            if 0 < x < W - 1 and 0 < y < HT - 1:
                px[x, y] = C('625565'); px[x + 1, y] = C('3e3546'); px[x, y - 1] = C('9babb2')
    save(bg, G + 'zone/ground.png')


def darken(im, k=0.72):
    a = np.array(im).astype(float); a[..., :3] *= k
    return quant(Image.fromarray(a.clip(0, 255).astype(np.uint8)))


def zone_props():
    props = {
        'house_a': darken(Image.open(EXT + 'buildings/house_dunmore_night.png').convert('RGBA'), 0.9),
        'house_b': darken(Image.open(EXT + 'buildings/house_hale_night.png').convert('RGBA'), 0.9),
        'store': darken(Image.open(EXT + 'buildings/store_ridge_mart_dark.png').convert('RGBA'), 0.85),
        'house_c': darken(Image.open(EXT + 'buildings/house_okoro.png').convert('RGBA'), 0.7),
    }
    for n in ('car_wreck_burned', 'car_wreck', 'suv_red', 'van', 'streetlight', 'fence_picket_broken', 'fence_chainlink',
              'trash_can', 'hydrant', 'mailbox', 'recycling_bin', 'for_sale_sign', 'hedge'):
        props[n] = Image.open(EXT + f'props/{n}.png').convert('RGBA')
    props['tree_dead'] = dead_tree(Image.open(EXT + 'props/tree.png').convert('RGBA'))
    for n, im in props.items(): save(im, G + f'zone/{n}.png')


def dead_tree(im):
    """The suburb's tree in the time of distress: most leaves gone, the rest withered to grey-brown."""
    a = np.array(im); greens = {H(c) for c in ('1ebc73', '239063', '165a4c', '91db69', '0eaf9b', '547e64', '374e4a', 'cddf6c', 'f9c22b', 'fbb954')}
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y, x, 3] and tuple(a[y, x, :3]) in greens:
                if dith(x, y) < 0.62: a[y, x, 3] = 0
                else: a[y, x, :3] = H('676633' if dith(x + 2, y) < 0.5 else '4c3e24')
    return keep_main(Image.fromarray(a), 0.1)


def review(mi, dm):
    o = Image.new('RGBA', (F * 13, F * 2), (30, 28, 45, 255))
    o.alpha_composite(mi, (0, 0))
    for i, (n, b) in enumerate(dm.items()): o.alpha_composite(b, (i * F, F))
    for i, (n, _, _) in enumerate(PRAYERS): o.alpha_composite(Image.open(G + f'people/{n}.png').crop((0, 0, 64, 64)), ((4 + i) * F, F))
    o.resize((o.width * 3, o.height * 3), Image.NEAREST).save('out/sprites_3x.png')


if __name__ == '__main__':
    os.makedirs('out', exist_ok=True)
    mi = michael(); dm = demons(); items(); praying(); ground(); zone_props(); review(mi, dm)
    print('arpg art ok')
