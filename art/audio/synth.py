"""Procedural audio for the heaven demo (all original, CC0). Writes game/audio/*.ogg (loops) and *.wav (one-shots).
Loops are seamless: every loop is rendered longer than its period and the overhang (note releases, reverb tail,
filtered noise) is wrapped back onto the start, so the end flows into the beginning sample-exactly."""
import os, subprocess
import numpy as np
from scipy.signal import butter, sosfiltfilt, fftconvolve

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '../../game/audio/')
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def midi(n): return 440.0 * 2 ** ((n - 69) / 12)
def t_axis(d): return np.arange(int(d * SR)) / SR


def env_adsr(n, a, r, sustain_end=None):
    e = np.ones(n)
    na = max(1, int(a * SR)); nr = max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na) ** 1.5
    e[-nr:] *= np.linspace(1, 0, nr) ** 1.5
    return e


def lp(x, f, order=2):
    return sosfiltfilt(butter(order, f, 'low', fs=SR, output='sos'), x, axis=0)
def hp(x, f, order=2):
    return sosfiltfilt(butter(order, f, 'high', fs=SR, output='sos'), x, axis=0)
def bp(x, lo, hi, order=2):
    return sosfiltfilt(butter(order, [lo, hi], 'band', fs=SR, output='sos'), x, axis=0)


# ------------------------------------------------------------------ instruments
def pad_note(f, dur, a=1.6, r=2.2, bright=1.6, det=0.004):
    """Warm additive pad, two slightly detuned voices per side (stereo)."""
    t = t_axis(dur + r); out = np.zeros((len(t), 2))
    for ch, d in ((0, -det), (1, det)):
        for v in (1 - d, 1 + d * 0.5):
            for k in range(1, 9):
                out[:, ch] += np.sin(2 * np.pi * f * v * k * t + rng.uniform(0, 6.28)) / k ** bright
    e = env_adsr(len(t), a, r)
    return out * e[:, None] * 0.12


def choir_note(f, dur, a=2.0, r=2.6):
    """Wordless 'aah' choir: harmonics shaped by vowel formants, gentle vibrato, several voices."""
    t = t_axis(dur + r); out = np.zeros((len(t), 2))
    formants = ((800, 120, 1.0), (1150, 140, 0.5), (2900, 300, 0.12))
    for voice in range(4):
        dv = 1 + rng.uniform(-0.006, 0.006)
        vib = 1 + 0.004 * np.sin(2 * np.pi * rng.uniform(4.6, 5.6) * t + rng.uniform(0, 6))
        phase = 2 * np.pi * np.cumsum(f * dv * vib) / SR
        sig = np.zeros(len(t))
        for k in range(1, 30):
            fk = f * k
            if fk > 6000: break
            amp = sum(g * np.exp(-((fk - fc) / bw) ** 2) for fc, bw, g in formants) + 0.25 / k
            sig += amp * np.sin(k * phase)
        pan = (voice % 2) * 0.6 + 0.2
        out[:, 0] += sig * (1 - pan); out[:, 1] += sig * pan
    e = env_adsr(len(t), a, r)
    return out * e[:, None] * 0.05


def harp_note(f, dur=3.0, vel=1.0):
    """Plucked harp: harmonic partials, higher ones decay faster, soft attack transient."""
    t = t_axis(dur)
    sig = np.zeros(len(t))
    for k in range(1, 8):
        sig += np.sin(2 * np.pi * f * k * t * (1 + 0.0004 * k)) * np.exp(-t * (0.9 + 0.9 * k)) / k ** 1.3
    att = np.minimum(1, t / 0.004)
    sig *= att * vel * 0.22
    return np.stack([sig, sig], 1)


def bell(f, dur=2.5, vel=1.0, ratios=(1, 2.756, 5.404, 8.933), decays=(1.6, 1.0, 0.6, 0.35)):
    t = t_axis(dur); sig = np.zeros(len(t))
    for r_, d, a in zip(ratios, decays, (1, 0.5, 0.25, 0.12)):
        sig += a * np.sin(2 * np.pi * f * r_ * t) * np.exp(-t / d)
    sig *= np.minimum(1, t / 0.002) * vel * 0.25
    return np.stack([sig, sig], 1)


def reverb(x, secs=2.6, wet=0.35, damp=5000):
    n = int(secs * SR); t = np.arange(n) / SR
    ir = np.stack([rng.standard_normal(n), rng.standard_normal(n)], 1) * np.exp(-t / (secs / 5))[:, None]
    ir = lp(ir, damp)
    ir[: int(0.012 * SR)] = 0
    ir /= np.sqrt((ir ** 2).sum(0))
    y = np.stack([fftconvolve(x[:, c], ir[:, c]) for c in range(2)], 1)
    dry = np.zeros_like(y); dry[: len(x)] = x
    return dry * (1 - wet) + y * wet * 1.6


def place(buf, snd, at):
    i = int(at * SR); j = min(len(buf), i + len(snd))
    buf[i:j] += snd[: j - i]


def wrap(x, period):
    n = int(period * SR); out = x[:n].copy()
    over = x[n:]
    while len(over):
        k = min(n, len(over)); out[:k] += over[:k]; over = over[k:]
    return out


def periodic_noise(period, stereo=True):
    """White noise that loops seamlessly once filtered (filtering is done circularly via wrap)."""
    n = int(period * SR)
    return rng.standard_normal((n, 2 if stereo else 1))


def circ_filter(x, fn, pad=2.0):
    """Apply a zero-phase filter circularly so the result loops seamlessly."""
    p = int(pad * SR)
    ext = np.concatenate([x[-p:], x, x[:p]])
    return fn(ext)[p:-p]


def normalize(x, peak_db=-6.0):
    pk = np.abs(x).max()
    return x * (10 ** (peak_db / 20) / pk) if pk > 0 else x


def save(name, x, loop=False, peak_db=-6.0):
    x = normalize(x, peak_db)
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    wav = OUT + name + '.wav'
    import wave
    with wave.open(wav, 'wb') as w:
        w.setnchannels(pcm.shape[1]); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    if loop:
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '5', OUT + name + '.ogg'], check=True)
        os.remove(wav)
    rms = 20 * np.log10(np.sqrt((x ** 2).mean()) + 1e-9)
    print(f'{name:16s} {len(x) / SR:6.2f}s peak {20 * np.log10(np.abs(x).max()):6.1f} dBFS  rms {rms:6.1f} dBFS  {"loop" if loop else ""}')


# ------------------------------------------------------------------ music
D_MAJ = {'D': [50, 57, 62, 66, 69], 'G/D': [50, 55, 59, 62, 67], 'Bm': [47, 54, 59, 62, 66], 'A': [45, 52, 57, 61, 64],
         'G': [43, 50, 55, 59, 62], 'D/F#': [42, 50, 57, 62, 66], 'Em': [40, 52, 55, 59, 64], 'Asus': [45, 52, 57, 62, 64]}


def music_loop(chords, beat, beats_per_chord, harp_pattern, pad_level=1.0, choir=False, pedal=None, bells=False):
    period = len(chords) * beats_per_chord * beat
    total = period + 6.0
    buf = np.zeros((int(total * SR), 2))
    cd = beats_per_chord * beat
    for i, c in enumerate(chords):
        notes = D_MAJ[c]
        for n in notes[:4]:
            place(buf, pad_note(midi(n), cd + 0.6) * pad_level, i * cd)
            if choir: place(buf, choir_note(midi(n + 12), cd + 0.4), i * cd)
        for s, deg in enumerate(harp_pattern):
            if deg is None: continue
            tones = sorted(set(m + 12 for m in notes[1:]) | set(m + 24 for m in notes[2:4]))
            place(buf, harp_note(midi(tones[deg % len(tones)]), 3.0, 0.8 + 0.2 * rng.random()), i * cd + s * beat / 2)
        if bells and i % 2 == 1:
            place(buf, bell(midi(notes[-1] + 24), 3.0, 0.35), i * cd + beat * 1.5)
    if pedal:
        t = t_axis(total)
        org = sum(np.sin(2 * np.pi * midi(pedal) * k * t) / k ** 2 for k in (1, 2, 3, 4))
        lfo = 0.85 + 0.15 * np.sin(2 * np.pi * t / period * 2)
        buf += np.stack([org, org], 1) * 0.05 * lfo[:, None]
    wet = reverb(buf, 3.0, 0.4)
    return wrap(wet, period)


def city_music():
    pat = [0, None, 2, 1, 3, None, 2, None]           # gentle harp figure, 8 half-beats per chord
    return music_loop(['D', 'G/D', 'Bm', 'A', 'G', 'D/F#', 'Em', 'Asus'], 1.0, 4, pat, pad_level=1.0)


def menu_music():
    return music_loop(['D', 'Bm', 'G', 'Asus'], 1.0, 4, [0, 2, 1, 3, 2, None, 4, None], pad_level=0.9)


def throne_drone():
    # choir + organ pedal on D, slow progression, harp rolls and distant bells
    period_chords = ['D', 'G/D', 'Bm', 'D', 'G/D', 'Em', 'Asus', 'D']
    return music_loop(period_chords, 1.0, 4, [0, None, None, None, 2, None, None, None], pad_level=0.6, choir=True, pedal=38, bells=True)


def holy_swell():
    """Instrumental arrangement of the opening phrase of NICAEA ("Holy, Holy, Holy", J. B. Dykes, 1861 - public domain)."""
    beat = 0.85
    # (scale-degree MIDI note, beats); D major: D4=62
    phrase1 = [(62, 1), (62, 1), (66, 1), (66, 1), (69, 2), (69, 2), (71, 1), (71, 1), (71, 1), (69, 1), (66, 4)]
    phrase2 = [(62, 1), (62, 1), (66, 1), (66, 1), (69, 2), (69, 2), (71, 1), (71, 1), (71, 1), (69, 1), (64, 2), (62, 4)]
    chords1 = [('D', 4), ('D', 4), ('G', 3), ('D', 1), ('D/F#', 4)]
    chords2 = [('D', 4), ('D', 4), ('G', 3), ('D', 1), ('A', 2), ('D', 6)]
    total = (sum(b for _, b in phrase1) + sum(b for _, b in phrase2)) * beat + 6
    buf = np.zeros((int(total * SR), 2))
    t0 = 0.0
    for phrase, chords in ((phrase1, chords1), (phrase2, chords2)):
        tt = t0
        for n, b in phrase:   # melody: soft flute/organ voice with vibrato
            d = b * beat; t = t_axis(d + 0.4)
            vib = 1 + 0.003 * np.sin(2 * np.pi * 5 * t)
            ph = 2 * np.pi * np.cumsum(midi(n) * vib) / SR
            s = (np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)) * env_adsr(len(t), 0.06, 0.35) * 0.11
            place(buf, np.stack([s, s], 1), tt); tt += d
        tc = t0
        for c, b in chords:
            for n in D_MAJ[c][:4]:
                place(buf, choir_note(midi(n + 12), b * beat + 0.3, a=0.5, r=1.2) * 1.2, tc)
                place(buf, pad_note(midi(n), b * beat + 0.3, a=0.4, r=1.0) * 0.8, tc)
            place(buf, harp_note(midi(D_MAJ[c][1] + 12), 3.0, 0.7), tc)
            tc += b * beat
        t0 = tt
    for k, n in enumerate((62, 66, 69, 74, 78, 81)):   # final rolled harp chord
        place(buf, harp_note(midi(n), 4.0, 0.8), t0 - 6 * beat + k * 0.09)
    fade = np.ones(len(buf)); nf = int(3 * SR); fade[-nf:] = np.linspace(1, 0, nf)
    return reverb(buf * fade[:, None], 3.2, 0.42)


# ------------------------------------------------------------------ ambiences (seamless)
def river():
    period = 8.0
    n = periodic_noise(period)
    water = circ_filter(n, lambda x: bp(x, 250, 2600))
    t = t_axis(period)
    mod = 0.75 + 0.25 * np.sin(2 * np.pi * t * 3 / period) * np.sin(2 * np.pi * t * 5 / period + 1)
    water = water * mod[:, None]
    buf = np.zeros((int((period + 1) * SR), 2)); buf[: len(water)] += water * 0.25
    for _ in range(46):   # small bubbles / trickles
        f0 = rng.uniform(500, 1300); d = rng.uniform(0.03, 0.08); tb = t_axis(d)
        ch = np.sin(2 * np.pi * np.cumsum(f0 * (1 + 1.5 * tb / d)) / SR) * np.sin(np.pi * tb / d) * 0.09
        pan = rng.uniform(0.2, 0.8)
        place(buf, np.stack([ch * (1 - pan), ch * pan], 1), rng.uniform(0, period))
    return wrap(buf, period)


def calm_air():
    period = 12.0
    n = periodic_noise(period)
    air = circ_filter(n, lambda x: lp(x, 380, 2))
    t = t_axis(period)
    air *= (0.7 + 0.3 * np.sin(2 * np.pi * t / period) ** 2)[:, None]
    return air


def lamp_crackle():
    period = 6.0
    hiss = circ_filter(periodic_noise(period), lambda x: bp(x, 600, 4000)) * 0.05
    buf = np.zeros((int((period + 0.2) * SR), 2)); buf[: len(hiss)] += hiss
    for _ in range(int(period * 9)):
        d = rng.uniform(0.002, 0.012); k = rng.standard_normal(int(d * SR)) * np.exp(-np.linspace(0, 6, int(d * SR)))
        k = hp(k, 1500) * rng.uniform(0.15, 0.6)
        pan = rng.uniform(0.3, 0.7)
        place(buf, np.stack([k * (1 - pan), k * pan], 1), rng.uniform(0, period))
    return wrap(buf, period)


# ------------------------------------------------------------------ one-shots
def thunder(seed):
    r = np.random.default_rng(seed)
    dur = 5.0; t = t_axis(dur)
    noise = np.cumsum(r.standard_normal((len(t), 2)), 0); noise -= lp(noise, 8)   # brown noise, DC removed
    rum = lp(noise, 140, 4)
    envl = np.zeros(len(t))
    for k in range(r.integers(3, 6)):   # several rolls
        at = r.uniform(0.0, 2.2) if k else 0.05
        envl += r.uniform(0.5, 1.0) * np.exp(-np.maximum(0, t - at) / r.uniform(0.6, 1.4)) * (t >= at) * np.minimum(1, (t - at).clip(0) / 0.25)
    out = rum * envl[:, None]
    fade = np.ones(len(t)); fade[-int(1.0 * SR):] = np.linspace(1, 0, int(1.0 * SR))
    return reverb(out * fade[:, None], 2.0, 0.3, damp=900)


def step_chime(f):
    s = bell(f, 0.35, 0.5, ratios=(1, 2.01, 3.2), decays=(0.09, 0.05, 0.03))
    tick = hp(rng.standard_normal(int(0.004 * SR)), 3000) * 0.08
    s[: len(tick), 0] += tick; s[: len(tick), 1] += tick
    return s


def step_grass():
    d = 0.09; n = rng.standard_normal(int(d * SR))
    s = bp(n, 300, 2500) * np.exp(-np.linspace(0, 5, len(n))) * 0.3
    return np.stack([s, s], 1)


def gate_chime():
    buf = np.zeros((int(5 * SR), 2))
    for k, n in enumerate((74, 78, 81, 86, 90, 93)):
        place(buf, bell(midi(n), 3.5, 0.8 - k * 0.07), k * 0.16)
    t = t_axis(3.5)
    sh = hp(rng.standard_normal(len(t)), 6000) * np.exp(-t / 0.9) * np.minimum(1, t / 0.4) * 0.03
    place(buf, np.stack([sh, sh], 1), 0.2)
    return reverb(buf, 3.0, 0.45)


def crown_cast():
    buf = np.zeros((int(3.0 * SR), 2))
    for k, n in enumerate(range(74, 98, 2)):   # soft rising harp glissando
        place(buf, harp_note(midi(n), 1.8, 0.45), k * 0.07)
    return reverb(buf, 2.4, 0.4)


G_MAJ = {'G': [43, 55, 59, 62, 67], 'C': [48, 55, 60, 64, 67], 'Em': [40, 55, 59, 64, 67], 'D': [50, 57, 62, 66, 69],
         'Am': [45, 57, 60, 64, 69]}


def pastoral_music():
    """New earth: open pastoral loop in G - pads, harp, and a simple flute-like tune (original)."""
    beat = 0.9; chords = ['G', 'C', 'Em', 'D', 'G', 'Am', 'C', 'D']
    period = len(chords) * 4 * beat
    buf = np.zeros((int((period + 6) * SR), 2))
    tune = [67, 71, 74, 72, 71, 69, 67, 69, 71, 72, 74, 76, 74, 72, 71, 69,
            67, 71, 74, 76, 74, 72, 71, 69, 72, 71, 69, 67, 69, 71, 69, 66]
    for i, c in enumerate(chords):
        for n in G_MAJ[c][:4]:
            place(buf, pad_note(midi(n), 4 * beat + 0.5, a=1.2, r=1.8) * 0.8, i * 4 * beat)
        for s_, deg in enumerate([0, 2, 1, 3, 2, 4, 1, 3]):
            tones = sorted(set(m + 12 for m in G_MAJ[c][1:]))
            place(buf, harp_note(midi(tones[deg % len(tones)]), 2.5, 0.55), i * 4 * beat + s_ * beat / 2)
        for k in range(4):   # flute: soft sine with breath and vibrato
            n = tune[(i * 4 + k) % len(tune)]
            d = beat * 0.95; t = t_axis(d + 0.3)
            vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1, t / 0.3)
            ph = 2 * np.pi * np.cumsum(midi(n + 12) * vib) / SR
            breath = lp(rng.standard_normal(len(t)), 3000) * 0.015
            sig = (np.sin(ph) + 0.12 * np.sin(2 * ph) + breath) * env_adsr(len(t), 0.08, 0.25) * 0.075
            place(buf, np.stack([sig * 0.9, sig], 1), i * 4 * beat + k * beat)
    return wrap(reverb(buf, 2.6, 0.35), period)


def voice(f0s, dur, formants, vib_rate, trem=0.0, bright=1.0):
    t = t_axis(dur)
    f = np.interp(t, np.linspace(0, dur, len(f0s)), f0s)
    vib = 1 + 0.03 * np.sin(2 * np.pi * vib_rate * t)
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    sig = np.zeros(len(t))
    for k in range(1, 40):
        fk = np.mean(f) * k
        if fk > 5000: break
        amp = sum(g * np.exp(-((fk - fc) / bw) ** 2) for fc, bw, g in formants) * bright + 0.05 / k
        sig += amp * np.sin(k * ph)
    env = np.minimum(1, t / 0.06) * np.minimum(1, (dur - t) / 0.25)
    if trem: env *= 1 - trem * (0.5 + 0.5 * np.sin(2 * np.pi * 7 * t))
    return reverb(np.stack([sig * env, sig * env], 1), 1.2, 0.25)


def lamb_baa():
    return voice([330, 360, 300], 0.9, ((750, 160, 1.0), (1250, 200, 0.6), (2600, 300, 0.2)), 6.5, trem=0.35)


def cow_moo():
    return voice([118, 126, 100], 1.6, ((320, 120, 1.0), (750, 160, 0.5)), 3.0)


def hammer_knock():
    t = t_axis(0.35)
    thump = np.sin(2 * np.pi * 190 * t * (1 - 0.3 * t)) * np.exp(-t / 0.05)
    click = bp(rng.standard_normal(len(t)), 900, 3500) * np.exp(-t / 0.012) * 0.5
    s_ = (thump + click) * 0.6
    return reverb(np.stack([s_, s_], 1), 0.8, 0.2)


def wing_whoosh():
    d = 1.1; t = t_axis(d)
    n = rng.standard_normal((len(t), 2))
    sweep = np.stack([bp(n[:, c], 180, 1400) for c in range(2)], 1)
    env = np.sin(np.pi * np.clip(t / d, 0, 1)) ** 2
    return sweep * env[:, None]


def crown_land():
    s = bell(1760, 0.6, 0.6, ratios=(1, 2.41, 4.07, 6.3), decays=(0.22, 0.12, 0.07, 0.04))
    return reverb(s, 1.0, 0.2)


if __name__ == '__main__':
    save('city_music', city_music(), loop=True, peak_db=-5)
    save('menu_music', menu_music(), loop=True, peak_db=-5)
    save('throne_music', throne_drone(), loop=True, peak_db=-5)
    save('river', river(), loop=True, peak_db=-6)
    save('air', calm_air(), loop=True, peak_db=-8)
    save('lamps', lamp_crackle(), loop=True, peak_db=-8)
    save('holy', holy_swell(), peak_db=-4)
    save('thunder1', thunder(1), peak_db=-5)
    save('thunder2', thunder(2), peak_db=-5)
    for i, f in enumerate((2349, 2637, 2960)):
        save(f'step_gold{i}', step_chime(f), peak_db=-6)
    for i in range(2):
        save(f'step_grass{i}', step_grass(), peak_db=-6)
    save('gate_chime', gate_chime(), peak_db=-4)
    save('crown_cast', crown_cast(), peak_db=-5)
    save('crown_land', crown_land(), peak_db=-5)
    save('wing_whoosh', wing_whoosh(), peak_db=-10)
    save('pastoral_music', pastoral_music(), loop=True, peak_db=-5)
    save('lamb', lamb_baa(), peak_db=-8)
    save('cow', cow_moo(), peak_db=-8)
    save('knock', hammer_knock(), peak_db=-8)
