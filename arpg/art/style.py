"""The ARPG's art style, as data and small functions shared by the build scripts and tools/check_palette.py.
Michael's approved sprite (game/art/michael/idle.png, front frame) is the reference: its colours, its 1 px #2e222f
outline, light from the top-left, 3/4 top-down view, and its size (58 px from head to feet without the wings).
See STYLE.md for the rules in words."""
import numpy as np
from PIL import Image

OUTLINE = '2e222f'
MICHAEL_HEIGHT = 58                     # px, head top to feet, without the wings (front idle frame)

# Michael's 20 colours (the reference) ...
MICHAEL = ['c7dcd0', '2e222f', '9babb2', '625565', '7f708a', 'ab947a', 'fdcbb0', '313638', 'ffffff', '4c3e24',
           '676633', '966c6c', '3e3546', 'b2ba90', 'e6904e', 'fbb954', '694f62', 'cd683d', 'fca790', '45293f']
# ... plus the few ramps the night world needs: grass, embers/brick, night blue, gold light, sky glass.
WORLD_EXTRA = ['165a4c', '374e4a', '547e64', '92a984',          # grass and leaves (dark -> light)
               '6e2727', 'b33831',                              # brick, embers, scorch
               '323353', '484a77', '4d65b4',                    # night blue: cars, glass in shadow, signs
               'f9c22b', 'f79617']                              # warm window light, fire
WORLD = MICHAEL + WORLD_EXTRA                                   # 31 colours: every world sprite and the ground

# Real-size rules relative to Michael (measured on the source art; scales chosen to meet them).
DOOR_RATIO = 1.15                       # a door is about 1.15 x Michael's height
CAR_RATIO = (1.6, 1.9)                  # a car is 1.6-1.9 x Michael's height long
FENCE_RATIO = (0.4, 0.6)                # fences are about waist high
PIECES = {  # art: (source door / car length / fence height in px at scale 1, kind, scale)
    'house_a': (45, 'door', 3 / 2), 'house_b': (45, 'door', 3 / 2), 'house_c': (52, 'door', 4 / 3),
    'store': (57, 'door', 6 / 5),
    'car_wreck': (111, 'car', 1.0), 'car_wreck_burned': (111, 'car', 1.0), 'van': (109, 'car', 1.0),
    'suv_red': (109, 'car', 1.0),
    'fence_picket': (36, 'fence', 4 / 5), 'fence_picket_broken': (36, 'fence', 4 / 5), 'fence_chainlink': (40, 'fence', 3 / 4),
}


def H(h): return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


PAL = np.array([H(c) for c in WORLD])


def to_world_palette(im):
    """Every opaque pixel to the nearest WORLD colour (alpha made binary)."""
    a = np.array(im.convert('RGBA'))
    rgb = a[..., :3].reshape(-1, 3).astype(int)
    uniq, inv = np.unique(rgb, axis=0, return_inverse=True)
    idx = ((uniq[:, None, :] - PAL[None]) ** 2).sum(2).argmin(1)
    a[..., :3] = PAL[idx][inv.reshape(-1)].reshape(a.shape[:2] + (3,)).astype(np.uint8)
    a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
    return Image.fromarray(a)


def pixel_rescale(im, num, den):
    """Scale pixel art by num/den without blur: nearest x num, then each den x den block takes its most common colour
    (ties: the darker, so outlines survive)."""
    a = np.array(im.convert('RGBA'))
    if num == den:
        return Image.fromarray(a)
    big = np.repeat(np.repeat(a, num, 0), num, 1)
    h, w = big.shape[0] // den, big.shape[1] // den
    big = big[:h * den, :w * den].reshape(h, den, w, den, 4).transpose(0, 2, 1, 3, 4).reshape(h * w, den * den, 4)
    lum = big[..., 0].astype(int) * 3 + big[..., 1].astype(int) * 6 + big[..., 2].astype(int) + (big[..., 3] == 0) * 10000
    key = (big[..., 0].astype(np.int64) << 24) | (big[..., 1].astype(np.int64) << 16) | (big[..., 2].astype(np.int64) << 8) | big[..., 3]
    n = den * den
    counts = (key[:, :, None] == key[:, None, :]).sum(2)              # how often each block member's colour occurs
    score = counts * 100000 - lum                                      # most common, then darkest
    pick = score.argmax(1)
    out = big[np.arange(h * w), pick].reshape(h, w, 4)
    return Image.fromarray(out.astype(np.uint8))


def outline(im):
    """A 1 px #2e222f outline around the silhouette where the edge has none (like Michael)."""
    a = np.array(im.convert('RGBA'))
    m = a[..., 3] > 0
    e = np.zeros_like(m)
    e[1:] |= m[:-1]; e[:-1] |= m[1:]; e[:, 1:] |= m[:, :-1]; e[:, :-1] |= m[:, 1:]
    ring = e & ~m
    pad = np.zeros((a.shape[0] + 2, a.shape[1] + 2, 4), np.uint8); pad[1:-1, 1:-1] = a
    m2 = pad[..., 3] > 0
    e2 = np.zeros_like(m2)
    e2[1:] |= m2[:-1]; e2[:-1] |= m2[1:]; e2[:, 1:] |= m2[:, :-1]; e2[:, :-1] |= m2[:, 1:]
    pad[e2 & ~m2] = list(H(OUTLINE)) + [255]
    return Image.fromarray(pad)


def edge_outline_share(im):
    """Share of silhouette edge pixels that are the outline colour (for the checker)."""
    a = np.array(im.convert('RGBA'))
    m = a[..., 3] > 0
    inner = m.copy()
    inner[1:] &= m[:-1]; inner[:-1] &= m[1:]; inner[:, 1:] &= m[:, :-1]; inner[:, :-1] &= m[:, 1:]
    edge = m & ~inner
    if not edge.any():
        return 1.0
    return float((a[edge][:, :3] == H(OUTLINE)).all(1).mean())
