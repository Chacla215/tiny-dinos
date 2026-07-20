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
