# EP2 — "HIGH WATER MARK" — production plan

**Status: NOTHING GENERATED. Awaiting Charlie's read (rule 7).**
Type B (den / cutscene, low tide). Target ~18-22s. **WORDLESS** — decided
2026-07-20. Story from `SAGA_OUTLINE.md`.

## Why wordless

Arthur cannot generate new lines, ever. The outline's fallback was speech
bubbles, but the script itself says *"neither speaks"* — so silence is the
script, not a compromise. It also buys format variety, which
`SAGA_RISING_TIDE.md` flags as a real demonetization defence (YouTube assesses
"interchangeable" videos at channel level). Ep1 was 60s, narrated, action.
Ep2 is 20s, silent, still. That contrast is an asset.

**No on-screen text at all.** Not even a hook card. Ep1 used a hook card and a
time signpost; Ep2 uses none, which is itself the variety.

## The beats

1. The tide has gone out — the world gave itself back.
2. Ralph, soaked, in his den. He sets the leaf down to dry. *First time we
   have ever seen him put it down.*
3. He scratches a fresh mark at the new high-water line. Older marks sit
   below. **The new one is higher than all of them.**
4. A shadow in the doorway: Max. Also soaked. Holding nothing. Not attacking.
   He does not come in.
5. Max sets something at the threshold: **a piece of ice.** On a tropical
   island. Already melting.
6. Ralph looks at the ice, then at the mark, then at Max.

## Assets already on disk (`wip/ep2_den/`)

| file | what it is | use |
|---|---|---|
| `ep2_start.png` | den interior, Ralph on the drying rock, Max silhouetted in the sunset doorway, tally marks on the left wall | start frame for CLIP 2 |
| `ep2_start2.png` | variant | fallback |
| `ep2_ice_end.png` | den, empty, ice glowing at the threshold | start frame for CLIP 3 |
| `ep2_ice_end2.png` | variant | fallback |

**Lost in the /tmp wipe:** `build_ep2.sh` and the speech-bubble overlays. The
build script gets rebuilt from `build_ep1.sh`, which is far better tested now.
The overlays are no longer needed — the episode is wordless.

## Shot plan

Every clip leads with its un-losable beat, because Seedance renders
front-to-back and drops the tail when it runs out of clip (the rule that cost
us an earlier clip and forced Ep1's mix-up into two generations).

### STILL A — Ralph alone, leaf already down (~1.5cr)
A nano_banana edit of `ep2_start.png`: **remove Max from the doorway** and put
the leaf on the drying rock. This is the bridge recipe — change the world in a
cheap still, then let the video model merely continue it. Becomes CLIP 1's
start frame.

### CLIP 1 — THE MARK (~54cr, use ~7s)
Start: STILL A. Un-losable beat FIRST: the claw meets the stone.
> Painterly chibi cartoon dinosaur, storybook picture-book style, warm low
> evening light. Continue this exact scene inside the small rock den.
> IMMEDIATELY the small sage-green chibi dinosaur with tall teal-blue back
> spikes and cream belly reaches up and scratches ONE short horizontal mark
> high on the stone wall with his claw. Several older scratched marks sit on
> the wall BELOW the new one — the new mark is clearly the HIGHEST. He lowers
> his arm and looks up at it, quiet and uneasy. He holds that look. Slow,
> still, melancholy. He is soaking wet, water dripping off him. A single green
> leaf lies drying on the flat rock beside him. Exactly ONE green dinosaur in
> the entire scene. NO other creatures. NO weapons, NO cape. All-ages.

### CLIP 2 — THE VISITOR (~54cr, use ~7s)
Start: `ep2_start.png` (Max already in the doorway). Un-losable beat FIRST:
the ice being set down.
> Painterly chibi cartoon dinosaurs, storybook picture-book style, warm low
> evening light. Continue this exact scene. IMMEDIATELY the small brick-red
> chibi raptor with darker red stripes and cream belly, standing soaking wet
> in the den's mouth, crouches and carefully SETS DOWN a clear block of ice on
> the sand at the threshold, then straightens up and takes one step back. He
> does NOT come inside. He is not attacking and holds no weapon. The small
> sage-green chibi dinosaur with tall teal-blue back spikes turns his head and
> looks at the ice. Quiet, still, no fighting, nobody speaks. Exactly ONE green
> dinosaur and exactly ONE red raptor. NO weapons, NO cape. All-ages.

### CLIP 3 — THE ICE (~54cr, use ~5s) — the ending
Start: `ep2_ice_end.png`. Un-losable beat FIRST: the melt.
This replaces the old still-with-push-in ending, which violated the no-stills
rule.
> Painterly, storybook picture-book style, warm low evening light. Continue
> this exact scene. IMMEDIATELY the clear block of ice sitting on the sand at
> the den's threshold MELTS — droplets run down its sides and a small pool of
> meltwater spreads across the sand around it, catching the sunset light. The
> ice slowly shrinks. Nothing else moves. No characters in frame. Very slow,
> very quiet, melancholy. Hold on the ice for the entire shot. All-ages.

## Timeline (~20s)

```
0.0   clip1 [the mark]        7.0   he scratches it, looks up at it
7.0   clip2 [the visitor]     7.5   Max sets the ice down, steps back
14.5  clip3 [the ice]         5.5   it melts, alone. END on the ice.
                             ~20.0
```

Ends on the ice with no resolution — the cliffhanger widens from personal
(Ep1) to world-scale, per the outline.

## Sound (free — all CC0 assets already in repo)

Silence is the point, so the mix is ambience-led:
- distant surf, low, throughout (the `anoisesrc` ocean bed from `build_ep1.sh`)
- water dripping in the den
- **the claw scratch** — the loudest thing in the episode, because it is the
  title
- the ice: soft settle, then dripping that grows as it melts
- **music: none, or a single sustained low pad under the last 6s.** Ep1 leaned
  on the battle theme; Ep2 earning its quiet is the contrast.
- master to −14 LUFS, same chain as Ep1

## Cost

| item | cr |
|---|---|
| STILL A (remove Max, leaf down) | ~1.5 |
| CLIP 1 the mark | ~54 |
| CLIP 2 the visitor | ~54 |
| CLIP 3 the ice | ~54 |
| **total** | **~163** |
| balance after (~229 now) | **~66** |

**Economy option (~109cr, leaves ~120):** drop CLIP 3 and end on CLIP 2's
tail. NOT recommended — the ice IS the episode's payload, and putting it in a
clip's tail is exactly the drop zone that loses beats.

## Build

`scripts/social/build_ep2.sh`, rebuilt from `build_ep1.sh`. Inherits every
lesson: per-segment punch-in support, `apad` on any sidechain key, no bare
`loudnorm`, verify-after-write, and a text sweep that should find **nothing**
because the episode has no text at all.

## Publishing gate (learned the expensive way on Ep1)

Finish the cut → upload **unlisted** to YouTube → Charlie watches → only then
post to Instagram and TikTok. Ep1 went to Instagram the same night it was
finished and cost its momentum when it had to be replaced. Instagram
publishing is a commit: no caption-edit API, no video swap, and deleting a
performing post throws away its reach.

---

# 2026-07-23 SESSION — v2 rebuild started: pilot fired, one defect left

**Balance 58.71 → 7.21. Everything below is verified-by-looking, per
`CLIP_PREFLIGHT.md`. wip/ is gitignored — all local files also carry their
Higgsfield gen id, so they are recoverable from the library/CDN.**

## Decisions (Charlie, this session)

1. **Ep2 is NARRATED after all** — Arthur's preset
   (`30fc8796-ceb6-4a66-b3a7-4a145ef7f346`, seed_audio,
   `speech_rate:10, loudness_rate:15` — the Ep1 locked take) works for NEW
   lines. "Why wordless" above is superseded; the visuals stay as planned,
   Arthur carries legibility.
2. Pilot-first at 10s (45cr) instead of 12s (54cr) — Seedance bills 4.5cr/s,
   shorter pilot buys headroom.

## The four Arthur lines (GENERATED, QA'd for duration, cached wip/ep2_den/vo/)

| # | line | gen id | dur |
|---|---|---|---|
| 1 | "The sea always gives the island back. Ralph keeps track." | `a20c003b` | 3.72s |
| 2 | "It has never... EVER... been that high." | `f1627172` | 4.91s |
| 3 | "And Max? Max didn't come to fight." | `05196bd6` | 2.63s |
| 4 | "Ice. On a warm little island... Now where would THAT come from?" | `7724e640` | 6.42s |

Re-fetch: `https://d8j0ntlcm91z4.cloudfront.net/user_3G9RgW1xzgz2TkE3tUOlVwesChE/hf_20260723_<time>_<gen id full>.wav`
(vo1 `175223_a20c003b-0ef6-4478-b4a0-9ec768992667`, vo2 `175300_f1627172-1058-4ab0-b786-e9c2f2eda881`,
vo3 `175301_05196bd6-8a49-409a-b261-b62ba1808ef6`, vo4 `7724e640-803f-4946-ac2c-3420868a6d3d` at `175302`).
17.7s total speech → episode stretches to ~22s. Mix: music/ambience ducks
under VO, same sidechain chain as Ep1.

## STILL A is FINAL: `wip/ep2_den/still_a_v2.png` (gen `ca189650-3df8-4724-95fc-1b929c75cc1d`)

Built from `ep2_start2.png` (NOT ep2_alone — nano_banana refused three times
to ground the floating Ralph in ep2_alone/ep2_start; the start2 variant had
him on the floor already). Verified by face-crop: grounded with contact
shadow (no sprite ellipse), Max removed from doorway, worried face (brows up,
downturned mouth), soaked with drips, NO leaf on his head, leaf ON the drying
rock, and a clean column of FOUR tally marks on the left wall with empty
stone above for the new mark. Intermediates ep2_alone_v2/v3/v4 + still_a_v1
are dead ends — do not reuse.

## PILOT (clip 1 THE MARK v2, gen `7b6877f4-ef82-4766-9c4d-47eed2ffc72d`, 10s) — NOT USABLE, but it validated the pipeline

`wip/ep2_den/clip1_mark_v2.mp4`, QA frames in `qa_v2/`.

**FIXED vs v1 (all three of Charlie's complaints):** Ralph stays grounded the
whole clip (no pasted sprite shadow), the worried performance is real
(welling eyes, trembling mouth — mechanical face direction works), style
on-model, scene keeps moving.

**THE ONE REMAINING DEFECT:** he never scratches the wall. The model read
"scratches a mark HIGH on the stone wall" as sky-high and materialized two
dark strokes floating IN THE SKY above the doorway (~t=4.5s on). The
un-losable beat — the title of the episode — is missing. 0–4s is clean but
the clip cannot carry the story.

**Re-roll prompt fix (apply to the pilot prompt, keep everything else):**
- replace the scratch sentence with: "reaches up on his tiptoes and scratches
  ONE new short horizontal mark into the STONE WALL directly in front of him,
  just ABOVE the topmost of the four existing scratch marks on the wall"
- append: "All scratch marks exist ONLY carved into the stone wall surface.
  Nothing appears in the sky; the sky and sea stay exactly as they are."
- drips read as drool when they come from the mouth — say "water drips off
  the back of his head and his tail", not his chin.
- start frame = still_a_v2.png (gen `ca189650`), ralph_hero ref, 10s, 9:16,
  720p std, generate_audio:false, decline preset `24bae836` (IN THE DARK).

## Top-up budget to finish Ep2 (~180cr safe)

| item | cr |
|---|---|
| clip 1 re-roll (10s) | 45 |
| clip 2 THE VISITOR (10s) | 45 |
| clip 3 THE ICE (8s — only ~5.5s used) | 36 |
| headroom / one re-roll | ~54 |

Clip 2 start frame still needs its own preflight pass before firing (Max is
GRINNING in ep2_start.png and nobody is wet — same fix recipe as STILL A).
Clip 3: remember the NSFW false positive on the bare melting-ice shot —
write defensively, and its start frame should move the ice to the threshold
(ep2_ice_end.png has it out at the waterline).

## Fire order next session (after top-up)

1. Preflight clip 2 + 3 start frames (nano_banana, ~2-3cr, face-crop QA)
2. Re-roll clip 1 with the fixed prompt → QA → only then fire clips 2, 3
3. `build_ep2.sh`: swap in the narrated mix (VO spine + ducked ambience;
   the wordless ambience-led mix design above is superseded)
4. Text sweep (should find nothing), −14 LUFS, unlisted YT → Charlie watches
