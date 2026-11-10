"""Pixel-art helpers for hand fixes (no generation): palette snap, 2:1 majority reduction,
low-saliency row/column removal, re-outlining. Used by tools/art_handfix.py."""
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUTLINE = (0x2E, 0x22, 0x2F)


def palette() -> np.ndarray:
    hexes = (ROOT / "art/style_anchors/resurrect64.hex").read_text().split()
    return np.array([[int(h[i:i + 2], 16) for i in (0, 2, 4)] for h in hexes if len(h) == 6], dtype=np.int32)


def snap(arr: np.ndarray, extra: list | None = None) -> np.ndarray:
    """Snaps RGB to the Resurrect 64 palette (+ extra allowed colours), alpha to 0/255."""
    pal = palette()
    if extra:
        pal = np.vstack([pal, np.array(extra, dtype=np.int32)])
    out = arr.copy()
    rgb = out[..., :3].astype(np.int32).reshape(-1, 3)
    d = ((rgb[:, None, :] - pal[None, :, :]) ** 2).sum(-1)
    out[..., :3] = pal[d.argmin(1)].reshape(out.shape[:2] + (3,)).astype(np.uint8)
    out[..., 3] = np.where(out[..., 3] >= 128, 255, 0)
    return out


def reduce_2to1(arr: np.ndarray) -> np.ndarray:
    """2:1 reduction by majority vote of each 2x2 block (outline colour wins ties so edges survive)."""
    h, w = arr.shape[0] // 2 * 2, arr.shape[1] // 2 * 2
    arr = arr[:h, :w]
    out = np.zeros((h // 2, w // 2, 4), dtype=np.uint8)
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            block = arr[y:y + 2, x:x + 2].reshape(-1, 4)
            opaque = [tuple(p[:3]) for p in block if p[3] > 127]
            if len(opaque) < 2:
                continue
            counts = Counter(opaque).most_common()
            best = counts[0][1]
            winners = [c for c, n in counts if n == best]
            colour = OUTLINE if OUTLINE in winners else winners[0]
            out[y // 2, x // 2] = (*colour, 255)
    return out


def reoutline(arr: np.ndarray) -> np.ndarray:
    """Every opaque pixel touching transparency (4-neighbour) becomes the outline colour."""
    a = arr[..., 3] > 0
    pad = np.pad(a, 1)
    edge = a & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    out = arr.copy()
    out[edge, :3] = OUTLINE
    return out


def _line_cost(arr: np.ndarray, axis: int) -> np.ndarray:
    """Cost of removing each row (axis 0) or column (axis 1): pixels differing from the previous line."""
    a = arr.astype(np.int32)
    if axis == 0:
        diff = (np.abs(a[1:] - a[:-1]).sum(-1) > 0).sum(1)
    else:
        diff = (np.abs(a[:, 1:] - a[:, :-1]).sum(-1) > 0).sum(0)
    return np.concatenate([[10 ** 9], diff])


def shrink_mask(arr: np.ndarray, target: int, axis: int, protect: list | None = None) -> np.ndarray:
    """Which whole rows (axis 0) / columns (axis 1) to keep so the size along `axis` becomes
    `target`, dropping the least visible lines first (those that repeat their neighbour).
    `protect` = list of (start, end) index ranges never removed. Removals are spread out: a line
    next to an already removed one is avoided while possible."""
    keep = np.ones(arr.shape[axis], dtype=bool)
    cost = _line_cost(arr, axis).astype(np.float64)
    for s, e in protect or []:
        cost[s:e] = 1e9
    cost[0] = cost[-1] = 1e9
    order = np.argsort(cost, kind="stable")
    to_remove = arr.shape[axis] - target
    removed = 0
    for spacing in (3, 2, 1, 0):
        for i in order:
            if removed >= to_remove:
                break
            if not keep[i] or cost[i] >= 1e9:
                continue
            lo, hi = max(0, i - spacing), min(len(keep), i + spacing + 1)
            if spacing and not keep[lo:hi].all():
                continue
            keep[i] = False
            removed += 1
        if removed >= to_remove:
            break
    return keep


def shrink_lines(arr: np.ndarray, target: int, axis: int, protect: list | None = None) -> np.ndarray:
    keep = shrink_mask(arr, target, axis, protect)
    return arr[keep] if axis == 0 else arr[:, keep]


def load(path) -> np.ndarray:
    return np.array(Image.open(path).convert("RGBA"))


def save(arr: np.ndarray, path) -> None:
    Image.fromarray(arr.astype(np.uint8), "RGBA").save(path)


def epx2(arr: np.ndarray) -> np.ndarray:
    """Scale2x/EPX: 2x magnification that keeps hard pixel edges and diagonals (no new colours)."""
    h, w = arr.shape[:2]
    p = np.pad(arr, ((1, 1), (1, 1), (0, 0)), mode="edge")
    key = p[..., 0].astype(np.int64) << 24 | p[..., 1].astype(np.int64) << 16 | p[..., 2].astype(np.int64) << 8 | p[..., 3]
    P = key[1:-1, 1:-1]
    A, B, C, D = key[:-2, 1:-1], key[1:-1, 2:], key[1:-1, :-2], key[2:, 1:-1]
    src = np.zeros((h * 2, w * 2), dtype=np.int64)
    e0 = np.where((C == A) & (C != D) & (A != B), A, P)
    e1 = np.where((A == B) & (A != C) & (B != D), B, P)
    e2 = np.where((D == C) & (D != B) & (C != A), C, P)
    e3 = np.where((B == D) & (B != A) & (D != C), D, P)
    src[0::2, 0::2], src[0::2, 1::2], src[1::2, 0::2], src[1::2, 1::2] = e0, e1, e2, e3
    out = np.zeros((h * 2, w * 2, 4), dtype=np.uint8)
    out[..., 0] = (src >> 24) & 255
    out[..., 1] = (src >> 16) & 255
    out[..., 2] = (src >> 8) & 255
    out[..., 3] = src & 255
    return out


def rescale_pixel_art(arr: np.ndarray, factor: float) -> np.ndarray:
    """Resizes by `factor` (0.5..2) without inventing colours: EPX 2x, then nearest sampling."""
    big = epx2(arr)
    h, w = arr.shape[:2]
    nh, nw = max(1, round(h * factor)), max(1, round(w * factor))
    ys = np.clip(((np.arange(nh) + 0.5) * (2 * h) / nh).astype(int), 0, 2 * h - 1)
    xs = np.clip(((np.arange(nw) + 0.5) * (2 * w) / nw).astype(int), 0, 2 * w - 1)
    return big[ys][:, xs]


def remove_stray_outline(arr: np.ndarray, rounds: int = 6) -> np.ndarray:
    """Deletes outline-coloured pixels that border no filled (non-outline) pixel: leftover lines."""
    out = arr.copy()
    for _ in range(rounds):
        opaque = out[..., 3] > 0
        is_ol = opaque & (out[..., 0] == OUTLINE[0]) & (out[..., 1] == OUTLINE[1]) & (out[..., 2] == OUTLINE[2])
        fill = opaque & ~is_ol
        pad = np.pad(fill, 1)
        near = np.zeros_like(fill)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                near |= pad[1 + dy:pad.shape[0] - 1 + dy, 1 + dx:pad.shape[1] - 1 + dx]
        kill = is_ol & ~near
        if not kill.any():
            break
        out[kill] = 0
    return out
