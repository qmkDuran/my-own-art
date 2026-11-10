"""Layout sanity scan (no Godot): trees fully on grass, nobody in water / hidden behind a canopy / inside a collider,
props off paths and water. Usage (from heaven/): python3 -I tools/scan_layout.py"""
import json
import numpy as np
from PIL import Image

CANOPY = (-54, -109, 55, 10)          # tree sprite footprint around its trunk base (x0, y0, x1, y1)
PERSON = (-14, -58, 14, 1)
issues = []


def rect(base, off): return (base[0] + off[0], base[1] + off[1], base[0] + off[2], base[1] + off[3])
def overlap(a, b): return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def garden():
    c = json.load(open('game/data/city.json'))
    r0, r1 = c['river']; sx0, sx1 = c['street_x']
    banks = c['banks']
    trees = [(t[1], t[2]) for t in c['trees']]
    for x, y in trees:
        x0, y0, x1, y1 = rect((x, y), CANOPY)
        bank = [b for b in banks if b[0] <= y0 and y1 <= b[1]]
        if not bank: issues.append(f'garden tree {x},{y}: canopy {y0}-{y1} not within one grass bank')
        if not (x1 < sx0 - 3 or x0 > sx1 + 3): issues.append(f'garden tree {x},{y}: canopy over the gold street')
        if y0 < 160: issues.append(f'garden tree {x},{y}: canopy over the wall')
        if y1 > 292 and y1 <= 318 and x0 < sx0: issues.append(f'garden tree {x},{y}: roots on the riverside path')
    shepherd = c.get('shepherd')
    people = c['people'] + ([['shepherd', shepherd['at'][0], shepherd['at'][1]]] if shepherd else [])
    for p in people:
        x, y = p[1], p[2]
        if y > 540: continue
        if r0 <= y <= r1 and not (sx0 <= x <= sx1): issues.append(f'garden person {p[0]} at {x},{y}: in the river')
        for tx, ty in trees:
            if overlap(rect((x, y), PERSON), rect((tx, ty), CANOPY)) and y < ty:
                issues.append(f'garden person {p[0]} at {x},{y}: hidden behind the tree at {tx},{ty}')
            if abs(x - tx) < 21 and ty - 9 <= y <= ty + 4: issues.append(f'garden person {p[0]}: on a tree trunk')
        if 292 <= y <= 316 and x < sx0: issues.append(f'garden person {p[0]} at {x},{y}: standing on the riverside path')


def earth():
    L = json.load(open('game/art/earth/layout.json'))
    path = np.load('game/art/earth/_path.npy'); stream = np.load('game/art/earth/_stream.npy')
    H, W = path.shape
    def touches(m, r):
        x0, y0, x1, y1 = [int(v) for v in r]
        return m[max(0, y0):min(H, y1), max(0, x0):min(W, x1)].any()
    for n, x, y in L['trees']:
        r = rect((x, y), CANOPY)
        if touches(path, r): issues.append(f'earth tree {n} at {x},{y}: canopy over a path')
        if touches(stream, r): issues.append(f'earth tree {n} at {x},{y}: canopy over the stream')
        if r[1] < 160: issues.append(f'earth tree {n} at {x},{y}: canopy over the wall')
    for n, x, y in L['animals']:
        if touches(stream, (x - 16, y - 4, x + 16, y + 1)): issues.append(f'earth animal {n}: in the stream')
        if touches(path, (x - 16, y - 4, x + 16, y + 1)): issues.append(f'earth animal {n}: standing on a path')
    for n, x, base in L['houses']:
        w = Image.open(f'game/art/earth/{n}.png').width
        if touches(stream, (x - w / 2, base - 40, x + w / 2, base)): issues.append(f'earth house {n}: over the stream')
        if touches(path, (x - w / 2 + 20, base - 30, x + w / 2 - 20, base - 16)): issues.append(f'earth house {n}: on a path')


ROWS = {'down': 0, 'up': 1, 'left': 2, 'right': 2}
_boxes = {}


def sprite_box(sheet, facing, x, y):
    """World box of a standing character's opaque pixels (origin at the feet, frame centred on x)."""
    key = (sheet, facing)
    if key not in _boxes:
        path = 'game/art/hero.png' if sheet == 'PLAYER' else f'game/art/people/{sheet}.png'
        a = np.array(Image.open(path).convert('RGBA'))[ROWS[facing] * 64:ROWS[facing] * 64 + 64, :64, 3]
        ys, xs = np.nonzero(a)
        x0, x1 = xs.min() - 32, xs.max() + 1 - 32
        if facing == 'right': x0, x1 = -x1, -x0
        _boxes[key] = (x0, ys.min() - ys.max() - 1, x1, 0)
    b = _boxes[key]
    return (x + b[0], y + b[1], x + b[2], y + b[3])


def overlaps():
    """No two characters' sprite boxes may overlap by more than 10% of the smaller box, in any scene."""
    for scene in ('city', 'earth'):
        c = json.load(open(f'game/data/{scene}.json'))
        chars = [(q[0] if isinstance(q[0], str) else f'p{q[0]:02d}', q[1], q[2], q[4]) for q in c['people']]
        if c.get('shepherd'):
            sh = c['shepherd']; chars.append((sh['sheet'], sh['at'][0], sh['at'][1], sh['facing']))
        # where the player is placed to stand still: demo pauses and fast-travel spots
        prev = c['demo'].get('start', c['player_start'])
        for w in c['demo']['waypoints']:          # facing = direction of the last move into the stop
            dx, dy = w[0] - prev[0], w[1] - prev[1]
            face = ('right' if dx > 0 else 'left') if abs(dx) > abs(dy) else ('down' if dy > 0 else 'up')
            if w[2] > 0: chars.append(('PLAYER', w[0], w[1], face))
            prev = w
        tscn = {'city': 'res://main.tscn', 'earth': 'res://earth.tscn'}[scene]
        for pl in json.load(open('game/data/places.json'))['places']:
            if pl['scene'] == tscn: chars.append(('PLAYER', pl['at'][0], pl['at'][1], pl.get('face', 'down')))
        boxes = [(n, sprite_box(n, f, x, y)) for n, x, y, f in chars]
        if scene == 'city':                          # nobody (player stops included) standing behind a garden canopy
            for n, b in boxes:
                for t in c['trees']:
                    cb = rect((t[1], t[2]), CANOPY)
                    if b[3] < t[2] and b[3] > cb[1] and min(b[2], cb[2]) - max(b[0], cb[0]) > 2 and b[3] <= 540:
                        issues.append(f'city: {n} at foot y {b[3]} stands behind the tree canopy at {t[1]},{t[2]}')
        for i, (n, a) in enumerate(boxes):
            for m, b in boxes[i + 1:]:
                if n == m == 'PLAYER': continue
                w = min(a[2], b[2]) - max(a[0], b[0]); h = min(a[3], b[3]) - max(a[1], b[1])
                if w <= 0 or h <= 0: continue
                small = min((a[2] - a[0]) * (a[3] - a[1]), (b[2] - b[0]) * (b[3] - b[1]))
                if w * h > 0.10 * small:
                    issues.append(f'{scene}: {n} and {m} overlap {100 * w * h / small:.0f}% of the smaller sprite')


def district():
    L = json.load(open('game/art/district/layout.json'))
    s0, s1 = L['street']
    for n, cx, base, w in L['dwellings']:
        if base > s0: issues.append(f'district dwelling {n}: base in the great street')
    for i, (n, cx, base, w) in enumerate(L['dwellings']):
        for m, cx2, b2, w2 in L['dwellings'][i + 1:]:
            if abs(cx - cx2) < (w + w2) / 2: issues.append(f'district dwellings {n}/{m} overlap')


if __name__ == '__main__':
    garden(); earth(); district(); overlaps()
    for i in issues: print(i)
    print(f'{len(issues)} layout issues')
