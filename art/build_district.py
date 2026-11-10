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
PLANTERS = [(1430, 236), (80, 236)]
GIFTS = [('gift_chest', 'gifts_03'), ('gift_jar', 'gifts_17'), ('gift_fruit', 'gifts_27'),
         ('gift_cloth', 'gifts_33'), ('gift_incense', 'gifts_41'), ('gift_gems', 'gifts_63')]
SKIN_RAMP = ['fdcbb0', 'fca790', 'e6904e', 'cd683d', '9e4539', '6e2727']
random.seed(21)


def gold_ground(bg):
    gold = [Image.open(f'art/raw/tA_{i:02d}.png').convert('RGBA') for i in (1, 2)]
    for ty in range(HT // 32 + 1):
        for tx in range(W // 32):
            bg.paste(gold[0] if random.random() < 0.8 else gold[1], (tx * 32, ty * 32))


LIGHTER = {H(a): C(b) for a, b in (('e6904e', 'f79617'), ('f79617', 'f9c22b'), ('f9c22b', 'fbb954'), ('fbb954', 'fbff86'), ('fbff86', 'ffffff'))}


DARKER = {H(a): C(b) for a, b in (('fbff86', 'fbb954'), ('fbb954', 'f9c22b'), ('f9c22b', 'f79617'), ('f79617', 'e6904e'))}


def calm_yards(px):
    """Courtyards and terrace one tone deeper than the great street, so the street of gold reads as the way."""
    for y in list(range(0, STREET[0] - 4)) + list(range(STREET[1] + 5, BALUSTRADE_Y)):
        for x in range(W):
            c = px[x, y][:3]
            if c in DARKER and dith(x, y) < 0.7: px[x, y] = DARKER[c]


def street(px):
    """The great street: brighter glassy gold with jasper curbs set with gems (Rev 21:21)."""
    y0, y1 = STREET
    for y in range(y0, y1):
        for x in range(W):
            c = px[x, y][:3]
            if c in LIGHTER and dith(x, y) < 0.5: px[x, y] = LIGHTER[c]
            u = (x + int(y * 0.75)) % 151
            if u < 5 and px[x, y][:3] in LIGHTER: px[x, y] = C('ffffff')
    for yc in (y0 - 4, y1):
        for x in range(W):
            for k, col in enumerate((OUT, C('ffffff'), C('c7dcd0'), C('9babb2'), OUT)):
                px[x, yc + k] = col
        for gx in range(16, W, 64):
            d, m, l = (C(c) for c in STONES[(gx // 64) % 12])
            for dx, dy, col in ((0, 1, l), (1, 1, m), (0, 2, m), (1, 2, d)):
                px[gx + dx, yc + dy] = col


def garden_street(px):
    """The garden's street continues down between the dwellings, with white jasper edges, into the great street."""
    x0, x1 = GARDEN_STREET
    for y in range(0, STREET[0] - 4):
        for x in (x0 - 3, x1 + 2):
            px[x, y] = OUT
        for x in (x0 - 2, x0 - 1, x1, x1 + 1):
            px[x, y] = C('fbff86') if x < x0 else C('e6904e')


def walkways(px):
    """A pearl-white walk from each door down to the great street (doors face the street)."""
    for _, _, cx, base in DWELLINGS:
        for y in range(base - 6, STREET[0] - 4):
            for x in range(cx - 16, cx + 17):
                edge = x in (cx - 16, cx + 16)
                px[x, y] = OUT if edge else (C('ffffff') if (y // 8 + (x - cx) // 16) % 2 else C('eaaded') if dith(x, y) < 0.2 else C('ffffff'))


def balustrade_and_haze(px):
    """A jasper balustrade with gem posts at the terrace edge; beyond it the city lies in light (no night, Rev 22:5)."""
    for y in range(HAZE_Y, HT):
        t = (y - HAZE_Y) / (HT - HAZE_Y)
        for x in range(W):
            px[x, y] = C('ffffff') if dith(x, y) < 0.55 + t else C('fbff86')
    y0 = BALUSTRADE_Y
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


def planters(px):
    for cx, base in PLANTERS:
        for y in range(base - 16, base):
            for x in range(cx - 24, cx + 25):
                edge = y in (base - 16, base - 1) or x in (cx - 24, cx + 24)
                inner = base - 16 < y < base - 9
                px[x, y] = OUT if edge else ((C('239063') if dith(x, y) < 0.6 else C('1ebc73')) if inner else C('c7dcd0'))
        for _ in range(16):
            x, y = random.randint(cx - 20, cx + 20), random.randint(base - 15, base - 10)
            c1 = random.choice(('f04f78', 'ffffff', 'f9c22b', 'a884f3'))
            px[x, y] = C(c1); px[x, y - 1] = C('fbff86')


def contact_shadows(px, sizes):
    for name, _, cx, base in DWELLINGS:
        sw = int(sizes[name][0] * 0.92)
        for y in range(base - 6, base + 5):
            for x in range(cx - sw // 2, cx + sw // 2):
                if ((x - cx) / (sw / 2)) ** 2 + ((y - base + 1) / 6) ** 2 <= 1 and dith(x, y) < 0.5:
                    px[x, y] = C('e6904e')


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


def shift_skin(sheet, steps):
    """A new individual from an existing one: every skin-ramp colour moved `steps` along the ramp (palette only)."""
    a = np.array(sheet)
    ramp = [H(c) for c in SKIN_RAMP]
    src = a.copy()
    for i, c in enumerate(ramp):
        j = max(0, min(len(ramp) - 1, i + steps))
        m = (src[..., 0] == c[0]) & (src[..., 1] == c[1]) & (src[..., 2] == c[2]) & (src[..., 3] > 0)
        a[m, :3] = ramp[j]
    return Image.fromarray(a)


def bearer_sheet(walker, steps, gift):
    """A gift bearer: the walker's west walk with the gift carried before the chest; hero.png layout (all rows = side)."""
    src = shift_skin(Image.open(f'game/art/people/{walker}.png').convert('RGBA'), steps)
    frames = []
    for i in range(8):
        f = src.crop((i * FRAME, 5 * FRAME, (i + 1) * FRAME, 6 * FRAME))
        b = f.getbbox()
        g = Image.new('RGBA', (FRAME, FRAME)); g.alpha_composite(f)
        g.alpha_composite(gift, (max(0, b[0] - gift.width // 2 + 2), b[1] + 33 - gift.height // 2))   # carried before the chest
        frames.append(g)
    sh = Image.new('RGBA', (FRAME * 8, FRAME * 7))
    for r in range(7):
        row = frames if r in (3, 4, 5) else [frames[0]] * 4
        for i, f in enumerate(row): sh.alpha_composite(f, (i * FRAME, r * FRAME))
    return sh


RESIDENTS = [('p31', 'p01', 3), ('p32', 'p15', 3), ('p33', 'p05', -2), ('p34', 'p07', 2), ('p35', 'p10', -2)]
BEARERS = [('bearer_a', 'walkerA', 3, 'gift_chest'), ('bearer_b', 'walkerB', -2, 'gift_jar'),
           ('bearer_c', 'walkerA', -1, 'gift_fruit'), ('bearer_d', 'walkerB', 2, 'gift_cloth'),
           ('bearer_e', 'walkerA', 1, 'gift_incense'), ('bearer_f', 'walkerB', -1, 'gift_gems')]


def people(gift_imgs):
    for new, old, steps in RESIDENTS:
        shift_skin(Image.open(f'game/art/people/{old}.png').convert('RGBA'), steps).save('game/art/people/' + new + '.png')
    for name, walker, steps, gift in BEARERS:
        bearer_sheet(walker, steps, gift_imgs[gift]).save(D + name + '.png')


def main():
    bg = Image.new('RGBA', (W, HT)); px = bg.load()
    gold_ground(bg)
    calm_yards(px); street(px); garden_street(px); walkways(px)
    sizes = dwellings()
    contact_shadows(px, sizes)
    planters(px); balustrade_and_haze(px)
    snap_rgb(bg).save(D + 'dbg.png')
    people(gifts())
    layout = {
        'origin_y': OY, 'size': [W, HT], 'street': [OY + STREET[0], OY + STREET[1]], 'balustrade_y': OY + BALUSTRADE_Y,
        'dwellings': [[n, cx, OY + base, sizes[n][0]] for n, _, cx, base in DWELLINGS],
        'planters': [[cx, OY + base] for cx, base in PLANTERS],
    }
    json.dump(layout, open(D + 'layout.json', 'w'), indent=1)
    print('district ok', sizes)


if __name__ == '__main__':
    main()
