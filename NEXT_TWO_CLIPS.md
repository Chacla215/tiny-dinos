# NEXT TWO CLIPS — the definitive spec (read this FIRST, trust nothing older)

**Rewritten 2026-07-19 evening after two rule violations in one day.**
Supersedes every earlier version of this file and every Ep1 ending before it.

## THE TWO IRON RULES (Charlie's, violated twice today — never again)

1. **NO SUBTITLES.** No narration captions, ever. Allowed on-screen text:
   the hook card and a time signpost ("12 SECONDS EARLIER"). **Text cards do
   NOT stand in for action** — the BONK! card was rejected: if a beat is
   missing from footage, GENERATE the beat. The caption code has been
   DELETED from `build_ep1_final.sh` — do not resurrect it from any older
   build script. This rule was violated twice by branching old scripts.
2. **NO STILLS IN THE SHIPPED VIDEO.** A still with a zoompan push-in is
   still a still and it reads as the video breaking. Stills are PRODUCTION
   AIDS ONLY: generate the changed world as a still (~1.5cr, iterate cheap),
   then use it as a **video START FRAME** so the model merely continues an
   already-changed world. Every second of a shipped episode is real footage
   or generated video. No exceptions, no "brief" stills, no dissolves
   between stills.

## Current Ep1 state (be precise — do not overclaim)

`wip/ep1/ep1_final.mp4` (40.8s, −13.4 LUFS) is **NOT POSTABLE**. What's right
and wrong with it:

- ✅ acts 0–2 (hook → flashback → leaf → sword → charge): real footage,
  subtitle-free, approved structure
- ✅ THE LANDING (new): leap → white flash + BONK! → tide.mp4 0.8–5.4s
  (Ralph lands on the rock, reclaims the leaf, Max deflates) — the strike
  reads; Charlie's note #1 addressed
- ✅ t1: the real tide footage tail (water creeps over the footprints)
- ❌ the ending after t1 is TWO STILLS with push-ins (shore still + ocean-POV
  still) — **rule 2 violation, this is the part that must be replaced**

## CLIP 1A — THE STRIKE (~54cr) — Charlie 2026-07-19: show the hit, no BONK card

The leap footage cuts at 8.30, right before contact, and no footage of the
hit exists — the BONK text card was papering over that gap and Charlie
rejected it: **he wants to SEE the sword land on Max, with a reaction
expression.** The card is removed from `build_ep1_final.sh` (a bare white
flash marks the splice point until this clip exists).

**Start frame (READY, QA'd):** `wip/ep1/strike_start.png` = beat5 @8.28 —
Ralph airborne, sword raised, directly above Max on the rock. Both on-model.
The model only has to complete the swing: one action, no world change.

**Generate:** 12s, 9:16, 720p std, `generate_audio:false`, decline preset,
`start_image = wip/ep1/strike_start.png`, both hero PNGs as references.

**Prompt:**

> Painterly chibi cartoon dinosaurs, storybook picture-book style, vivid
> colors, bright sunny tropical beach. Continue this exact scene: the small
> sage-green chibi dinosaur with tall teal-blue back spikes and cream belly
> is mid-leap above the rock, golden-hilted sword raised. He brings the flat
> of the sword down in one clean arc and lightly BONKS the small brick-red
> chibi raptor on the top of the head. The raptor's eyes fly open huge and
> crossed, his cheeks puff, he wobbles dizzily on the rock with little stars
> circling his head, comically squashed — a funny cartoon reaction, not
> hurt. The green leaf pops loose from his grip. The green dinosaur lands
> on the sand beside the rock. Soft cartoon impact, all-ages, playful, no
> blood, no injury, nobody cries. Exactly ONE green dinosaur and exactly
> ONE red raptor. He carries exactly ONE sword and wears NO cape.

**QA:** the hit lands ON SCREEN with Max's expression readable; flat-of-sword
comedic bonk (not a slash); leaf comes loose; one sword, no cape, on-model.

**Build splice:** best ~2–3s (swing → reaction) goes between seg5 (the leap)
and seg5r (tide.mp4 resolution: Ralph on the rock, leaf reclaimed). Drop the
white flash once it's in.

## CLIP 1B — Ep1's true ending: the ocean-POV shot IN MOTION (~54cr)

`wip/ep1/tide_ocean_pov.png` is APPROVED CONTENT (Charlie's own camera idea:
looking at them from the ocean) and it is already perfect as a START FRAME:
world already flooded (no state change asked of the video model), leaf
already in the foreground, both dinos on-model on the last sand, mid-look.

**Generate:** 12s, 9:16, 720p std, `generate_audio:false`, DECLINE the
recommended preset. `start_image = wip/ep1/tide_ocean_pov.png`.
`image_references`: `assets/concept/ralph/ralph_hero.png` +
`assets/concept/raptor/raptor_hero.png`.

**Prompt (one action; the look is the shot):**

> Painterly chibi cartoon dinosaurs, storybook picture-book style, vivid
> colors. Continue this exact scene: camera low over calm turquoise sea,
> looking at the last small patch of dry sand where a small sage-green chibi
> dinosaur with tall teal-blue back spikes and cream belly and a small
> brick-red chibi raptor with darker red stripes stand side by side. They
> slowly turn their heads and look at EACH OTHER, wary and calculating, and
> hold that look. That is the entire shot. The water ripples gently, the
> single green leaf drifts slowly past in the foreground, palm trees stand
> in the water behind them. Very slow, very quiet. The camera pushes in
> very slightly. Exactly ONE green dinosaur and exactly ONE red raptor.
> No other creatures, no boats, nobody swims, nobody is in danger, all-ages.

**QA:** one of each dino, on-model (spikes/belly/stripes), they end looking
at each other, leaf drifts, no new objects. Re-roll on any failure.

**Build change** (in `build_ep1_final.sh`): replace the current t2/t3 stills
block with the best ~4–6s of this clip (trim to where the look lands; end ON
the look, no outro). Keep t1 → hard cut to this clip. Then rebuild, verify
NO text after the signpost, −14 LUFS, re-host to CDN, update
`scripts/social/hosted_media.json` + calendar.

## CLIP 2 — Ep2 "HIGH WATER MARK" (~54cr) — unchanged, staged, correct

Everything in `wip/ep2_den/` is ready and rule-compliant:
- `ep2_start.png` = composite start frame (den standing set + Ralph by the
  marked wall + Max silhouetted in the doorway) — the world is already
  built, the model only animates
- prompt = in this file's previous version, reproduced here:

> Painterly chibi cartoon dinosaur, storybook picture-book style, vivid
> colors. Interior of a small cosy den in the rocks above a tropical beach:
> warm low evening light from a wide opening, sandy floor, a flat drying
> rock. Standing silhouetted in the den opening the whole time is a small
> chibi red raptor — brick-red body with darker red stripes, cream belly,
> tiny white feather tufts at the elbows, yellow eyes — soaking wet, holding
> nothing, not attacking, not coming in, just standing there. Inside the
> den, a small round chibi green dinosaur — sage-green body, cream belly
> plates, tall teal-blue back spikes and teal tail tip, big amber eyes, pink
> blush cheeks, a small green leaf tucked behind his head — stands soaking
> wet with water dripping off him. He reaches up and scratches one short
> horizontal mark high on the stone wall with his claw. On the wall below
> that new mark are several older scratched marks, all of them lower — the
> new mark is clearly the highest. He looks at it. Then he turns his head
> and sees the red raptor in the doorway. Hold on the two of them looking at
> each other across the den. Slow, quiet, melancholy, nobody fights. Exactly
> ONE green dinosaur and exactly ONE red raptor in the entire scene. NO
> weapons. NO cape on either dinosaur. All-ages, warm and sad.

- Settings: 12s, 9:16, 720p std, `generate_audio:false`, decline preset,
  `start_image = wip/ep2_den/ep2_start.png`, both hero PNGs as references.
- **CAUTION — the ice insert:** `build_ep2.sh`'s current ending is an
  `ice_insert.png` still push-in — that NOW VIOLATES RULE 2. Fix before
  shipping Ep2: either (a) composite the ice INTO the generated clip's final
  seconds as a static prop over moving footage, or (b) spend ~54cr on a
  second tiny clip from `ice_insert.png` as start frame (slow push toward
  the ice, nothing else moves). Decide by what the generated den clip's
  tail looks like. The QA gates in `wip/ep2_den/` and the overlays
  (bub_dots, cap_open, cap_close) remain valid.

## Budget for the top-up

| item | cr |
|---|---|
| clip 1A (Ep1 strike) | 54 |
| clip 1B (Ep1 ocean ending) | 54 |
| clip 2 (Ep2 den) | 54 |
| possible Ep2 ice mini-clip | 54 |
| re-roll headroom | ~60 |
| **safe top-up** | **~280** |

Balance at write time: **2.5**.

## Fire order (next session)

1. Top-up lands → generate clip 1A (strike) + clip 1B (ocean ending) → QA
   both → splice 1A at the flash, replace the stills tail with 1B → rebuild
   → text sweep + LUFS check → re-host → **Charlie watches** → post
2. Generate clip 2 → QA → decide the ice ending (composite vs mini-clip) →
   `build_ep2.sh` → Charlie watches → schedule per calendar
3. Only after both ship: write Ep3 "SHARE THE ROCK" production kit

## Everything already DONE today (don't redo)

- Ep1 landing beat (BONK) built into `build_ep1_final.sh`; subtitles deleted
- `tide_ocean_pov.png` generated + approved-in-content (needs motion only)
- Ep2: den standing set, `ep2_start.png`, overlays, `build_ep2.sh` chain
  placeholder-verified, ice element generated
- Socials: YT verified-pinned; IG authorized + hosting solved
  (`scripts/social/hosted_media.json`, Higgsfield CDN, ep1 URL there is the
  SUBTITLE-FREE STILLS interim — replace after clip 1); TikTok 1-tap
- Calendar reconciled; ROADMAP "THE NEXT FEW MONTHS" plan committed
