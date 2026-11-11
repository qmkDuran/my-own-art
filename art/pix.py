"""Pixel-art toolkit: palette-only canvases, hard-edged shape masks and cel shading with selective outlines.

Light always comes from the upper left. A part is painted as a mask with a ramp: base tone, a shadow band on the
lower right, a lit band on the upper left, and a contour where it overlaps an earlier part. `finish()` adds the
outer outline in the darkest tone of whatever it touches (a coloured "sel-out", ink where that is too light)."""
from __future__ import annotations

import math

import numpy as np
from PIL import Image, ImageDraw

from palette import PALETTE, RAMPS, WITHER, rgb

Mask = np.ndarray
NAMES: list[str] = list(PALETTE)
INDEX: dict[str, int] = {n: i + 1 for i, n in enumerate(NAMES)}   # 0 = transparent


class Canvas:
    """An indexed canvas: every pixel is a palette name (or empty), plus which ramp painted it."""

    def __init__(self, w: int, h: int) -> None:
        self.w, self.h = w, h
        self.px = np.zeros((h, w), dtype=np.int16)
        self.ramp = np.full((h, w), "", dtype=object)

    # --- masks -------------------------------------------------------------------------------------------------
    def grid(self) -> tuple[np.ndarray, np.ndarray]:
        yy, xx = np.mgrid[0:self.h, 0:self.w]
        return xx + 0.5, yy + 0.5

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, angle: float = 0.0) -> Mask:
        x, y = self.grid()
        dx, dy = x - cx, y - cy
        if angle:
            a = math.radians(angle)
            dx, dy = dx * math.cos(a) + dy * math.sin(a), -dx * math.sin(a) + dy * math.cos(a)
        return (dx / max(rx, 0.01)) ** 2 + (dy / max(ry, 0.01)) ** 2 <= 1.0

    def circle(self, cx: float, cy: float, r: float) -> Mask:
        return self.ellipse(cx, cy, r, r)

    def rect(self, x0: float, y0: float, x1: float, y1: float) -> Mask:
        x, y = self.grid()
        return (x >= x0) & (x < x1) & (y >= y0) & (y < y1)

    def poly(self, pts: list[tuple[float, float]]) -> Mask:
        im = Image.new("L", (self.w, self.h), 0)
        ImageDraw.Draw(im).polygon([(round(px), round(py)) for px, py in pts], fill=255)
        return np.array(im) > 0

    def capsule(self, x0: float, y0: float, x1: float, y1: float, r: float) -> Mask:
        """A thick stroke with round ends (limbs, tails)."""
        x, y = self.grid()
        vx, vy = x1 - x0, y1 - y0
        t = np.clip(((x - x0) * vx + (y - y0) * vy) / max(vx * vx + vy * vy, 0.01), 0, 1)
        return (x - (x0 + t * vx)) ** 2 + (y - (y0 + t * vy)) ** 2 <= r * r

    def taper(self, pts: list[tuple[float, float]], r0: float, r1: float) -> Mask:
        """A stroke along a polyline whose width runs from r0 to r1 (tails, horns, leaves)."""
        m = np.zeros((self.h, self.w), dtype=bool)
        n = len(pts) - 1
        for i in range(n):
            steps = 6
            for k in range(steps):
                t = (i + k / steps) / n
                ax = pts[i][0] + (pts[i + 1][0] - pts[i][0]) * k / steps
                ay = pts[i][1] + (pts[i + 1][1] - pts[i][1]) * k / steps
                m |= self.circle(ax, ay, r0 + (r1 - r0) * t)
        return m | self.circle(pts[-1][0], pts[-1][1], r1)

    def leaf(self, x0: float, y0: float, x1: float, y1: float, width: float) -> Mask:
        """A pointed leaf / petal / flame from (x0,y0) to (x1,y1)."""
        dx, dy = x1 - x0, y1 - y0
        length = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / length, dx / length
        pts = []
        for i in range(13):
            t = i / 12
            w = math.sin(t * math.pi) * width
            pts.append((x0 + dx * t + nx * w, y0 + dy * t + ny * w))
        for i in range(12, -1, -1):
            t = i / 12
            w = math.sin(t * math.pi) * width
            pts.append((x0 + dx * t - nx * w, y0 + dy * t - ny * w))
        return self.poly(pts)

    def solid(self) -> Mask:
        return self.px > 0

    # --- painting ----------------------------------------------------------------------------------------------
    def fill(self, mask: Mask, name: str, ramp: str = "") -> None:
        self.px[mask] = INDEX[name]
        self.ramp[mask] = ramp or _ramp_of(name)

    def dot(self, x: int, y: int, name: str) -> None:
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y, x] = INDEX[name]
            self.ramp[y, x] = _ramp_of(name)

    def part(self, mask: Mask, ramp: str, base: int, shade: float = 0.22, contour: bool = True,
             light: bool = True, gloss: bool = False) -> None:
        """Paint one body part, cel shaded: lower-right shadow band, upper-left lit rim, optional gloss spot."""
        tones = RAMPS[ramp]
        under = self.solid()
        size = _mask_size(mask)
        k = max(1, round(size * shade))
        self.fill(mask, tones[base], ramp)
        shadow = mask & ~_shift(mask, -k // 2 - 1, -k)
        self.fill(shadow, tones[max(base - 1, 0)], ramp)
        if size >= 8:
            deep = mask & ~_shift(mask, 0, -1) & ~_shift(mask, -1, -1)
            self.fill(deep & shadow, tones[max(base - 2, 0)], ramp)
        if light:
            lit = mask & ~_shift(mask, 1, 1) & ~shadow
            self.fill(lit, tones[min(base + 1, len(tones) - 1)], ramp)
        if gloss and size >= 10:
            self.fill(self._gloss(mask), tones[min(base + 2, len(tones) - 1)], ramp)
        if contour:
            edge = mask & ~_shrink(mask) & _grow(under & ~mask)
            self.fill(edge, tones[max(base - 2, 0)], ramp)

    def _gloss(self, mask: Mask) -> Mask:
        ys, xs = np.nonzero(mask)
        x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
        cx, cy = x0 + (x1 - x0) * 0.32, y0 + (y1 - y0) * 0.28
        return mask & self.ellipse(cx, cy, max(1.0, (x1 - x0) * 0.12), max(1.0, (y1 - y0) * 0.08))

    def flat(self, mask: Mask, name: str) -> None:
        """A flat detail colour (markings, mouths) that keeps the ramp of what is under it."""
        self.px[mask] = INDEX[name]

    def erase(self, mask: Mask) -> None:
        self.px[mask] = 0
        self.ramp[mask] = ""

    def finish(self, outline: bool = True) -> "Canvas":
        """The outer outline: each empty pixel touching the sprite takes the darkest tone of what it touches."""
        if not outline:
            return self
        solid = self.solid()
        ring = _grow(solid) & ~solid
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            src = _shift_arr(self.ramp, dx, dy)
            take = ring & (self.px == 0) & (src != "")
            for y, x in zip(*np.nonzero(take)):
                self.fill_one(x, y, _outline_tone(src[y, x]))
        return self

    def fill_one(self, x: int, y: int, name: str) -> None:
        self.px[y, x] = INDEX[name]
        self.ramp[y, x] = "outline"

    def flip(self) -> "Canvas":
        out = Canvas(self.w, self.h)
        out.px = self.px[:, ::-1].copy()
        out.ramp = self.ramp[:, ::-1].copy()
        return out

    def image(self, withered: bool = False) -> Image.Image:
        lut = np.zeros((len(NAMES) + 1, 4), dtype=np.uint8)
        for n, i in INDEX.items():
            lut[i] = rgb(WITHER.get(n, n) if withered else n)
        return Image.fromarray(lut[self.px], "RGBA")

    def paste(self, other: "Canvas", ox: int, oy: int) -> None:
        h, w = other.h, other.w
        for y in range(h):
            for x in range(w):
                if other.px[y, x] and 0 <= x + ox < self.w and 0 <= y + oy < self.h:
                    self.px[y + oy, x + ox] = other.px[y, x]
                    self.ramp[y + oy, x + ox] = other.ramp[y, x]


def _ramp_of(name: str) -> str:
    for r, tones in RAMPS.items():
        if name in tones:
            return r
    return "ink"


def _outline_tone(ramp: str) -> str:
    if ramp in ("", "outline", "ink"):
        return "ink"
    tones = RAMPS[ramp]
    return "ink" if ramp in ("skin",) else tones[0]


def _mask_size(mask: Mask) -> int:
    ys, xs = np.nonzero(mask)
    if len(xs) == 0:
        return 0
    return int(min(xs.max() - xs.min(), ys.max() - ys.min()) + 1)


def _shift(m: Mask, dx: int, dy: int) -> Mask:
    """Mask moved by (dx, dy); pixels moved in from outside are empty."""
    return _shift_arr(m, dx, dy)


def _shift_arr(a: np.ndarray, dx: int, dy: int) -> np.ndarray:
    out = np.full_like(a, "") if a.dtype == object else np.zeros_like(a)
    h, w = a.shape
    ys = slice(max(dy, 0), h + min(dy, 0))
    xs = slice(max(dx, 0), w + min(dx, 0))
    yd = slice(max(-dy, 0), h + min(-dy, 0))
    xd = slice(max(-dx, 0), w + min(-dx, 0))
    out[ys, xs] = a[yd, xd]
    return out


def _grow(m: Mask) -> Mask:
    return m | _shift(m, 1, 0) | _shift(m, -1, 0) | _shift(m, 0, 1) | _shift(m, 0, -1)


def _shrink(m: Mask) -> Mask:
    return m & _shift(m, 1, 0) & _shift(m, -1, 0) & _shift(m, 0, 1) & _shift(m, 0, -1)


def eye(c: Canvas, x: int, y: int, h: int = 5, w: int = 3, iris: str = "ink2", look: int = 0) -> None:
    """A friendly eye: ink oval, a coloured lower iris and a cream glint on the upper left."""
    m = c.ellipse(x + w / 2, y + h / 2, w / 2 + 0.01, h / 2 + 0.01)
    c.flat(m, "ink")
    if h >= 4:
        c.flat(m & c.rect(x, y + h * 0.6, x + w, y + h), iris)
    gx = x + (1 if look > 0 and w > 2 else 0)
    c.dot(gx, y + 1 if h >= 4 else y, "cream")
    if h >= 6 and w >= 4:
        c.dot(gx + 1, y + 1, "cream")
        c.dot(gx, y + 2, "cream")


def closed_eye(c: Canvas, x: int, y: int, w: int = 4) -> None:
    """A content, shut eye: a small downward arc."""
    for i in range(w):
        c.dot(x + i, y + (0 if 0 < i < w - 1 else 1), "ink")


def blush(c: Canvas, x: int, y: int, w: int = 3) -> None:
    c.flat(c.rect(x, y, x + w, y + 1), "rose2")
