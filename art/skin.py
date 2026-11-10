"""One skin ramp per character, and clean faces.

A character's ramp is the set of Resurrect 64 skin-ladder colours its approved front idle frame uses (face + hands),
after three clean-ups: drift colours the generator slipped into skin (golden, coral, salmon) go to the ladder shade of
nearest luminance; per-character `merge` rules lift a too-dark face onto a readable step or flatten speckle; per-character
`face_merge` rules remove blotches inside the head only. Every skin pixel in every other frame and direction that is not
in the ramp is then moved to the ramp colour of nearest luminance, so side, back and walk frames cannot drift.
Eyes (outline #2e222f), lips, beard, hair and sandals are not skin and are left alone.
Used by art/fix_skin.py (writes), art/build_district.py (ramp shifts for new individuals) and tools/check_skin.py."""
import numpy as np
from common import H

LADDER = [H(c) for c in ('fdcbb0', 'fca790', 'e6904e', 'cd683d', '9e4539', '6e2727', '45293f')]   # light -> deep
DRIFT = [H(c) for c in ('fbb954', 'f68181', 'f57d4a')]                                            # never in a ramp
# skin-like colours that are NOT skin unless a character says so: olive hair/sandal brown, sandal and beard greys,
# lip/blush wine, gold hair; and the deepest ladder brown, which most sprites use for hair and outline shading
DEFAULT_NOT_SKIN = [H(c) for c in ('45293f', '4c3e24', 'ab947a', '966c6c', '694f62', '7a3045', 'f9c22b')]
SKIN_LIKE = LADDER + DRIFT + DEFAULT_NOT_SKIN

SKIN_RULES = {
    'player':   {'not': ['45293f']},                                         # beard and hair shading
    'p00':      {'skin': ['45293f', '4c3e24'],                               # deep-toned face was 6e2727 with olive
                 'merge': {'6e2727': '9e4539', '4c3e24': '6e2727'},          # speckle: lift one step so eyes read
                 'merge_marker': '4c3e24'},                                   # (only while the speckle is there)
    'p07':      {'face_merge': {'e6904e': 'cd683d'}},                        # orange blotch on the chin
    'p09':      {'not': ['fbb954', 'e6904e']},                               # golden hair and its shading
    'p15':      {'skin': ['ab947a', '966c6c'], 'skip_feet': 4},              # the elder's grey-pink face shading
    'shepherd': {'not': ['fbb954', 'f68181'], 'skip_feet': 5},               # sash; bronze feet (Rev 1:15)
}
HEAD_FRAC = 0.42         # the head is the top 42% of the figure


def lum(c): return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def nearest(c, choices): return min(choices, key=lambda r: abs(lum(r) - lum(c)))


def shift_colour(c, steps):
    """A skin colour moved `steps` along the ladder (for new individuals made from an existing person)."""
    i = LADDER.index(nearest(c, LADDER))
    return LADDER[max(0, min(len(LADDER) - 1, i + steps))]


def extras(name): return [H(c) for c in SKIN_RULES.get(name, {}).get('skin', []) if H(c) not in LADDER]


def skin_colours(name):
    rule = SKIN_RULES.get(name, {})
    nots = (set(DEFAULT_NOT_SKIN) - {H(c) for c in rule.get('skin', [])}) | {H(c) for c in rule.get('not', [])}
    return {c for c in SKIN_LIKE if c not in nots}


def skin_mask(f, colours, skip_feet=0):
    m = np.zeros(f.shape[:2], bool)
    for c in colours: m |= (f[..., :3] == c).all(-1)
    m &= f[..., 3] > 0
    if skip_feet:
        ys = np.nonzero(f[..., 3])[0]
        if len(ys): m[ys.max() - skip_feet + 1:] = False
    return m


def colours_in(f, m): return {tuple(int(v) for v in p) for p in f[m][:, :3]}


def _recolour(f, m, table):
    """Simultaneous colour replacement on the masked pixels."""
    src = f[..., :3].copy()
    for c, to in table.items():
        f[m & (src == c).all(-1), :3] = to


def merge_due(name, front):
    """A `merge` rule is a one-time lift: it applies only while the front frame still holds its marker colour,
    so running fix_skin twice changes nothing."""
    rule = SKIN_RULES.get(name, {})
    if not rule.get('merge'): return False
    m = skin_mask(front, skin_colours(name), rule.get('skip_feet', 0))
    return H(rule['merge_marker']) in colours_in(front, m)


def clean(name, f, merge=True):
    """Drift -> ladder, merge rules, face_merge rules. Returns the skin mask (for the cleaned frame)."""
    rule = SKIN_RULES.get(name, {})
    m = skin_mask(f, skin_colours(name), rule.get('skip_feet', 0))
    _recolour(f, m, {c: nearest(c, LADDER) for c in DRIFT if c in skin_colours(name)})
    if merge: _recolour(f, m, {H(a): H(b) for a, b in rule.get('merge', {}).items()})
    if rule.get('face_merge'):
        ys = np.nonzero(f[..., 3])[0]
        head = np.zeros_like(m); head[ys.min():ys.min() + int((ys.max() - ys.min()) * HEAD_FRAC)] = True
        _recolour(f, m & head, {H(a): H(b) for a, b in rule['face_merge'].items()})
    return skin_mask(f, skin_colours(name), rule.get('skip_feet', 0))


def front_ramp(name, front):
    """The approved front frame's skin colours after clean-up, light -> dark (front itself is not modified)."""
    f = front.copy(); m = clean(name, f, merge_due(name, front))
    return sorted(colours_in(f, m), key=lum, reverse=True)


def unify(name, frames, front_key=(0, 0)):
    """frames: [(key, ndarray view)] of one character, edited in place. Returns (ramp, pixels changed)."""
    front = dict(frames)[front_key]
    merge = merge_due(name, front)
    ramp = front_ramp(name, front); changed = 0
    for _, f in frames:
        before = f.copy()
        m = clean(name, f, merge)
        for c in colours_in(f, m) - set(ramp):
            f[m & (f[..., :3] == c).all(-1), :3] = nearest(c, ramp)
        changed += int((before != f).any(-1).sum())
    return ramp, changed


def ramps_used(name, frames, front_key=(0, 0), ramp=None):
    """For the checker: (ramp, {direction row: off-ramp colours}, number of distinct skin ramps). A ramp may only hold
    ladder colours (plus a character's declared extra skin shades); `ramp` defaults to the front frame's skin colours,
    derived individuals pass their source's ramp shifted."""
    rule = SKIN_RULES.get(name, {})
    fm = dict(frames)
    if ramp is None:
        m = skin_mask(fm[front_key], skin_colours(name), rule.get('skip_feet', 0))
        ramp = colours_in(fm[front_key], m)
    ramp = set(ramp); off = {}
    bad = {c for c in ramp if c not in LADDER and c not in extras(name)}
    if bad: off['ramp'] = bad
    for (r, _), f in frames:
        extra = colours_in(f, skin_mask(f, skin_colours(name), rule.get('skip_feet', 0))) - ramp
        if extra: off.setdefault(r, set()).update(extra)
    return ramp, off, 1 + len({frozenset(v) for v in off.values()})
