"""Yumuşak bildirim sesi adayları (telifsiz sentez) — onay için üretilir.

Kullanım:  python tool/gen_soft_sounds.py  -> sound_candidates/*.wav
Tüm sesler 44.1 kHz, 16-bit, mono, ~0.4-0.9 sn, tepe -3 dBFS, yumuşak zarf.
"""
import math
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   'sound_candidates')
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, attack=0.004, decay=0.25, curve=4.0):
    """Yumuşak perküsif zarf: kısa atak + üstel sönüm."""
    t = np.arange(n) / SR
    a = np.clip(t / attack, 0, 1)
    a = np.sin(a * math.pi / 2)  # yumuşak atak
    d = np.exp(-t / decay * curve)
    return a * d


def glide_sine(dur, f0, f1, shape=2.0):
    """f0 -> f1 kayan sinüs (shape>1: önce hızlı sonra yavaş)."""
    t = t_axis(dur)
    p = (t / dur) ** (1 / shape)
    f = f0 + (f1 - f0) * p
    phase = 2 * math.pi * np.cumsum(f) / SR
    return np.sin(phase)


def biquad_bandpass(x, fc, q):
    w0 = 2 * math.pi * fc / SR
    alpha = math.sin(w0) / (2 * q)
    b0, b1, b2 = alpha, 0.0, -alpha
    a0, a1, a2 = 1 + alpha, -2 * math.cos(w0), 1 - alpha
    b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i, xi in enumerate(x):
        yi = b0 * xi + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        y[i] = yi
        x2, x1, y2, y1 = x1, xi, y1, yi
    return y


def lowpass(x, fc):
    rc = 1 / (2 * math.pi * fc)
    a = (1 / SR) / (rc + 1 / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i, xi in enumerate(x):
        acc += a * (xi - acc)
        y[i] = acc
    return y


def reverb(x, dur=0.18, amount=0.18):
    """Çok kısa, yumuşak oda kuyruğu (sönümlü gürültü ile evrişim)."""
    n = int(SR * dur)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / SR * 22)
    ir = lowpass(ir, 2500)
    ir /= np.max(np.abs(ir)) + 1e-9
    wet = np.convolve(x, ir)  # uzunluk len(x)+n-1
    dry = np.concatenate([x, np.zeros(len(wet) - len(x))])
    return dry + amount * wet


def pad(x, dur):
    n = int(SR * dur)
    return np.concatenate([x, np.zeros(max(0, n - len(x)))])[:n]


def finish(x, tail=0.06):
    x = x.astype(np.float64)
    # bitişte kısa fade
    n = int(SR * tail)
    if n < len(x):
        x[-n:] *= np.linspace(1, 0, n)
    x = x / (np.max(np.abs(x)) + 1e-9) * (10 ** (-3 / 20))
    return x


def save(name, x):
    x = finish(x)
    pcm = (x * 32767).astype('<i2')
    path = os.path.join(OUT, name + '.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print('yazıldı', path, f'{len(x) / SR:.2f}s')


# 1) Balon/baloncuk patlaması — yumuşak: kısa süzülmüş gürültü + aşağı kayan "blup"
def bubble_pop():
    dur = 0.32
    body = glide_sine(dur, 820, 240, shape=1.6) * env(int(SR * dur), 0.003, 0.09, 3.5)
    noise = rng.standard_normal(int(SR * 0.05))
    noise = biquad_bandpass(noise, 1800, 1.2) * env(len(noise), 0.001, 0.02, 3)
    x = pad(body, 0.5)
    x[: len(noise)] += 0.35 * noise
    return reverb(x, 0.15, 0.14)


# 2) Su damlası "plip": yukarı kayan sinüs + hafif alt rezonans
def water_drop():
    dur = 0.22
    plip = glide_sine(dur, 520, 1350, shape=0.7) * env(int(SR * dur), 0.002, 0.07, 3.2)
    low = glide_sine(0.3, 300, 180, 1.0) * env(int(SR * 0.3), 0.004, 0.12, 3.0)
    x = pad(plip, 0.6)
    x[: len(low)] += 0.45 * low
    return reverb(x, 0.2, 0.22)


# 3) Çift damla: plip-plip (ikincisi daha ince ve kısık)
def double_drip():
    d1 = glide_sine(0.2, 500, 1200, 0.7) * env(int(SR * 0.2), 0.002, 0.07, 3.2)
    d2 = glide_sine(0.18, 700, 1600, 0.7) * env(int(SR * 0.18), 0.002, 0.06, 3.2)
    x = pad(d1, 0.75)
    off = int(SR * 0.17)
    x[off: off + len(d2)] += 0.7 * d2
    return reverb(x, 0.2, 0.2)


# 4) Su altı baloncuğu "blub": kalın, yuvarlak, yukarı kayan
def soft_blub():
    dur = 0.26
    x = glide_sine(dur, 170, 430, shape=0.8) * env(int(SR * dur), 0.006, 0.11, 3.0)
    x = lowpass(x, 1800)
    noise = rng.standard_normal(int(SR * 0.08))
    noise = lowpass(noise, 900) * env(len(noise), 0.003, 0.03, 3)
    x = pad(x, 0.5)
    x[: len(noise)] += 0.18 * noise
    return reverb(x, 0.16, 0.12)


# 5) Damla + halka (ripple): plip'in ardından iki detune sinüs şimşir parıltısı
def ripple():
    plip = glide_sine(0.2, 560, 1300, 0.7) * env(int(SR * 0.2), 0.002, 0.07, 3.2)
    t = t_axis(0.7)
    shimmer = (np.sin(2 * math.pi * 659 * t) + np.sin(2 * math.pi * 664 * t)
               + 0.5 * np.sin(2 * math.pi * 988 * t)) / 2.5
    shimmer *= env(len(t), 0.02, 0.32, 3.0)
    x = pad(plip, 0.85)
    off = int(SR * 0.06)
    x[off: off + len(shimmer)] += 0.42 * shimmer
    return reverb(x, 0.22, 0.2)


# 6) Baloncuk dizisi: üç minik baloncuk art arda yükselir (ışıltılı, yumuşak)
def bubbles():
    x = np.zeros(int(SR * 0.8))
    for i, (f0, f1, at) in enumerate([(300, 650, 0.0), (420, 900, 0.11), (560, 1200, 0.21)]):
        b = glide_sine(0.16, f0, f1, 0.8) * env(int(SR * 0.16), 0.003, 0.06, 3.2)
        off = int(SR * at)
        x[off: off + len(b)] += (0.75 + 0.12 * i) * lowpass(b, 2500)
    return reverb(x, 0.18, 0.18)


# 7) Yumuşak "tık" — ahşap/damla arası, çok kısa ve nazik
def soft_tap():
    dur = 0.16
    x = glide_sine(dur, 980, 620, 1.2) * env(int(SR * dur), 0.002, 0.045, 3.5)
    x += 0.5 * glide_sine(dur, 490, 310, 1.2) * env(int(SR * dur), 0.002, 0.06, 3.5)
    x = pad(x, 0.45)
    return reverb(x, 0.17, 0.2)


# ---------------------------------------------------------------------------
# "Damla + halka" (ripple) ailesi — kullanıcının beğendiği karakterin çeşitleri
# ---------------------------------------------------------------------------
def _drop(dur, f0, f1, decay=0.07):
    return glide_sine(dur, f0, f1, 0.7) * env(int(SR * dur), 0.002, decay, 3.2)


def _shimmer(dur, freqs, decay, gains=None, detune=5.0):
    """Detune'lu sinüs çifti kümesi: yumuşak, hafif titreşen parıltı."""
    t = t_axis(dur)
    out = np.zeros_like(t)
    for i, f in enumerate(freqs):
        g = 1.0 if gains is None else gains[i]
        out += g * (np.sin(2 * math.pi * f * t) + np.sin(2 * math.pi * (f + detune) * t))
    out /= (2 * len(freqs))
    return out * env(len(t), 0.02, decay, 3.0)


def ripple_variant(name, drop=(560, 1300), drop_dur=0.2, shimmer_freqs=(659, 988),
                   shimmer_gains=None, shimmer_decay=0.32, shimmer_gain=0.42,
                   shimmer_offset=0.06, total=0.85, rev=(0.22, 0.2), second_drop=None,
                   lowpass_hz=None, detune=5.0):
    x = pad(_drop(drop_dur, *drop), total)
    sh = _shimmer(total - shimmer_offset - 0.02, shimmer_freqs, shimmer_decay,
                  shimmer_gains, detune)
    if lowpass_hz:
        sh = lowpass(sh, lowpass_hz)
    off = int(SR * shimmer_offset)
    x[off: off + len(sh)] += shimmer_gain * sh
    if second_drop is not None:
        at, f0, f1, g = second_drop
        d2 = _drop(0.18, f0, f1)
        o2 = int(SR * at)
        x[o2: o2 + len(d2)] += g * d2
    return reverb(x, *rev)


RIPPLES = {
    # Orijinal (referans)
    'ripple_01_orijinal': dict(),
    # Daha sıcak/alçak: damla daha tok, parıltı alt oktav (E5 + B5 yerine A4 + E5)
    'ripple_02_sicak': dict(drop=(420, 980), shimmer_freqs=(440, 659), shimmer_decay=0.36,
                            shimmer_gain=0.46, lowpass_hz=2200),
    # Daha ince/parlak ve kısa: yüksek damla, kısa ışıltı
    'ripple_03_ince_kisa': dict(drop=(700, 1600), drop_dur=0.17, shimmer_freqs=(880, 1319),
                                shimmer_decay=0.22, shimmer_gain=0.36, total=0.65),
    # Majör üçlü parıltı (C-E-G): daha "müzikal", yumuşak akor
    'ripple_04_akor': dict(drop=(523, 1200), shimmer_freqs=(523, 659, 784),
                           shimmer_gains=(1.0, 0.8, 0.6), shimmer_decay=0.34, shimmer_gain=0.44),
    # Çift damla + halka: plip-plip ardından parıltı
    'ripple_05_cift_damla': dict(drop=(520, 1200), shimmer_offset=0.22, shimmer_decay=0.3,
                                 shimmer_gain=0.4, total=1.0,
                                 second_drop=(0.15, 680, 1500, 0.65)),
    # Uzun, derin göl: yavaş sönen geniş parıltı, daha fazla oda
    'ripple_06_derin_gol': dict(drop=(480, 1100), shimmer_freqs=(392, 587, 784),
                                shimmer_gains=(1.0, 0.7, 0.5), shimmer_decay=0.5,
                                shimmer_gain=0.48, total=1.25, rev=(0.3, 0.28), lowpass_hz=2600),
    # Minimal: çok kısık parıltı, damla öne çıkar (en sade)
    'ripple_07_minimal': dict(drop=(600, 1400), shimmer_freqs=(880,), shimmer_decay=0.2,
                              shimmer_gain=0.22, total=0.6, rev=(0.18, 0.16)),
    # Nazik iki nota: damla sonrası iki kısa yükselen parıltı notası (ding-ding hissi, yumuşak)
    'ripple_08_iki_nota': dict(drop=(560, 1300), shimmer_freqs=(659,), shimmer_decay=0.26,
                               shimmer_gain=0.4, total=0.95,
                               second_drop=(0.28, 880, 1760, 0.45)),
}


def gen_ripples():
    for name, kw in RIPPLES.items():
        save(name, ripple_variant(name, **kw))


if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == 'ripples':
        gen_ripples()
        raise SystemExit
    save('cand_bubble_pop', bubble_pop())
    save('cand_water_drop', water_drop())
    save('cand_double_drip', double_drip())
    save('cand_soft_blub', soft_blub())
    save('cand_ripple', ripple())
    save('cand_bubbles', bubbles())
    save('cand_soft_tap', soft_tap())
