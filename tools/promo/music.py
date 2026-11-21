"""An original, synthesised score for the Hazri promo: peaceful, uplifting, modern.
D major, 90 BPM, I-V-vi-IV. Pad, piano-like arpeggio, sub, soft drums, bells,
whooshes on the scene changes and a chime when a hazri is marked."""
import numpy as np, wave, sys

SR = 48000
DUR = 60.0
N = int(SR * DUR)
t_all = np.arange(N) / SR
L = np.zeros(N); R = np.zeros(N)
rng = np.random.default_rng(7)

BPM = 90.0
BEAT = 60 / BPM
BAR = 4 * BEAT
OFF = 5.0 - 2 * BAR          # a downbeat lands on 5.0 s, when the first feature opens

def hz(m): return 440.0 * 2 ** ((m - 69) / 12)

# chords as midi notes (D, A, Bm, G)
CH = [[50, 54, 57, 62, 66], [45, 52, 57, 61, 64], [47, 54, 59, 62, 66], [43, 50, 55, 59, 62]]

def add(sig, start, gl=1.0, gr=1.0):
    i = int(start * SR)
    if i >= N: return
    if i < 0: sig = sig[-i:]; i = 0
    n = min(len(sig), N - i)
    L[i:i+n] += sig[:n] * gl; R[i:i+n] += sig[:n] * gr

def env_adsr(n, a, d, s, r):
    e = np.ones(n) * s
    na, nd, nr = int(a*SR), int(d*SR), int(r*SR)
    na = min(na, n); e[:na] = np.linspace(0, 1, na)
    nd = min(nd, n - na); e[na:na+nd] = np.linspace(1, s, nd)
    if nr > 0 and n > nr: e[-nr:] *= np.linspace(1, 0, nr)
    return e

def lowpass(x, fc):
    a = np.exp(-2 * np.pi * fc / SR)
    y = np.empty_like(x); acc = 0.0
    # vectorised one-pole via lfilter-like recursion in chunks
    from itertools import accumulate
    y = np.array(list(accumulate(x * (1 - a), lambda p, v: p * a + v)))
    return y

def automation(points):
    ts, vs = zip(*points)
    return np.interp(t_all, ts, vs)

# ---------- pad ----------
pad = np.zeros(N)
nbars = int(DUR / BAR) + 3
for b in range(-1, nbars):
    st = OFF + b * BAR
    chord = CH[b % 4]
    if st > DUR: break
    if st > 53.4 - BAR and st < 53.4:   # hold the last chord into the ending
        pass
    n = int((BAR + 1.2) * SR)
    tt = np.arange(n) / SR
    sig = np.zeros(n)
    for m in chord:
        f = hz(m + 12)
        for det in (-0.12, 0.0, 0.11):
            ff = f * 2 ** (det / 12)
            ph = rng.random() * 6.28
            sig += (np.sin(2*np.pi*ff*tt + ph) + 0.35*np.sin(4*np.pi*ff*tt + ph) + 0.12*np.sin(6*np.pi*ff*tt + ph))
    sig *= env_adsr(n, 0.9, 0.5, 0.85, 1.2) / 15
    i = int(st * SR)
    if i < 0: sig = sig[-i:]; i = 0
    k = min(len(sig), N - i)
    if k > 0: pad[i:i+k] += sig[:k]
# the final chord: a long D major with an added 9th
st = 53.4; n = int((DUR - st) * SR); tt = np.arange(n) / SR
fin = np.zeros(n)
for m in [38, 50, 57, 62, 64, 66, 69, 74]:
    for det in (-0.1, 0.0, 0.1):
        fin += np.sin(2*np.pi*hz(m)*2**(det/12)*tt) + 0.3*np.sin(4*np.pi*hz(m)*2**(det/12)*tt)
fin *= env_adsr(n, 0.05, 1.5, 0.7, 2.5) / 16
i = int(st*SR); pad[i:i+n] *= np.linspace(1, 0, n) ** 3; pad[i:i+n] += fin
pad = lowpass(pad, 2200)
pad *= automation([(0, 0.0), (1.5, 0.55), (5, 0.6), (24.5, 0.6), (26, 0.9), (31, 0.7), (53.4, 0.7), (54, 1.0), (60, 1.0)])
add(pad * 0.55, 0, 0.95, 1.0)

# ---------- piano-like arpeggio ----------
def pluck(f, dur=1.4, amp=1.0):
    n = int(dur * SR); tt = np.arange(n) / SR
    s = (np.sin(2*np.pi*f*tt) + 0.5*np.sin(4*np.pi*f*tt)*np.exp(-tt*6) + 0.25*np.sin(6*np.pi*f*tt)*np.exp(-tt*9)
         + 0.08*np.sin(2*np.pi*f*1.002*tt))
    e = np.exp(-tt * 3.2) * np.minimum(1, tt / 0.004)
    return s * e * amp

ARP = [0, 2, 3, 4, 3, 2, 1, 2]
arp_gain = automation([(0, 0), (2.6, 0), (3.2, 0.7), (5, 1.0), (24.5, 1.0), (25.5, 0.6), (31, 1.0), (53.4, 0.9), (54.5, 0)])
step = BEAT / 2
k0 = int(np.ceil((2.67 - OFF) / step))
for j in range(k0, int((54.4 - OFF) / step)):
    st = OFF + j * step
    b = int(np.floor((st - OFF) / BAR))
    chord = CH[b % 4]
    m = chord[ARP[j % 8]] + 24
    g = arp_gain[min(int(st*SR), N-1)] * (1.0 if j % 2 == 0 else 0.72)
    pan = 0.5 + 0.35 * np.sin(j * 0.7)
    add(pluck(hz(m), 1.3, 0.11 * g), st, 1 - pan * 0.6, 0.4 + pan * 0.6)

# ---------- bell motif, from the second section ----------
MOT = [(0, 74), (1.5, 76), (2, 78), (3, 81)]
for b in range(4, 18):
    if b in (7, 8): continue          # the simran zoom stays quiet
    st0 = OFF + b * BAR
    if st0 < 11 or st0 > 52: continue
    for (bt, m) in MOT if b % 2 == 0 else [(0, 78), (1, 76), (2, 74), (3.5, 73)]:
        n = int(2.2*SR); tt = np.arange(n)/SR
        f = hz(m + (0 if (b//4) % 2 == 0 else -2))
        s = (np.sin(2*np.pi*f*tt) + 0.4*np.sin(2*np.pi*f*2.76*tt)*np.exp(-tt*4) + 0.2*np.sin(2*np.pi*f*5.4*tt)*np.exp(-tt*7))
        s *= np.exp(-tt*2.2) * np.minimum(1, tt/0.003) * 0.05
        add(s, st0 + bt*BEAT, 0.8, 1.0)

# ---------- sub bass ----------
for b in range(0, nbars):
    st = OFF + b * BAR
    if st < 4.9 or st > 53: continue
    root = CH[b % 4][0] - 12
    n = int(BAR * SR); tt = np.arange(n)/SR
    s = np.sin(2*np.pi*hz(root)*tt) * env_adsr(n, 0.02, 0.3, 0.8, 0.25) * 0.20
    if 24.4 < st < 31: s *= 0.5
    add(s, st)

# ---------- drums ----------
def kick():
    n = int(0.5*SR); tt = np.arange(n)/SR
    f = 48 + 90*np.exp(-tt*28)
    return np.sin(2*np.pi*np.cumsum(f)/SR) * np.exp(-tt*7) * 0.55
def hat(dec=40):
    n = int(0.12*SR); x = rng.standard_normal(n); x = np.diff(np.concatenate([[0], x]))
    return x * np.exp(-np.arange(n)/SR*dec) * 0.05
def snap():
    n = int(0.3*SR); tt = np.arange(n)/SR; x = rng.standard_normal(n)
    x = x - lowpass(x, 900)
    return (x * np.exp(-tt*22) * 0.11 + np.sin(2*np.pi*190*tt)*np.exp(-tt*30)*0.08)
KD = kick()
for j in range(int((5.0-OFF)/BEAT), int((53.3-OFF)/BEAT)):
    st = OFF + j*BEAT
    half = 24.4 < st < 31.0
    beat = j % 4
    if beat in (0, 2) and not (half and beat == 2):
        add(KD * (0.6 if half else 1.0), st)
    if beat in (1, 3) and st > 11.3 and not half:
        add(snap(), st, 0.9, 1.0)
    if st > 11.3 and not half:
        add(hat(), st + BEAT/2, 0.7, 1.0)
        add(hat(70) * 0.6, st, 1.0, 0.7)

# ---------- whooshes on scene changes, chimes on a hazri ----------
def whoosh(dur=0.9):
    n = int(dur*SR); tt = np.arange(n)/SR; x = rng.standard_normal(n)
    e = np.sin(np.pi * tt/dur) ** 2
    lo = lowpass(x, 400); hi = x - lowpass(x, 3000)
    mix = (lo * (1 - tt/dur) + hi * (tt/dur) * 0.5)
    return mix * e * 0.09
for ts in [2.75, 11.2, 18.4, 24.3, 30.8, 36.5, 41.8, 48.1, 53.1]:
    w = whoosh(); add(w, ts - 0.3, 1.0, 0.6); add(w[::-1] * 0.4, ts - 0.3, 0.6, 1.0)
def chime(f0, amp=0.06):
    n = int(3*SR); tt = np.arange(n)/SR; s = np.zeros(n)
    for i, m in enumerate([0, 7, 12, 16]):
        f = f0 * 2**(m/12); d = int(i*0.07*SR)
        s[d:] += (np.sin(2*np.pi*f*tt[:n-d]) + 0.3*np.sin(2*np.pi*f*3*tt[:n-d])*np.exp(-tt[:n-d]*5)) * np.exp(-tt[:n-d]*1.8)
    return s * amp
for ts in [7.62, 9.55, 40.05]: add(chime(hz(86)), ts)
add(chime(hz(81), 0.05), 50.55)
def tick():
    n = int(0.06*SR); tt = np.arange(n)/SR
    return np.sin(2*np.pi*1900*tt) * np.exp(-tt*120) * 0.05
for ts in [4.55, 12.85, 20.5, 21.35, 28.3, 32.3, 39.15, 42.85, 50.45]: add(tick(), ts)
# the ending impact
n = int(4*SR); tt = np.arange(n)/SR
boom = np.sin(2*np.pi*np.cumsum(40 + 30*np.exp(-tt*6))/SR) * np.exp(-tt*1.6) * 0.35
add(boom, 53.45)

# ---------- reverb ----------
def ir(seed, dur=2.8):
    r = np.random.default_rng(seed); n = int(dur*SR); tt = np.arange(n)/SR
    h = r.standard_normal(n) * np.exp(-tt * 3.0); h[:int(0.012*SR)] = 0
    return h / np.sqrt(np.sum(h**2))
def conv(x, h):
    m = len(x) + len(h) - 1; F = 1 << int(np.ceil(np.log2(m)))
    return np.fft.irfft(np.fft.rfft(x, F) * np.fft.rfft(h, F), F)[:len(x)]
wetL = conv(L, ir(1)); wetR = conv(R, ir(2))
L2 = L * 0.82 + wetL * 0.33; R2 = R * 0.82 + wetR * 0.33

# master: fade in/out, gentle glue, normalise
fade = automation([(0, 0), (0.4, 1), (58.2, 1), (60, 0)])
out = np.stack([L2, R2], 1) * fade[:, None]
out = np.tanh(out * 1.4) / np.tanh(1.4)
out *= 0.89 / np.max(np.abs(out))
pcm = (out * 32767).astype('<i2')
with wave.open(sys.argv[1], 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
print('wrote', sys.argv[1], pcm.shape)
