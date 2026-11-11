"""Small pixel-art drawing kit on top of PIL: every colour is a palette name, shapes are aliased, and finishing passes
(outline, rim light, emissive layer) give all sprites the same look. Used by every art/build_*.py script."""
from __future__ import annotations

import math
import random

from PIL import Image, ImageDraw

from palette import OUTLINE, PAL, rgba

Point = tuple[float, float]


class Spr:
    """An RGBA sprite drawn with palette colours, plus an emissive layer (pixels that glow in the dark)."""

    def __init__(self, w: int, h: int) -> None:
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)
        self.g = ImageDraw.Draw(self.glow)

    # ---------------------------------------------------------------- primitives
    def px(self, x: float, y: float, c: str, glow: bool = False) -> None:
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((x, y), rgba(c))
            if glow:
                self.glow.putpixel((x, y), rgba(c))

    def rect(self, x0: float, y0: float, x1: float, y1: float, c: str, glow: bool = False) -> None:
        box = [int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))]
        self.d.rectangle(box, fill=rgba(c))
        if glow:
            self.g.rectangle(box, fill=rgba(c))

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, c: str, glow: bool = False) -> None:
        box = [int(round(cx - rx)), int(round(cy - ry)), int(round(cx + rx)), int(round(cy + ry))]
        self.d.ellipse(box, fill=rgba(c))
        if glow:
            self.g.ellipse(box, fill=rgba(c))

    def poly(self, pts: list[Point], c: str, glow: bool = False) -> None:
        p = [(int(round(x)), int(round(y))) for x, y in pts]
        self.d.polygon(p, fill=rgba(c))
        if glow:
            self.g.polygon(p, fill=rgba(c))

    def line(self, pts: list[Point], c: str, width: int = 1, glow: bool = False) -> None:
        p = [(int(round(x)), int(round(y))) for x, y in pts]
        self.d.line(p, fill=rgba(c), width=width)
        if glow:
            self.g.line(p, fill=rgba(c), width=width)

    def opaque(self, x: int, y: int) -> bool:
        return 0 <= x < self.w and 0 <= y < self.h and self.img.getpixel((x, y))[3] > 0

    def color_at(self, x: int, y: int) -> tuple[int, int, int, int]:
        return self.img.getpixel((x, y))

    # ---------------------------------------------------------------- finishing passes
    def recolor_edge(self, dx: int, dy: int, c: str, only: set[str] | None = None, depth: int = 1) -> None:
        """Rim light: pixels whose neighbour toward (dx, dy) is empty take colour c (optionally only on some colours)."""
        src = self.img.copy()
        allowed = None if only is None else {PAL[n] for n in only}
        for y in range(self.h):
            for x in range(self.w):
                p = src.getpixel((x, y))
                if p[3] == 0 or (allowed is not None and p[:3] not in allowed):
                    continue
                for k in range(1, depth + 1):
                    nx, ny = x + dx * k, y + dy * k
                    if not (0 <= nx < self.w and 0 <= ny < self.h) or src.getpixel((nx, ny))[3] == 0:
                        self.img.putpixel((x, y), rgba(c))
                        break

    def outline(self, c: str = OUTLINE) -> None:
        """A 1 px outline around every opaque pixel (4-neighbourhood), the same on all art."""
        src = self.img.copy()
        for y in range(self.h):
            for x in range(self.w):
                if src.getpixel((x, y))[3] != 0:
                    continue
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < self.w and 0 <= ny < self.h and src.getpixel((nx, ny))[3] != 0:
                        self.img.putpixel((x, y), rgba(c))
                        break

    def flipped(self) -> "Spr":
        out = Spr(self.w, self.h)
        out.img = self.img.transpose(Image.FLIP_LEFT_RIGHT)
        out.glow = self.glow.transpose(Image.FLIP_LEFT_RIGHT)
        out.d, out.g = ImageDraw.Draw(out.img), ImageDraw.Draw(out.glow)
        return out


def dither_fill(s: Spr, pts: list[Point], a: str, b: str, ratio: float, seed: int) -> None:
    """Fill a polygon with colour a, then scatter colour b over it (ordered-ish noise) for texture."""
    s.poly(pts, a)
    rnd = random.Random(seed)
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    mask = Image.new("L", (s.w, s.h), 0)
    ImageDraw.Draw(mask).polygon([(int(round(x)), int(round(y))) for x, y in pts], fill=255)
    for y in range(int(min(ys)), int(max(ys)) + 1):
        for x in range(int(min(xs)), int(max(xs)) + 1):
            if 0 <= x < s.w and 0 <= y < s.h and mask.getpixel((x, y)) and rnd.random() < ratio:
                s.px(x, y, b)


def sheet(frames: list[list[Spr]], fw: int, fh: int) -> tuple[Image.Image, Image.Image]:
    """Rows of frames -> (colour sheet, emissive sheet)."""
    cols = max(len(r) for r in frames)
    img = Image.new("RGBA", (cols * fw, len(frames) * fh), (0, 0, 0, 0))
    glow = Image.new("RGBA", (cols * fw, len(frames) * fh), (0, 0, 0, 0))
    for j, row in enumerate(frames):
        for i, f in enumerate(row):
            img.paste(f.img, (i * fw, j * fh))
            glow.paste(f.glow, (i * fw, j * fh))
    return img, glow


def arc_points(cx: float, cy: float, r: float, a0: float, a1: float, n: int) -> list[Point]:
    return [(cx + math.cos(a0 + (a1 - a0) * i / (n - 1)) * r, cy + math.sin(a0 + (a1 - a0) * i / (n - 1)) * r)
            for i in range(n)]
