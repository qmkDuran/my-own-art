"""Style checks for the ARPG art (run from heaven/arpg/:  python3 -I tools/check_palette.py; exit 1 on failure).
- palette: every world sprite and the ground use only the WORLD palette (art/style.py); every character and item
  sprite uses only Resurrect 64;
- outline: world props and characters have a 1 px #2e222f outline on (almost) all of their silhouette edge (demons:
  their coloured rim sits outside the outline, so the rule is checked one pixel in);
- scale: doors, cars and fences meet the size rules relative to Michael (STYLE.md), from the measured source sizes and
  the scale each piece is built at; and Michael's sheet is the reference height."""
import glob, os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, 'art')
import style   # noqa: E402
HEAVEN_TOOLS = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'tools')
sys.path.insert(0, HEAVEN_TOOLS)
from plh import R64   # noqa: E402

R64SET = {tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in R64}
WORLDSET = {style.H(c) for c in style.WORLD}
NOT_OUTLINED = {'ground', 'overpass'}         # the ground is a map; the overpass is a deck drawn overhead
problems = []


def colours(path):
    a = np.array(Image.open(path).convert('RGBA'))
    return {tuple(int(v) for v in p) for p in np.unique(a[a[..., 3] > 0][:, :3], axis=0)}


def check_palette():
    for p in sorted(glob.glob('game/art/zone/*.png')):
        bad = colours(p) - WORLDSET
        if bad: problems.append(f'{p}: {len(bad)} colours outside the world palette')
    for p in sorted(glob.glob('game/art/michael/*.png') + glob.glob('game/art/demons/*.png') +
                    glob.glob('game/art/people/*.png') + glob.glob('game/art/items/*.png')):
        bad = colours(p) - R64SET
        if bad: problems.append(f'{p}: {len(bad)} colours outside Resurrect 64')


def check_outline():
    for p in sorted(glob.glob('game/art/zone/*.png')):
        n = os.path.basename(p)[:-4]
        if n in NOT_OUTLINED: continue
        share = style.edge_outline_share(Image.open(p))
        if share < 0.9: problems.append(f'{p}: only {share:.0%} of the silhouette edge is outlined')
    m = Image.open('game/art/michael/idle.png').crop((0, 0, 64, 64))
    if style.edge_outline_share(m) < 0.6: problems.append('Michael: outline weaker than the reference')


def check_scale():
    for name, (src, kind, sc) in style.PIECES.items():
        size = src * sc
        if kind == 'door' and abs(size / style.MICHAEL_HEIGHT - style.DOOR_RATIO) > 0.12:
            problems.append(f'{name}: door {size:.0f} px is {size / style.MICHAEL_HEIGHT:.2f} x Michael (want ~{style.DOOR_RATIO})')
        if kind == 'car' and not style.CAR_RATIO[0] <= size / style.MICHAEL_HEIGHT <= style.CAR_RATIO[1] + 0.05:
            problems.append(f'{name}: {size:.0f} px long is {size / style.MICHAEL_HEIGHT:.2f} x Michael')
        if kind == 'fence' and not style.FENCE_RATIO[0] <= size / style.MICHAEL_HEIGHT <= style.FENCE_RATIO[1]:
            problems.append(f'{name}: {size:.0f} px high is {size / style.MICHAEL_HEIGHT:.2f} x Michael')
        path = f'game/art/zone/{name}.png'
        if os.path.exists(path) and kind == 'door':
            built = Image.open(path).height
            src_h = Image.open(f'art/ext/buildings/{SOURCE[name]}.png').height - ROOF_CUT.get(name, 0)
            if abs(built / (src_h * sc + 2) - 1.0) > 0.08:
                problems.append(f'{name}: built at {built} px, expected {src_h * sc:.0f} (scale {sc})')
    a = np.array(Image.open('game/art/michael/idle.png').convert('RGBA'))[:64, :64]
    ys = np.nonzero(a[..., 3])[0]
    if not 56 <= ys.max() - 4 + 1 <= 60: problems.append('Michael: reference height changed')


ROOF_CUT = {'store': 25}        # the store's roof rows are halved for the 3/4 view (build_zone.store_roof_3q)
SOURCE = {'house_a': 'house_dunmore_night', 'house_b': 'house_hale_night', 'house_c': 'house_okoro', 'store': 'store_ridge_mart_dark'}


if __name__ == '__main__':
    check_palette(); check_outline(); check_scale()
    for p in problems: print(p)
    print(f'{len(problems)} style problems')
    sys.exit(1 if problems else 0)
