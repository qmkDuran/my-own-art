"""Checks that every character uses exactly ONE skin ramp (its approved front frame's) in all frames and directions.
Usage (from heaven/): python3 -I tools/check_skin.py   -> prints per character, exits 1 if any has more than one."""
import json, sys
sys.path.insert(0, 'art')
from skin import ramps_used, front_ramp, shift_colour
from fix_skin import CHARACTERS, load_frames, HERO_LAYOUT, PEOPLE_LAYOUT
from build_district import RESIDENTS, BEARERS, MUSICIANS   # (new, source, steps[, gift/instrument]): ramp-shifted copies


def source_ramp(source, steps):
    path, cols, rows = CHARACTERS[source]
    return {shift_colour(c, steps) for c in front_ramp(source, dict(load_frames(path, cols, rows)[1])[(0, 0)])}


def report(name, frames, ramp=None):
    ramp, off, n = ramps_used(name, frames, ramp=ramp)
    hexes = lambda s: ' '.join(sorted('%02x%02x%02x' % c for c in s))
    print(f'{name:9s} skin ramps: {n}   ramp: {hexes(ramp)}' + ''.join(f'\n          row {r} off-ramp: {hexes(v)}' for r, v in off.items()))
    return n == 1


def main():
    ok = True
    for name, (path, cols, rows) in CHARACTERS.items():
        ok &= report(name, load_frames(path, cols, rows)[1])
    for name, source, steps in RESIDENTS + [m[:3] for m in MUSICIANS]:
        ok &= report(name, load_frames(f'game/art/people/{name}.png', *PEOPLE_LAYOUT)[1], source_ramp(source, steps))
    boxes = json.load(open('game/art/district/layout.json')).get('gift_boxes', {})
    for name, source, steps, _ in BEARERS:
        _, frames = load_frames(f'game/art/district/{name}.png', *HERO_LAYOUT)
        for (r, c), f in frames:                    # the carried gift is not skin
            for x0, y0, x1, y1 in boxes.get(name, [])[c % 8: c % 8 + 1] if r >= 3 else boxes.get(name, [])[:1]:
                f[max(0, y0):y1, max(0, x0):x1, 3] = 0
        ok &= report(name, frames, source_ramp(source, steps))
    ok &= report('gate_angel', load_frames('game/art/people/gate_angel.png', *PEOPLE_LAYOUT)[1])
    print('SKIN PASS: one skin ramp per character' if ok else 'SKIN FAIL')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
