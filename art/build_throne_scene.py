"""Throne room (Revelation 4-5), hand-composed. Writes game/art/throne/{tbg,throne_glow,throne_core,flame,bowl,rays}.png
and layout.json (positions used by game/scripts/throne.gd)."""
import json, math, random, sys
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
from common import C, OUT, dith, snap_rgb, radial_glow as glow

W, H = 960, 540
D = 'game/art/throne/'
CX, CY = 480, 104          # centre of the throne (light)
HORIZON = 84               # where the sea of glass meets the light
DAIS = (330, 630, 150, 214)  # x0, x1, top y, bottom y of the steps
random.seed(4)

img = Image.new('RGBA', (W, H), C('ffffff'))
px = img.load()

# ---------------------------------------------------------------- light above the horizon (no sun, no lamp: glory)
for y in range(HORIZON):
    for x in range(W):
        t = y / HORIZON
        r = math.hypot((x - CX) / 520, (y - CY) / 260)
        warm = min(1, max(0, 1.1 - r))
        px[x, y] = C('fbff86') if dith(x, y) < 0.35 * (1 - warm) * t + 0.05 * t else C('ffffff')

# ---------------------------------------------------------------- the sea of glass, clear as crystal (Rev 4:6)
for y in range(HORIZON, H):
    for x in range(W):
        dy = y - HORIZON
        far = max(0.0, 1 - dy / 46)                       # fades into light at the horizon
        col = '8ff8e2'
        if dith(x, y) < far: col = 'ffffff'
        # a few soft slab joints
        if dy > 60 and (x % 120 == 60 or dy % 80 == 0): col = 'c7dcd0'
        # a few broad gleams
        u = (x + int(y * 0.8)) % 347
        if u < 4 or u == 9: col = 'ffffff'
        # reflection of the throne's glory running down toward the viewer
        rx = abs(x - CX) / (34 + dy * 0.12)
        fade = max(0.0, 1 - dy / 420)
        if rx < 1 and dith(x, y) < (1 - rx) * 0.7 * fade: col = 'ffffff' if rx < 0.3 else 'fbff86'
        px[x, y] = C(col)


# ---------------------------------------------------------------- rainbow round about the throne, like an emerald (Rev 4:3)
BANDS = ['165a4c', '239063', '1ebc73', '91db69', 'cddf6c', '91db69', '1ebc73', '239063']
for y in range(0, DAIS[2] + 6):
    for x in range(CX - 140, CX + 141):
        r = math.hypot((x - CX) / 128, (y - (CY + 8)) / 112)
        k = int((r - 0.86) / 0.14 * len(BANDS))
        if 0 <= k < len(BANDS):
            px[x, y] = C(BANDS[k])
        elif k == -1 and dith(x, y) < 0.5:
            px[x, y] = C('cddf6c')

# ---------------------------------------------------------------- dais of jasper with golden edges
x0, x1, ty, by = DAIS
for y in range(ty, by):
    for x in range(x0, x1):
        step = (y - ty) // 16                            # four steps
        inset = (3 - step) * 10 if step < 4 else 0
        if x < x0 + (3 - step) * 0 or x >= x1: continue
        local = (y - ty) % 16
        col = 'ffffff' if local == 0 else ('c7dcd0' if local < 8 else ('9babb2' if local < 14 else 'f9c22b'))
        if local == 15: col = OUT
        if x in (x0, x1 - 1): col = OUT
        px[x, y] = col if isinstance(col, tuple) else C(col)
    if y == ty:
        for x in range(x0, x1): px[x, y] = OUT

# ---------------------------------------------------------------- the throne itself: jasper and gold, its seat filled with light
TX0, TX1, TTOP, TSEAT = CX - 38, CX + 38, 34, 152
def tp(x, y, c):
    if 0 <= x < W and 0 <= y < H: px[x, y] = c if isinstance(c, tuple) else C(c)
for y in range(TTOP, TSEAT):
    half = 40
    for x in range(CX - half, CX + half + 1):
        edge = x in (CX - half, CX + half) or y == TTOP
        frame = abs(x - CX) > half - 7 or y < TTOP + 7
        if edge: c = OUT
        elif frame: c = 'fbff86' if x < CX else 'f9c22b'
        else:   # jasper panel with a lozenge lattice
            u, v = (x - CX) % 12, (y - TTOP) % 12
            c = '92a984' if abs(u - 6) + abs(v - 6) == 6 else ('c7dcd0' if (x + y) % 9 else 'ffffff')
        tp(x, y, c)
for fx in (CX - 34, CX, CX + 34):   # three pointed finials on the crest
    for k in range(9):
        for x in range(fx - (8 - k) // 2, fx + (8 - k) // 2 + 1):
            e = x in (fx - (8 - k) // 2, fx + (8 - k) // 2) or k == 8
            tp(x, TTOP - k, OUT if e else ('fbff86' if x <= fx else 'f9c22b'))
# armrests and seat front
for y in range(TSEAT - 34, TSEAT + 4):
    for x in list(range(TX0 - 14, TX0 + 2)) + list(range(TX1 - 2, TX1 + 14)):
        e = y in (TSEAT - 34, TSEAT + 3) or x in (TX0 - 14, TX0 + 1, TX1 - 2, TX1 + 13)
        tp(x, y, OUT if e else ('fbff86' if y < TSEAT - 28 else 'f9c22b'))
for y in range(TSEAT, TSEAT + 4):
    for x in range(TX0, TX1):
        tp(x, y, OUT if y == TSEAT + 3 else 'f79617')
# carnelian and jasper stones set in the throne frame
for (x, y, c) in ((CX, TTOP - 3, 'e83b3b'), (CX - 34, TTOP + 40, '92a984'), (CX + 34, TTOP + 40, '92a984'),
                  (CX - 34, TTOP + 80, 'b33831'), (CX + 34, TTOP + 80, 'b33831')):
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            tp(x + dx, y + dy, c)
    tp(x - 1, y - 1, 'ffffff')

# ---------------------------------------------------------------- seven lamps of fire before the throne (Rev 4:5): golden stands
LAMPS = [(CX + k * 40, 236) for k in range(-3, 4)]
for (lx, ly) in LAMPS:
    for y in range(ly - 22, ly):
        for x in range(lx - 2, lx + 3):
            tp(x, y, OUT if x in (lx - 2, lx + 2) else ('fbff86' if x == lx - 1 else 'f9c22b'))
    for y in range(ly - 26, ly - 21):          # cup
        for x in range(lx - 5, lx + 6):
            tp(x, y, OUT if (y in (ly - 26, ly - 22) or x in (lx - 5, lx + 5)) else 'f9c22b')
    for y in range(ly - 2, ly + 2):            # foot
        for x in range(lx - 6, lx + 7):
            tp(x, y, OUT if (y in (ly - 2, ly + 1) or x in (lx - 6, lx + 6)) else 'f79617')

# ---------------------------------------------------------------- elders' thrones: two arcs of six on each side (24, Rev 4:4)
def arc_points(rx, ry, th0, th1, n, cy=160):
    ts = np.linspace(math.radians(th0), math.radians(th1), 2000)
    pts = np.stack([rx * np.sin(ts), cy + ry * np.cos(ts)], 1)
    seg = np.r_[0, np.cumsum(np.hypot(*np.diff(pts, axis=0).T))]
    return [pts[np.searchsorted(seg, t)] for t in np.linspace(0, seg[-1], n)]
elders = []
for side in (-1, 1):
    for ring, (rx, ry, th0, th1) in enumerate(((432, 318, 88, 22), (330, 236, 88, 30))):
        for k, (dx, y) in enumerate(arc_points(rx, ry, th0, th1, 6)):
            elders.append({'x': round(CX + side * dx), 'y': round(y), 'face': -side, 'variant': (k + ring + (side > 0)) % 3})
elders.sort(key=lambda e: e['y'])
# a small gold footing under each throne so it stands on the glass
for e in elders:
    for y in range(e['y'] - 2, e['y'] + 3):
        for x in range(e['x'] - 20, e['x'] + 21):
            tp(x, y, OUT if y in (e['y'] - 2, e['y'] + 2) or x in (e['x'] - 20, e['x'] + 20) else ('fbff86' if y == e['y'] - 1 else 'f9c22b'))

snap_rgb(img, opaque=False).save(D + 'tbg.png')

# ---------------------------------------------------------------- light: the One on the throne is shown only as light (Rev 4:2-3)

Image.fromarray(glow(640, 420, 320, 150, 320, 230, 'fbff86', 140, 2.2)).save(D + 'throne_glow.png')
# core: a round, irregular burst of light centred on the seat - no shape that could read as a figure.
# Spikes alternate jasper (clear, sea-green) and carnelian (sardine stone) - Rev 4:3.
BS = 128
core = Image.new('RGBA', (BS * 4, BS)); cp = core.load()
rng = random.Random(9)
for f in range(4):
    ph = [rng.uniform(0, 6.3) for _ in range(4)]
    for y in range(BS):
        for x in range(BS):
            dx, dy = x - BS / 2 + 0.5, y - BS / 2 + 0.5
            d = math.hypot(dx, dy); th = math.atan2(dy, dx)
            spikes = (abs(math.cos(8 * th + ph[0])) ** 10) * 0.9 + (abs(math.cos(13 * th + ph[1])) ** 14) * 0.6
            wob = 0.08 * math.sin(3 * th + ph[2]) + 0.05 * math.sin(5 * th + ph[3])
            R = 24 * (1 + wob) + 34 * spikes
            rho = d / R
            if rho >= 1: continue
            sector = int(((th + math.pi) / (2 * math.pi)) * 16 + ph[0]) % 2
            if d < 15 * (1 + wob): c = C('ffffff')
            elif d < 21 * (1 + wob): c = C('fbff86')
            elif rho < 0.75: c = C('ffffff') if sector else C('fbff86')
            elif sector: c = C('8ff8e2') if rho < 0.9 else C('0eaf9b', 220)
            else: c = C('f57d4a') if rho < 0.9 else C('ea4f36', 220)
            cp[f * BS + x, y] = c
core.save(D + 'throne_core.png')
# rays (additive): soft spokes of light
rays = np.zeros((420, 640, 4), np.uint8)
yy, xx = np.mgrid[0:420, 0:640]
ang = np.arctan2(yy - 150, xx - 320); rr = np.hypot(xx - 320, (yy - 150) * 1.15)
spoke = (np.cos(ang * 12) * 0.5 + 0.5) ** 6
rays[..., :3] = 255; rays[..., 3] = (spoke * np.clip(1 - rr / 330, 0, 1) * 120).astype(np.uint8)
Image.fromarray(rays).save(D + 'rays.png')

# ---------------------------------------------------------------- lamp flame, 4 frames (hand-drawn shapes)
FL = [
    ["...O...", "..OYO..", "..OYO..", ".OYWYO.", ".OYWYO.", "OYYWWYO", "OYWWWYO", ".OYWYO.", "..OOO.."],
    ["..O....", "..OO...", ".OYO...", ".OYYO..", ".OYWYO.", "OYYWYO.", "OYWWWYO", ".OYWYO.", "..OOO.."],
    ["....O..", "...OO..", "...OYO.", "..OYYO.", ".OYWYO.", ".OYWYYO", "OYWWWYO", ".OYWYO.", "..OOO.."],
    ["...O...", "...O...", "..OYO..", "..OYO..", ".OYWYO.", "OYYWYYO", "OYWWWYO", ".OYWYO.", "..OOO.."],
]
fl = Image.new('RGBA', (7 * 4, 9)); fp = fl.load()
for k, fr in enumerate(FL):
    for y, row in enumerate(fr):
        for x, ch in enumerate(row):
            if ch != '.': fp[k * 7 + x, y] = C({'O': 'ea4f36', 'Y': 'f9c22b', 'W': 'ffffff'}[ch])
fl.save(D + 'flame.png')

# ---------------------------------------------------------------- golden bowl of incense (Rev 5:8)
BOWL = ["..XXXXXXX..", ".XWYYYYYYX.", "XYYYYYYYOOX", ".XYYYYYOOX.", "..XXYOOXX..", "....XOX....", "....XYX....",
        "....XOX....", "....XYX....", "....XOX....", "...XXYXX...", "..XYYYOOX..", "..XXXXXXX.."]
bw = Image.new('RGBA', (11, len(BOWL))); bp = bw.load()
for y, row in enumerate(BOWL):
    for x, ch in enumerate(row):
        if ch != '.': bp[x, y] = C({'X': '2e222f', 'W': 'fbff86', 'Y': 'f9c22b', 'O': 'f79617'}[ch])
bw.save(D + 'bowl.png')

# crowns cast before the throne land in two neat rows on the glass in front of the lamps
CROWN_SLOTS = [[CX + (c - 5.5) * 17, row_y] for row_y in (250, 263) for c in range(12)]
layout = {
    'throne': [CX, CY], 'horizon': HORIZON, 'dais': DAIS, 'lamps': LAMPS, 'lamb': [CX, 196],
    'creatures': [['lion', 318, 214], ['ox', 642, 214], ['man', 400, 386], ['eagle', 560, 386]],
    'light': [CX, 122], 'crown_slots': CROWN_SLOTS, 'kneel': [CX, 304],
    'elders': elders,
}
json.dump(layout, open(D + 'layout.json', 'w'), indent=1)
print('elders', len(elders), 'ok')
