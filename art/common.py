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


KNEEL_HIP = 0.66
KNEEL_DROP = 9


def kneel(f, facing):
    """Kneeling: the upper body lowers onto a hand-drawn pool of robe (no feet); robe falls behind in profile."""
    a = np.array(f); ys = np.nonzero(a[..., 3])[0]; top, bot = ys.min(), ys.max()
    hip = top + int((bot - top) * KNEEL_HIP)
    out = np.zeros_like(a)
    xs_hip = np.nonzero(a[hip - 1, :, 3])[0]
    cx = (xs_hip.min() + xs_hip.max()) / 2; half = (xs_hip.max() - xs_hip.min()) / 2
    _robe_pool(out, cx, half, hip + KNEEL_DROP - 2, bot, {'left': 3, 'right': -3}.get(facing, 0))
    up = a[top:hip]
    for k in range(up.shape[0]):
        m = up[k][:, 3] > 0
        out[top + KNEEL_DROP + k][m] = up[k][m]
    return Image.fromarray(out)


def _robe_pool(out, cx, half, y_top, y_bot, back):
    n = y_bot - y_top
    for y in range(y_top, y_bot + 1):
        t = (y - y_top) / max(1, n)
        hw = half + 3 * t ** 0.6                                  # flares gently from the waist
        if y >= y_bot - 1: hw -= 2 - (y_bot - y)                  # rounded bottom corners
        c = cx + back * t
        l, r = int(round(c - hw)), int(round(c + hw))
        for x in range(max(0, l), min(FRAME, r + 1)):
            if x in (l, r) or y == y_bot: col = OUTL
            elif y == y_bot - 1 or x >= r - 2: col = LIGHT if y < y_bot - 1 else MID
            elif x == int(round(c + hw * 0.25)) and y > y_top + n // 2: col = LIGHT   # one soft fold
            else: col = WHITE
            out[y, x] = (*col, 255)


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
