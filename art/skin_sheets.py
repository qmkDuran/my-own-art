"""Review sheets for the skin pass: out/skin_fix_before_after.png (front, side, back per character; before | after, 3x)
and out/npc_lineup.png (every character's front idle with where it appears). Before copies: art/work/skin_before/."""
import sys
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, 'art')
from build_people4 import PEOPLE

BG, INK, SUB, LINE = (230, 222, 196, 255), (46, 34, 47, 255), (110, 96, 100, 255), (200, 190, 160, 255)
FONT = ImageFont.truetype('game/fonts/monogram_ext.ttf', 32)
SMALL = ImageFont.truetype('game/fonts/monogram_ext.ttf', 24)
HERO_VIEWS = [(0, 0), (2, 0), (1, 0)]                 # front, side, back (hero.png layout)
PEOPLE_VIEWS = [(0, 0), (2, 0), (1, 0)]               # front, side (left), back (people layout)
BEARER_VIEWS = [(3, 0), (3, 2), (3, 4)]               # bearers only walk west: three steps

PEOPLE_PLACES = {0: 'city + earth', 1: 'city + earth', 2: 'city + earth', 5: 'city + earth', 6: 'city + earth',
                 7: 'city + earth', 9: 'city + earth', 10: 'city + earth', 14: 'city + earth', 15: 'city + earth'}
CAST = ([(f'P{i:02d}', f'game/art/people/p{i:02d}.png', f'p{i:02d}', PEOPLE_VIEWS, PEOPLE_PLACES[i]) for i in PEOPLE]
        + [(f'P{i}', f'game/art/people/p{i}.png', f'p{i}', PEOPLE_VIEWS, 'city (district)') for i in range(31, 36)]
        + [(f'P{i}', f'game/art/people/p{i}.png', None, PEOPLE_VIEWS, 'district (Ps 150)') for i in (36, 37)]
        + [('Walker A', 'game/art/people/walkerA.png', 'walkerA', HERO_VIEWS, 'city + earth'),
           ('Walker B', 'game/art/people/walkerB.png', 'walkerB', HERO_VIEWS, 'city + earth')]
        + [(f'Bearer {k.upper()}', f'game/art/district/bearer_{k}.png', f'bearer_{k}', BEARER_VIEWS, 'district')
           for k in 'abcdef']
        + [('Gate angel', 'game/art/people/gate_angel.png', None, PEOPLE_VIEWS, 'pearl gate (Rev 21:12)'),
           ('Shepherd', 'game/art/people/shepherd.png', 'shepherd', PEOPLE_VIEWS, 'garden (Rev 7:17)'),
           ('PLAYER', 'game/art/hero.png', 'hero', HERO_VIEWS, 'you')])


def frame(path, rc, scale=3):
    r, c = rc
    return Image.open(path).convert('RGBA').crop((c * 64, r * 64, c * 64 + 64, r * 64 + 64)).resize((64 * scale,) * 2, 0)


def before_after():
    cell, cols = 64 * 3, 2
    block_w, block_h = cell * 6 + 40, cell + 44
    rows = (len(CAST) + cols - 1) // cols
    out = Image.new('RGBA', (block_w * cols + 40, block_h * rows + 70), BG); d = ImageDraw.Draw(out)
    d.text((20, 14), 'Skin pass: before (left three) | after (right three) - front, side, back at 3x', font=FONT, fill=INK)
    for i, (label, path, key, views, _) in enumerate([c for c in CAST if c[2]]):
        x0, y0 = 20 + (i % cols) * block_w, 60 + (i // cols) * block_h
        d.text((x0, y0), label, font=FONT, fill=INK)
        for j, v in enumerate(views):
            out.alpha_composite(frame(f'art/work/skin_before/{key}.png', v), (x0 + j * cell, y0 + 34))
            out.alpha_composite(frame(path, v), (x0 + 3 * cell + 24 + j * cell, y0 + 34))
        d.line((x0 + 3 * cell + 11, y0 + 36, x0 + 3 * cell + 11, y0 + 34 + cell), fill=LINE, width=3)
    out.convert('RGB').save('out/skin_fix_before_after.png')


def lineup():
    cell_w, cell_h, cols = 212, 248, 6
    rows = (len(CAST) + cols - 1) // cols
    out = Image.new('RGBA', (cell_w * cols, cell_h * rows), BG); d = ImageDraw.Draw(out)
    for i, (label, path, _, views, where) in enumerate(CAST):
        x0, y0 = (i % cols) * cell_w, (i // cols) * cell_h
        out.alpha_composite(frame(path, views[0]), (x0 + 10, y0))
        d.text((x0 + 8, y0 + 194), label, font=FONT, fill=INK)
        d.text((x0 + 8, y0 + 218), where, font=SMALL, fill=SUB)
    out.convert('RGB').save('out/npc_lineup.png')


if __name__ == '__main__':
    before_after(); lineup()
