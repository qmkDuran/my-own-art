"""Generate all SFX + ambience for Project R, Chapter 1 "Night One".

    python3 audio/tools/gen_sfx.py [name ...]  # writes audio/sfx/*.wav and audio/ambience/*.ogg

Deterministic (seeded). Pure synthesis: no recorded samples.
Level policy:
  * one-shot SFX ........ peak -3 dBFS
  * UI / text ticks ..... peak -6 dBFS
  * silence_ring ........ peak -24 dBFS (meant to be barely there)
  * looping SFX ......... integrated -22 LUFS (peak capped -3 dBFS)
  * ambience beds ....... integrated -26 LUFS (peak capped -6 dBFS)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from synth import *  # noqa: E402,F401,F403

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REG = []  # (folder, name, func, level_kind)


def sfx(name, folder="sfx", level="oneshot"):
    def deco(fn):
        REG.append((folder, name, fn, level))
        return fn
    return deco


def R(seed):
    return np.random.default_rng(seed)


def stereo_from(mono_l, mono_r):
    return np.stack([mono_l, mono_r], 1)


# ======================================================================= footsteps
def _thump(rng, f0=90, f1=55, dur=0.12, tau=0.035):
    n = n_of(dur)
    f = np.linspace(f0, f1, n)
    return np.sin(osc_phase(f)) * env_exp(n, tau, 0.002)


def step_wood(seed):
    rng = R(seed)
    n = n_of(0.35)
    y = np.zeros(n)
    heel = _thump(rng, rng.uniform(95, 120), 60, 0.2, 0.03)
    click = bp(white(0.03, rng), 900, 3500) * env_exp(n_of(0.03), 0.006)
    body = reson(white(0.25, rng) * env_exp(n_of(0.25), 0.012), rng.uniform(180, 240), 6)
    body += 0.5 * reson(white(0.25, rng) * env_exp(n_of(0.25), 0.01), rng.uniform(420, 520), 10)
    place(y, heel, 0, 1.0)
    place(y, click, 0, 0.35)
    place(y, body, 0, 0.5)
    # toe roll, a little later and softer
    place(y, _thump(rng, 130, 80, 0.12, 0.02), rng.uniform(0.045, 0.07), 0.35)
    place(y, bp(white(0.02, rng), 1500, 5000) * env_exp(n_of(0.02), 0.004), 0.06, 0.12)
    # occasional floorboard creak
    if seed % 2 == 0:
        cn = n_of(0.18)
        cf = np.linspace(rng.uniform(300, 380), rng.uniform(250, 300), cn)
        creak = additive(cf, cn, 25, lambda k: 1 / k) * adsr(cn, 0.03, 0.05, 0.6, 0.08)
        creak = reson(creak, 900, 4) + 0.3 * reson(creak, 1700, 6)
        place(y, creak, 0.06, 0.05)
    return fade(lp(y, 7000), 0, 0.05)


def step_carpet(seed):
    rng = R(seed)
    n = n_of(0.3)
    y = np.zeros(n)
    nz = lp(white(0.25, rng), 500, 2) * adsr(n_of(0.25), 0.012, 0.05, 0.2, 0.15)
    place(y, nz, 0, 1.0)
    place(y, _thump(rng, 80, 50, 0.15, 0.03), 0.004, 0.6)
    fuzz = bp(white(0.2, rng), 1500, 5000) * adsr(n_of(0.2), 0.02, 0.06, 0.15, 0.1)
    place(y, fuzz, 0.01, 0.06)
    return fade(y, 0.002, 0.05)


def step_asphalt(seed):
    rng = R(seed)
    n = n_of(0.35)
    y = np.zeros(n)
    heel = bp(white(0.04, rng), 1800, 6500) * env_exp(n_of(0.04), 0.007)
    place(y, heel, 0, 0.8)
    place(y, _thump(rng, 110, 60, 0.12, 0.022), 0, 0.7)
    # gritty scuff: dense tiny grains of grit
    sn = n_of(0.16)
    grains = (rng.random(sn) < 0.04) * rng.standard_normal(sn)
    grit = hp(grains, 2500) * adsr(sn, 0.02, 0.05, 0.4, 0.08)
    place(y, grit, rng.uniform(0.03, 0.06), 0.5)
    place(y, bp(white(0.16, rng), 3000, 9000) * adsr(sn, 0.02, 0.04, 0.3, 0.09), 0.04, 0.12)
    return fade(y, 0, 0.04)


def step_grass(seed):
    rng = R(seed)
    n = n_of(0.4)
    y = np.zeros(n)
    sn = n_of(0.3)
    grains = (rng.random(sn) < 0.12) * rng.standard_normal(sn)
    rust = bp(grains + 0.3 * rng.standard_normal(sn), 1800, 8000) * adsr(sn, 0.04, 0.06, 0.5, 0.18)
    place(y, rust, 0, 0.9)
    place(y, lp(white(0.2, rng), 400) * adsr(n_of(0.2), 0.01, 0.05, 0.2, 0.12), 0.01, 0.5)
    place(y, _thump(rng, 70, 45, 0.12, 0.03), 0.01, 0.4)
    return fade(y, 0.002, 0.05)


def step_glass(seed):
    rng = R(seed)
    y = step_asphalt(seed + 100) * 0.7
    n = len(y)
    # many tiny glass fragments: short high pings + crackle
    for _ in range(rng.integers(18, 30)):
        st = rng.uniform(0.0, 0.18)
        f = rng.uniform(3000, 11000)
        pn = n_of(rng.uniform(0.01, 0.05))
        ping = np.sin(osc_phase(f, pn)) * env_exp(pn, rng.uniform(0.003, 0.012))
        ping += 0.5 * np.sin(osc_phase(f * rng.uniform(1.4, 2.3), pn)) * env_exp(pn, 0.004)
        place(y, ping, st, rng.uniform(0.05, 0.25))
    cr = n_of(0.2)
    crackle = hp((rng.random(cr) < 0.08) * rng.standard_normal(cr), 4000) * adsr(cr, 0.005, 0.05, 0.4, 0.1)
    place(y, crackle, 0.005, 0.5)
    return fade(y, 0, 0.04)


for i in range(4):
    sfx(f"footstep_wood_{i + 1:02d}")(lambda i=i: step_wood(10 + i))
    sfx(f"footstep_carpet_{i + 1:02d}")(lambda i=i: step_carpet(20 + i))
    sfx(f"footstep_asphalt_{i + 1:02d}")(lambda i=i: step_asphalt(30 + i))
    sfx(f"footstep_grass_{i + 1:02d}")(lambda i=i: step_grass(40 + i))
    sfx(f"footstep_glass_{i + 1:02d}")(lambda i=i: step_glass(50 + i))


# ======================================================================= doors
def _creak(rng, dur, f_start, f_end, rough=0.25):
    n = n_of(dur)
    f = np.linspace(f_start, f_end, n) * (1 + 0.08 * smooth_random(dur, 12, rng, -1, 1))
    # stick-slip friction: pulse train with irregular amplitude
    src = additive(f, n, 40, lambda k: 1 / k ** 0.8)
    src *= 1 + rough * smooth_random(dur, 40, rng, -1, 1)
    y = reson(src, 650, 3) + 0.6 * reson(src, 1400, 5) + 0.3 * reson(src, 2600, 6)
    return y * adsr(n, 0.08, 0.1, 0.8, 0.2)


def _latch(rng, bright=1.0):
    n = n_of(0.12)
    c = hp(white(0.12, rng), 1500) * env_exp(n, 0.004)
    m = np.sin(osc_phase(2300, n)) * env_exp(n, 0.02) + 0.6 * np.sin(osc_phase(3550, n)) * env_exp(n, 0.012)
    y = c + 0.15 * m * bright
    second = np.zeros(n)
    place(second, c * 0.6, 0.035)
    return y + second


@sfx("door_open")
def door_open():
    rng = R(101)
    y = np.zeros(n_of(1.6))
    place(y, _latch(rng), 0, 0.8)
    place(y, _creak(rng, 0.9, 210, 140), 0.12, 0.25)
    place(y, lp(white(1.0, rng), 600) * adsr(n_of(1.0), 0.2, 0.2, 0.5, 0.4), 0.1, 0.08)  # air movement
    return fade(reverb(y, 0.5, 0.18, rng)[: n_of(1.6)], 0, 0.1)


@sfx("door_close")
def door_close():
    rng = R(102)
    y = np.zeros(n_of(1.4))
    place(y, _creak(rng, 0.35, 160, 200), 0, 0.12)
    st = 0.3
    thud = _thump(rng, 85, 45, 0.4, 0.07) + 0.6 * lp(white(0.4, rng), 300) * env_exp(n_of(0.4), 0.04)
    place(y, thud, st, 1.0)
    place(y, _latch(rng), st + 0.005, 0.7)
    rattle = reson(white(0.3, rng) * env_exp(n_of(0.3), 0.04), 1100, 8)
    place(y, rattle, st + 0.01, 0.2)
    return fade(reverb(y, 0.6, 0.22, rng)[: n_of(1.4)], 0, 0.1)


# ======================================================================= home loops
@sfx("fridge_hum_loop", level="loop")
def fridge_hum():
    rng = R(110)
    L = 12.0
    t = tt(L + 1)
    wob = 1 + 0.002 * np.sin(2 * np.pi * 0.25 * t)
    y = np.zeros(len(t))
    for k, a in [(1, 1.0), (2, 0.6), (3, 0.35), (4, 0.25), (5, 0.12), (6, 0.08), (8, 0.05)]:
        y += a * np.sin(osc_phase(60 * k * wob))
    y *= 0.6
    comp = lp(brown(L + 1, rng), 250) * 0.4
    tick = bp(white(L + 1, rng), 3000, 6000) * 0.02
    y = y + comp + tick
    y *= 1 + 0.05 * smooth_random(L + 1, 0.5, rng, -1, 1)
    return loop_crossfade(lp(y, 2500), L, 1.0)


def _syllable(rng, f0, dur, vowel=None):
    vowels = {
        "a": [(750, 90), (1200, 110), (2550, 150)],
        "e": [(450, 70), (1900, 120), (2600, 150)],
        "i": [(300, 60), (2300, 140), (3000, 170)],
        "o": [(480, 70), (850, 90), (2500, 150)],
        "u": [(330, 60), (900, 90), (2300, 150)],
    }
    v = vowels[vowel or rng.choice(list(vowels))]
    n = n_of(dur)
    contour = f0 * np.linspace(1 + rng.uniform(-0.05, 0.12), 1 + rng.uniform(-0.15, 0.03), n)
    src = glottal(contour, n, rng, 0.015, 40)
    y = formants(src, v, [1.0, 0.6, 0.3])
    # consonant-ish noise onset
    cons = bp(white(dur, rng), 2500, 7000) * env_exp(n, 0.015)
    y = y / (np.max(np.abs(y)) + 1e-9) + 0.25 * cons * (rng.random() < 0.6)
    return y * adsr(n, 0.02, 0.04, 0.8, min(0.06, dur * 0.4))


def _speech(rng, dur, f0, rate=4.5, pause_p=0.12):
    y = np.zeros(n_of(dur))
    t = 0.0
    while t < dur - 0.3:
        if rng.random() < pause_p:
            t += rng.uniform(0.25, 0.7)
            continue
        sd = rng.uniform(0.6, 1.4) / rate
        p = f0 * (1 + 0.15 * np.sin(t * 0.9) + rng.uniform(-0.08, 0.08))
        place(y, _syllable(rng, p, sd), t, rng.uniform(0.5, 1.0))
        t += sd * rng.uniform(0.85, 1.0)
    return y


@sfx("tv_murmur_loop", level="loop")
def tv_murmur():
    """Muffled TV through a wall: two 'voices' alternating + a quiet music bed. Unintelligible."""
    rng = R(120)
    L = 24.0
    D = L + 1.5
    y = np.zeros(n_of(D))
    t = 0.0
    who = 0
    while t < D:
        seg = rng.uniform(2.5, 5.5)
        place(y, _speech(rng, seg, [115, 190][who]), t, 0.8 if who == 0 else 0.7)
        t += seg + rng.uniform(0.2, 0.6)
        who = 1 - who
    # TV music bed (soft chords) underneath
    bed = np.zeros(n_of(D))
    for i, m in enumerate([57, 60, 64, 55, 59, 62, 53, 57, 60]):
        st = (i // 3) * 3.0
        place(bed, additive(midi_hz(m), n_of(3.2), 8) * adsr(n_of(3.2), 0.3, 0.5, 0.6, 0.8), st, 0.08)
    for k in range(1, int(D / 9.0) + 1):
        place(bed, bed[: n_of(9.0)].copy(), 9.0 * k, 1.0)
    y = y + bed
    y = lp(hp(y, 180), 1800, 4)  # small speaker + through a wall
    y = reverb(y, 0.4, 0.2, rng)[: len(y)]
    return loop_crossfade(y, L, 1.5)


@sfx("cutlery_clink")
def cutlery():
    rng = R(130)
    y = np.zeros(n_of(1.2))
    t = 0.0
    for i in range(4):
        n = n_of(0.5)
        base = rng.uniform(1800, 2600)
        ratios = [1, 2.71, 4.53, 6.9]
        hit = sum(np.sin(osc_phase(base * r, n)) * env_exp(n, rng.uniform(0.04, 0.12) / r ** 0.5) / r ** 0.4
                  for r in ratios)
        hit += 0.6 * hp(white(0.5, rng), 3000) * env_exp(n, 0.002)
        place(y, hit, t, rng.uniform(0.3, 0.8))
        t += rng.uniform(0.12, 0.3)
    # ceramic plate tap
    pn = n_of(0.3)
    plate = (np.sin(osc_phase(1200, pn)) + 0.5 * np.sin(osc_phase(3350, pn))) * env_exp(pn, 0.03)
    place(y, plate, 0.05, 0.3)
    return fade(reverb(y, 0.35, 0.15, rng)[: len(y)], 0, 0.1)


@sfx("phone_buzz")
def phone_buzz():
    """Phone vibrating on a wooden table: two buzzes."""
    rng = R(140)
    y = np.zeros(n_of(1.6))
    for st in (0.0, 0.75):
        n = n_of(0.5)
        motor = square(175 * (1 + 0.01 * smooth_random(0.5, 20, rng, -1, 1)), n, 20)
        rattle = (np.abs(motor) > 0.8) * hp(white(0.5, rng), 2000)
        b = reson(motor, 175, 2) + 0.4 * reson(motor, 520, 6) + 0.15 * rattle
        place(y, b * adsr(n, 0.01, 0.02, 1.0, 0.03), st, 1.0)
    return lp(y, 6000)


# ======================================================================= store
def _bell(rng, f, dur=2.5, bright=1.0):
    n = n_of(dur)
    partials = [(0.5, 0.25, 1.5), (1.0, 1.0, 1.0), (2.0, 0.5, 0.6), (2.76, 0.4 * bright, 0.4),
                (5.4, 0.25 * bright, 0.2), (8.93, 0.12 * bright, 0.1)]
    y = np.zeros(n)
    for r, a, tau in partials:
        y += a * np.sin(osc_phase(f * r * (1 + rng.uniform(-0.001, 0.001)), n)) * env_exp(n, tau * dur / 2.5, 0.001)
    return y


@sfx("store_door_chime")
def store_chime():
    rng = R(150)
    y = np.zeros(n_of(3.0))
    place(y, _bell(rng, midi_hz(88)), 0.0, 0.8)   # E6
    place(y, _bell(rng, midi_hz(84)), 0.28, 0.75)  # C6
    place(y, 0.3 * _bell(rng, midi_hz(88) * 1.003, 2.0), 0.02, 0.2)  # sympathetic jingle
    return fade(reverb(y, 0.6, 0.15, rng)[: len(y)], 0, 0.3)


@sfx("register_beep")
def register_beep():
    n = n_of(0.16)
    y = square(2350, n, 6) * adsr(n, 0.003, 0.01, 0.9, 0.02)
    return reson(y, 2350, 3) + 0.3 * y


@sfx("fluorescent_hum_loop", level="loop")
def fluorescent_hum():
    rng = R(160)
    L = 10.0
    D = L + 1
    y = np.zeros(n_of(D))
    for k, a in [(1, 1.0), (2, 0.5), (3, 0.6), (5, 0.3), (7, 0.15), (9, 0.08), (11, 0.05)]:
        y += a * np.sin(osc_phase(120 * k, n_of(D)) + rng.uniform(0, 6))
    buzz = np.sign(np.sin(osc_phase(120, n_of(D)))) * 0.15
    y = lp(y + buzz, 3000) * 0.6
    whine = np.sin(osc_phase(15700, n_of(D))) * 0.01
    hiss = hp(white(D, rng), 5000) * 0.015
    y = y + whine + hiss
    # a couple of starter "tinks"/flickers
    for st in (2.3, 7.1):
        tk = n_of(0.08)
        place(y, hp(white(0.08, rng), 2000) * env_exp(tk, 0.006), st, 0.25)
        y[n_of(st):n_of(st + 0.06)] *= 0.6
    return loop_crossfade(y, L, 1.0)


# ======================================================================= the vanishing
@sfx("power_cut")
def power_cut():
    """Electrical thunk (breaker/transformer) + the room hum pitching down and dying."""
    rng = R(170)
    D = 3.5
    y = np.zeros(n_of(D))
    # spark crack
    place(y, hp(white(0.05, rng), 1500) * env_exp(n_of(0.05), 0.006), 0, 0.9)
    # heavy thunk
    th = _thump(rng, 70, 32, 0.8, 0.15) + 0.5 * lp(white(0.8, rng), 180) * env_exp(n_of(0.8), 0.09)
    place(y, th, 0.005, 1.0)
    # mains hum spinning down
    n = n_of(2.6)
    k = np.linspace(0, 1, n)
    f = 60 * (1 - 0.65 * k ** 0.7)
    hum = sum(a * np.sin(osc_phase(f * h)) for h, a in [(1, 1), (2, 0.6), (3, 0.4), (4, 0.2), (6, 0.1)])
    hum *= (1 - k) ** 2.2
    place(y, lp(hum, 1500), 0.0, 0.45)
    # relay click a beat later
    place(y, hp(white(0.02, rng), 2500) * env_exp(n_of(0.02), 0.003), 0.18, 0.3)
    return fade(reverb(y, 1.0, 0.2, rng)[: len(y)], 0, 0.3)


@sfx("car_alarm_loop", level="loop")
def car_alarm():
    """Generic two-tone alternating alarm (not modelled on any specific product)."""
    rng = R(180)
    L = 4.8  # 12 cycles of 0.4 s
    n = n_of(L)
    t = np.arange(n) / SR
    which = (np.floor(t / 0.2) % 2).astype(bool)
    f = np.where(which, 1180.0, 860.0)
    f = np.convolve(f, np.ones(64) / 64, mode="same")
    f[:64] = 860.0
    y = square(f, n, 12)
    y = reson(y, 1500, 1.2) * 0.7 + 0.3 * y
    y = hp(lp(y, 4500), 400)
    return y


@sfx("car_crash")
def car_crash():
    rng = R(190)
    D = 4.0
    y = np.zeros(n_of(D))
    # main impact
    boom = _thump(rng, 80, 30, 1.2, 0.25) + lp(white(1.2, rng), 250) * env_exp(n_of(1.2), 0.15)
    place(y, boom, 0, 1.0)
    # metal crunch: dense resonant noise bursts
    for _ in range(14):
        st = rng.uniform(0, 0.35)
        dn = n_of(rng.uniform(0.08, 0.3))
        b = white(dn / SR, rng) * env_exp(dn, rng.uniform(0.02, 0.08))
        b = reson(b, rng.uniform(300, 2500), rng.uniform(4, 15)) + 0.4 * bp(b, 800, 5000)
        place(y, b, st, rng.uniform(0.2, 0.6))
    # crumpled panel ringing
    rn = n_of(1.5)
    ring = sum(np.sin(osc_phase(f, rn)) * env_exp(rn, 0.3) for f in (423, 611, 1240, 1777))
    place(y, ring, 0.02, 0.05)
    # glass
    place(y, glass_break_core(rng, 1.6), 0.03, 0.7)
    # scrape / grind
    sn = n_of(1.2)
    scrape = bp(white(1.2, rng), 1500, 6000) * (1 + 0.6 * smooth_random(1.2, 30, rng, -1, 1))
    place(y, scrape * adsr(sn, 0.05, 0.2, 0.6, 0.6), 0.25, 0.25)
    # debris settling
    for _ in range(12):
        st = rng.uniform(0.6, 2.4)
        dn = n_of(0.05)
        place(y, bp(white(0.05, rng), 1500, 6000) * env_exp(dn, 0.008), st, rng.uniform(0.05, 0.2))
    y = reverb(y, 1.6, 0.25, rng)[: len(y)]
    return fade(y, 0, 0.5)


def glass_break_core(rng, dur=2.0):
    y = np.zeros(n_of(dur))
    place(y, hp(white(0.03, rng), 2000) * env_exp(n_of(0.03), 0.004), 0, 1.0)
    place(y, bp(white(0.3, rng), 2500, 12000) * env_exp(n_of(0.3), 0.05), 0, 0.6)
    for _ in range(90):
        st = abs(rng.normal(0, 0.18)) + (rng.random() < 0.25) * rng.uniform(0.2, 1.0)
        f = rng.uniform(2500, 12000)
        pn = n_of(rng.uniform(0.03, 0.2))
        tau = rng.uniform(0.008, 0.05)
        p = np.sin(osc_phase(f, pn)) * env_exp(pn, tau)
        p += 0.5 * np.sin(osc_phase(f * rng.uniform(1.3, 2.4), pn)) * env_exp(pn, tau * 0.5)
        place(y, p, st, rng.uniform(0.03, 0.18))
    return y


@sfx("glass_break")
def glass_break():
    rng = R(200)
    y = glass_break_core(rng, 2.2)
    place(y, _thump(rng, 120, 60, 0.15, 0.03), 0, 0.4)
    return fade(reverb(y, 0.9, 0.2, rng)[: len(y)], 0, 0.3)


@sfx("explosion_distant")
def explosion_distant():
    rng = R(210)
    D = 6.0
    y = np.zeros(n_of(D))
    n = n_of(5.0)
    body = lp(brown(5.0, rng), 160, 4) * adsr(n, 0.04, 0.4, 0.5, 4.0) * env_exp(n, 1.6, 0.03)
    place(y, body, 0, 1.0)
    place(y, _thump(rng, 55, 28, 2.0, 0.5), 0, 0.8)
    crack = lp(white(0.4, rng), 1200) * env_exp(n_of(0.4), 0.05)
    place(y, crack, 0.0, 0.35)
    # rolling echoes off buildings
    for d, g in [(0.35, 0.4), (0.8, 0.3), (1.4, 0.2)]:
        place(y, lp(body, 120), d, g)
    y = reverb(y, 3.0, 0.35, rng, dark=700)[: len(y)]
    return fade(lp(y, 900), 0, 0.8)


@sfx("fire_crackle_loop", level="loop")
def fire_crackle():
    rng = R(220)
    L = 14.0
    D = L + 1.0
    roar = lp(brown(D, rng), 400) * (0.7 + 0.3 * smooth_random(D, 1.5, rng))
    roar += 0.3 * bp(pink(D, rng), 300, 1500) * smooth_random(D, 3, rng, 0.3, 1.0)
    y = roar * 0.5
    nn = n_of(D)
    # crackles: many tiny pops with varied colour, plus occasional larger snaps
    t = 0.0
    while t < D:
        t += rng.exponential(0.03)
        pn = n_of(rng.uniform(0.002, 0.02))
        pop = white(pn / SR, rng) * env_exp(pn, rng.uniform(0.0008, 0.004))
        lo = rng.uniform(800, 3000)
        pop = bp(pop, lo, min(lo * rng.uniform(2, 5), 15000))
        place(y, pop, t, rng.uniform(0.1, 1.0) * (3.0 if rng.random() < 0.04 else 1.0))
    y = y[:nn]
    return loop_crossfade(y, L, 1.0)


@sfx("siren_distant_loop", level="loop")
def siren_distant():
    """Generic rising/falling wail, far away and bouncing off houses (not a specific real siren)."""
    rng = R(230)
    L = 18.0
    n = n_of(L)
    t = np.arange(n) / SR
    period = 4.5  # 4 cycles in 18 s
    sweep = 0.5 - 0.5 * np.cos(2 * np.pi * t / period)
    f = 640 + 620 * sweep ** 1.3
    f *= 1 + 0.004 * np.sin(2 * np.pi * t / L * 2)  # slight drift (still periodic)
    y = additive(f, n, 10, lambda k: 1 / k ** 1.5)
    amp = 0.6 + 0.4 * (0.5 - 0.5 * np.cos(2 * np.pi * t / L))  # comes a bit closer and away
    y = lp(y * amp, 2200)
    wet = reverb(np.concatenate([y, y]), 2.2, 0.55, rng, dark=1500)
    return wet[n:2 * n]  # second copy = steady-state, seamless circular reverb


@sfx("dog_bark")
def dog_bark():
    """Stylised medium dog: three barks (synthesised, not a recording)."""
    rng = R(240)
    y = np.zeros(n_of(1.6))
    for st, f0 in [(0.0, 480), (0.32, 520), (0.78, 450)]:
        dur = rng.uniform(0.13, 0.18)
        n = n_of(dur)
        k = np.linspace(0, 1, n)
        contour = f0 * (0.75 + 0.45 * np.sin(np.pi * k ** 0.6))
        src = glottal(contour, n, rng, 0.03, 30) + 0.5 * white(dur, rng)
        b = formants(src, [(700, 200), (1300, 250), (2500, 400)], [1, 0.7, 0.3])
        b *= adsr(n, 0.008, 0.03, 0.7, 0.06)
        b = np.tanh(2 * b / (np.max(np.abs(b)) + 1e-9))
        place(y, b, st, 1.0)
    return fade(reverb(y, 0.9, 0.22, rng)[: len(y)], 0, 0.2)


@sfx("dog_growl")
def dog_growl():
    rng = R(250)
    D = 1.8
    n = n_of(D)
    f0 = 95 * (1 + 0.1 * smooth_random(D, 3, rng, -1, 1))
    src = glottal(f0, n, rng, 0.06, 40)
    src *= 1 + 0.8 * np.sin(osc_phase(28 * (1 + 0.2 * smooth_random(D, 4, rng, -1, 1))))  # rattle
    src += 0.4 * lp(white(D, rng), 1500)
    y = formants(src, [(450, 150), (1100, 200), (2300, 300)], [1, 0.5, 0.2])
    y *= adsr(n, 0.15, 0.2, 0.85, 0.35)
    return lp(np.tanh(1.5 * y / (np.max(np.abs(y)) + 1e-9)), 3500)


def _crowd(rng, D, density=10, scream_p=0.15):
    y = np.zeros(n_of(D))
    for _ in range(int(D * density)):
        st = rng.uniform(-1, D)
        if rng.random() < scream_p:
            dur = rng.uniform(0.6, 1.4)
            n = n_of(dur)
            f = rng.uniform(500, 900) * (1 + 0.2 * np.sin(np.pi * np.linspace(0, 1, n)))
            v = glottal(f, n, rng, 0.03, 15)
            v = formants(v, [(900, 200), (1500, 250), (2900, 400)], [1, 0.7, 0.4])
            v *= adsr(n, 0.06, 0.1, 0.8, 0.3)
            g = rng.uniform(0.3, 0.8)
        else:
            dur = rng.uniform(0.3, 1.2)
            v = _speech(rng, dur, rng.uniform(140, 330), rate=6, pause_p=0.0)
            g = rng.uniform(0.3, 0.9)
        place(y, v / (np.max(np.abs(v)) + 1e-9), max(st, 0), g)
    return y


@sfx("crowd_panic_far_loop", level="loop")
def crowd_panic():
    rng = R(260)
    L = 16.0
    D = L + 2.0
    y = _crowd(rng, D, 9, 0.2)
    y += 0.4 * bp(pink(D, rng), 300, 2500) * smooth_random(D, 1, rng, 0.4, 1)
    y = lp(y, 2000, 4)
    y = reverb(y, 2.4, 0.5, rng, dark=1200)[: len(y)]
    return loop_crossfade(y, L, 2.0)


@sfx("scream_distant")
def scream_distant():
    """Stylised, wordless distant scream for the moment the lights go out."""
    rng = R(265)
    dur = 1.6
    n = n_of(dur)
    k = np.linspace(0, 1, n)
    f = 620 + 280 * np.sin(np.pi * np.clip(k * 1.4, 0, 1)) - 150 * k
    v = glottal(f, n, rng, 0.04, 14) + 0.25 * white(dur, rng)
    v = formants(v, [(950, 180), (1600, 220), (3000, 400)], [1, 0.7, 0.4])
    v *= adsr(n, 0.05, 0.2, 0.8, 0.6)
    v = lp(v / (np.max(np.abs(v)) + 1e-9), 2200)
    return fade(reverb(np.pad(v, (0, n_of(1.8))), 2.2, 0.55, rng, dark=1300), 0, 0.5)


# ======================================================================= fight
def _whoosh(rng, dur, f_lo, f_hi, q=1.5):
    n = n_of(dur)
    k = np.linspace(0, 1, n)
    shape = np.sin(np.pi * k) ** 2
    center = f_lo + (f_hi - f_lo) * shape
    y = tv_bandpass(white(dur, rng), center, q)
    return y * shape


@sfx("whoosh")
def whoosh():
    rng = R(270)
    return fade(_whoosh(rng, 0.35, 300, 2200, 1.2), 0.002, 0.02)


@sfx("bat_swing")
def bat_swing():
    rng = R(275)
    y = _whoosh(rng, 0.45, 180, 900, 2.0)
    y += 0.5 * _whoosh(rng, 0.45, 600, 2600, 3.0)
    return fade(y, 0.002, 0.03)


@sfx("punch")
def punch():
    rng = R(280)
    y = np.zeros(n_of(0.45))
    place(y, _whoosh(rng, 0.09, 500, 2000), 0, 0.3)
    st = 0.08
    place(y, _thump(rng, 140, 55, 0.25, 0.04), st, 1.0)
    slap = bp(white(0.05, rng), 1200, 5000) * env_exp(n_of(0.05), 0.008)
    place(y, slap, st, 0.7)
    place(y, lp(white(0.15, rng), 400) * env_exp(n_of(0.15), 0.03), st, 0.5)
    return fade(np.tanh(1.5 * y), 0, 0.05)


@sfx("hit_heavy")
def hit_heavy():
    """Bat / heavy blunt impact on a body."""
    rng = R(285)
    y = np.zeros(n_of(0.7))
    place(y, _thump(rng, 110, 40, 0.5, 0.08), 0, 1.0)
    crack = bp(white(0.06, rng), 900, 6000) * env_exp(n_of(0.06), 0.01)
    place(y, crack, 0, 0.9)
    wood = reson(white(0.2, rng) * env_exp(n_of(0.2), 0.02), 620, 8)
    place(y, wood, 0, 0.3)
    place(y, lp(white(0.3, rng), 300) * env_exp(n_of(0.3), 0.05), 0, 0.6)
    y = np.tanh(1.8 * y)
    return fade(reverb(y, 0.4, 0.12, rng)[: len(y)], 0, 0.1)


def _vocal_burst(rng, dur, f_start, f_end, vowel_f, noise=0.3, tense=1.0):
    n = n_of(dur)
    k = np.linspace(0, 1, n)
    f = f_start + (f_end - f_start) * k ** 0.8
    src = glottal(f, n, rng, 0.03 * tense, 30) + noise * white(dur, rng)
    y = formants(src, vowel_f, [1, 0.6, 0.25])
    y *= adsr(n, 0.015, 0.05, 0.7, dur * 0.5)
    y = lp(y / (np.max(np.abs(y)) + 1e-9), 3500)
    return y


@sfx("hurt")
def hurt():
    """Non-verbal pain exhale ('ugh'), stylised."""
    rng = R(290)
    y = _vocal_burst(rng, 0.38, 170, 120, [(600, 120), (1100, 150), (2500, 300)], 0.35, 1.5)
    return fade(reverb(np.pad(y, (0, n_of(0.3))), 0.3, 0.1, rng), 0.002, 0.05)


@sfx("grunt")
def grunt():
    """Non-verbal effort grunt, stylised."""
    rng = R(295)
    y = _vocal_burst(rng, 0.25, 125, 105, [(500, 110), (950, 140), (2400, 300)], 0.45, 1.2)
    return fade(reverb(np.pad(y, (0, n_of(0.25))), 0.3, 0.1, rng), 0.002, 0.05)


# ======================================================================= ui & interaction
def _blip(f1, f2, dur, partials=3, tau=0.05):
    n = n_of(dur)
    f = np.linspace(f1, f2, n)
    return additive(f, n, partials, lambda k: 1 / k ** 2) * env_exp(n, tau, 0.002)


@sfx("ui_blip", level="ui")
def ui_blip():
    return fade(_blip(1320, 1320, 0.07, 3, 0.02), 0.001, 0.01)


@sfx("ui_confirm", level="ui")
def ui_confirm():
    y = np.zeros(n_of(0.35))
    place(y, _blip(midi_hz(76), midi_hz(76), 0.2, 4, 0.06), 0, 0.7)
    place(y, _blip(midi_hz(83), midi_hz(83), 0.25, 4, 0.08), 0.07, 0.8)
    return fade(y, 0.001, 0.03)


@sfx("ui_back", level="ui")
def ui_back():
    y = np.zeros(n_of(0.3))
    place(y, _blip(midi_hz(79), midi_hz(79), 0.18, 4, 0.05), 0, 0.7)
    place(y, _blip(midi_hz(72), midi_hz(72), 0.2, 4, 0.06), 0.07, 0.7)
    return fade(y, 0.001, 0.03)


@sfx("pickup", level="ui")
def pickup():
    rng = R(300)
    y = np.zeros(n_of(0.6))
    place(y, lp(white(0.08, rng), 3000) * env_exp(n_of(0.08), 0.015), 0, 0.25)  # hand grab
    for i, m in enumerate([79, 83, 86]):
        place(y, _bell(rng, midi_hz(m), 0.5, 0.4), 0.04 + i * 0.06, 0.35)
    return fade(y, 0.001, 0.08)


@sfx("inventory_open", level="ui")
def inventory_open():
    """Backpack zip/cloth rustle + soft tone."""
    rng = R(310)
    y = np.zeros(n_of(0.6))
    zn = n_of(0.25)
    zip_ = hp((rng.random(zn) < 0.25) * rng.standard_normal(zn), 2500) * adsr(zn, 0.02, 0.05, 0.8, 0.05)
    place(y, zip_, 0, 0.5)
    place(y, bp(white(0.3, rng), 400, 3000) * adsr(n_of(0.3), 0.03, 0.1, 0.4, 0.15), 0.15, 0.3)
    place(y, _blip(midi_hz(64), midi_hz(64), 0.35, 4, 0.12), 0.18, 0.35)
    return fade(y, 0.001, 0.05)


def _tick(seed):
    rng = R(seed)
    n = n_of(0.05)
    c = hp(white(0.05, rng), 2500) * env_exp(n, 0.0025)
    c += 0.3 * np.sin(osc_phase(rng.uniform(1700, 2100), n)) * env_exp(n, 0.006)
    return fade(c, 0.0005, 0.01)


for i in range(3):
    sfx(f"typewriter_tick_{i + 1:02d}", level="ui")(lambda i=i: _tick(320 + i))


@sfx("paper_rustle")
def paper_rustle():
    """Unfolding Mom's letter / turning a Bible page."""
    rng = R(330)
    D = 1.1
    n = n_of(D)
    grains = (rng.random(n) < 0.05) * rng.standard_normal(n)
    y = bp(grains + 0.25 * white(D, rng), 1200, 9000) * smooth_random(D, 8, rng, 0.1, 1.0)
    y *= adsr(n, 0.05, 0.2, 0.7, 0.3)
    return fade(y, 0.002, 0.05)


# ======================================================================= body / tension
@sfx("heartbeat_loop", level="loop")
def heartbeat():
    """~80 bpm heartbeat, 8 beats per loop."""
    rng = R(340)
    beat = 0.75
    L = beat * 8
    y = np.zeros(n_of(L))
    for i in range(8):
        st = i * beat
        place_wrap(y, lp(_thump(rng, 65, 38, 0.3, 0.05), 200), st, 1.0)
        place_wrap(y, lp(_thump(rng, 58, 36, 0.3, 0.045), 200), st + 0.19, 0.65)
    return y


@sfx("drone_tension_loop", level="loop")
def drone():
    rng = R(350)
    L = 24.0
    n = n_of(L)
    t = np.arange(n) / SR
    y = np.zeros(n)
    # periodic slow beating: detunes chosen so every partial completes whole cycles in L
    for f, a in [(41.0 + 1 / 24, 1.0), (41.0 + 3 / 24, 0.8), (61.5 + 2 / 24, 0.4), (82.0 + 1 / 24, 0.25),
                 (123.0 + 5 / 24, 0.08)]:
        fq = round(f * L) / L
        y += a * np.sin(2 * np.pi * fq * t + rng.uniform(0, 6))
    mod = smooth_random_loop(L, 0.25, rng, 0.5, 1.0)
    y *= mod
    rum = lp(brown(L + 2, rng), 120, 4)
    rum = loop_crossfade(rum, L, 2.0) * smooth_random_loop(L, 0.2, rng, 0.2, 0.6)
    air = bp(pink(L + 2, rng), 200, 900)
    air = loop_crossfade(air, L, 2.0) * smooth_random_loop(L, 0.15, rng, 0.0, 0.25)
    return y * 0.7 + rum * 0.6 + air * 0.15


@sfx("silence_ring", level="quiet")
def silence_ring():
    """Faint tinnitus-like ring for the 'total silence' beat (optional, very quiet)."""
    D = 4.0
    n = n_of(D)
    y = np.sin(osc_phase(6200, n)) + 0.3 * np.sin(osc_phase(6213, n))
    return y * adsr(n, 1.2, 0.5, 0.8, 1.5)


@sfx("emergency_broadcast_tone")
def eb_tone():
    """Generic broadcast alert: three short pips, then a sustained two-sine tone.
    Deliberately NOT the real EAS/NOAA attention frequencies or SAME data bursts."""
    rng = R(360)
    D = 6.0
    y = np.zeros(n_of(D))
    for i in range(3):
        n = n_of(0.18)
        place(y, (np.sin(osc_phase(1250, n))) * adsr(n, 0.005, 0.01, 1, 0.01), 0.1 + i * 0.32, 0.6)
    n = n_of(4.2)
    tone = np.sin(osc_phase(740, n)) + np.sin(osc_phase(1110, n))
    tone = np.tanh(1.3 * tone) * adsr(n, 0.01, 0.05, 1.0, 0.05)
    place(y, tone, 1.3, 0.5)
    y = bp(y, 300, 3400, 4)  # broadcast / TV speaker band-limit
    y += hp(white(D, rng), 3000) * 0.004
    return fade(y, 0.002, 0.2)


# ======================================================================= ambience beds (stereo)
def _cricket(rng, D, rate, f, pulses=3):
    """Single cricket: chirps of n pulses at rate per second."""
    y = np.zeros(n_of(D))
    period = 1.0 / rate
    t = rng.uniform(0, period)
    pn = n_of(0.018)
    pulse = np.sin(osc_phase(f, pn)) * np.hanning(pn)
    pulse += 0.15 * np.sin(osc_phase(2 * f, pn)) * np.hanning(pn)
    while t < D:
        if rng.random() > 0.08:
            for p in range(pulses):
                place(y, pulse, t + p * 0.024, rng.uniform(0.7, 1.0))
        t += period * rng.uniform(0.96, 1.04)
    return y


def _loop_amb(fn_stereo, L, X):
    return loop_crossfade(fn_stereo, L, X)


@sfx("crickets_night_loop", folder="ambience", level="amb")
def crickets_night():
    rng = R(400)
    L = 30.0
    D = L + 2
    out = np.zeros((n_of(D), 2))
    for i in range(7):
        f = rng.uniform(3900, 4900)
        c = _cricket(rng, D, rng.uniform(1.6, 3.0), f, rng.integers(2, 5))
        dist = rng.uniform(0.25, 1.0)
        c = lp(c, 9000 - 4000 * (1 - dist)) * dist
        place(out, c, 0, 1.0, pan=rng.uniform(-0.9, 0.9))
    # distant katydid-ish trill, very soft
    trill = _cricket(rng, D, 0.6, 7200, 9) * 0.15
    place(out, lp(trill, 8000), 0, 1.0, pan=-0.6)
    # warm night air
    air = np.stack([lp(pink(D, rng), 700), lp(pink(D, rng), 700)], 1) * 0.08
    out += air
    out = reverb(out, 1.4, 0.25, rng, stereo_out=True)[: len(out)]
    return _loop_amb(out, L, 2.0)


def _bird(rng, kind):
    if kind == 0:  # quick descending whistle pair
        y = np.zeros(n_of(0.6))
        for st in (0.0, 0.22):
            n = n_of(0.15)
            f = np.linspace(rng.uniform(3200, 4200), rng.uniform(2300, 2800), n)
            place(y, np.sin(osc_phase(f)) * np.hanning(n), st, 1.0)
        return y
    if kind == 1:  # trill
        n = n_of(0.7)
        base = rng.uniform(3500, 4500)
        f = base + 600 * np.sin(osc_phase(np.full(n, 22.0)))
        return np.sin(osc_phase(f)) * adsr(n, 0.05, 0.1, 0.7, 0.2)
    # robin-ish warble: 3-4 short FM notes
    y = np.zeros(n_of(1.2))
    t = 0
    for _ in range(rng.integers(3, 5)):
        n = n_of(rng.uniform(0.09, 0.16))
        c = rng.uniform(2200, 3600)
        f = c * (1 + 0.15 * np.sin(np.linspace(0, np.pi * rng.uniform(1, 3), n)))
        place(y, np.sin(osc_phase(f)) * np.hanning(n), t, rng.uniform(0.6, 1.0))
        t += n / SR + rng.uniform(0.03, 0.09)
    return y


def _lawnmower(rng, D):
    n = n_of(D)
    rpm = 28 * (1 + 0.06 * smooth_random(D, 0.3, rng, -1, 1))
    y = additive(rpm, n, 60, lambda k: 1 / k ** 0.9)
    y = lp(y, 900) + 0.3 * lp(bp(white(D, rng), 200, 1200), 800)
    # mower moving back and forth across a yard (level swells)
    y *= 0.5 + 0.5 * (0.5 - 0.5 * np.cos(2 * np.pi * np.arange(n) / SR / 9.0))
    return lp(y, 700)


@sfx("suburban_evening_loop", folder="ambience", level="amb")
def suburban_evening():
    rng = R(410)
    L = 40.0
    D = L + 3
    out = np.zeros((n_of(D), 2))
    # birds
    t = 0.0
    while t < D:
        t += rng.exponential(1.4)
        b = _bird(rng, rng.integers(0, 3))
        dist = rng.uniform(0.3, 1.0)
        place(out, lp(b, 7000) * dist, t, 0.5, pan=rng.uniform(-0.9, 0.9))
    # distant lawnmower
    place(out, _lawnmower(rng, D), 0, 0.35, pan=0.5)
    # kids playing far away: wordless high voice blips and a few laugh-like bursts
    t = 1.0
    while t < D:
        t += rng.exponential(2.5)
        if rng.random() < 0.5:
            v = _speech(rng, rng.uniform(0.4, 1.0), rng.uniform(280, 380), rate=7, pause_p=0)
        else:  # laugh-ish: a few "ha" bursts
            v = np.zeros(n_of(0.8))
            f0 = rng.uniform(300, 420)
            for j in range(rng.integers(3, 6)):
                place(v, _syllable(rng, f0 * (1 - 0.04 * j), 0.11, "a"), j * 0.13, 1.0)
        v = lp(v / (np.max(np.abs(v)) + 1e-9), 1600)
        place(out, v, t, rng.uniform(0.08, 0.16), pan=rng.uniform(-0.7, 0.2))
    # a car passing on a far street, once
    n = n_of(7.0)
    car = lp(pink(7.0, rng), 500) * np.hanning(n)
    place(out, car, 18.0, 0.25, pan=-0.2)
    # air
    out += np.stack([lp(pink(D, rng), 900), lp(pink(D, rng), 900)], 1) * 0.06
    out = reverb(out, 1.2, 0.25, rng, stereo_out=True)[: len(out)]
    return _loop_amb(out, L, 3.0)


@sfx("wind_loop", folder="ambience", level="amb")
def wind():
    rng = R(420)
    L = 30.0
    D = L + 3
    chans = []
    for c in range(2):
        nz = pink(D, rng)
        center = smooth_random(D, 0.3, rng, 250, 900)
        gust = smooth_random(D, 0.25, rng, 0.2, 1.0) ** 1.5
        w = tv_bandpass(nz, center, 1.2) * gust
        w += 0.5 * lp(brown(D, rng), 150) * gust
        whistle = tv_bandpass(white(D, rng), center * 2.4, 25) * gust ** 2 * 0.15
        chans.append(w + whistle)
    out = np.stack(chans, 1)
    return _loop_amb(out, L, 3.0)


@sfx("chaos_city_far_loop", folder="ambience", level="amb")
def chaos_city_far():
    """Bed for the street sequence: far sirens, alarms, crowd, a dull roar of the town burning."""
    rng = R(430)
    L = 30.0
    D = L + 3
    out = np.zeros((n_of(D), 2))
    roar = np.stack([lp(brown(D, rng), 300), lp(brown(D, rng), 300)], 1)
    out += roar * 0.25
    cr = _crowd(rng, D, 5, 0.25)
    cr = lp(cr, 1400, 4)
    place(out, cr, 0, 0.25, pan=-0.3)
    # two far sirens with different periods
    for per, base, pan in [(5.2, 600, 0.6), (3.7, 720, -0.7)]:
        n = n_of(D)
        t = np.arange(n) / SR
        f = base + 500 * (0.5 - 0.5 * np.cos(2 * np.pi * t / per)) ** 1.3
        s = lp(additive(f, n, 6, lambda k: 1 / k ** 1.6), 1500)
        s *= smooth_random(D, 0.1, rng, 0.3, 1.0)
        place(out, s, 0, 0.12, pan=pan)
    # a far car alarm cycling in and out
    n = n_of(D)
    t = np.arange(n) / SR
    fa = np.where((np.floor(t / 0.22) % 2).astype(bool), 1050.0, 800.0)
    alarm = lp(square(np.convolve(fa, np.ones(64) / 64, "same"), n, 8), 1500)
    alarm *= (np.sin(2 * np.pi * t / 11) > -0.2) * smooth_random(D, 0.2, rng, 0.2, 1)
    place(out, alarm, 0, 0.04, pan=0.3)
    # occasional distant bangs
    for _ in range(4):
        st = rng.uniform(0, D - 2)
        bn = n_of(1.5)
        bang = lp(white(1.5, rng), 300) * env_exp(bn, 0.25)
        place(out, bang, st, 0.4, pan=rng.uniform(-0.8, 0.8))
    out = reverb(out, 2.5, 0.4, rng, stereo_out=True, dark=1000)[: len(out)]
    return _loop_amb(out, L, 3.0)


@sfx("dawn_quiet_loop", folder="ambience", level="amb")
def dawn_quiet():
    """Morning after: a few hesitant birds, light breeze, one very far siren now and then."""
    rng = R(440)
    L = 40.0
    D = L + 3
    out = np.zeros((n_of(D), 2))
    t = 0.0
    while t < D:
        t += rng.exponential(3.5)
        b = _bird(rng, rng.integers(0, 3))
        place(out, lp(b, 6500) * rng.uniform(0.3, 0.8), t, 0.5, pan=rng.uniform(-0.9, 0.9))
    out += np.stack([lp(pink(D, rng), 600), lp(pink(D, rng), 600)], 1) * 0.07 * \
        smooth_random(D, 0.2, rng, 0.4, 1.0)[:, None]
    n = n_of(12.0)
    tt_ = np.arange(n) / SR
    f = 620 + 450 * (0.5 - 0.5 * np.cos(2 * np.pi * tt_ / 4.8)) ** 1.3
    s = lp(additive(f, n, 5, lambda k: 1 / k ** 1.6), 1100) * np.hanning(n)
    place(out, s, 20.0, 0.03, pan=-0.6)
    out = reverb(out, 1.6, 0.3, rng, stereo_out=True)[: len(out)]
    return _loop_amb(out, L, 3.0)


# ======================================================================= render
LEVELS = {
    "oneshot": ("peak", -3.0),
    "ui": ("peak", -6.0),
    "quiet": ("peak", -24.0),
    "loop": ("lufs", -22.0, -3.0),
    "amb": ("lufs", -26.0, -6.0),
}


def main(only=None):
    report = []
    for folder, name, fn, level in REG:
        if only and name not in only:
            continue
        x = np.asarray(fn(), dtype=np.float64)
        x = x - np.mean(x, axis=0)
        spec = LEVELS[level]
        if spec[0] == "peak":
            # one-shots: keep a hair of fade at the end so nothing clicks
            x = norm_peak(x, spec[1])
            lufs = None
        else:
            x, lufs = norm_lufs(x, spec[1], spec[2])
        path = os.path.join(ROOT, folder, name + ".wav")
        write_wav(path, x)
        if folder == "ambience":  # long stereo beds ship as OGG Vorbis (sample-accurate loops, 1/10 size)
            encode_ogg(path, path[:-4] + ".ogg", 6)
            os.unlink(path)
            path = path[:-4] + ".ogg"
        ch = 2 if x.ndim == 2 else 1
        pk = 20 * np.log10(np.max(np.abs(x)) + 1e-12)
        line = f"{os.path.relpath(path, ROOT)}  {len(x) / SR:6.2f}s  ch={ch}  peak={pk:5.1f} dBFS" + \
            (f"  {lufs:5.1f} LUFS" if lufs is not None else "")
        print(line, flush=True)
        report.append(line)
    return report


if __name__ == "__main__":
    main(set(sys.argv[1:]) or None)
