"""One skin ramp per character (art/skin.py), applied to the final sheets in place.
Run after build_char / build_walkers / build_people4 / build_shepherd and BEFORE build_district
(the district's residents and gift bearers are derived from these sheets by ramp shifts, so they inherit one ramp)."""
import sys
from PIL import Image
import numpy as np
sys.path.insert(0, 'art')
from skin import unify
from build_people4 import PEOPLE

HERO_LAYOUT = (8, 6)      # idle d/u/side, walk d/u/side
PEOPLE_LAYOUT = (4, 3)    # idle, breathe, palm A, palm B x down/up/left
CHARACTERS = {'player': ('game/art/hero.png',) + HERO_LAYOUT,
              'walkerA': ('game/art/people/walkerA.png',) + HERO_LAYOUT,
              'walkerB': ('game/art/people/walkerB.png',) + HERO_LAYOUT}
CHARACTERS.update({f'p{i:02d}': (f'game/art/people/p{i:02d}.png',) + PEOPLE_LAYOUT for i in PEOPLE})
CHARACTERS['shepherd'] = ('game/art/people/shepherd.png',) + PEOPLE_LAYOUT


def load_frames(path, cols, rows):
    a = np.array(Image.open(path).convert('RGBA'))
    return a, [((r, c), a[r * 64:(r + 1) * 64, c * 64:(c + 1) * 64]) for r in range(rows) for c in range(cols)
               if a[r * 64:(r + 1) * 64, c * 64:(c + 1) * 64, 3].any()]


def main():
    for name, (path, cols, rows) in CHARACTERS.items():
        a, frames = load_frames(path, cols, rows)
        ramp, changed = unify(name, frames)
        Image.fromarray(a).save(path)              # frames are views into `a`: edited in place
        print(f'{name:9s} ramp {" ".join("%02x%02x%02x" % c for c in ramp)}  ({changed} px moved onto it)')


if __name__ == '__main__':
    main()
