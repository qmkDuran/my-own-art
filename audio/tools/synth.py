"""Small procedural-audio toolkit used to generate every sound in Project R.

Everything here is original synthesis (noise, oscillators, filters, envelopes).
No samples are loaded from anywhere. Requires numpy + scipy; ffmpeg is used
only for loudness measurement (EBU R128) and OGG encoding.
"""
import os
import re
import subprocess
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100


# ---------------------------------------------------------------- basics
def n_of(sec):
    return int(round(sec * SR))


def tt(sec):
    return np.arange(n_of(sec)) / SR


def white(sec, rng):
    return rng.standard_normal(n_of(sec))


def pink(sec, rng):
    n = n_of(sec)
    X = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = f[1]
    X /= np.sqrt(f)
    y = np.fft.irfft(X, n)
    return y / (np.std(y) + 1e-12)


def brown(sec, rng):
    n = n_of(sec)
    X = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = f[1]
    X /= f
    X[f < 15] = 0
    y = np.fft.irfft(X, n)
    return y / (np.std(y) + 1e-12)


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


# ---------------------------------------------------------------- filters
def _sos(kind, f, order=2):
    return signal.butter(order, f, kind, fs=SR, output="sos")


def lp(x, f, order=2):
    f = min(f, SR * 0.45)
    return signal.sosfilt(_sos("low", f, order), x, axis=0)


def hp(x, f, order=2):
    return signal.sosfilt(_sos("high", f, order), x, axis=0)


def bp(x, lo, hi, order=2):
    hi = min(hi, SR * 0.45)
    return signal.sosfilt(_sos("band", [lo, hi], order), x, axis=0)


def reson(x, f, q):
    """Resonant peak (like a body / cavity mode)."""
    b, a = signal.iirpeak(min(f, SR * 0.45), q, fs=SR)
    return signal.lfilter(b, a, x, axis=0)


def formants(x, fs_and_bw, gains=None):
    out = np.zeros_like(x)
    gains = gains or [1.0] * len(fs_and_bw)
    for (f, bw), g in zip(fs_and_bw, gains):
        out += g * reson(x, f, max(f / bw, 0.5))
    return out


def tv_lowpass(x, cutoff, block=256):
    """Time-varying 2nd-order lowpass; cutoff is an array (len == len(x))."""
    y = np.zeros_like(x)
    zi = np.zeros((1, 2))
    for i in range(0, len(x), block):
        c = float(np.clip(cutoff[min(i, len(cutoff) - 1)], 20, SR * 0.45))
        sos = _sos("low", c)
        y[i:i + block], zi = signal.sosfilt(sos, x[i:i + block], zi=zi)
    return y


def tv_bandpass(x, center, q=2.0, block=256):
    y = np.zeros_like(x)
    zi = np.zeros((1, 2))
    for i in range(0, len(x), block):
        c = float(np.clip(center[min(i, len(center) - 1)], 30, SR * 0.4))
        b, a = signal.iirpeak(c, q, fs=SR)
        zi_in = zi[0] if zi.ndim == 2 else zi
        seg, zo = signal.lfilter(b, a, x[i:i + block], zi=zi_in)
        y[i:i + block] = seg
        zi = zo
    return y


# ---------------------------------------------------------------- envelopes
def env_exp(n, tau_sec, attack_sec=0.0005):
    t = np.arange(n) / SR
    e = np.exp(-t / max(tau_sec, 1e-5))
    na = max(1, n_of(attack_sec))
    e[:na] *= np.linspace(0, 1, na)
    return e


def adsr(n, a, d, s, r):
    na, nd, nr = n_of(a), n_of(d), n_of(r)
    ns = max(0, n - na - nd - nr)
    e = np.concatenate([
        np.linspace(0, 1, max(na, 1)),
        np.linspace(1, s, max(nd, 1)),
        np.full(ns, s),
        np.linspace(s, 0, max(nr, 1)),
    ])
    if len(e) < n:
        e = np.pad(e, (0, n - len(e)))
    return e[:n]


def fade(x, fin=0.005, fout=0.01):
    x = x.copy()
    a, b = n_of(fin), n_of(fout)
    if a:
        x[:a] *= np.linspace(0, 1, a)[:, None] if x.ndim == 2 else np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)[:, None] if x.ndim == 2 else np.linspace(1, 0, b)
    return x


def smooth_random(sec, rate_hz, rng, lo=0.0, hi=1.0):
    """Slow random control signal (cubic-ish interpolated points)."""
    n = n_of(sec)
    k = max(4, int(sec * rate_hz) + 3)
    pts = rng.uniform(lo, hi, k)
    xs = np.linspace(0, n, k)
    y = np.interp(np.arange(n), xs, pts)
    w = max(3, int(SR / rate_hz / 2))
    y = np.convolve(y, np.hanning(w) / np.hanning(w).sum(), mode="same")
    # edges of the convolution droop, re-pin them
    y[:w] = y[w]
    y[-w:] = y[-w - 1]
    return y


def smooth_random_loop(sec, rate_hz, rng, lo=0.0, hi=1.0):
    """Periodic slow control signal: value at end == value at start."""
    n = n_of(sec)
    k = max(3, int(sec * rate_hz))
    t = np.arange(n) / n
    y = np.zeros(n)
    for h in range(1, k + 1):
        amp = rng.uniform(0, 1) / h
        y += amp * np.sin(2 * np.pi * h * t + rng.uniform(0, 2 * np.pi))
    y = (y - y.min()) / (y.max() - y.min() + 1e-12)
    return lo + (hi - lo) * y


# ---------------------------------------------------------------- oscillators
def osc_phase(freq, n=None):
    if np.isscalar(freq):
        return 2 * np.pi * freq * np.arange(n) / SR
    return 2 * np.pi * np.cumsum(freq) / SR


def additive(freq, n, partials, amp_fn=None):
    """Band-limited sum of harmonics. freq may be an array (pitch contour)."""
    ph = osc_phase(freq, n)
    fmax = np.max(freq) if not np.isscalar(freq) else freq
    y = np.zeros(n)
    for k in range(1, partials + 1):
        if k * fmax > SR * 0.45:
            break
        a = amp_fn(k) if amp_fn else 1.0 / k
        y += a * np.sin(k * ph)
    return y


def saw(freq, n, partials=40):
    return additive(freq, n, partials, lambda k: 1.0 / k)


def square(freq, n, partials=30):
    return additive(freq, n, partials, lambda k: (1.0 / k) if k % 2 else 0.0)


def glottal(f0, n, rng, jitter=0.01, partials=60):
    """Voice-like buzz source with a pitch contour and slight jitter."""
    f = f0 * (1 + jitter * smooth_random(n / SR, 30, rng, -1, 1))
    return additive(f, n, partials, lambda k: 1.0 / k ** 1.3)


# ---------------------------------------------------------------- space
def make_ir(decay, rng, bright=6000, predelay=0.01, stereo=False, dark=1800):
    n = n_of(decay * 1.2 + predelay)
    t = np.arange(n) / SR
    chans = []
    for _ in range(2 if stereo else 1):
        nz = rng.standard_normal(n)
        early = lp(nz, bright) * np.exp(-t / (decay / 6.9 * 0.35))
        late = lp(nz, dark) * np.exp(-t / (decay / 6.9))
        ir = 0.6 * early + late
        ir[: n_of(predelay)] = 0
        ir /= np.sqrt(np.sum(ir ** 2)) + 1e-12
        chans.append(ir)
    return np.stack(chans, 1) if stereo else chans[0]


def reverb(x, decay=1.2, wet=0.25, rng=None, stereo_out=False, bright=6000, dark=1800, predelay=0.012):
    rng = rng or np.random.default_rng(7)
    if stereo_out:
        ir = make_ir(decay, rng, bright, predelay, True, dark)
        if x.ndim == 1:
            x = np.stack([x, x], 1)
        n = len(x) + len(ir) - 1
        w = np.stack([signal.fftconvolve(x[:, c], ir[:, c]) for c in range(2)], 1)
        dry = np.pad(x, ((0, n - len(x)), (0, 0)))
        return (1 - wet) * dry + wet * w
    ir = make_ir(decay, rng, bright, predelay, False, dark)
    w = signal.fftconvolve(x, ir)
    dry = np.pad(x, (0, len(w) - len(x)))
    return (1 - wet) * dry + wet * w


# ---------------------------------------------------------------- mixing
def place(buf, x, start_sec, gain=1.0, pan=None):
    s = n_of(start_sec)
    if s >= len(buf):
        return buf
    if buf.ndim == 2 and x.ndim == 1:
        p = 0.0 if pan is None else pan
        ang = (p + 1) * np.pi / 4
        x = np.stack([x * np.cos(ang), x * np.sin(ang)], 1) * np.sqrt(2)
    e = min(len(buf), s + len(x))
    buf[s:e] += gain * x[: e - s]
    return buf


def place_wrap(buf, x, start_sec, gain=1.0, pan=None):
    """Like place() but anything running past the end wraps to the start (for loops)."""
    s = n_of(start_sec) % len(buf)
    if buf.ndim == 2 and x.ndim == 1:
        p = 0.0 if pan is None else pan
        ang = (p + 1) * np.pi / 4
        x = np.stack([x * np.cos(ang), x * np.sin(ang)], 1) * np.sqrt(2)
    x = x * gain
    pos = s
    i = 0
    while i < len(x):
        take = min(len(x) - i, len(buf) - pos)
        buf[pos:pos + take] += x[i:i + take]
        i += take
        pos = 0
    return buf


def loop_crossfade(x, loop_sec, xfade_sec):
    """x must be at least loop+xfade long. Returns a seamless loop of loop_sec."""
    L, X = n_of(loop_sec), n_of(xfade_sec)
    y = x[:L].copy()
    ramp = np.linspace(0, 1, X)
    fi, fo = np.sqrt(ramp), np.sqrt(1 - ramp)  # equal power (uncorrelated material)
    if x.ndim == 2:
        fi, fo = fi[:, None], fo[:, None]
    y[:X] = x[:X] * fi + x[L:L + X] * fo
    return y


def wrap_tail(x, loop_sec):
    """Fold everything after loop_sec back onto the start (reverb tails of loops)."""
    L = n_of(loop_sec)
    y = x[:L].copy()
    rest = x[L:]
    i = 0
    while i < len(rest):
        take = min(L, len(rest) - i)
        y[:take] += rest[i:i + take]
        i += take
    return y


def soft_limit(x, ceiling=0.89):
    """Gentle peak control: linear below 70% of ceiling, tanh knee above."""
    k = 0.7 * ceiling
    a = np.abs(x)
    over = a > k
    y = x.copy()
    y[over] = np.sign(x[over]) * (k + (ceiling - k) * np.tanh((a[over] - k) / (ceiling - k)))
    return y


def db(v):
    return 10 ** (v / 20.0)


# ---------------------------------------------------------------- io
def _to_int16(x, rng=None):
    rng = rng or np.random.default_rng(0)
    d = (rng.uniform(-0.5, 0.5, x.shape) + rng.uniform(-0.5, 0.5, x.shape)) / 32768.0
    return np.clip((x + d) * 32767, -32768, 32767).astype(np.int16)


def write_wav(path, x):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    wavfile.write(path, SR, _to_int16(x))


def measure_lufs(x):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        p = f.name
    try:
        y = x
        # ebur128 needs >= 400 ms; repeat short sounds
        if len(y) < n_of(3.0):
            reps = int(np.ceil(n_of(3.0) / len(y)))
            y = np.concatenate([y] * reps)
        wavfile.write(p, SR, y.astype(np.float32))
        r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", p, "-af", "ebur128", "-f", "null", "-"],
                           capture_output=True, text=True)
        m = re.findall(r"I:\s+(-?[\d.]+) LUFS", r.stderr)
        return float(m[-1]) if m else -70.0
    finally:
        os.unlink(p)


def norm_peak(x, peak_db=-3.0):
    return x / (np.max(np.abs(x)) + 1e-12) * db(peak_db)


def norm_lufs(x, target, peak_cap_db=-1.5):
    cur = measure_lufs(x)
    y = x * db(target - cur)
    cap = db(peak_cap_db)
    if np.max(np.abs(y)) > cap * 0.7:
        y = soft_limit(y, cap)
    return y, measure_lufs(y)


def encode_ogg(wav_path, ogg_path, q=6):
    subprocess.run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", wav_path,
                    "-c:a", "libvorbis", "-q:a", str(q), ogg_path], check=True)
