"""Generate placeholder combat SFX as small 16-bit mono WAVs, pure stdlib (no
deps). main.gd already plays res://assets/sfx/<name>.wav on each combat event,
so running this turns the game's audio on. Replace these with real SFX later
(Freesound etc.) by dropping files at the same paths. Run from repo root:
    python3 scripts/tools/gen_sfx.py

Style: short, punchy, slightly chiptune-y to match the cute brawler tone.
"""
import wave, struct, math, random, os

SR = 22050
OUT = "assets/sfx"
random.seed(1234)  # deterministic regen


def write_wav(name, samples, gain=1.0):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    frames = bytearray()
    for s in samples:
        v = max(-1.0, min(1.0, s * gain))
        frames += struct.pack("<h", int(v * 32767))
    w = wave.open(path, "w")
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(bytes(frames))
    w.close()
    print("wrote", path, "(%.2fs)" % (len(samples) / SR))


def sine(f, i):
    return math.sin(2.0 * math.pi * f * i / SR)


def n(seconds):
    return int(seconds * SR)


# --- whoosh: smoothed noise, downward feel (attack swing) ---
def gen_swing():
    out = []
    prev = 0.0
    total = n(0.11)
    for i in range(total):
        t = i / total
        ns = random.uniform(-1, 1)
        prev = prev * 0.6 + ns * 0.4          # low-pass -> airy
        out.append(prev * math.sin(math.pi * t) * (1.0 - 0.5 * t))
    return out


# --- whoosh up (dodge): brighter as it rises ---
def gen_dodge():
    out = []
    prev = 0.0
    total = n(0.13)
    for i in range(total):
        t = i / total
        ns = random.uniform(-1, 1)
        k = 0.3 + 0.55 * t                    # let more highs through over time
        prev = prev * (1.0 - k) + ns * k
        out.append(prev * math.sin(math.pi * t) * 0.9)
    return out


# --- heavy bite/impact: low tone dropping in pitch + crunch transient ---
def gen_hit_chomp():
    out = []
    total = n(0.20)
    for i in range(total):
        t = i / total
        f = 160 * (1 - 0.6 * t)
        tone = sine(f, i) * 0.7 + sine(f * 0.5, i) * 0.4   # add a sub for weight
        crunch = random.uniform(-1, 1) if t < 0.12 else 0.0
        out.append((tone + crunch * 0.5) * math.exp(-5.0 * t))
    return out


# --- light slash/hit: sharper, higher, quick ---
def gen_hit_claw():
    out = []
    total = n(0.10)
    for i in range(total):
        t = i / total
        f = 430 * (1 - 0.4 * t)
        tone = sine(f, i) * 0.5
        crunch = random.uniform(-1, 1) if t < 0.05 else 0.0
        out.append((tone + crunch * 0.6) * math.exp(-12.0 * t))
    return out


# --- block: short metallic two-tone clank ---
def gen_block():
    out = []
    total = n(0.13)
    for i in range(total):
        t = i / total
        s = sine(640, i) * 0.5 + sine(965, i) * 0.4
        tick = random.uniform(-1, 1) if t < 0.02 else 0.0
        out.append((s + tick * 0.5) * math.exp(-16.0 * t))
    return out


# --- guard break: harsh descending shatter + low boom ---
def gen_guard_break():
    out = []
    prev = 0.0
    total = n(0.32)
    for i in range(total):
        t = i / total
        ns = random.uniform(-1, 1)
        prev = prev * 0.5 + ns * 0.5
        boom = sine(120 * (1 - 0.5 * t), i)
        out.append((prev * 0.6 + boom * 0.5) * math.exp(-6.0 * t))
    return out


# --- KO: big low boom + descending zap ---
def gen_ko():
    out = []
    total = n(0.45)
    for i in range(total):
        t = i / total
        boom = sine(90 * (1 - 0.5 * t), i)
        zap = sine(700 * (1 - 0.8 * t) + 80, i)
        out.append((boom * 0.75 + zap * 0.3) * math.exp(-5.0 * t))
    return out


# --- win: cheerful ascending chiptune arpeggio ---
def gen_win():
    out = []
    notes = [523, 659, 784, 1047]   # C5 E5 G5 C6
    dur = n(0.14)
    for f in notes:
        for i in range(dur):
            t = i / dur
            sq = 1.0 if sine(f, i) >= 0 else -1.0   # square wave
            out.append((sq * 0.4 + sine(f, i) * 0.2) * math.exp(-3.0 * t))
    return out


write_wav("swing", gen_swing(), gain=0.55)
write_wav("dodge", gen_dodge(), gain=0.6)
write_wav("hit_chomp", gen_hit_chomp(), gain=0.95)
write_wav("hit_claw", gen_hit_claw(), gain=0.8)
write_wav("block", gen_block(), gain=0.7)
write_wav("guard_break", gen_guard_break(), gain=0.85)
write_wav("ko", gen_ko(), gain=1.0)
write_wav("win", gen_win(), gain=0.7)
print("done")
