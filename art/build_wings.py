"""Hand-made wing motion (no generation). Wings rise and fall by a column shear: every pixel outside the body's
central column moves vertically in proportion to its distance from the body, so wing roots stay attached and the
tips travel furthest; eye-jewel motifs ride along with their feathers. Writes:
  game/art/throne/creature_<kind>_flap.png  (6 frames in a row, slow majestic loop)
  game/art/throne/angels_flap.png           (20 angels x 4 frames, rows = frames)"""
import math
import numpy as np
from PIL import Image

D = 'game/art/throne/'


def shear_frame(a, body0, body1, amp, span, pad, right_ylim=None):
    """Return a copy of RGBA array `a` (padded by `pad` rows top/bottom) with the wing columns shifted."""
    h, w = a.shape[:2]
    out = np.zeros((h + 2 * pad, w, 4), np.uint8)
    for x in range(w):
        dist = body0 - x if x < body0 else (x - body1 if x > body1 else 0)
        dy = int(round(amp * min(1.0, dist / span))) if dist > 0 else 0
        if right_ylim is not None and x > body1:      # keep e.g. the lion's tail still: only rows above move
            out[pad + dy:pad + dy + right_ylim, x] = a[:right_ylim, x]
            lower = a[right_ylim:, x]; keep = lower[:, 3] > 0
            out[pad + right_ylim:pad + h, x][keep] = lower[keep]
        else:
            out[pad + dy:pad + dy + h, x] = a[:, x]
    return out


# body column (x range that stays still) and wing reach per creature, read off the sprites
CREATURES = {'lion': (30, 80, 40), 'ox': (40, 72, 40), 'man': (46, 66, 40), 'eagle': (48, 64, 46)}
YLIM = {'lion': 82}
FRAMES = 6
for kind, (b0, b1, span) in CREATURES.items():
    a = np.array(Image.open(D + f'creature_{kind}.png').convert('RGBA'))
    pad = 4
    frames = []
    for f in range(FRAMES):
        amp = -3.2 * math.sin(2 * math.pi * f / FRAMES)          # negative = wings raised
        frames.append(shear_frame(a, b0, b1, amp, span, pad, YLIM.get(kind)))
    strip = np.concatenate(frames, 1)
    Image.fromarray(strip).save(D + f'creature_{kind}_flap.png')

ang = np.array(Image.open(D + 'angels.png').convert('RGBA'))
n = ang.shape[1] // 32
rows = []
for f, amp in enumerate((0, -1.6, -2.4, -1.0)):                    # 4-frame gentle flap
    row = []
    for k in range(n):
        cell = ang[:, k * 32:(k + 1) * 32]
        row.append(shear_frame(cell, 10, 21, amp, 9, 3))
    rows.append(np.concatenate(row, 1))
Image.fromarray(np.concatenate(rows, 0)).save(D + 'angels_flap.png')

# preview: creature frames + one angel's frames at 3x
prev = Image.new('RGBA', (FRAMES * 120, 4 * 122 + 40), (150, 220, 215, 255))
for r, kind in enumerate(CREATURES):
    s = Image.open(D + f'creature_{kind}_flap.png')
    for f in range(FRAMES):
        prev.alpha_composite(s.crop((f * 112, 0, f * 112 + 112, s.height)), (f * 120, r * 122))
an = Image.open(D + 'angels_flap.png')
for f in range(4):
    prev.alpha_composite(an.crop((0, f * 38, 32, f * 38 + 38)), (f * 40, 4 * 122))
prev.resize((prev.width * 2, prev.height * 2), Image.NEAREST).save('art/work/wings_preview.png')
print('ok', n, 'angels')
