"""Shared helpers for every art build script (palette, colours, quantizing, sprite operations).
Import from the heaven/ folder:  sys.path.insert(0, 'art'); from common import *"""
import os, sys
from collections import deque
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'tools'))
from plh import RGB, R64, contact  # noqa: E402  (palette lives with the API helpers)

PALA = np.array(RGB)
FRAME = 64                      # character frame size
FEET_ROW = 61                   # feet sit on this row of a 64x64 frame


def H(hexcode):
    """'2e222f' -> (46, 34, 47)"""
    return tuple(int(hexcode[i:i + 2], 16) for i in (0, 2, 4))


def C(hexcode, alpha=255):
    """'2e222f' -> (46, 34, 47, 255)"""
    return H(hexcode) + (alpha,)


OUTL = H('2e222f')              # outline colour (RGB)
OUT = C('2e222f')               # outline colour (RGBA)
WHITE, LIGHT, MID = H('ffffff'), H('c7dcd0'), H('9babb2')   # robe ramp


def dith(x, y):
    """4x4 Bayer threshold in 0..1."""
    m = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
    return (m[y % 4][x % 4] + 0.5) / 16


def _nearest(rgb):
    return PALA[((rgb[:, None, :].astype(int) - PALA[None]) ** 2).sum(2).argmin(1)]


def quant(im):
    """Snap an image to Resurrect 64 and make alpha binary (threshold 128)."""
    a = np.array(im.convert('RGBA')).astype(int)
    q = _nearest(a[..., :3].reshape(-1, 3)).reshape(a.shape[:2] + (3,))
    return Image.fromarray(np.dstack([q, np.where(a[..., 3] >= 128, 255, 0)]).astype(np.uint8), 'RGBA')


def snap_rgb(img, opaque=True):
    """Palette-snap a whole background image (keeps or forces alpha)."""
    a = np.array(img)
    a[..., :3] = _nearest(a[..., :3].reshape(-1, 3)).reshape(a.shape[:2] + (3,))
    if opaque: a[..., 3] = 255
    return Image.fromarray(a)


def radial_glow(w, h, cx, cy, rx, ry, col, amax, p=1.8):
    """Smooth elliptical glow (RGBA ndarray) for additive light sprites."""
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.sqrt(((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2)
    g = np.zeros((h, w, 4), np.uint8); g[..., :3] = C(col)[:3]; g[..., 3] = (np.clip(1 - r, 0, 1) ** p * amax).astype(np.uint8)
    return g


# ------------------------------------------------------------------ character frames
def feet_to(im, row=FEET_ROW):
    b = im.getbbox(); g = Image.new('RGBA', (FRAME, FRAME)); g.alpha_composite(im, (0, row - b[3] + 1)); return g


def breathe(f):
    """Idle 'breath': the upper body (above the waist) sinks 1 px, feet stay."""
    b = f.getbbox(); waist = b[1] + int((b[3] - b[1]) * 0.55)
    g = Image.new('RGBA', (FRAME, FRAME)); g.alpha_composite(f.crop((0, waist, FRAME, FRAME)), (0, waist))
    g.alpha_composite(f.crop((0, 0, FRAME, waist)), (0, 1)); return g


KNEEL_HIP = 0.62          # where the robe below the waist starts (fraction of the figure's height)
KNEEL_DROP = 0.2          # how much shorter a kneeling figure is
ROBE = {WHITE, LIGHT, MID}


def _robe_extent(a, y):
    """Left/right x of the robe on row y: the longest run of robe colours (ignores arms, palms, hair)."""
    best, run = (0, -1), None
    for x in range(a.shape[1] + 1):
        inside = x < a.shape[1] and a[y, x, 3] and tuple(a[y, x, :3]) in ROBE
        if inside and run is None: run = x
        if not inside and run is not None:
            if x - 1 - run > best[1] - best[0]: best = (run, x - 1)
            run = None
    return best


def kneel(f, facing):
    """Kneeling upright in worship, drawn by hand on the frame (no basin shape, no rim line):
    down  - the robe falls over two knees (rounded bumps, a fold between them);
    up    - from behind: folds converge to the waist, the soles of both feet show below the hem;
    left/right - profile: knees under the body, shins and heel along the ground behind."""
    a = np.array(f); ys = np.nonzero(a[..., 3])[0]; top, bot = int(ys.min()), int(ys.max())
    hgt = bot - top + 1
    hip = top + int(hgt * KNEEL_HIP); drop = int(hgt * KNEEL_DROP)
    x0, x1 = _robe_extent(a, hip + 2)
    sole = _sole_colour(a, bot)
    y0 = hip + drop
    mask = np.zeros(a.shape[:2], bool)
    if facing in ('left', 'right'):
        _profile_mask(mask, x0, x1, y0, bot, 1 if facing == 'left' else -1)
    else:
        _front_back_mask(mask, x0, x1, y0, bot - (2 if facing == 'up' else 0), facing == 'down')
    out = np.zeros_like(a)
    _paint_robe(out, mask, y0, (x0 + x1) / 2.0, facing)
    if facing == 'up':
        _soles(out, (x0 + x1) / 2.0, bot, sole)
    elif facing in ('left', 'right'):
        _heel(out, mask, bot, sole, 1 if facing == 'left' else -1)
    up = a[top:hip + 1]
    for k in range(up.shape[0]):
        m = up[k][:, 3] > 0
        out[top + drop + k][m] = up[k][m]
    return Image.fromarray(out)


def _sole_colour(a, bot):
    """Sandal/skin colour from the original feet (bottom rows), so the soles match the person."""
    cols = {}
    for y in range(bot - 2, bot + 1):
        for x in range(a.shape[1]):
            c = tuple(a[y, x, :3])
            if a[y, x, 3] and c not in ROBE and c != OUTL: cols[c] = cols.get(c, 0) + 1
    return max(cols, key=cols.get) if cols else H('966c6c')


def _front_back_mask(mask, x0, x1, y0, y1, knees):
    n = max(1, y1 - y0)
    for y in range(y0, y1 + 1):
        grow = int(round(2 * (y - y0) / n))                    # the robe flares a little toward the ground
        mask[y, max(0, x0 - 1 - grow):min(FRAME, x1 + 2 + grow)] = True
    cx = (x0 + x1) / 2.0
    for x in range(FRAME):                                     # rounded corners; knees: a dip between them
        if not mask[y1, x]: continue
        u = abs(x - cx) / ((x1 - x0) / 2.0 + 3)
        cut = 2 if u > 0.92 else (1 if u > 0.8 or (knees and u < 0.1) else 0)
        for k in range(cut): mask[y1 - k, x] = False


def _profile_mask(mask, x0, x1, y0, y1, fwd):
    """fwd = +1 facing left (knees to the left), -1 facing right."""
    front, back = (x0 - 1, x1 + 1) if fwd > 0 else (x1 + 1, x0 - 1)
    shin = max(5, (x1 - x0) // 2 + 3)                       # shins about half the body's width behind
    for y in range(y0, y1 + 1):
        f = front - fwd * (1 if y >= y1 - 5 else 0)            # the knee pushes the robe forward a little
        b = back + fwd * (shin if y >= y1 - 3 else 0)          # shins and feet lie along the ground behind
        lo, hi = sorted((f, b))
        mask[y, max(0, lo):min(FRAME, hi + 1)] = True
    tip = back + fwd * shin                                    # round the end of the shin
    for y in (y1 - 3, y1):
        if 0 <= tip < FRAME: mask[y, tip] = False


def _paint_robe(out, mask, y_top, cx, facing):
    h, w = mask.shape
    def inside(y, x): return y < y_top or (0 <= y < h and 0 <= x < w and mask[y, x])   # no outline along the waist
    for y, x in zip(*np.nonzero(mask)):
        edge = not all(inside(y + dy, x + dx) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge: col = OUTL
        elif not inside(y + 1, x) or not inside(y + 2, x): col = LIGHT          # soft shade along the ground
        elif x > cx + 2 and facing != 'right': col = LIGHT                     # shaded side (light from top-left)
        else: col = WHITE
        out[y, x] = (*col, 255)
    ys = np.nonzero(mask.any(1))[0]
    if facing not in ('up', 'down') or not len(ys): return
    y0, y1 = ys.min(), ys.max()
    for y in range(y0 + 1, y1 - 1):                            # folds that follow the body
        t = (y - y0) / max(1, y1 - y0)
        for dx in ((-1 - 2 * t, 1 + 2 * t) if facing == 'up' else (0,)):
            x = int(round(cx + dx))
            if mask[y, x] and tuple(out[y, x, :3]) == WHITE: out[y, x, :3] = MID if facing == 'up' else LIGHT


def _soles(out, cx, bot, sole):
    """Seen from behind: the soles of both feet below the hem (4 x 3 each)."""
    for side in (-1, 1):
        xa = int(round(cx)) + (1 if side > 0 else -5)
        for y in range(bot - 2, bot + 1):
            for x in range(xa, xa + 4):
                edge = y in (bot - 2, bot) or x in (xa, xa + 3)
                out[y, x] = (*(OUTL if edge else sole), 255)


def _heel(out, mask, bot, sole, fwd):
    """Profile: the heel at the back end of the shin."""
    cols = np.nonzero(mask[bot - 1])[0]
    if not len(cols): return
    xb = cols.max() if fwd > 0 else cols.min()
    for y in range(bot - 3, bot + 1):
        for x in (xb - fwd, xb, xb + fwd):
            if 0 <= x < FRAME:
                out[y, x] = (*OUTL, 255) if (y in (bot - 3, bot) or x == xb + fwd) else (*sole, 255)


PALM = {H(c) for c in ('1ebc73', '239063', '165a4c', '91db69', '0b5e65', '0b8a8f', '313638', '547e64', '92a984', '374e4a', 'cddf6c')}


def palm_mask(a):
    """Pixels of a palm frond (its greens plus the outline pixels that touch them)."""
    m = np.zeros(a.shape[:2], bool)
    for y, x in zip(*np.nonzero(a[..., 3])):
        if tuple(a[y, x, :3]) in PALM: m[y, x] = True
    ring = np.zeros_like(m)
    for y, x in zip(*np.nonzero(m)):
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < a.shape[0] and 0 <= nx < a.shape[1] and a[ny, nx, 3] and tuple(a[ny, nx, :3]) == OUTL: ring[ny, nx] = True
    return m | ring


def sway(f, shift):
    """Palm branch leans `shift` px at its tip; a row-wise shift keeps the frond solid. None if no palm."""
    a = np.array(f); m = palm_mask(a)
    if m.sum() < 25: return None
    ys, xs = np.nonzero(m); y_top, y_bot = ys.min(), ys.max()
    out = a.copy(); out[m] = (0, 0, 0, 0)
    for y, x in zip(ys, xs):                     # refill from the nearest non-frond pixel on the left
        l = (a[y, max(0, x - 4):x, 3] > 0) & ~m[y, max(0, x - 4):x]
        r = (a[y, x + 1:x + 5, 3] > 0) & ~m[y, x + 1:x + 5]
        if l.any() and r.any():
            for lx in range(x - 1, max(-1, x - 5), -1):
                if a[y, lx, 3] and not m[y, lx]: out[y, x] = a[y, lx]; break
    for y in range(y_top, y_bot + 1):
        k = (y_bot - y) / max(1, y_bot - y_top)
        dx = int(round(shift * k ** 0.8))
        for x in np.nonzero(m[y])[0]:
            if 0 <= x + dx < a.shape[1]: out[y, x + dx] = a[y, x]
    return Image.fromarray(out)


# ------------------------------------------------------------------ cleanup of generated sprites
def recolor(im, mapping):
    """{'src hex': 'dst hex'} exact colour swaps."""
    a = np.array(im)
    for src, dst in mapping.items():
        s = H(src)
        m = (a[..., 0] == s[0]) & (a[..., 1] == s[1]) & (a[..., 2] == s[2]) & (a[..., 3] > 0)
        a[m, :3] = H(dst)
    return Image.fromarray(a)


def _neighbours4(y, x):
    return ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1))


def strip_bg(im, bgcols):
    """Flood-fill from the border through background colours (stops at the outline)."""
    a = np.array(im); h, w = a.shape[:2]
    seen = np.zeros((h, w), bool)
    q = deque([(0, x) for x in range(w)] + [(h - 1, x) for x in range(w)] + [(y, 0) for y in range(h)] + [(y, w - 1) for y in range(h)])
    while q:
        y, x = q.popleft()
        if not (0 <= y < h and 0 <= x < w) or seen[y, x]: continue
        if a[y, x, 3] and tuple(a[y, x, :3]) not in bgcols: continue
        seen[y, x] = True; a[y, x, 3] = 0
        q.extend(_neighbours4(y, x))
    return Image.fromarray(a)


def keep_main(im, min_frac=0.25):
    """Drop small detached pieces (halos, sparkles) that float apart from the figure."""
    a = np.array(im); h, w = a.shape[:2]
    lab = -np.ones((h, w), int); sizes = []
    for y in range(h):
        for x in range(w):
            if a[y, x, 3] and lab[y, x] < 0:
                sizes.append(_flood_label(a, lab, y, x, len(sizes)))
    big = max(sizes)
    for k, n in enumerate(sizes):
        if n < big * min_frac: a[lab == k, 3] = 0
    return Image.fromarray(a)


def _flood_label(a, lab, y, x, k):
    h, w = lab.shape; n = 0; q = deque([(y, x)]); lab[y, x] = k
    while q:
        cy, cx = q.popleft(); n += 1
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < h and 0 <= nx < w and a[ny, nx, 3] and lab[ny, nx] < 0:
                    lab[ny, nx] = k; q.append((ny, nx))
    return n


def erode_ground(im, colors, y0=0):
    """Remove generated ground patches: peel pixels of the given colours that touch transparency (outline-protected)."""
    a = np.array(im); h, w = a.shape[:2]; cols = {H(c) for c in colors}
    changed = True
    while changed:
        changed = False
        for y in range(y0, h):
            for x in range(w):
                if a[y, x, 3] and tuple(a[y, x, :3]) in cols:
                    if any(not (0 <= ny < h and 0 <= nx < w) or a[ny, nx, 3] == 0 for ny, nx in _neighbours4(y, x)):
                        a[y, x, 3] = 0; changed = True
    return Image.fromarray(a)
