"""Synthesizes LOGOS IN ME audio assets (pure stdlib, deterministic).

Usage: python3 tool/generate_audio.py   (from the mobile app root)
Outputs into assets/audio/.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def write(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = 0.85 / peak
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * gain * 32767)) for s in samples))
    print("wrote", path)


def bell(freqs, seconds, decay):
    n = int(RATE * seconds)
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(1.0, t / 0.01)
        s = 0.0
        for f, a, d in freqs:
            s += a * math.sin(2 * math.pi * f * t) * math.exp(-t * decay * d)
        out.append(s * attack)
    return out


def pad(chord, seconds, lfo_hz, noise_amt, seed):
    """Seamless loop: integer Hz partials + LFO with whole cycles in `seconds`."""
    rnd = random.Random(seed)
    n = int(RATE * seconds)
    out = []
    lp = 0.0
    for i in range(n):
        t = i / RATE
        lfo = 0.6 + 0.4 * math.sin(2 * math.pi * lfo_hz * t)
        s = 0.0
        for k, f in enumerate(chord):
            phase_lfo = 0.5 + 0.5 * math.sin(2 * math.pi * lfo_hz * t + k * 1.3)
            s += (0.5 + 0.5 * phase_lfo) * math.sin(2 * math.pi * f * t)
        lp += 0.02 * (rnd.uniform(-1, 1) - lp)  # soft brown-ish air
        out.append(s * lfo / len(chord) + lp * noise_amt)
    # crossfade tail into head so noise loops cleanly
    fade = int(RATE * 0.5)
    for i in range(fade):
        a = i / fade
        out[i] = out[i] * a + out[n - fade + i] * (1 - a)
    return out[: n - fade]


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    # Amen chime: warm bell (C5 with inharmonic partials) + fifth
    write("amen_chime.wav", [a + 0.6 * b for a, b in zip(
        bell([(523, 1.0, 1.0), (1046, 0.4, 1.6), (1414, 0.2, 2.4), (2093, 0.1, 3.0)], 2.8, 1.6),
        [0.0] * int(RATE * 0.18) + bell([(784, 1.0, 1.0), (1568, 0.3, 1.8)], 2.62, 1.8),
    )])
    # Sanctuary chime: single soft bell
    write("sanctuary_chime.wav", bell([(432, 1.0, 1.0), (864, 0.3, 1.5), (1296, 0.12, 2.2)], 3.0, 1.2))
    # Ambient pads (432 Hz family), 20.5 s -> 20 s seamless loop
    write("ambient_sanctuary_dawn.wav", pad([108, 162, 216, 270, 324], 20.5, 0.1, 0.35, 1))
    write("ambient_sanctuary_dune.wav", pad([96, 144, 192, 240, 288], 20.5, 0.1, 0.5, 2))

    # Night Breeze: 10s seamless ambient wind loop
    rnd = random.Random(42)
    n_breeze = int(RATE * 10.5)
    breeze_samples = []
    lp1, lp2 = 0.0, 0.0
    for i in range(n_breeze):
        t = i / RATE
        swell = 0.5 + 0.3 * math.sin(2 * math.pi * 0.1 * t) + 0.2 * math.sin(2 * math.pi * 0.25 * t + 1.2)
        white = rnd.uniform(-1, 1)
        lp1 += 0.035 * (white - lp1)
        lp2 += 0.035 * (lp1 - lp2)
        drone = 0.15 * math.sin(2 * math.pi * 108.0 * t) * (0.8 + 0.2 * math.sin(2 * math.pi * 0.05 * t))
        breeze_samples.append((lp2 * swell * 0.85) + drone)
    fade = int(RATE * 0.5)
    for i in range(fade):
        a = i / fade
        breeze_samples[i] = breeze_samples[i] * a + breeze_samples[n_breeze - fade + i] * (1 - a)
    write("ambient_night_breeze.wav", breeze_samples[: int(RATE * 10.0)])

    # Sanctuary Bells: 10s distant bronze cathedral bells loop
    n_bells = int(RATE * 10.0)
    bells_samples = [0.0] * n_bells

    def add_bell(strike_time, freqs, decay, base_vol):
        start_idx = int(strike_time * RATE)
        for i in range(start_idx, n_bells):
            t = (i - start_idx) / RATE
            attack = min(1.0, t / 0.008)
            s = 0.0
            for f, amp, d in freqs:
                s += amp * math.sin(2 * math.pi * f * t) * math.exp(-t * decay * d)
            bells_samples[i] += s * attack * base_vol

    add_bell(0.4, [(432.0, 1.0, 1.0), (864.0, 0.45, 1.4), (1296.0, 0.2, 2.0), (1728.0, 0.1, 2.8)], 0.9, 0.8)
    add_bell(5.2, [(648.0, 0.9, 1.1), (1296.0, 0.4, 1.5), (1944.0, 0.18, 2.2)], 1.0, 0.65)
    reverb_delay = int(RATE * 0.08)
    for i in range(reverb_delay, n_bells):
        bells_samples[i] += bells_samples[i - reverb_delay] * 0.22
    for i in range(fade):
        a = i / fade
        bells_samples[i] = bells_samples[i] * a + bells_samples[n_bells - fade + i] * (1 - a)
    write("ambient_sanctuary_bells.wav", bells_samples)

