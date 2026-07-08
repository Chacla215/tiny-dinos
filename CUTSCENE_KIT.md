# CUTSCENE KIT — short-form hype content

**Goal:** a steady drip of short cutscenes for **TikTok / Reels / YouTube Shorts**
to build hype around Tiny Dinos. Charlie's chosen formats: **9:16 vertical shorts**,
**character intro cards** (one per dino), and **story teasers** (hint the career
journey / rival arc).

Pipeline (proven — same as the trailer + motion pass, see memory
`seedance-motion-pipeline`, `trailer-progress`): Higgsfield **Seedance 2.0**,
`<dino>_hero.png` as `start_image`, adapt the motion/framing prompt, decline the
"IN THE DARK" preset (`declined_preset_id`). ~18 cr/clip; balance ~706. For 9:16
pass the vertical aspect. Cutout/keying + ffmpeg for any compositing as before.

## Batch A — CHARACTER INTRO CARDS (6 clips, 9:16, ~5s each)

One signature moment per dino that sells its personality + signature passive. End
frame holds on a name card (baked in post: DISPLAY NAME + subtitle + one-line
passive, styling lifted from the title logo). Source personalities from
`ralph_creator.gd` PROFILES.

| dino | name | subtitle | the moment (prompt seed) |
|---|---|---|---|
| ralph | RALPH | THE TINY KING | struts up, tiny but fearless, chomps the air, cocky grin to camera |
| raptor | MAX | THE SPEEDSTER | blurs across frame, skids to a stop, sickle claws up, smug head-tilt |
| trike | GUS | THE BULWARK | lowers three horns, paws the ground, unstoppable charge past camera |
| pterry | JESSIE | THE SKY ACE | drops in on a wing, cocky landing, screech, dust settles |
| bronto | STEVE | THE GENTLE GIANT | ambles in with a flower in mouth, dreamy sweep of the long neck |
| anky | FRANK | THE VETERAN | steady stance, club-tail thud, grizzled nod — "seen it all" |

Post: 0.5s whip-in → the moment → 1.5s name-card hold. Cut to the beat of a short
audio sting. Caption overlay: "MEET <NAME>" + "TINY DINOS".

## Batch B — STORY TEASERS (2–3 clips, 9:16, ~6s)

Tease the career journey without spoiling it. Cinematic, mysterious.
1. **THE JOURNEY** — a lone dino silhouette on a beach at dawn, six islands on the
   horizon; text: "ONE DINO. SIX ISLANDS. ONE JOURNEY." → TINY DINOS.
2. **THE RIVAL** — two dinos face off across a smoking arena, slow push-in on the
   glare; text: "SOME RIVALRIES ARE DESTINY." → TINY DINOS.
3. **THE BOND** (optional) — quiet DEN beat: a dino resting, the player "feeding"
   it; text: "RAISE YOUR CHAMPION." → ties directly to the new career mode.

## Format spec (all)

- **9:16**, 720p, ~5–6s, `generate_audio:false` (we add stings/music in post).
- Consistent grade so the series reads as one brand (the painterly-chibi look).
- Safe margins: keep action + text in the middle 80% (platform UI eats edges).
- Each ships as its own file → `assets/concept/shorts/<name>.mp4`.

## Rollout

1. **Pilot first** — generate ONE (RALPH intro card, 9:16) end-to-end, bake the
   name card + sting, review with Charlie. Lock the look.
2. Batch A (remaining 5 intro cards) once the pilot look is approved.
3. Batch B teasers.
4. Charlie posts; track which format lands and double down.

Open question for Charlie: audio — reuse the battle/menu tracks for stings, or
source short CC0 stingers per clip? (Recommend: a 1–2s sting from the battle
track's drop for intro cards; menu track for teasers.)
