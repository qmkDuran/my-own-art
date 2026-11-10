"""Builds every sprite of the ARPG prototype from the PixelLab outputs (heaven/art/raw/arpg_*, anim/michael/) and the
Project R exterior art copied into arpg/art/ext/ (read-only source). No API calls. Run from heaven/arpg/:
    python3 art/build_arpg.py
Outputs go to game/art/: michael/, demons/, items/, people/ + review sheets in out/. The zone: art/build_zone.py."""
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


# ------------------------------------------------------------------ Revelation enemies (paid batches; hand animation)
REVELATION = {  # name: (raw image, mirror to face left, rim colour)
    'locust': ('arpg_locust_02', False, 'f9c22b'),       # Rev 9:7-10
    'frog': ('arpg_frog_04', False, 'cddf6c'),           # Rev 16:13-14
    'firehorse': ('arpg_firehorse_01', True, 'f57d4a'),  # Rev 9:17-19
}


def top_shift(im, dy, frac=0.5):
    """Move the upper part of a sprite (wings, mane) by dy pixels: a wingbeat or a toss of the head."""
    a = np.array(im); out = a.copy()
    bb = im.getbbox(); cut = bb[1] + int((bb[3] - bb[1]) * frac)
    out[:cut] = 0
    src = a[:cut]
    if dy < 0: out[:cut + dy] = np.where(src[-dy:, ..., 3:4] > 0, src[-dy:], out[:cut + dy])
    else: out[dy:cut] = np.where(src[:cut - dy, ..., 3:4] > 0, src[:cut - dy], out[dy:cut])
    return Image.fromarray(out)


def revelation():
    for name, (raw, flip, rim_col) in REVELATION.items():
        base = keep_main(load(RAW + raw + '.png'), 0.2)
        if flip: base = mirror(base)
        bb = base.getbbox(); b = Image.new('RGBA', (F, F)); b.alpha_composite(base.crop(bb), ((F - (bb[2] - bb[0])) // 2, F - 2 - (bb[3] - bb[1])))
        base = rim(b, rim_col)
        if name == 'locust':        # hovering on beating wings, darting, stinging
            idle = [top_shift(base, -2), top_shift(base, 1)]
            move = [shift(top_shift(base, -2), 0, -3), shift(top_shift(base, 1), -2, -2), shift(top_shift(base, -2), 0, -3), shift(top_shift(base, 1), 2, -2)]
            attack = [shift(base, 4, -4, 1.0, 1.04), shift(base, -8, 1, 1.08, 0.95), shift(base, -3, 0)]
        elif name == 'frog':        # crouch and hop; spit
            idle = [base, shift(base, 0, 0, 1.04, 0.96)]
            move = [shift(base, 0, 0, 1.08, 0.9), shift(base, -2, -8, 0.94, 1.06), shift(base, -3, -10, 0.94, 1.06), shift(base, -1, -3)]
            attack = [shift(base, 2, 0, 1.06, 0.94), shift(base, -4, -2, 0.96, 1.05), base]
        else:                       # gallop; rear and breathe fire
            idle = [base, top_shift(base, 1, 0.4)]
            move = [shift(base, 0, -2), shift(top_shift(base, 1, 0.4), -1, 0), shift(base, 0, -2), shift(top_shift(base, -1, 0.4), 1, 0)]
            attack = [shift(top_shift(base, -2, 0.45), 2, -2), shift(base, -5, 0, 1.05, 0.97), shift(base, -2, 0)]
        save(sheet([idle, move, attack]), G + f'demons/{name}.png')


# ------------------------------------------------------------------ demon variants by palette (no new generations)
VARIANTS = {  # name: (source sheet, body ramp dark->light, rim colour, eye colour or None to keep)
    'cinder': ('swarmer', ['2e222f', '6e2727', 'b33831', 'e83b3b'], 'f57d4a', 'fbff86'),
    'stalker': ('caster', ['2e222f', '374e4a', '547e64', '92a984'], 'cddf6c', 'cddf6c'),
    'caller': ('caster', ['2e222f', '3e3546', '625565', '9babb2'], 'c7dcd0', 'e83b3b'),
    'ravager': ('brute', ['2e222f', '6e2727', '9e4539', 'cd683d'], 'e83b3b', 'fbff86'),
    'mauler': ('brute', ['2e222f', '3e3546', '625565', '7f708a'], '9babb2', 'e83b3b'),
}
EYES = {H(c) for c in ('f57d4a', 'e6904e', 'f9c22b', 'fbb954', 'ea4f36', 'f79617', 'fbff86', 'e83b3b')}


def lum(c): return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def recolour_demon(src, ramp, rim_col, eye_col, old_rim):
    """Body pixels move onto `ramp` by luminance; eyes take `eye_col`; the rim takes `rim_col`; outline stays."""
    a = np.array(Image.open(G + f'demons/{src}.png').convert('RGBA'))
    cols = {tuple(int(v) for v in p) for p in a[a[..., 3] > 0][:, :3]} - {H('2e222f')}
    body = sorted([c for c in cols if c not in EYES and c != H(old_rim)], key=lum)
    counts = {c: int(((a[..., :3] == c).all(-1) & (a[..., 3] > 0)).sum()) for c in body}
    total = float(sum(counts.values())); acc = 0.0; rank = {}
    for c in body:                                                   # by share of pixels, dark -> light
        rank[c] = (acc + counts[c] / 2) / total; acc += counts[c]
    out = a.copy()
    for c in cols:
        m = (a[..., :3] == c).all(-1) & (a[..., 3] > 0)
        if c == H(old_rim): out[m, :3] = H(rim_col)
        elif c in EYES: out[m, :3] = H(eye_col) if eye_col else c
        else:
            k = (0 if rank[c] < 0.35 else 1 if rank[c] < 0.72 else 2 if rank[c] < 0.93 else 3)
            out[m, :3] = H(ramp[k])
    return Image.fromarray(out)


def variants():
    for name, (src, ramp, rim_col, eye_col) in VARIANTS.items():
        save(recolour_demon(src, ramp, rim_col, eye_col, RIM[src]), G + f'demons/{name}.png')


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


def review(mi, dm):
    o = Image.new('RGBA', (F * 14, F * 2), (30, 28, 45, 255))
    o.alpha_composite(mi, (0, 0))
    for i, n in enumerate(list(dm) + list(VARIANTS) + list(REVELATION)):
        o.alpha_composite(Image.open(G + f'demons/{n}.png').crop((0, 0, 64, 64)), (i * F, F))
    for i, (n, _, _) in enumerate(PRAYERS): o.alpha_composite(Image.open(G + f'people/{n}.png').crop((0, 0, 64, 64)), ((11 + i) * F, F))
    o.resize((o.width * 3, o.height * 3), Image.NEAREST).save('out/sprites_3x.png')


if __name__ == '__main__':
    os.makedirs('out', exist_ok=True)
    mi = michael(); dm = demons(); variants(); revelation(); items(); praying(); review(mi, dm)
    print('arpg art ok')
