"""The city's outer works, shared by every screen that shows them: the luminous sky above, the jasper wall with its
twelve-stone foundations (Rev 21:18-20) and the gate of one pearl (Rev 21:21). Drawn at any width."""
import numpy as np
from PIL import Image
from common import C, OUT

WALL_BOTTOM = 160
WALL_H = 110
WALL_TOP = WALL_BOTTOM - WALL_H
GATE_Y = 9
GATE_PASSAGE_FROM_LEFT = 74     # the open arch is centred 74 px from the gate image's left edge


def draw_sky(px, width):
    """Pure light, no sun (Rev 21:23): white with a warm dither growing toward the wall."""
    for y in range(0, WALL_BOTTOM):
        for x in range(width):
            t = y / WALL_TOP if WALL_TOP else 1
            d = ((x * 7 + y * 13) % 16) / 16
            px[x, y] = C('fbff86') if (t > 0.55 and d < (t - 0.55) * 1.2) else C('ffffff')


STONES = [  # (dark, mid, light) - the twelve foundations, Rev 21:19-20
    ('547e64', '92a984', 'c7dcd0'),  # jasper
    ('484a77', '4d65b4', '4d9be6'),  # sapphire
    ('7f708a', '9babb2', 'c7dcd0'),  # agate (NIV; chalcedony)
    ('165a4c', '239063', '1ebc73'),  # emerald
    ('9e4539', 'cd683d', 'e6904e'),  # onyx (NIV; sardonyx)
    ('6e2727', 'b33831', 'e83b3b'),  # ruby (NIV; carnelian)
    ('a2a947', 'd5e04b', 'fbff86'),  # chrysolite
    ('0b8a8f', '0eaf9b', '30e1b9'),  # beryl
    ('f79617', 'f9c22b', 'fbff86'),  # topaz
    ('239063', '91db69', 'cddf6c'),  # turquoise (NIV; chrysoprase)
    ('b33831', 'ea4f36', 'f57d4a'),  # jacinth
    ('6b3e75', '905ea9', 'a884f3'),  # amethyst
]


def wall_strip(W):
    """The jasper wall, W px wide and WALL_H tall, built as clean repeating bands from the generated wall."""
    src = Image.open('art/raw/wall_00.png').convert('RGBA')
    wall = Image.new('RGBA', (W, WALL_H))
    wp = wall.load()
    # crenellations: src rows 10..17, period 23
    CREN_P, CREN_X = 23, 33
    for x in range(W):
        sx = CREN_X + (x % CREN_P)
        for y in range(8):
            wp[x, y] = src.getpixel((sx, 10 + y))
    # walkway (clean slabs, no cracks): rows 8..29
    for x in range(W):
        col = {8: '9babb2', 20: 'ffffff', 21: '9babb2', 22: '9babb2', 23: '9babb2', 24: OUT, 25: '547e64', 26: '547e64', 27: '9babb2', 28: '9babb2', 29: OUT}
        for y in range(8, 30):
            c = col.get(y, 'c7dcd0')
            wp[x, y] = c if isinstance(c, tuple) else C(c)
        if (x % 32 == 0):
            for y in range(9, 16): wp[x, y] = C('9babb2')
        if ((x + 16) % 32 == 0):
            for y in range(17, 20): wp[x, y] = C('9babb2')
        wp[x, 16] = C('9babb2')
        if x % 32 in (3, 4) : wp[x, 10] = C('ffffff')
    # crystal panels: src rows 40..88, module x 25..133 (109 px, posts on both ends)
    for x in range(W):
        sx = 25 + (x % 109)
        for y in range(49):
            wp[x, 30 + y] = src.getpixel((sx, 40 + y))
    # foundations garnished with the twelve precious stones (Rev 21:19-20)
    GY = 79
    GEM = ["..XXXXX..",
           ".XLWLMMX.",
           "XLWLMMMMX",
           "XLLMMMMDX",
           "XMMMMMMDX",
           "XMMMMMDDX",
           ".XMMMDDX.",
           "..XXXXX.."]
    for x in range(W):
        for k in range(31):
            y = GY + k
            if k == 0 or k == 30: c = OUT
            elif k == 1: c = C('ffffff')
            elif k == 2: c = C('c7dcd0')
            elif k >= 27: c = C('7f708a')
            else: c = C('9babb2') if (x + k) % 7 else C('c7dcd0')
            wp[x, y] = c
    for row, (gy, off) in enumerate(((GY + 4, 0), (GY + 16, 7))):
        for i, gx in enumerate(range(-14 + off, W + 14, 14)):
            idx = (i + row * 6) % 12
            d, m, l = (C(c) for c in STONES[idx])
            for yy, line in enumerate(GEM):
                for xx, ch in enumerate(line):
                    X = gx + xx
                    if ch == '.' or not (0 <= X < W): continue
                    wp[X, gy + yy] = {'X': OUT, 'L': l, 'M': m, 'D': d, 'W': C('ffffff')}[ch]
        # small gold studs between gems
        for gx in range(-14 + off + 11, W, 14):
            for (dx, dy) in ((0, 3), (1, 3), (0, 4), (1, 4)):
                if 0 <= gx + dx < W: wp[gx + dx, gy + dy] = C('f9c22b') if dy == 3 else C('f79617')


    return wall


GATE_NAME = 'JUDAH'           # Rev 21:12: on the gates the names of the twelve tribes of Israel (Rev 7:5 lists Judah first)
GLYPHS = {'J': ['..#', '..#', '..#', '#.#', '.#.'], 'U': ['#.#', '#.#', '#.#', '#.#', '###'],
          'D': ['##.', '#.#', '#.#', '#.#', '##.'], 'A': ['.#.', '#.#', '###', '#.#', '#.#'],
          'H': ['#.#', '#.#', '###', '#.#', '#.#']}


def inscribe(ga, text, cx, y0):
    """Small gold capitals on the pearl, centred on cx (3x5 glyphs, 1 px apart)."""
    w = len(text) * 4 - 1
    x0 = cx - w // 2
    for i, ch in enumerate(text):
        for r, line in enumerate(GLYPHS[ch]):
            for c, on in enumerate(line):
                if on != '#': continue
                x, y = x0 + i * 4 + c, y0 + r
                ga[y, x, :3] = C('f79617')[:3]


def pearl_gate():
    """The gate of one pearl, standing open; floating ornaments and the generated plinth removed."""
    g = Image.open('art/raw/gate_00.png').convert('RGBA')
    ga = np.array(g)
    keep = np.zeros(ga.shape[:2], bool)
    keep[:118, :] = True                 # the pearl itself
    keep[118:, 49:104] = True            # arch columns
    keep[144:, 46:104] = True            # threshold steps
    PEARL = {(0xff, 0xff, 0xff), (0xea, 0xad, 0xed), (0xc7, 0xdc, 0xd0), (0x9b, 0xab, 0xb2)}
    for y in range(90, 118):             # drop the small gold ornaments at the pearl's foot
        for x in list(range(0, 32)) + list(range(112, 144)):
            if not ga[y, x, 3]: continue
            c = tuple(ga[y, x, :3])
            if c in PEARL: continue
            if c == (0x2e, 0x22, 0x2f) and (x < 72 and ga[y, x - 1, 3] == 0 or x > 72 and ga[y, x + 1, 3] == 0):
                continue                 # keep the pearl's outer outline
            keep[y, x] = False
    ga[~keep, 3] = 0
    # soften the pink lustre: every other pink pixel becomes white -> pearly sheen
    pink = (ga[..., 0] == 0xea) & (ga[..., 1] == 0xad) & (ga[..., 2] == 0xed)
    yy, xx = np.mgrid[0:ga.shape[0], 0:ga.shape[1]]
    ga[pink & ((xx + yy) % 2 == 0), :3] = (0xff, 0xff, 0xff)
    inscribe(ga, GATE_NAME, GATE_PASSAGE_FROM_LEFT, 49)


    return Image.fromarray(ga)


def add_city_top(bg, gate_x):
    """Wall across the whole width of `bg`, the pearl gate with its image's left edge at gate_x."""
    bg.alpha_composite(wall_strip(bg.width), (0, WALL_TOP))
    bg.alpha_composite(pearl_gate(), (gate_x, GATE_Y))
