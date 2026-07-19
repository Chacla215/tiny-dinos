# NEXT TWO CLIPS — fire on top-up

**Claude, 2026-07-19.** Two generations, in this order: **Ep1's ending
(re-shoot)**, then **Ep2 "HIGH WATER MARK"**. Written after frame-inspecting
the shipped `ep1_rev.mp4`, which revealed three failures the old prompts
caused. Both prompts below are rewritten against those failures.

> **SAME-DAY UPDATE — CLIP 1 IS CANCELLED.** The failures were real but the
> file was stale: `ep1_rev.mp4` (02:08) predates the restyled tide stills
> (02:15), and `build_ep1_final.sh` had never been rewired to them. Fixed for
> zero credits: `tide_styled_leaf.png` composited (leaf lifted from the old
> still onto the restyled frame), build pointed at `tide_styled_a.png` +
> `tide_styled_leaf.png`, rebuilt. **`ep1_final.mp4` now passes all four
> locked plants** (look = last beat, leaf drifts in, style-matched, on-model)
> at −13.7 LUFS. Ep1 is READY pending Charlie's eyeball.
>
> The clip-1 prompt below is kept as the paid fallback if Charlie watches the
> still-based ending in motion and wants a fully animated look instead.
> **Budget drops to ~110–160: Ep2 only, plus re-roll headroom.**
>
> Extra lesson for the pile: the world-change refusal (dry→flooded ignored by
> image-to-video) means clip 1, if ever fired, should ALSO use a composite
> start frame with the water already high — not the 8.15 dry frame + rising
> water as written below.

Lives at repo root with the other kits (`wip/` is gitignored). Companion to
`SAGA_RISING_TIDE.md` (Ep1 brief, identity locks) and
`SAGA_OUTLINE.md` (the arc, Ep2's original kit — **superseded by this file**).

---

## What the shipped Ep1 ending actually did wrong

Verified by extracting frames from `assets/concept/shorts/wip/ep1/ep1_rev.mp4`, not by watching it.

| # | failure | cause | fix encoded below |
|---|---|---|---|
| 1 | **Ralph and Max change design in the final clip** — Ralph loses his tall teal back spikes and cream belly, goes smaller and darker, gains a tan head patch; Max loses his white elbow tufts and stripes | TIDE-2 used an abbreviated identity string instead of the full lock, and chained from a weak start frame | full lock verbatim, every clip, plus a mandatory `start_image` |
| 2 | **The look between them is not the last frame** — both face camera | the look was the *fourth* action in a four-action prompt; the model dropped the tail | **one action per clip**, and the look IS the clip |
| 3 | **The leaf never floats away** | asked of the generator when it was always meant to be a post composite | stays in post, free — do not put it in the prompt |
| 4 | **The tide reads as a normal beach** — a gentle lick at the shoreline, not "the water is at the tree line" | "shrinking patch of dry sand" is an abstraction; the model rendered an ordinary shore | concrete, measurable staging: *water covering the footprints, palm trunks standing in water* |

**The generalized lesson, worth carrying to every future episode:**
Seedance renders prompts front-to-back and runs out of clip. Put the
non-negotiable beat FIRST. Describe geography in things that can be measured
against (footprints, tree trunks, a rock), never in adjectives ("shrinking",
"half-submerged").

---

## Settings (both clips — the proven recipe)

**12s, 9:16, 720p std, `generate_audio:false`, DECLINE the recommended
preset** (pass its id as `declined_preset_id` and resubmit).

`image_references` on both clips:
- `assets/concept/ralph/ralph_hero.png`
- `assets/concept/raptor/raptor_hero.png`

**~54 cr per clip.** Two clips = ~108. Budget ~250 for re-roll headroom —
clip 2 is a new location and historically the highest-risk shot in the saga.

### Identity locks — paste VERBATIM, never abbreviate

> **RALPH:** small round chibi green dinosaur, sage-green body, cream belly
> plates, tall teal-blue back spikes and teal tail tip, big amber eyes, pink
> blush cheeks

> **MAX:** small chibi red raptor, brick-red body with darker red stripes,
> cream belly, tiny white feather tufts at the elbows, yellow eyes

Guards, every prompt: *"exactly ONE green dinosaur and exactly ONE red raptor
in the entire scene"* + *"NO cape on either dinosaur"*.

---

## CLIP 1 — Ep1 ending re-shoot ("THE LOOK")

Replaces the current finishing clip. **The look between them is the whole
clip** — it is the first thing described and the only action requested.

**Start frame (mandatory — this is the drift fix):** the last clean frame of
the existing `assets/concept/shorts/wip/ep1/beat5.mp4` at **8.15s**, so the new clip inherits the correct
character designs from footage that already looks right.

```
ffmpeg -ss 8.15 -i assets/concept/shorts/wip/ep1/beat5.mp4 \
  -frames:v 1 assets/concept/shorts/wip/ep1/tide_look_start.png
```

QA that frame before generating: one sword, no cape, Ralph's teal spikes tall
and clearly visible. If the spikes don't read in the start frame, the clip
will not fix them.

**Frame QA result (2026-07-19, done):** `tide_look_start.png` built and
verified — identity is clean (spikes, spot pattern, Max's tufts and stripes
all read; one sword; no cape). Two notes it produced:

- The **tan patch on Ralph's head is sand from the fight**, present in this
  frame too — it is continuity, not drift. Don't re-roll over it.
- The frame is **mid-action** (Ralph atop the rock over Max, dry beach,
  footprints visible), so the prompt below opens with a one-line bridge —
  they step apart — and stages the water as RISING during the clip rather
  than already risen. Frames later than 8.15 were checked and are worse
  (Ralph goes airborne); 8.15 stands.

### Prompt

> Painterly chibi cartoon dinosaurs, storybook picture-book style, vivid
> colors, bright sunny tropical beach. The fight is over: a small round chibi
> green dinosaur — sage-green body, cream belly plates, tall teal-blue back
> spikes and teal tail tip, big amber eyes, pink blush cheeks, a little sand
> dusted on his head — steps down off the rock and lets the sword drop to the
> sand, and the small chibi red raptor — brick-red body with darker red
> stripes, cream belly, tiny white feather tufts at the elbows, yellow eyes —
> hops down beside him. They stand side by side, and slowly turn their heads
> to look directly AT EACH OTHER. They hold that look for a long moment, wary
> and calculating, neither one attacking. That look is the heart of the shot
> and the final frame. While they stand there, calm seawater rises steadily
> up the beach behind them: it slides over the rows of footprints in the sand
> and reaches the trunks of the palm trees, until the two of them are on the
> last small patch of dry sand. The sea is flat and calm, not stormy, which
> makes it worse. Slow gentle push in on the two of them. No fighting. Exactly
> ONE green dinosaur and exactly ONE red raptor in the entire scene. NO cape
> on either dinosaur. All-ages, nobody is in danger, nobody drowns.

### QA before accepting (re-roll if any fail)

- [ ] Ralph's **tall teal back spikes and cream belly** present and matching
      the earlier acts — this is the failure that shipped
- [ ] Max's **white elbow tufts and stripes** present
- [ ] exactly one of each dino, none cloned into the background
- [ ] **they are looking at each other**, and that is the final frame
- [ ] water covers the footprints and reaches the palm trunks
- [ ] no cape, no sword, no leaf in hand

### Post (free, after the clip lands)

1. **Composite the floating leaf** drifting across the water — slow horizontal
   drift plus a gentle bob, cut from `ralph_hero.png` or a beat-1 frame.
   Nobody reaches for it. This is plant #1 and it has never yet shipped.
2. Music **stops** at the turn (a stop, not a fade); water, then wind.
3. No outro card. The episode ends dead on the look.
4. Re-master to −14 LUFS. (Current cut measures −13.7 LUFS / −1.5 dBTP, so
   the existing chain is already correct — just re-run it.)

---

## CLIP 2 — Ep2 "HIGH WATER MARK"

Type B, low tide, den. Speech bubbles, **no narrator** (the Arthur voice is
unavailable — den episodes need none). ~18s final.

### Three changes from the kit in SAGA_OUTLINE.md

The original Ep2 prompt asks for **six** sequential actions: sit soaking → set
the leaf down → reach up → scratch the mark → stare at it → turn sharply to
find Max in the doorway. Ep1 just proved the tail gets dropped — and here the
dropped tail would be **Max in the doorway**, which is the entire hook. So:

1. **Max is in frame from the first second**, standing silhouetted in the
   opening. He is not a reveal the model can fail to reach. Ralph *turning to
   find him already there* is the shot.
2. **Cut to two actions**: scratch the mark, turn to Max. Setting the leaf
   down is now a **post composite** — the leaf sits on the drying rock as a
   static prop, which costs nothing and cannot be dropped.
3. **The ice is NOT in the prompt.** It is composited at the threshold in
   post, guaranteed. Asking a generator for "a piece of melting ice on a
   tropical island" invites a weird object in the saga's single most important
   plant.

### Start frame — build it, don't skip it

The den is a new location, so there's no end frame to chain from, and clip 1
just showed what happens without one.

**DONE (2026-07-19):** `assets/concept/shorts/wip/ep2_den/ep2_start.png` —
built by `make_ep2_start.py` in the same folder. The den interior itself was
generated with nano_banana_2 (1.5 cr, A/B'd two candidates; `den_bg_A.png`
won on drying-rock prominence + readable wall + clean doorway) and is now the
**series' standing set**: every future Type B episode composites onto this
same den, which is both free and the strongest possible location continuity.
Ralph (hero, keyed, warmed) stands by the marked wall; Max (hero, keyed,
darkened to silhouette) stands in the doorway against the sunset sea.

Two facts the frame changed about the plan:
- **Ralph wears the leaf behind his head** (it's baked into the hero art) —
  better than compositing it onto the rock: he carried it home. The
  leaf-on-rock post composite is now optional.
- Ralph is **standing**, so the prompt below says "stands", not "sits".

### Prompt

> Painterly chibi cartoon dinosaur, storybook picture-book style, vivid
> colors. Interior of a small cosy den in the rocks above a tropical beach:
> warm low evening light from a wide opening, sandy floor, a flat drying rock.
> Standing silhouetted in the den opening the whole time is a small chibi red
> raptor — brick-red body with darker red stripes, cream belly, tiny white
> feather tufts at the elbows, yellow eyes — soaking wet, holding nothing, not
> attacking, not coming in, just standing there. Inside the den, a small round
> chibi green dinosaur — sage-green body, cream belly plates, tall teal-blue
> back spikes and teal tail tip, big amber eyes, pink blush cheeks, a small
> green leaf tucked behind his head — stands
> soaking wet with water dripping off him. He reaches up and scratches one
> short horizontal mark high on the stone wall with his claw. On the wall
> below that new mark are several older scratched marks, all of them lower —
> the new mark is clearly the highest. He looks at it. Then he turns his head
> and sees the red raptor in the doorway. Hold on the two of them looking at
> each other across the den. Slow, quiet, melancholy, nobody fights. Exactly
> ONE green dinosaur and exactly ONE red raptor in the entire scene. NO
> weapons. NO cape on either dinosaur. All-ages, warm and sad.

### QA before accepting (re-roll if any fail)

- [ ] exactly one of each dino — **Ep2's original shoot failed by cloning the
      hero into the background; check the whole frame**
- [ ] Ralph's tall teal spikes + cream belly, Max's white elbow tufts
- [ ] the wall marks **visibly stack, newest highest** (this is the series'
      dread-meter — if it doesn't read, the episode has no plot)
- [ ] Max stays in the doorway and never enters or attacks
- [ ] no weapons, no cape

### Post (free)

1. Composite **the leaf** on the drying rock.
2. Composite **the piece of ice** at the threshold where Max set it down,
   slightly melted with a small wet patch under it. Saga's central mystery —
   it must be unmistakable and it must be the last thing the eye lands on.
3. Speech bubbles only, no narrator, no captions. Language rhymes with the
   game's own `MatchConfig.EMOTES` (`HI!`, `HUH?`, `ZZZ`).
4. Ambient water + wind bed. Master to −14 LUFS. ~18s.
5. No outro card.

---

## Fire order

1. Build `tide_look_start.png`, QA it, generate **clip 1**, QA, re-roll if needed
2. Post-finish Ep1 (leaf composite, music stop, re-master) → Ep1 is postable
3. Build Ep2's composite start frame (free), generate **clip 2**, QA
4. Post-finish Ep2 (leaf, ice, bubbles, bed) → Ep2 is postable
5. Update `scripts/social/post_calendar.json` — its `ep1` and `ep2` entries are
   both **stale**: ep1 still reads BLOCKED, and ep2 still points at the
   pre-reboot `wip/ep2_max/ep2_narrated.mp4`, which is not this episode.
