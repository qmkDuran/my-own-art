"""Procedural placeholder score for Project R, Chapter 1.

    python3 audio/tools/gen_music.py [track ...]   # writes audio/music/<track>.ogg

Simple additive synths (felt-piano, pad, strings, music-box bell, soft drums),
hand-written chord progressions and melodies, a synthetic convolution reverb.
Each track is rendered as an exact loop: whatever rings past the loop point
(reverb, release tails) is folded back onto the start, so the file loops
seamlessly. Loudness-normalised to -16 LUFS integrated, peaks <= -1.5 dBFS.
"""
import os
import sys
import tempfile

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from synth import *  # noqa: E402,F401,F403

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TAIL = 7.0


# ======================================================================= instruments
def piano(m, dur, vel, rng, bright=1.0):
    f = midi_hz(m)
    n = n_of(dur + 1.5)
    t = np.arange(n) / SR
    B = 0.00025
    T0 = float(np.clip(5.0 * (261.6 / f) ** 0.6, 0.9, 9.0))
    y = np.zeros(n)
    for k in range(1, 18):
        fk = k * f * np.sqrt(1 + B * k * k)
        if fk > 9000:
            break
        a = (1 / k ** 1.15) * np.exp(-(k - 1) * (1.25 - vel * bright) * 0.45)
        tau = T0 / (1 + 0.45 * (k - 1))
        e = 0.55 * np.exp(-t / (tau * 0.22)) + 0.45 * np.exp(-t / tau)
        det = 1 + rng.uniform(0.0002, 0.0009)
        y += a * e * 0.5 * (np.sin(2 * np.pi * fk * t) + np.sin(2 * np.pi * fk * det * t + rng.uniform(0, 1)))
    ham = lp(rng.standard_normal(n), 1800 + 1500 * vel) * np.exp(-t / 0.006) * 0.08
    y += ham
    y[: n_of(0.002)] *= np.linspace(0, 1, n_of(0.002))
    damp = np.ones(n)
    s = n_of(dur)
    damp[s:] = np.exp(-(t[s:] - dur) / 0.12)
    y *= damp
    y = lp(y, 1400 + 4200 * vel * bright)  # felt / soft-hammer colour
    return y * vel


def pad(ms, dur, rng, cutoff=1100, attack=1.6, release=2.5, detune_c=7.0, voices=3):
    n = n_of(dur + release)
    y = np.zeros(n)
    for m in ms:
        f = midi_hz(m)
        parts = max(2, min(40, int(cutoff * 1.6 / f)))
        for v in range(voices):
            c = (v - (voices - 1) / 2) * detune_c
            fv = f * 2 ** (c / 1200) * (1 + 0.0015 * np.sin(osc_phase(np.full(n, rng.uniform(0.1, 0.3)))
                                                          + rng.uniform(0, 6)))
            y += additive(fv, n, parts, lambda k: 1 / k)
    y = lp(y, cutoff)
    env = adsr(n, attack, 0.5, 0.85, release)
    return y * env / (len(ms) * voices)


def strings(m, dur, vel, rng, attack=0.5, release=1.2, cutoff=3200):
    f = midi_hz(m)
    n = n_of(dur + release)
    t = np.arange(n) / SR
    vib_depth = 0.004 * np.clip((t - 0.4) / 0.8, 0, 1)
    fv = f * (1 + vib_depth * np.sin(2 * np.pi * 5.2 * t + rng.uniform(0, 6)))
    parts = max(2, min(40, int(cutoff * 1.5 / f)))
    y = 0.6 * additive(fv, n, parts, lambda k: 1 / k) + \
        0.4 * additive(fv * 1.003, n, parts, lambda k: 1 / k)
    y = lp(y, cutoff) + 0.02 * bp(rng.standard_normal(n), 2000, 6000)  # a hint of bow
    y = reson(y, 450, 1.2) * 0.5 + y * 0.6  # wooden body
    return y * adsr(n, attack, 0.3, 0.9, release) * vel


def bell(m, dur, vel, rng):
    f = midi_hz(m)
    n = n_of(max(dur, 0.1) + 3.0)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for r, a, tau in [(1.0, 1.0, 1.6), (2.0, 0.35, 0.9), (3.0, 0.12, 0.5), (4.16, 0.10, 0.35),
                      (5.43, 0.05, 0.2)]:
        y += a * np.sin(2 * np.pi * f * r * t + rng.uniform(0, 1)) * np.exp(-t / tau)
    y[: n_of(0.002)] *= np.linspace(0, 1, n_of(0.002))
    return y * vel


def sub(m, dur, vel):
    f = midi_hz(m)
    n = n_of(dur + 0.3)
    y = np.sin(osc_phase(f, n)) + 0.25 * np.sin(osc_phase(2 * f, n))
    return y * adsr(n, 0.02, 0.2, 0.7, 0.3) * vel


def kick_soft(vel, rng):
    n = n_of(0.6)
    f = 45 + 70 * np.exp(-np.arange(n) / SR / 0.03)
    return np.sin(osc_phase(f)) * env_exp(n, 0.18, 0.002) * vel


def tom(f0, vel, rng):
    n = n_of(0.9)
    f = f0 * (1 + 0.5 * np.exp(-np.arange(n) / SR / 0.04))
    y = np.sin(osc_phase(f)) * env_exp(n, 0.25, 0.002)
    y += 0.4 * lp(rng.standard_normal(n), 900) * env_exp(n, 0.03)
    return y * vel


def hat(vel, rng, dur=0.05):
    n = n_of(dur + 0.05)
    return hp(rng.standard_normal(n), 7000) * env_exp(n, dur * 0.4, 0.001) * vel


# ======================================================================= arrangement helpers
class Track:
    def __init__(self, length, seed):
        self.L = length
        self.rng = np.random.default_rng(seed)
        self.dry = np.zeros((n_of(length + TAIL), 2))
        self.send = np.zeros_like(self.dry)

    def add(self, x, start, gain=1.0, pan=0.0, rev=0.3, human=0.0):
        if human:
            start = max(0.0, start + self.rng.uniform(-human, human))
        place(self.dry, x, start, gain * (1 - rev * 0.5), pan)
        place(self.send, x, start, gain * rev, pan)

    def render(self, decay=2.6, dark=2200):
        wet = reverb(self.send, decay, 1.0, self.rng, stereo_out=True, dark=dark, predelay=0.02)
        n = len(wet)
        mix = np.pad(self.dry, ((0, n - len(self.dry)), (0, 0))) + wet
        return wrap_tail(mix, self.L)


def diatonic(m, steps, scale_root=62, scale=(0, 2, 4, 5, 7, 9, 11)):
    """Move m by `steps` scale degrees within the given major scale (root pc)."""
    pcs = sorted(((scale_root + s) % 12) for s in scale)
    cands = [x for x in range(m - 24, m + 25) if x % 12 in pcs]
    i = cands.index(m) if m in cands else min(range(len(cands)), key=lambda j: abs(cands[j] - m))
    return cands[i + steps]


# ======================================================================= pieces
def home_evening():
    """Warm, nostalgic: felt piano arpeggios in D major, gentle melody, soft pad. 72 bpm, 24 bars."""
    bpm = 72
    bt = 60 / bpm
    bars = 24
    tr = Track(bars * 4 * bt, 1)
    rng = tr.rng
    prog = [
        [50, 57, 62, 66, 69],   # D
        [47, 54, 59, 62, 66],   # Bm
        [43, 50, 55, 59, 62],   # G
        [45, 52, 57, 61, 64],   # A
        [42, 50, 57, 62, 66],   # D/F#
        [43, 50, 55, 59, 62],   # G
        [40, 47, 55, 59, 62],   # Em7
        [45, 52, 57, 62, 64],   # Asus4 (-> A on beat 3)
    ]
    arp = [0, 1, 2, 3, 4, 3, 2, 1]
    for bar in range(bars):
        pool = list(prog[bar % 8])
        for e, idx in enumerate(arp):
            if bar % 8 == 7 and e >= 4 and pool[idx] == 62:
                pool[idx] = 61  # sus4 resolves
            note = pool[idx]
            st = (bar * 4 + e * 0.5) * bt
            vel = (0.42 if e == 0 else 0.30) + rng.uniform(-0.04, 0.04)
            if bar < 2:
                vel *= 0.85
            tr.add(piano(note, 1.6 * bt, vel, rng), st, 0.9, pan=-0.25 + 0.1 * (idx - 2), rev=0.35, human=0.008)
        if bar >= 2:
            chord = [pool[2], pool[3], pool[4]]
            tr.add(pad(chord, 4 * bt, rng, cutoff=900, attack=1.2, release=2.0), bar * 4 * bt, 0.22, 0.0, 0.5)
        if bar >= 16:
            tr.add(strings(pool[0], 4 * bt, 0.5, rng, 0.8, 1.5, 1500), bar * 4 * bt, 0.10, -0.1, 0.5)
    melody = [(0, 2, 78), (2, 1, 76), (3, 1, 74), (4, 1.5, 74), (5.5, .5, 73), (6, 2, 71),
              (8, 1, 71), (9, 1, 74), (10, 2, 79), (12, 1, 78), (13, 1, 76), (14, 2, 73),
              (16, 2, 81), (18, 1, 78), (19, 1, 74), (20, 1.5, 79), (21.5, .5, 78), (22, 1, 76), (23, 1, 74),
              (24, 1, 76), (25, 1, 79), (26, 2, 83), (28, 2, 81), (30, 1, 76), (31, 1, 73)]
    for sec, base_bar in [(1, 8), (2, 16)]:
        for b0, d, m in melody:
            st = (base_bar * 4 + b0) * bt
            v = 0.55 + rng.uniform(-0.05, 0.05)
            tr.add(piano(m, d * bt * 1.1, v, rng, 1.1), st, 0.75, 0.15, 0.35, human=0.012)
            if sec == 2:
                h = diatonic(m, -2)
                tr.add(piano(h, d * bt * 1.1, v * 0.55, rng), st + 0.01, 0.5, 0.25, 0.4)
    return tr.render(2.4)


def unease():
    """Sparse, low, tense. A-minor-ish drone, isolated low piano, faint dissonances. 64 s."""
    L = 64.0
    tr = Track(L, 2)
    rng = tr.rng
    for st in np.arange(0, L, 16.0):
        tr.add(pad([33, 40], 16.0, rng, cutoff=380, attack=4.0, release=4.0, detune_c=9), st, 0.9, 0.0, 0.4)
    lows = [(0, 45), (6, 45), (12, 41), (18, 40), (24, 45), (32, 46), (38, 41), (44, 40), (50, 45), (56, 44)]
    for st, m in lows:
        tr.add(piano(m, 3.5, 0.55, rng), st, 0.9, -0.15, 0.55)
        tr.add(piano(m - 12, 3.5, 0.4, rng), st + 0.005, 0.6, -0.15, 0.55)
    for st, ms in [(9, (81, 82)), (29, (76, 77)), (47, (84, 83)), (60, (75, 76))]:
        for m in ms:
            tr.add(piano(m, 2.5, 0.22, rng), st + rng.uniform(0, 0.04), 0.5, 0.45, 0.7)
    for st, ms in [(14, [69, 70]), (40, [64, 65])]:
        tr.add(pad(ms, 8.0, rng, cutoff=2500, attack=3.5, release=4.0, detune_c=3, voices=2), st, 0.10, -0.4, 0.7)
    for st in np.arange(16, 48, 4.0):
        tr.add(lp(kick_soft(0.5, rng), 140), st, 0.5, 0.0, 0.2)
        tr.add(lp(kick_soft(0.32, rng), 140), st + 0.32, 0.5, 0.0, 0.2)
    return tr.render(3.5, dark=1500)


def chaos():
    """Pulsing, urgent: 16th-note low string ostinato in D minor, taiko-ish toms, string stabs. 128 bpm."""
    bpm = 128
    bt = 60 / bpm
    bars = 32
    tr = Track(bars * 4 * bt, 3)
    rng = tr.rng
    roots = [38, 38, 34, 34, 43, 43, 45, 45]
    highs = [[62, 65, 69], [62, 65, 69], [62, 65, 70], [62, 65, 70], [62, 67, 70], [62, 67, 70],
             [61, 64, 69], [61, 64, 69]]
    pattern = [0, 0, 12, 0, 0, 12, 0, 7, 0, 0, 12, 0, 0, 12, 7, 12]
    cache = {}

    def ost(m, v):
        key = (m, round(v, 2))
        if key not in cache:
            cache[key] = strings(m, 0.11, v, rng, attack=0.006, release=0.09, cutoff=2400)
        return cache[key]

    for bar in range(bars):
        r = roots[bar % 8]
        for s, off in enumerate(pattern):
            v = 0.9 if s % 4 == 0 else 0.55
            tr.add(ost(r + off, v), (bar * 4 + s * 0.25) * bt, 0.55, -0.2 + 0.4 * (s % 2), 0.15, human=0.003)
        # toms: beats 1 and 3 always (urgency), plus offbeat from bar 9
        for b in (0, 2):
            tr.add(tom(70, 0.9, rng), (bar * 4 + b) * bt, 0.7, 0.0, 0.3)
        if bar >= 8:
            tr.add(tom(95, 0.6, rng), (bar * 4 + 3.5) * bt, 0.55, 0.3, 0.3)
        if bar % 4 == 3 and bar >= 4:
            for k in range(4):
                tr.add(tom(110 + 12 * k, 0.4 + 0.12 * k, rng), (bar * 4 + 3 + k * 0.25) * bt, 0.5, -0.3, 0.3)
        if bar >= 16:
            for e in range(8):
                tr.add(hat(0.5 if e % 2 else 0.25, rng), (bar * 4 + e * 0.5) * bt, 0.18, 0.5, 0.15)
            if bar % 2 == 0:
                for m in highs[bar % 8]:
                    tr.add(strings(m, 8 * bt, 0.5, rng, attack=0.6, release=1.0), bar * 4 * bt, 0.13,
                           rng.uniform(-0.5, 0.5), 0.45)
        # dark swell into every 8-bar boundary
        if bar % 8 == 6:
            n = n_of(8 * bt)
            sw = pad([r - 12, r - 5, r], 8 * bt, rng, cutoff=1400, attack=8 * bt * 0.95, release=0.2,
                     detune_c=12)
            tr.add(sw, bar * 4 * bt, 0.5, 0.0, 0.4)
    return tr.render(1.8)


def aftermath():
    """Mournful and slow: strings in D minor, sparse piano melody, cello line. 54 bpm, 16 bars."""
    bpm = 54
    bt = 60 / bpm
    bars = 16
    tr = Track(bars * 4 * bt, 4)
    rng = tr.rng
    chords = [[50, 57, 62, 65], [46, 53, 62, 65], [43, 50, 58, 62], [45, 52, 61, 64],
              [50, 57, 62, 65], [41, 53, 57, 60], [46, 55, 58, 62], [45, 52, 57, 61]]
    for bar in range(bars):
        ch = chords[bar % 8]
        for i, m in enumerate(ch[1:]):
            tr.add(strings(m, 4 * bt, 0.5, rng, attack=1.4, release=2.0, cutoff=2200), bar * 4 * bt, 0.16,
                   -0.4 + 0.4 * i, 0.55)
        tr.add(strings(ch[0] - 12, 4 * bt, 0.6, rng, attack=1.0, release=2.0, cutoff=900), bar * 4 * bt, 0.2,
               -0.1, 0.45)
    mel = [(0, 3, 81), (3, 1, 77), (4, 1.5, 74), (5.5, .5, 76), (6, 2, 77), (8, 3, 79), (11, 1, 77),
           (12, 2, 76), (14, 2, 73), (16, 3, 74), (19, 1, 77), (20, 2, 81), (22, 1, 79), (23, 1, 77),
           (24, 2, 79), (26, 1, 82), (27, 1, 79), (28, 4, 81)]
    for b0, d, m in mel:
        tr.add(piano(m, d * bt, 0.5 + rng.uniform(-0.04, 0.04), rng), b0 * bt, 0.7, 0.15, 0.45, human=0.015)
    cello = [(32, 2, 57), (34, 2, 62), (36, 3, 62), (39, 1, 60), (40, 4, 58), (44, 2, 57), (46, 2, 61),
             (48, 4, 62), (52, 2, 60), (54, 2, 57), (56, 2, 58), (58, 2, 55), (60, 4, 57)]
    for b0, d, m in cello:
        tr.add(strings(m, d * bt, 0.8, rng, attack=0.35, release=1.0, cutoff=2000), b0 * bt, 0.3, -0.25, 0.4)
    for b0, d, m in [(34, 2, 81), (42, 2, 77), (50, 2, 74), (58, 2, 76), (61, 3, 73)]:
        tr.add(piano(m, d * bt, 0.32, rng), b0 * bt, 0.6, 0.3, 0.6)
    return tr.render(3.0, dark=1800)


def dawn_hope():
    """Quiet, a hint of hope: G major-ish (Em-C-G-D), high piano, pad, strings entering. 66 bpm."""
    bpm = 66
    bt = 60 / bpm
    bars = 16
    tr = Track(bars * 4 * bt, 5)
    rng = tr.rng
    pools = [[64, 67, 71, 76], [64, 67, 72, 76], [62, 67, 71, 74], [62, 66, 69, 74]]
    bass = [40, 36, 43, 38]
    pads = [[52, 55, 59], [52, 55, 60], [50, 55, 59], [50, 54, 57]]
    for bar in range(bars):
        i = bar % 4
        st = bar * 4 * bt
        tr.add(pad(pads[i], 4 * bt, rng, cutoff=1300, attack=1.8, release=2.5), st, 0.3, 0.0, 0.55)
        tr.add(piano(bass[i], 3.5 * bt, 0.35, rng), st, 0.6, -0.2, 0.45)
        for q, idx in enumerate([0, 1, 2, 1]):
            v = 0.3 if bar < 8 else 0.24
            tr.add(piano(pools[i][idx], 2 * bt, v + rng.uniform(-0.03, 0.03), rng), st + q * bt, 0.7,
                   0.2, 0.45, human=0.01)
        if bar >= 8:
            for k, m in enumerate(pads[i]):
                tr.add(strings(m + 12, 4 * bt, 0.45, rng, attack=1.5, release=2.0, cutoff=2600), st, 0.08,
                       -0.4 + 0.4 * k, 0.6)
    mel = [(32, 2, 83), (34, 2, 81), (36, 3, 79), (39, 1, 76), (40, 2, 79), (42, 2, 81), (44, 4, 78),
           (48, 2, 83), (50, 2, 86), (52, 3, 88), (55, 1, 86), (56, 2, 83), (58, 2, 81), (60, 4, 81)]
    for b0, d, m in mel:
        tr.add(piano(m, d * bt, 0.5, rng, 1.1), b0 * bt, 0.65, -0.1, 0.45, human=0.012)
    for b0 in (2, 10, 18, 26):
        tr.add(bell(88, 1.0, 0.25, rng), b0 * bt, 0.25, 0.5, 0.7)
    return tr.render(3.0)


def title():
    """Main menu: A minor, music-box motif over pad and soft pulse; strings join second half. 70 bpm."""
    bpm = 70
    bt = 60 / bpm
    bars = 16
    tr = Track(bars * 4 * bt, 6)
    rng = tr.rng
    roots = [45, 41, 48, 43, 45, 41, 48, 40]
    pads = [[57, 60, 64], [57, 60, 65], [55, 60, 64], [55, 59, 62], [57, 60, 64], [57, 60, 65], [55, 60, 64],
            [56, 59, 64]]
    for bar in range(bars):
        i = bar % 8
        st = bar * 4 * bt
        tr.add(pad(pads[i], 4 * bt, rng, cutoff=1000, attack=1.5, release=2.5), st, 0.32, 0.0, 0.5)
        for b in range(4):
            tr.add(lp(sub(roots[i] - 12, 0.6 * bt, 0.5 if b == 0 else 0.32), 300), st + b * bt, 0.5, 0.0, 0.1)
        tr.add(piano(roots[i], 3.8 * bt, 0.38, rng), st, 0.55, -0.2, 0.45)
        if bar >= 8:
            for k, m in enumerate(pads[i]):
                tr.add(strings(m, 4 * bt, 0.5, rng, attack=1.2, release=1.8, cutoff=2400), st, 0.1,
                       -0.5 + 0.5 * k, 0.55)
    motif = [(0, .5, 69), (.5, .5, 76), (1, 1, 81), (2, 2, 83), (4, 1, 84), (5, 1, 83), (6, 2, 81),
             (8, 1, 76), (9, 1, 79), (10, 2, 84), (12, 2, 83), (14, 2, 79),
             (16, .5, 69), (16.5, .5, 76), (17, 1, 81), (18, 2, 83), (20, 1, 84), (21, 1, 83), (22, 2, 77),
             (24, 1, 76), (25, 1, 79), (26, 2, 84), (28, 2, 80), (30, 2, 83)]
    for rep in range(2):
        for b0, d, m in motif:
            tr.add(bell(m, d * bt, 0.45 if rep == 0 else 0.4, rng), (rep * 32 + b0) * bt, 0.35, 0.25, 0.55,
                   human=0.006)
            if rep == 1:
                tr.add(piano(m - 12, d * bt, 0.25, rng), (rep * 32 + b0) * bt, 0.4, -0.1, 0.5)
    return tr.render(3.2)


TRACKS = {
    "title": title,
    "home_evening": home_evening,
    "unease": unease,
    "chaos": chaos,
    "aftermath": aftermath,
    "dawn_hope": dawn_hope,
}


def main(names):
    out_dir = os.path.join(ROOT, "music")
    os.makedirs(out_dir, exist_ok=True)
    keep_wav = os.environ.get("KEEP_WAV")
    for name in names:
        x = TRACKS[name]()
        x = x - x.mean(0)
        x = hp(np.concatenate([x, x]), 25)[len(x):]  # circular high-pass keeps the loop seamless
        x, lufs = norm_lufs(x, -16.0, -1.5)
        tmp = os.path.join(tempfile.gettempdir() if not keep_wav else keep_wav, f"{name}.wav")
        write_wav(tmp, x)
        encode_ogg(tmp, os.path.join(out_dir, name + ".ogg"), 6)
        pk = 20 * np.log10(np.max(np.abs(x)))
        print(f"music/{name}.ogg  {len(x) / SR:6.2f}s  {lufs:5.1f} LUFS  peak {pk:5.1f} dBFS", flush=True)
        if not keep_wav:
            os.unlink(tmp)


if __name__ == "__main__":
    main(sys.argv[1:] or list(TRACKS))
