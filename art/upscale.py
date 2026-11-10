"""Pixel-art 2x upscale for buildings that must match the people's scale: Scale2x (EPX) keeps diagonals clean,
then the doubled outlines are thinned back to 1 px so line weight matches every other sprite."""
import sys
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
from common import OUTL


def scale2x(a):
    h, w = a.shape[:2]
    out = np.zeros((h * 2, w * 2, 4), a.dtype)
    P = lambda y, x: tuple(a[min(max(y, 0), h - 1), min(max(x, 0), w - 1)])
    for y in range(h):
        for x in range(w):
            p = tuple(a[y, x]); A, B, C, D = P(y - 1, x), P(y, x + 1), P(y, x - 1), P(y + 1, x)
            e = [p, p, p, p]
            if C == A and C != D and A != B: e[0] = A
            if A == B and A != C and B != D: e[1] = B
            if D == C and D != B and C != A: e[2] = C
            if B == D and B != A and D != C: e[3] = D
            out[2 * y, 2 * x], out[2 * y, 2 * x + 1], out[2 * y + 1, 2 * x], out[2 * y + 1, 2 * x + 1] = e
    return out


def thin_outline(a):
    """Outline pixels whose outward neighbour is also outline become the inner colour: 2 px lines -> 1 px."""
    h, w = a.shape[:2]
    out = a.copy()
    is_out = (a[..., 3] > 0) & (a[..., 0] == OUTL[0]) & (a[..., 1] == OUTL[1]) & (a[..., 2] == OUTL[2])
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if not is_out[y, x]: continue
            for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                outer, inner = (y - dy, x - dx), (y + dy, x + dx)
                if is_out[outer] and a[inner][3] and not is_out[inner]:
                    out[y, x] = a[inner]; break
    return out


def upscale(im):
    return Image.fromarray(thin_outline(scale2x(np.array(im.convert('RGBA')))))


if __name__ == '__main__':
    im = Image.open(sys.argv[1]); up = upscale(im); up.save(sys.argv[2]); print(up.size)
