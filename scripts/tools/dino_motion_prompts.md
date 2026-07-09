# Dino MOTION kit — Seedance 2.0 image-to-video prompts

Companion to `dino_art_prompts.md` / `ralph_art_prompts.md`. Those kits made the
still heroes; this kit turns each hero into **real animation frames** via
image-to-video (Seedance 2.0 or similar: Kling, Veo, Runway). Today every
in-match frame is a bake-time transform of ONE still — video-gen gives us true
walk cycles, weight shifts, and brand-new states (hit reactions, KO tumbles,
dodges) that part-rotation can't fake.

The bake side is automated: `scripts/tools/gen_dino_motion.py` eats the clips,
keys the background, aligns the feet baseline, and prints the `dino.gd`
ANIM_LAYOUTS block. Your only job is generating clips per this kit.

## How to use this kit (READ FIRST)

1. **PILOT FIRST: generate only RALPH `walk` + `attack`** and stop. I run them
   through the bake and we check them in-game. Only after the pilot reads well
   do we batch the other clips/dinos — don't burn credits on 48 clips before
   the pipeline is proven.
2. In Seedance 2.0 **image-to-video**, upload the dino's hero PNG
   (`assets/concept/<dino>/<dino>_hero.png`) as the reference/first-frame
   image. If the tool accepts multiple reference images, add the same hero
   again (or a skin variant of the SAME pose) — consistency beats variety here.
3. Prompt = `[FRAMING BLOCK]` + the species' one-line look reminder + one
   `[MOTION]` block below. **4 seconds is enough** for every clip — shortest =
   cheapest, and we only extract ~8-12 frames anyway.
4. Save clips as `assets/concept/<dino>/motion/<anim>.mp4`
   (e.g. `assets/concept/ralph/motion/walk.mp4`). The filename IS the animation
   name — use exactly: `idle`, `walk`, `attack`, `heavy`, `hit`, `ko`, `dodge`,
   `win`.
5. Generation quality bar: the character must **stay fully in frame** the whole
   clip, the background must **stay flat** (no scenery fading in), and the
   character must stay **on-model** (right colors, signature details). If any
   of those break, regenerate — a drifting clip bakes into a flickering sprite.

## FRAMING BLOCK — prepend to EVERY motion prompt

```
Locked-off static camera, absolutely no camera movement, no zoom, no cut.
The character performs the motion IN PLACE, staying centered in frame, full
body always fully visible with margin on all sides, feet contact level held
constant. Flat solid light grey-blue studio background that never changes,
even soft studio lighting, soft contact shadow under the feet. The character
keeps facing 3/4 front-right the entire clip, exactly as in the reference
image. Same painterly-chibi mobile-game art style as the reference image,
crisp silhouette, no motion blur. No text, no watermark, no extra characters.
```

## LOOK REMINDERS — one line per species (insert after the framing block)

- **ralph**: `A cute chibi green baby T-rex-like dino (Ralph), oversized head, tiny arms, stubby tail.`
- **trex**: `A cute chibi scarlet-red baby T-rex with a cream belly stripe and a small scar on the right side of the snout.`
- **raptor**: `A cute chibi crimson baby velociraptor with a red feather tuft down the spine and a white feather behind the left ear.`
- **trike**: `A cute chibi mustard-yellow baby triceratops with a sage-green frill and a chipped right brow horn.`
- **pterry**: `A cute chibi burnt-orange baby pterodactyl with ruby-red wings and a white bandage on the right wing elbow.`
- **bronto**: `A cute chibi blue-violet baby brontosaurus with white cloud spots, a long curved neck, and a white flower in its mouth.`
- **anky**: `A cute chibi sandy-tan baby ankylosaurus with mossy-green armor plates and a big rounded tail club.`

## MOTION blocks (append ONE per clip)

**walk** — the big fluidity win (replaces a 4-frame fake cycle)
```
[MOTION] The character does a bouncy energetic cartoon WALK CYCLE in place,
like on a treadmill: legs stepping with clear up-down body bounce, weight
shifting side to side, tail swaying as counterbalance, head bobbing slightly.
Steady constant rhythm, about two full step cycles per second, perfectly
repeating loop.
```

**idle**
```
[MOTION] The character stands in place in a relaxed IDLE: gentle breathing
with the chest and body softly rising and falling, tail swishing slowly, an
occasional small blink. Subtle, calm, perfectly loopable — the feet never move.
```

**attack** (match the species' signature: chomp for bipeds, horn-jab for trike,
wing-buffet for pterry, neck-whip for bronto, tail-swing for anky)
```
[MOTION] The character performs ONE quick cartoon ATTACK to its front-right:
a brief anticipation wind-up leaning back, then a fast snappy strike (a lunging
bite / headbutt / tail swing appropriate to its body), then it settles back to
the starting stance. One single attack, big readable silhouette change, snappy
squash-and-stretch cartoon timing.
```

**heavy**
```
[MOTION] The character performs ONE slow HEAVY ATTACK to its front-right: a
big exaggerated wind-up, crouching and coiling with the tail rising, a brief
held pause at full tension, then an explosive powerful strike with full body
weight behind it, then it settles back to the starting stance. One single
attack, maximum anticipation, cartoon power.
```

**hit** — new state, currently faked with a tint flash
```
[MOTION] The character gets HIT from the front: a sharp cartoon flinch — head
snapping back, body compressing into a squash, eyes squeezed shut, briefly
staggering one step back — then it recovers back to its stance. Quick and
readable, big exaggerated reaction, no attacker visible in frame.
```

**ko** — new state, feeds ring-out / KO moments
```
[MOTION] The character gets KNOCKED OUT in cartoon style: it reels dizzily,
wobbles with spiral eyes, then tips over and flops onto its back with feet up,
completely dazed. Exaggerated comedic knockout, no attacker visible in frame.
```

**dodge** — new state
```
[MOTION] The character does ONE quick cartoon DODGE: a sudden crouch and
snappy little hop-roll to the side with the body tucking into a ball, then it
pops back up to its stance. One single fast evasive move, springy cartoon
timing.
```

**win** — victory pose for round/match end screens
```
[MOTION] The character celebrates a VICTORY: a happy little jump with a
mid-air fist-pump / triumphant roar to the sky, tail wagging, landing in a
proud chest-out heroic pose, beaming. Joyful, bouncy, cartoon celebration.
```

## Bake workflow (Claude runs this part)

```
python3 scripts/tools/gen_dino_motion.py <dino>            # bake every clip in motion/
python3 scripts/tools/gen_dino_motion.py <dino> --fps 16   # denser sampling
```

The tool prints the exact ANIM_LAYOUTS block for `dino.gd` and writes a
contact-sheet preview to `/tmp/ralph/<dino>_motion_preview.png` for review
before anything is wired in.

## Notes / gotchas

- **Walking in place is non-negotiable** — if the character travels, it leaves
  frame or the model starts panning the camera, and frame alignment dies.
  If a generation walks forward anyway, retry with "treadmill" emphasized.
- Video models love to animate the BACKGROUND (drifting clouds, sudden
  scenery). The flat background line fights that; still, check before saving.
- **One action per clip.** Asking for walk-then-attack gives you neither.
- Signature asymmetries (scar side, feather side, bandage side) drift in video
  even more than in stills — the look-reminder lines re-state them; regenerate
  if a detail migrates or vanishes.
- Duration: pick the minimum (4s). Resolution: whatever the tool defaults to —
  frames get downscaled to ~132px character height anyway, so don't pay for 4K.
- The game only uses ~6-12 frames per animation; a slightly imperfect clip is
  fine if it contains one clean cycle we can sample from.
