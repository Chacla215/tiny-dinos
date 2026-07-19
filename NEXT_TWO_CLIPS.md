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

## ⇢ STATUS (2026-07-19, late) — Ep1 v4 IS BUILT, awaiting Charlie's watch

`wip/ep1/ep1_v4.mp4` — 58.3s, -13.9 LUFS, peak -1.4 dBFS. Built by the
committed `scripts/social/build_ep1.sh`. All three of Charlie's v3 corrections
are addressed: Arthur VO restored as audio (music sidechain-ducks ~10 dB under
him), `tide.mp4` plays continuously 0.40->11.60 so the turn is whole, and the
strike holds 6.0s so Max's dazed reaction lands on screen.

Verified, not assumed: text sweep clean past the signpost (3.05s); no dead air
(the sweep caught and fixed a music dropout at t=40 caused by
`sidechaincompress` truncating to its shorter input); ending holds ON the look.

**ONE OPEN QUESTION for Charlie** — the world-state jump at 51.2s. `tide.mp4`
ends on a wide, mostly-dry beach with footprints; `clip1b` opens on a tiny sand
patch ringed by ocean. Narratively that jump IS the premise, but it happens in
a hard cut. Options: (a) ship as-is, the rising water in the tide segment does
signal it; (b) spend ~54cr on the bridge clip — generate the half-flooded beach
as a still, use it as a video START FRAME. Balance is 394cr.

(NOTE: the left-right dino swap across that cut is CORRECT — clip1b is a
reverse angle from the sea, so the flip reads as the camera crossing.)

### Superseded — the v4 brief as originally written

v3 was built, uploaded UNLISTED (`youtube.com/shorts/2YEO8u0xYUc`) and Charlie
reviewed it on WhatsApp. **v3 is superseded — do not post it.** His three
corrections, verbatim:

> "I don't want still in the short, what happened to the narration part of it?
> Goes from max getting bonked to now they're together? You try to wrap it up
> to quick and leave out key transition details"

### Correction 2 is the big one: THE NARRATION IS NOT BANNED

The iron rule is **no SUBTITLES** — the on-screen caption text. It was never
"no narration". The v2 cut carried Arthur VO **audio** with captions burned on
top; v3 stripped the captions *and* threw the voice away with them. That was
the error. **Ep1 has a narrator. Put him back, as audio, with no text.**

The Arthur lines still exist in the Higgsfield library and are downloadable —
this is what "Arthur is unregenerable" actually means: no NEW lines, but the
five Ep1 lines are safe. They are the locked take (`speech_rate:10,
loudness_rate:15`). Re-fetch with
`https://d8j0ntlcm91z4.cloudfront.net/user_3G9RgW1xzgz2TkE3tUOlVwesChE/<file>.wav`:

| line | gen id | file | dur |
|---|---|---|---|
| "This is Ralph! King of a very tiny island… nobody… touches… the leaf." | `5b6e9ccf` | `hf_20260709_140447_5b6e9ccf-2c0c-4cba-aa60-f36a6ad3018e` | 8.11s |
| "Max touched the leaf!" | `b70d9c73` | `hf_20260709_140448_b70d9c73-1e63-491e-8f81-9b29fdc8c20f` | 1.34s |
| "Now, Ralph is not the fastest… he's mostly just… tiny!" | `20ba43d4` | `hf_20260709_140449_20ba43d4-9811-4abf-a9f8-bf74ab576e7a` | 6.46s |
| "But this island takes care of its little king… help — from the sky!" | `441c4017` | `hf_20260709_140500_441c4017-cbce-4a34-939a-2b3220bc3106` | 8.11s |
| "And Max? Oh, Max was about to learn Ralph's SECOND rule!" | `3d244e3f` | `hf_20260709_140501_3d244e3f-4e25-4cad-a0aa-047178845ea1` | 4.34s |

(Cached at `wip/ep1/vo/` — gitignored, so use the table if they're gone.
Ignore the Kevin / Mabel / Sterling takes of the same lines; Arthur is locked.
`18add782` "fast… and being STRONG" is **Ep2's** line, not Ep1's.)

### Corrections 1 + 3: the ending is rushed

v3 already has zero stills, so "I don't want still" is either the rule restated
or the very slow ocean push-in reading as frozen — watch for that. The real
defect is the jump from the bonk to the two of them together: **v3 chopped the
middle out of `tide.mp4`**, using 0.4–5.0 and 8.6–11.6 but skipping 5.4–8.6 —
which is exactly the turn (camera drifts back, Ralph sees the sea, Max gets up).
Play `tide.mp4` **continuously 0.4 → 11.6** and the transition is restored.

A gap remains even so: tide ends with water creeping over footprints on a
mostly-dry beach, and clip1b opens on an almost-submerged island. If that still
reads as too big a leap, the fix is a **bridge clip** (~54cr) — generate the
half-flooded beach as a still, use it as a video START FRAME. Charlie's call,
since it costs credits.

### v4 timeline (VO is the spine; times are finished-cut seconds)

```
0.00   beat5[7.20-8.70]   1.50  HOOK: the leap          + hook card
1.50   beat1[0.60-3.60]   3.00  yawn, king              + signpost   VO1 @1.8
4.50   beat1[6.60-11.60]  5.00  nap -> snatch -> wake                VO2 @10.1
9.50   beat2[4.50-9.50]   5.00  rises furious, Max taunts
14.50  beat3[3.00-7.50]   4.50  chase -> trip                        VO3 @12.8
19.00  beat3[7.50-11.50]  4.00  spent, Max taunts                    VO4 @19.6
23.00  beat4[1.20-4.50]   3.30  the sword falls (~24.3, under "from the sky")
26.30  beat4[9.00-11.60]  2.60  pulls it free, hero stance
28.90  beat5[3.60-8.70]   5.10  charge + leap                        VO5 @29.2
34.00  clip1a[1.20-6.20]  5.00  THE STRIKE (contact ~36.0)
39.00  tide[0.40-11.60]  11.20  lands, leaf reclaimed, THE TURN, water creeps
50.20  clip1b[3.50-10.50] 7.00  ENDING: ocean POV, the look
                          ~57s
```

Music must **duck under the VO** (sidechaincompress keyed off the voice bus);
v3's flat music bed will bury Arthur. Keep: impact SFX on the contact, ocean
wash under the ending, −14 LUFS master, and the two text overlays as the only
on-screen text.

## 2026-07-19 PM update — top-up landed, clips FIRED, workshop recovered

- Top-up landed: balance 502cr. Clips 1A + 1B generating (Seedance 2.0, 12s,
  9:16, 720p std, no audio, hero refs): job `43080158-50c4-49eb-8e30-546104970f2c`
  (1A strike), job `d738743b-fed3-477f-9bc4-463cac702c18` (1B ocean ending).
- **The /tmp workshop was WIPED** (build_ep1_final.sh, build_ep2.sh, strike_start,
  tide_ocean_pov, segment mp4s all lost — session scratchpads are ephemeral).
  Recovered into **repo `wip/` (persistent, use this from now on)**:
  - `wip/ep1/tide_ocean_pov.png` — re-downloaded from Higgsfield gen `2ec8a136`
  - `wip/ep1/strike_start.png` — beat5 @8.30 QA extract (the @8.28 original is
    gone; visually the same airborne pose, promoted to start frame)
  - `wip/ep1/tide.mp4` — Higgsfield gen `7e292293`
  - `wip/ep1/ep1_final_v2.mp4` — the hosted 40.8s v2 cut, from the CDN
  - `wip/ep2_den/ep2_start.png` (+ start2, ice_end, ice_end2) — from scratchpad
- **Build scripts are NOT recovered** — `build_ep1_final.sh` must be rebuilt.
  Plan: operate on `ep1_final_v2.mp4` directly (splice 1A at the white flash,
  replace the stills tail after t1 with 1B). Rewrite as
  `scripts/social/build_ep1_final.sh` and COMMIT it this time.
- Media ids uploaded this session: strike_start `172dfdfd`, ralph_hero
  `9f7e9ad4`, raptor_hero `0901826b`.

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
