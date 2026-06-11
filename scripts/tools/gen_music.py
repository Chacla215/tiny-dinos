"""Generate looping chiptune music as 16-bit mono WAVs, pure stdlib (no deps) —
the music sibling of gen_sfx.py. Two tracks:

    assets/music/title_theme.wav   - cheerful menu loop (title/select/creator)
    assets/music/battle_theme.wav  - driving in-match loop

The Audio autoload streams these; replace with real tracks later by dropping
files at the same paths. Loops are sample-exact (rendered to the bar), but the
WAV importer must be set to loop (edit/loop_mode=1 in the .import). Run from
repo root:
    python3 scripts/tools/gen_music.py

Style: 4-channel tracker chiptune — square lead (vibrato + echo), arpeggio
chords, triangle octave-bounce bass, kick/snare/hat drums.
"""
import wave, struct, math, random, os

SR = 22050
OUT = "assets/music"
random.seed(99)  # deterministic regen


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    peak = max(0.0001, max(abs(s) for s in samples))
    gain = 0.88 / peak
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
    print("wrote", path, "(%.1fs)" % (len(samples) / SR))


# --- note language -----------------------------------------------------------

NOTE_OFFSETS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi(name):
    """'C5' / 'G#4' / 'Bb3' -> midi number."""
    letter = name[0]
    rest = name[1:]
    acc = 0
    if rest and rest[0] in "#b":
        acc = 1 if rest[0] == "#" else -1
        rest = rest[1:]
    return (int(rest) + 1) * 12 + NOTE_OFFSETS[letter] + acc


def freq(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def parse(tokens):
    """'E5:2 r:2 ...' -> [(midi_or_None, steps), ...] (steps are 16ths)."""
    out = []
    for tok in tokens.split():
        name, _, steps = tok.partition(":")
        steps = int(steps) if steps else 2
        out.append((None if name == "r" else midi(name), steps))
    return out


# --- channel renderers (each returns a full-length float list) ---------------

def render_notes(events, total, spb, wave_fn, gain, vibrato=False):
    out = [0.0] * total
    step = 0
    for m, steps in events:
        a = int(round(step * spb))
        b = int(round((step + steps) * spb))
        step += steps
        if m is None:
            continue
        f = freq(m)
        phase = 0.0
        length = b - a
        rel = max(1, int(0.012 * SR))
        for i in range(length):
            t = i / SR
            fv = f
            if vibrato and t > 0.09:
                fv = f * (1.0 + 0.005 * math.sin(2 * math.pi * 5.5 * t))
            phase += fv / SR
            env = min(1.0, i / (0.004 * SR))            # click-free attack
            if i > length - rel:
                env *= (length - i) / rel               # click-free release
            env *= 1.0 - 0.25 * (i / length)            # gentle decay
            out[a + i] += wave_fn(phase) * env * gain
    return out


def square(phase):
    return 0.7 if (phase % 1.0) < 0.5 else -0.7


def square_thin(phase):
    return 0.6 if (phase % 1.0) < 0.25 else -0.6        # 25% duty - brighter


def triangle(phase):
    p = phase % 1.0
    return 4.0 * abs(p - 0.5) - 1.0


def render_drums(bars, total, spb):
    out = [0.0] * total
    for bar_i, pattern in enumerate(bars):
        assert len(pattern) == 16, "drum bar must be 16 steps: %r" % pattern
        for s, ch in enumerate(pattern):
            if ch == ".":
                continue
            at = int(round((bar_i * 16 + s) * spb))
            if ch == "K":
                _kick(out, at)
            elif ch == "S":
                _snare(out, at)
            elif ch == "h":
                _hat(out, at)
    return out


def _kick(out, at):
    phase = 0.0
    for i in range(min(int(0.10 * SR), len(out) - at)):
        t = i / (0.10 * SR)
        f = 130.0 * (45.0 / 130.0) ** t
        phase += f / SR
        out[at + i] += math.sin(2 * math.pi * phase) * (1.0 - t) ** 1.6


def _snare(out, at):
    prev = 0.0
    for i in range(min(int(0.08 * SR), len(out) - at)):
        t = i / (0.08 * SR)
        ns = random.uniform(-1, 1)
        hp = ns - prev * 0.6                            # crude high-pass
        prev = ns
        tone = math.sin(2 * math.pi * 185.0 * i / SR) * 0.3
        out[at + i] += (hp * 0.7 + tone) * (1.0 - t) ** 2.0 * 0.8


def _hat(out, at):
    prev = 0.0
    for i in range(min(int(0.03 * SR), len(out) - at)):
        t = i / (0.03 * SR)
        ns = random.uniform(-1, 1)
        hp = ns - prev * 0.9
        prev = ns
        out[at + i] += hp * (1.0 - t) ** 1.5 * 0.30


def render_arp(chords, total, spb, pattern, gain, wave_fn=square_thin):
    """16th-note arpeggio over chord tones; pattern indexes [root,3rd,5th,oct]."""
    events = []
    for root, quality in chords:
        third = 3 if quality == "min" else 4
        tones = [root + 12, root + 12 + third, root + 12 + 7, root + 24]
        for idx in pattern:
            events.append((tones[idx], 16 // len(pattern)))
    return render_notes(events, total, spb, wave_fn, gain)


def render_bass(chords, total, spb, offsets, gain):
    """Eighth-note bass line; offsets are semitones from each bar's root."""
    events = []
    for root, _quality in chords:
        for off in offsets:
            events.append((None if off is None else root + off, 2))
    return render_notes(events, total, spb, triangle, gain)


def add_echo(buf, delay_steps, spb, amount):
    d = int(round(delay_steps * spb))
    for i in range(d, len(buf)):
        buf[i] += buf[i - d] * amount
    return buf


def mix(total, *channels):
    out = [0.0] * total
    for buf in channels:
        for i in range(total):
            out[i] += buf[i]
    # soft saturation + one-pole low-pass to take the chip edge off
    prev = 0.0
    for i in range(total):
        v = math.tanh(out[i] * 1.1)
        prev = prev * 0.25 + v * 0.75
        out[i] = prev
    return out


def render_song(bpm, chords, melody, drums, arp_pattern, bass_offsets,
                arp_gain, lead_gain=0.30, bass_gain=0.26, drum_gain=0.95):
    bars = len(chords)
    spb = SR * (60.0 / bpm) / 4.0                       # samples per 16th
    total = int(round(bars * 16 * spb))
    events = parse(melody)
    assert sum(s for _, s in events) == bars * 16, \
        "melody is %d steps, want %d" % (sum(s for _, s in events), bars * 16)
    assert len(drums) == bars
    lead = render_notes(events, total, spb, square, lead_gain, vibrato=True)
    lead = add_echo(lead, 3, spb, 0.22)                 # dotted-8th echo
    arp = render_arp(chords, total, spb, arp_pattern, arp_gain)
    bass = render_bass(chords, total, spb, bass_offsets, bass_gain)
    drum = render_drums(drums, total, spb)
    drum = [d * drum_gain for d in drum]
    return mix(total, lead, arp, bass, drum)


# --- TITLE THEME: sunny island bounce, C major, I-V-vi-IV ---------------------

C, G, Am, F = (midi("C3"), "maj"), (midi("G2"), "maj"), \
              (midi("A2"), "min"), (midi("F2"), "maj")

TITLE_CHORDS = [C, G, Am, F] * 4                       # 16 bars

TITLE_MELODY_A = " ".join([
    "E5 G5 C6 G5 E5 G5 E5 D5",                          # C
    "D5 G5 B5 G5 D5 G5 B4 D5",                          # G
    "C5 E5 A5 E5 C5 E5 C5 B4",                          # Am
    "A4 C5 F5 C5 A5:4 G5 F5",                           # F
    "G5 E5 C5 E5 G5 C6:4 G5",                           # C
    "A5 G5 D5 G5 B5:4 G5 r",                            # G
    "C6 B5 A5 E5 C5:4 E5 G5",                           # Am
    "F5 G5 A5 B5 C6:4 r:4",                             # F (rising turnaround)
])
TITLE_MELODY_B = " ".join([
    "E5 G5 C6 G5 E5 G5 E5 D5",                          # C
    "D5 G5 B5 G5 D5 G5 B4 D5",                          # G
    "C5 E5 A5 E5 C5 E5 C5 B4",                          # Am
    "A4 C5 F5 C5 A5:4 G5 F5",                           # F
    "C6:4 G5 E5 G5:4 E5 C5",                            # C (answer phrase)
    "B4 D5 G5:4 A5 B5 D5:4",                            # G
    "A5:4 E5 C5 E5:4 D5 C5",                            # Am
    "D5 E5 F5 G5 C6:8",                                 # F (long resolve)
])

TITLE_DRUMS_BAR = "K...h.h.S...h.h."
TITLE_DRUMS_FILL = "K...h.h.S..SS.h."


# --- BATTLE THEME: driving Am Andalusian run (Am-G-F-E), 152 BPM --------------

Bm_A, Bm_G, Bm_F, Bm_E = (midi("A2"), "min"), (midi("G2"), "maj"), \
                          (midi("F2"), "maj"), (midi("E2"), "maj")

BATTLE_CHORDS = [Bm_A, Bm_G, Bm_F, Bm_E] * 4           # 16 bars

BATTLE_RIFF = " ".join([
    "A4 r E5 r A5 r G5 E5",                             # Am (stab riff)
    "G4 r D5 r G5 r F5 D5",                             # G
    "F4 r C5 r F5 r E5 C5",                             # F
    "E5 r B4 r G#5 r B5 r",                             # E (harmonic sting)
    "A5 G5 E5 C5 D5 E5 C5 A4",                          # Am (run answer)
    "B4 D5 G5 B5 A5 G5 D5 B4",                          # G
    "C5 F5 A5 C6 A5 F5 C5 A4",                          # F
    "G#4 B4 E5 G#5 B5:4 r E5",                          # E (climb into loop)
])
BATTLE_MELODY = BATTLE_RIFF + " " + BATTLE_RIFF

BATTLE_DRUMS_BAR = "K.h.S.h.K.h.S.hh"
BATTLE_DRUMS_FILL = "K.h.S.h.K.hhSShh"


def main():
    title = render_song(
        bpm=126,
        chords=TITLE_CHORDS,
        melody=TITLE_MELODY_A + " " + TITLE_MELODY_B,
        drums=[TITLE_DRUMS_BAR] * 7 + [TITLE_DRUMS_FILL]
              + [TITLE_DRUMS_BAR] * 7 + [TITLE_DRUMS_FILL],
        arp_pattern=[0, 2, 3, 2] * 2,                   # 8th-note roll
        bass_offsets=[0, 12, 0, 12, 0, 12, 0, 12],      # octave bounce
        arp_gain=0.085,
    )
    write_wav("title_theme", title)

    battle = render_song(
        bpm=152,
        chords=BATTLE_CHORDS,
        melody=BATTLE_MELODY,
        drums=([BATTLE_DRUMS_BAR] * 3 + [BATTLE_DRUMS_FILL]) * 4,
        arp_pattern=[0, 2, 3, 2] * 4,                   # 16th-note drive
        bass_offsets=[0, 0, 12, 0, 0, 0, 12, 0],        # pumping 8ths
        arp_gain=0.07,
        lead_gain=0.32,
    )
    write_wav("battle_theme", battle)


if __name__ == "__main__":
    main()
