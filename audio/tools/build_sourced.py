"""Build the Project R sounds that use third-party recordings (see audio/CREDITS.md).

Usage:
    python3 audio/tools/build_sourced.py --src <download dir> --placeholders <dir> [name ...]

--src           folder holding the original downloads, laid out as
                  bigsoundbank/<number>/<number>.(flac|wav)
                  kenney_impact-sounds/x/Audio/*.ogg, kenney_rpg-audio/x/Audio/*.ogg
                  opengameart/<slug>/<file>
                (every source is listed with its URL in audio/CREDITS.md)
--placeholders  folder with the synthesised placeholders from gen_sfx.py
                (sfx/, ambience/, music/); a few sounds layer them in quietly
                for low end or for parts no recording covered (noted in CREDITS.md).

Writes into audio/sfx, audio/ambience and audio/music with the same names,
formats and loudness targets as the placeholders (see AUDIO_LIST.md).
Requires numpy, scipy and ffmpeg (libvorbis).
"""
import argparse
import glob
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy import signal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from synth import (SR, n_of, lp, hp, bp, reverb, place, place_wrap, loop_crossfade,  # noqa: E402
                   norm_peak, norm_lufs, write_wav, encode_ogg, measure_lufs, soft_limit, db)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = None  # parsed args


# ---------------------------------------------------------------- io helpers
def load(path, stereo=False):
    ch = 2 if stereo else 1
    raw = subprocess.run(["ffmpeg", "-v", "quiet", "-i", path, "-ac", str(ch), "-ar", str(SR),
                          "-f", "f32le", "-"], capture_output=True, check=True).stdout
    x = np.frombuffer(raw, np.float32).astype(np.float64)
    return x.reshape(-1, 2) if stereo else x


def bsb(num, stereo=False):
    f = [p for p in glob.glob(os.path.join(A.src, "bigsoundbank", num, num + ".*")) if not p.endswith(".json")]
    return load(f[0], stereo)


def kenney(pack, name):
    return load(os.path.join(A.src, "kenney_" + pack, "x", "Audio", name))


def oga(slug, fname, stereo=False):
    return load(os.path.join(A.src, "opengameart", slug, fname), stereo)


def ph(rel, stereo=False):
    return load(os.path.join(A.placeholders, rel), stereo)


def cut(x, t0, t1, fin=0.003, fout=0.03):
    y = x[n_of(t0):n_of(t1)].copy()
    a, b = n_of(fin), n_of(fout)
    if a:
        y[:a] *= np.linspace(0, 1, a)[:, None] if y.ndim == 2 else np.linspace(0, 1, a)
    if b:
        r = np.cos(np.linspace(0, np.pi / 2, b)) ** 2
        y[-b:] *= r[:, None] if y.ndim == 2 else r
    return y


def pad(x, sec):
    n = n_of(sec)
    if len(x) >= n:
        return x[:n]
    return np.concatenate([x, np.zeros((n - len(x),) + x.shape[1:])])


def tail_fade(x, sec):
    b = n_of(sec)
    r = np.cos(np.linspace(0, np.pi / 2, b)) ** 2
    x = x.copy()
    x[-b:] *= r[:, None] if x.ndim == 2 else r
    return x


def speed(x, ratio):
    """Resample so it plays `ratio` times faster (pitch up by the same ratio)."""
    from fractions import Fraction
    fr = Fraction(1 / ratio).limit_denominator(200)
    return signal.resample_poly(x, fr.numerator, fr.denominator, axis=0)


def mix(sec, *layers):
    """layers: (signal, start_sec, gain_db)."""
    buf = np.zeros(n_of(sec))
    for x, t, g in layers:
        place(buf, x, t, db(g))
    return buf


def remove_dc(x):
    return hp(x, 25, 2)


def out_sfx(name, x, peak=-3.0):
    x = remove_dc(x)
    x = norm_peak(x, peak)
    write_wav(os.path.join(ROOT, "sfx", name + ".wav"), x)
    print(f"sfx/{name}.wav  {len(x) / SR:5.2f}s  peak {peak} dBFS", flush=True)


def norm_lufs_iter(x, lufs, cap):
    """norm_lufs, repeated so the soft limiter's loss is made up (rarely needs more than 3 passes)."""
    y, l = norm_lufs(x, lufs, peak_cap_db=cap)
    for _ in range(4):
        if abs(l - lufs) < 0.3:
            break
        y, l = norm_lufs(y, lufs, peak_cap_db=cap)
    return y, l


def out_loop_sfx(name, x, lufs=-22.0):
    y, l = norm_lufs_iter(x, lufs, -3.0)
    write_wav(os.path.join(ROOT, "sfx", name + ".wav"), y)
    print(f"sfx/{name}.wav  {len(y) / SR:5.2f}s  {l:5.1f} LUFS  peak {20 * np.log10(np.abs(y).max()):5.1f}", flush=True)


def out_ogg(folder, name, x, lufs, cap):
    y, l = norm_lufs_iter(x, lufs, cap)
    with tempfile.TemporaryDirectory() as td:
        w = os.path.join(td, name + ".wav")
        write_wav(w, y)
        encode_ogg(w, os.path.join(ROOT, folder, name + ".ogg"), 6)
    print(f"{folder}/{name}.ogg  {len(y) / SR:6.2f}s  {l:5.1f} LUFS  peak {20 * np.log10(np.abs(y).max()):5.1f}",
          flush=True)


def music_loop(x, a, b, xf):
    """Seamless loop of x[a:b]: the material that follows b is crossfaded into the start."""
    seg = x[n_of(a):]
    return loop_crossfade_lin(seg, b - a, xf)


def loop_crossfade_lin(x, loop_sec, xfade_sec):
    L, X = n_of(loop_sec), n_of(xfade_sec)
    y = x[:L].copy()
    r = np.linspace(0, 1, X)
    fi, fo = np.sin(r * np.pi / 2) ** 2, np.cos(r * np.pi / 2) ** 2  # equal gain (correlated material)
    if x.ndim == 2:
        fi, fo = fi[:, None], fo[:, None]
    y[:X] = x[:X] * fi + x[L:L + X] * fo
    return y


# ---------------------------------------------------------------- SFX
BUILD = {}


def job(name):
    def deco(fn):
        BUILD[name] = fn
        return fn
    return deco


@job("footsteps")
def footsteps():
    # wood: BigSoundBank #0165 "Man Footsteps on the Wooden Floor"
    w = bsb("0165")
    for i, t in enumerate([1.09, 2.34, 2.94, 3.56], 1):
        out_sfx(f"footstep_wood_{i:02d}", pad(cut(hp(w, 50), t - 0.01, t + 0.34, fout=0.08), 0.35))
    # asphalt: BigSoundBank #0514 "Footsteps, Shoe on Concrete"
    c = hp(bsb("0514"), 60)
    for i, t in enumerate([0.40, 1.08, 2.48, 7.50], 1):
        out_sfx(f"footstep_asphalt_{i:02d}", pad(cut(c, t - 0.01, t + 0.32, fout=0.07), 0.35))
    # glass: other concrete steps + the crunch of the synthesised placeholder (high-passed, so its
    # own thump drops out) + a faint Kenney Impact Sounds glass tick
    for i, (t, g) in enumerate([(6.78, 0), (8.21, 1), (8.96, 2), (1.43, 3)], 1):
        step = cut(c, t - 0.01, t + 0.32, fout=0.07)
        crunch = hp(ph(f"sfx/footstep_glass_{i:02d}.wav"), 2500, 4)
        gl = hp(kenney("impact-sounds", f"impactGlass_light_{g:03d}.ogg"), 2500)
        x = mix(0.35, (norm_peak(step, -1), 0, 0), (norm_peak(crunch, -1), 0.005, -3), (norm_peak(gl, -1), 0.02, -16))
        out_sfx(f"footstep_glass_{i:02d}", tail_fade(x, 0.06))
    # carpet: Kenney Impact Sounds (only 3 unique carpet takes; #04 is take 001 slowed 7% and darker)
    for i, (f, sp) in enumerate([("000", 1.0), ("001", 1.0), ("003", 1.0), ("001", 0.93)], 1):
        x = kenney("impact-sounds", f"footstep_carpet_{f}.ogg")
        if sp != 1.0:
            x = lp(speed(x, sp), 2500)
        out_sfx(f"footstep_carpet_{i:02d}", pad(tail_fade(x, 0.03), 0.30))
    # grass: Kenney Impact Sounds footstep_grass_000..003, trimmed to 0.4 s
    for i in range(4):
        x = kenney("impact-sounds", f"footstep_grass_{i:03d}.ogg")
        out_sfx(f"footstep_grass_{i + 1:02d}", tail_fade(pad(x, 0.40), 0.12))


@job("doors")
def doors():
    # BigSoundBank #1702 "Apartment Door, Opening #1": latch, handle, door swing
    out_sfx("door_open", tail_fade(cut(hp(bsb("1702"), 40), 0.0, 1.75, fout=0.0), 0.35))
    # BigSoundBank #1704 "Apartment Door, Closing #1": end of the swing, then the slam and latch
    out_sfx("door_close", tail_fade(cut(hp(bsb("1704"), 40), 1.95, 3.6, fin=0.05, fout=0.0), 0.3))


@job("cutlery_clink")
def cutlery():
    x = hp(bsb("1191"), 80)  # BigSoundBank #1191 "Cutlery, set on a plate"
    out_sfx("cutlery_clink", tail_fade(mix(1.2, (cut(x, 4.62, 5.25), 0, 0), (cut(x, 9.15, 9.75), 0.55, -2)), 0.1))


@job("phone_buzz")
def phone():
    x = bsb("1034")  # BigSoundBank #1034 "Mobile vibrator without protective shell"
    b1 = cut(x, 0.30, 0.95, fin=0.01, fout=0.06)
    b2 = cut(x, 2.32, 2.97, fin=0.01, fout=0.06)
    out_sfx("phone_buzz", mix(1.6, (b1, 0.0, 0), (b2, 0.9, 0)))


@job("glass_break")
def glass():
    m = bsb("0387")  # BigSoundBank #0387 "A Mirror Explodes"
    bits = hp(bsb("0771"), 300)  # BigSoundBank #0771 "Broken glass" (falling shards)
    x = mix(2.2, (cut(m, 0.03, 1.43, fout=0.15), 0, 0), (cut(bits, 3.86, 4.05), 1.25, -12),
            (cut(bits, 6.22, 6.40), 1.7, -16))
    x = reverb(x, decay=0.7, wet=0.12)[:n_of(2.2)]
    out_sfx("glass_break", tail_fade(x, 0.2))


@job("car_crash")
def car_crash():
    steel = bsb("1774")  # BigSoundBank #1774 "Falling sheet steel bar #4"
    steel2 = bsb("1776")  # #1776 "Fall 2 sheet steel bars #1"
    can = bsb("1266")  # #1266 "Metal trash can"
    gl = bsb("0148")  # #0148 "Glass Burst"
    bits = hp(bsb("0771"), 300)  # #0771 "Broken glass"
    kmet = kenney("impact-sounds", "impactMetal_heavy_000.ogg")
    kmet2 = kenney("impact-sounds", "impactMetal_heavy_003.ogg")
    low = lp(ph("sfx/car_crash.wav"), 300)  # body/sub from the synthesised placeholder
    x = mix(4.0,
            (low, 0.0, -4),
            (cut(can, 3.60, 4.6, fout=0.3), 0.0, -1),
            (cut(steel, 0.08, 3.9, fout=1.6), 0.02, -2),
            (norm_peak(kmet, -1), 0.0, -4),
            (cut(gl, 0.0, 1.6, fout=0.3), 0.07, -5),
            (cut(steel2, 0.04, 2.5, fout=0.5), 0.55, -9),
            (norm_peak(kmet2, -1), 1.05, -14),
            (cut(bits, 0.16, 0.55), 1.35, -13),
            (cut(bits, 1.94, 2.40), 2.1, -15),
            (cut(bits, 3.86, 4.0), 2.9, -18))
    x = reverb(x, decay=1.4, wet=0.2)[:n_of(4.0)]
    out_sfx("car_crash", tail_fade(x, 0.4))


@job("explosion_distant")
def explosion():
    e = bsb("1023")  # BigSoundBank #1023 "Explosion far Away #1"
    th = bsb("3113")  # #3113 "Thunder #2" used as the rolling echo tail
    boom = lp(speed(e, 0.8), 2200, 2)
    roll = lp(cut(th, 0.6, 5.0, fin=0.4, fout=1.2), 900, 2)
    low = lp(ph("sfx/explosion_distant.wav"), 160)
    x = mix(6.0, (boom, 0.0, 0), (roll, 0.25, -5), (low, 0.0, -6))
    x = reverb(x, decay=2.4, wet=0.3, dark=1200)[:n_of(6.0)]
    out_sfx("explosion_distant", tail_fade(x, 1.0))


@job("dog")
def dog():
    b = hp(bsb("2954"), 90)  # BigSoundBank #2954 "Barking Dog #2"
    out_sfx("dog_bark", tail_fade(mix(1.6, (cut(b, 0.03, 0.75, fout=0.1), 0, 0),
                                      (cut(b, 2.42, 3.2, fout=0.2), 0.82, -1)), 0.15))
    # OpenGameArt "Dog Snarl Grunt Grumble" by qubodup (CC0): growl, grumble, snarl joined
    d = os.path.join("dog-snarl-grunt-grumble", "x", "dog")
    g = oga(d, "dog-growl.flac")
    gr = oga(d, "dog-grumble.flac")
    sn = oga(d, "dog-snarl.flac")
    x = mix(1.8, (tail_fade(g, 0.06), 0.0, 0), (tail_fade(gr, 0.08), 0.52, -1), (tail_fade(sn, 0.12), 1.06, 0))
    out_sfx("dog_growl", tail_fade(hp(x, 60), 0.1))


@job("voices")
def voices():
    # scream: OpenGameArt "Female Scream 1" by Nocturnal_Vanguard (CC0), made distant
    s = oga("female-scream-1", "female_scream_1.ogg")
    s = bp(s, 300, 3200, 2)
    x = reverb(np.concatenate([s, np.zeros(n_of(5))]), decay=3.2, wet=0.55, dark=1500, predelay=0.04)
    out_sfx("scream_distant", tail_fade(pad(x, 6.0), 1.5))
    # hurt / grunt: OpenGameArt "Pain sounds by EmoPreben" (CC0)
    p = os.path.join("pain-sounds-by-emopreben", "x")
    h = oga(p, "Painsounds v2 - Track 5 - Urggh.ogg")
    out_sfx("hurt", tail_fade(pad(hp(h, 70), 1.0), 0.15))
    gnt = oga(p, "Painsounds v2 - Track 3 - Huuurh.ogg")
    out_sfx("grunt", tail_fade(pad(hp(gnt, 70), 0.9), 0.15))


@job("fight")
def fight():
    # whoosh: BigSoundBank #1799 "Whoosh #6"; bat swing: #1795 "Whoosh #3" slowed 15%
    out_sfx("whoosh", tail_fade(pad(cut(bsb("1799"), 0.06, 0.45), 0.35), 0.08))
    out_sfx("bat_swing", tail_fade(pad(cut(lp(speed(bsb("1795"), 0.85), 5000), 0.18, 0.66), 0.45), 0.1))
    # punch: short whoosh (#1797 "Whoosh #5") into BigSoundBank #2461 "Punch #6"
    wh = cut(bsb("1797"), 0.12, 0.32, fout=0.04)
    pu = cut(bsb("2461"), 0.04, 0.45, fout=0.1)
    out_sfx("punch", tail_fade(mix(0.45, (wh, 0.0, -8), (pu, 0.08, 0)), 0.08))
    # hit_heavy: Kenney impactPunch_heavy_000 layered with BigSoundBank #0444 "Punch #2"
    k = kenney("impact-sounds", "impactPunch_heavy_000.ogg")
    p2 = cut(bsb("0444"), 1.11, 1.6, fout=0.1)
    out_sfx("hit_heavy", tail_fade(mix(0.7, (norm_peak(k, -1), 0, 0), (norm_peak(p2, -1), 0.0, -3),
                                       (lp(norm_peak(k, -1), 180), 0.0, -2)), 0.15))


@job("paper_rustle")
def paper():
    x = hp(bsb("0493"), 120)  # BigSoundBank #0493 "Pages that turn #1"
    out_sfx("paper_rustle", tail_fade(pad(cut(x, 3.86, 4.96, fout=0.2), 1.1), 0.2))


@job("tv_murmur_loop")
def tv_murmur():
    # BigSoundBank #0684 "Walla Group: Averages Discussions" through a TV speaker and a wall,
    # with a very low music bed from "Calm Piano 1 (Vaporware)" by The Cynic Project (CC0)
    w = bsb("0684")[n_of(30):n_of(58)]
    v = bp(w, 220, 2600, 2)
    v = lp(v, 1100, 2)
    m = oga("calm-piano-1-vaporware", "003_Vaporware_2.mp3")[n_of(40):n_of(68)]
    m = lp(bp(m, 180, 3000, 2), 1300, 2)
    x = v / np.std(v) + db(-14) * m / np.std(m)
    x = reverb(x, decay=0.5, wet=0.2)[:len(w)]
    out_loop_sfx("tv_murmur_loop", loop_crossfade(x, 24.0, 2.0))


@job("crowd_panic_far_loop")
def crowd():
    # BigSoundBank #3391 "Manifestation #14" + #0685 "Walla Group: Strong Discussions",
    # far-away screams from #1662/#1663 "Howling of a Girl", #1664/#1679 "Howling of a Boy"
    # and OGA "Female Scream 1" (CC0), all filtered and pushed back with reverb.
    L = 16.0
    base = bsb("3391")[n_of(20):n_of(20 + L + 3)]
    walla = bsb("0685")[n_of(10):n_of(10 + L + 3)]
    x = base / np.std(base) + db(-4) * walla / np.std(walla)
    x = lp(hp(x, 180), 1600, 2)
    loop = loop_crossfade(x, L, 3.0)
    loop = loop / np.std(loop)
    rng = np.random.default_rng(11)
    shouts = [bsb("1662"), bsb("1663"), bsb("1664"), bsb("1679"), oga("female-scream-1", "female_scream_1.ogg")]
    for i, (t, s) in enumerate(zip([1.5, 5.2, 8.4, 11.0, 13.6], shouts)):
        s = lp(bp(s, 400, 3000), 1800)
        s = reverb(np.concatenate([s, np.zeros(n_of(3))]), decay=2.5, wet=0.7, dark=1300, predelay=0.05)
        place_wrap(loop, s / (np.abs(s).max() + 1e-9), t + rng.uniform(-0.3, 0.3), db(-2 - 3 * rng.random()) * 4)
    loop = reverb(loop, decay=1.8, wet=0.35, dark=1400)
    loop = loop[:n_of(L)] + np.pad(loop[n_of(L):], (0, max(0, n_of(L) - len(loop[n_of(L):]))))[:n_of(L)]
    out_loop_sfx("crowd_panic_far_loop", loop)


@job("fire_crackle_loop")
def fire():
    x = bsb("0987")  # BigSoundBank #0987 "Big Branching Fire #1"
    seg = hp(x[n_of(8):n_of(8 + 17)], 40)
    out_loop_sfx("fire_crackle_loop", loop_crossfade(seg, 14.0, 2.5))


# ---------------------------------------------------------------- ambience (stereo OGG, -26 LUFS)
def amb(name, x):
    out_ogg("ambience", name, x, -26.0, -6.0)


@job("suburban_evening_loop")
def suburban():
    # BigSoundBank #1859 "Evening Birds" + #1082 "Parisian park, children's games" far away
    birds = bsb("1859", True)[n_of(60):n_of(60 + 44)]
    kids = bsb("1082", True)[n_of(20):n_of(20 + 44)]
    kids = lp(hp(kids, 250), 2200)
    x = birds / np.std(birds) + db(-13) * kids / np.std(kids)
    amb("suburban_evening_loop", loop_crossfade(x, 40.0, 4.0))


@job("crickets_night_loop")
def crickets():
    x = bsb("1880", True)[n_of(60):n_of(60 + 34)]  # BigSoundBank #1880 "Campaign at Night #4"
    amb("crickets_night_loop", loop_crossfade(hp(x, 60), 30.0, 4.0))


@job("wind_loop")
def wind():
    x = bsb("1714", True)[n_of(20):n_of(20 + 35)]  # BigSoundBank #1714 "Wind from inside #1"
    amb("wind_loop", loop_crossfade(hp(x, 30), 30.0, 5.0))


@job("dawn_quiet_loop")
def dawn():
    # BigSoundBank #0935 "Birds waking #2" + the placeholder's own far siren, very low
    birds = bsb("0935", True)[n_of(26):n_of(26 + 44)]
    siren = ph("sfx/siren_distant_loop.wav")
    siren = lp(siren, 1500)
    sb = np.zeros((n_of(44), 2))
    place(sb, np.tile(siren, 3)[:n_of(44)], 0, 1.0, pan=-0.4)
    x = birds / np.std(birds) + db(-24) * sb / (np.std(sb) + 1e-9)
    amb("dawn_quiet_loop", loop_crossfade(hp(x, 40), 40.0, 4.0))


# ---------------------------------------------------------------- music (stereo OGG, -16 LUFS)
def mus(name, x):
    out_ogg("music", name, x, -16.0, -1.5)


@job("home_evening")
def home_evening():
    x = oga("at-home-orchestral", "cinematic-calm.wav", True)  # "At Home - Orchestral" by Wolfgang_ (CC0)
    mus("home_evening", music_loop(x, 1.50, 47.93, 1.5))


@job("aftermath")
def aftermath():
    x = oga("emotional-piano-0", "emotional_piano_solo_0.ogg", True)  # "Emotional Piano" by Centurion_of_war
    mus("aftermath", music_loop(x, 1.50, 59.09, 1.5))


@job("dawn_hope")
def dawn_hope():
    x = oga("the-hope", "Hope.mp3", True)  # "The Hope" by TAD (CC0)
    mus("dawn_hope", music_loop(x, 11.00, 144.54, 2.0))


@job("title")
def title():
    x = oga("revelation", "Revelation.Wav", True)  # "Revelation" by Indieteur (CC0)
    mus("title", music_loop(x, 1.50, 78.30, 2.0))


def main():
    global A
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--placeholders", required=True)
    ap.add_argument("names", nargs="*")
    A = ap.parse_args()
    for n in A.names or list(BUILD):
        BUILD[n]()


if __name__ == "__main__":
    main()
