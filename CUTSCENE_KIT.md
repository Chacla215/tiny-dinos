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

## TEMPLATE V2 (Charlie's pilot notes, 2026-07-09)

Locked from his read of the Ralph action pilot — every short from here obeys:

1. **Immersed in the island** — no flat backdrops. Composite the keyed hero onto
   a 9:16 slice of the REAL arena art (crop below the baked banner, y≥170) and
   use that as `start_image`. The world of the short = the world of the game.
2. **One weapon per short, consistent** — Ralph = the SWORD (the slash he loved).
   Assign each dino a signature weapon from the game set and keep it through
   every beat.
3. **Personality** — every short needs a character beat (taunt, wink, strut,
   tail-wag), not just action.
4. **Hype the GAME through the character** — show game moments: rival clashes,
   the weapon-drop scramble, knockbacks, ring-out energy. Character-in-the-game,
   not character-in-a-void.
5. **Per-dino UNIQUE label, SAME texture** — shared lower-third (dark band +
   Impact + outline + accent underline), unique per dino: name in their body
   colour, their emblem, their subtitle. (`make_v2_overlays.py` DINOS table.)
6. **ALWAYS end on the closing graphic** — the standing brand card
   (`closing_card.png`, Charlie-picked 2026-07-09: BRIGHT beach, the integrated
   logo big, one small white line "A COUCH BRAWLER FOR 1-4 PLAYERS" — sunny
   like the brand; no dark dim, no tagline block).
7. **Longer clips** — 12s per Seedance clip (model caps at 15s). Action short =
   2×12s + card ≈ 27s. **Cost: 54 cr per 12s std 720p clip.**

## STORY SHORTS — 1-minute character arcs (Charlie, 2026-07-09)

One ~60s story per dino: **5 chained 12s clips + the closing graphic**. Chain =
extract the last frame of clip N (ffmpeg), composite/clean if needed, feed as
`start_image` of clip N+1 — the proven continuity recipe. Every story is a real
arc (want → struggle → change), built from GAME pieces (weapon drops, arenas,
passives, the career rivalry). ~270 cr per story → **current balance funds ONE
pilot (RALPH); the six-story season needs a credit top-up.**

**RALPH — "THE LEAF" EPISODE 1 (the pilot — MONETIZATION CUT, 2026-07-09):**
Built for Reels/Shorts/TikTok: hook inside the first beat, ~60s, ends on a
CLIFFHANGER (the resolution — Ralph reclaiming the leaf + helping Max up — is
saved as the Episode 2 opener). Two audio mixes per episode: NARRATED (seed_audio
preset "Arthur", lines below) and NO-VO (music + action only) — post both,
let the platform data pick. Cliffhanger card ("TO BE CONTINUED…") precedes the
standing closing graphic.

| beat | 12s clip | narrator line |
|---|---|---|
| 1 | Ralph yawns, curls up under the palm — a red blur (MAX) snatches the leaf off his head; Ralph wakes, pats his bare head, horror. | "This is Ralph. King of a very tiny island. Ralph has exactly one rule: nobody… touches… the leaf." |
| 2 | Max struts and twirls the leaf, taunting; Ralph's sad face hardens; Max blows a raspberry and dashes off; Ralph gives chase. | "Max touched the leaf." |
| 3 | The chase — stubby waddle-run vs blur, sand sprays, Ralph tumbles hard, gets up panting; Max gloats from atop a rock. LOW POINT. | "Now, Ralph is not the fastest dino on the island. Or the strongest. Honestly? He's mostly just… tiny." |
| 4 | A sword drops from the sky, sticks upright in the sand before Ralph. He looks up. Grips it. Eyes narrow. Stands tall, wind rising. | "But this island takes care of its little king. And sometimes… it sends help. From the sky." |
| 5 | Ralph CHARGES, leaps sword-high; Max's smug grin collapses into wide-eyed shock — FREEZE mid-air → smash to "TO BE CONTINUED…" | "And Max? Max was about to learn Ralph's second rule." |

**AUDIO TEMPLATE — LOCKED (Charlie, 2026-07-09, after a 2-round A/B):**
- **Narrator:** seed_audio preset **"Arthur"** at **speech_rate +10 /
  loudness_rate +15**, lines punched with exclamation emphasis — deadpan
  through beats 1–3 (that's the joke), energy ramps at the turn (beats 4–5).
- **Music bed:** **"Go to the Picnic"** (Loyalty Freak Music, CC0,
  FreeMusicArchive — bouncy cartoon-comedy, no jazz) at 0.4 for beats 1–3,
  then the game **battle theme** from the sword/turn moment (36.4s) at 0.75 —
  the 3.5s buildup lands the drop right on the hero moment. NO-VO mix = same
  bed without lines. Rejected on the way: menu-soul + island-loop beds (too
  jazzy), Sterling/Mabel/Kevin narrators (Arthur most natural).
- Recipe + final mixes: `wip/ep1/build_ep1.sh` (`ep1_narrated.mp4`,
  `ep1_no_vo.mp4`, takes in `vo_e*.wav`). This voice+bed is the template for
  the whole six-story season.

**MAX — "FAST ISN'T STRONG" EPISODE 2 (BUILT 2026-07-09, sumo recut):**
Opens on the Ep1 resolution (serialized hook), then Max's own arc — a **SUMO
match** (real in-game mode; the first cut was a race, remade because racing
isn't a Tiny Dinos mode and Max drifted off-model). Beach arena, signature
weapon = **DAGGER**, co-star Steve (bronto hero). Locked audio template;
captions + TBC card in `wip/ep2_max/`; VO `wip/ep2_max/vo_e1..5.wav`. Battle
drop lands on beat 4's one-step push. Seedance: 12s/beat, 9:16 720p,
`generate_audio:false`, decline IN THE DARK, beat 1 start_image = **Ep1's
final frame** (perfect cold-open continuity), chain last frames
beat-to-beat, AND pass a clean Max frame from beat 1 as `image_references`
on every later beat so Max stays on-model (caveat: the identity ref can
clone Max into the crowd — if it does, re-roll with "exactly ONE red raptor,
crowd contains NO red dinosaurs"). Finale trick: generate the cliffhanger
short (7s) and extend the freeze with `tpad=stop_mode=clone` to 12s.

| beat | 12s clip | narrator line |
|---|---|---|
| 1 | COLD OPEN = Ep1 payoff: Max flat in the sand, Ralph plucks the leaf back onto his head, offers a hand up; Max slaps it away, storms off burning with embarrassment. | "When we last saw Max… he lost. To the tiniest king on the island. And Max does not. Lose." |
| 2 | Max needs a win: he scratches a SUMO RING in the sand with his dagger and challenges Steve (ambling by, flower in mouth); Steve slow-blinks… nods, steps in. Dinos gather. | "So Max picked a new game. Sumo! First one out of the ring… loses." |
| 3 | THE MATCH: Max zips around Steve in a blur — shoves his legs, tail, belly from every angle. Steve does not move an inch, chewing his flower. Max poses for the crowd anyway. | "Max has a hundred moves! Steve has… one." |
| 4 | THE TURN: Steve takes his ONE slow step. Max braces against the giant leg with everything — and slides backward through the sand toward the ring's edge, panic dawning. (BATTLE DROP HERE) | "And Steve? Steve only knows one speed. He just… never… stops!" |
| 5 | CLIFFHANGER: Max teeters on one toe ON the ring line, arms windmilling, Steve's foot hanging mid-air above him — FREEZE → "TO BE CONTINUED…" (resolution = Ep3 opener: one gentle final step; the flower + handshake.) | "Max was about to learn the difference between being fast… and being STRONG!" |

**PACING RULE (from Ep2's tight recut — apply to every episode):** raw 12s
Seedance beats carry ~5-8s of real action and the rest is idle standing;
never ship beats raw. Post pass (`wip/ep2_max/build_ep2_tight.sh` is the
template): trim each beat to its action window (make 1fps contact sheets to
find it), speed-ramp slow stretches 1.1-1.6x, replace any freeze-frame hold
with a slow zoompan push-in (motion, never a static frame), then retime
VO/captions/music to the measured segment starts (VO must fit its segment:
check `ffprobe` durations). Ep2 went 65s -> 45s and reads twice as alive.
Target: no 2 consecutive seconds with a static composition.

**STEVE — "THE GENTLE GIANT" EPISODE 3 (PRE-PRODUCED 2026-07-09 — generation
awaits the credit top-up, ~400 cr safe):** cold open resolves Ep2 (the one
gentle step; flower + handshake; Max smiles), then Steve's arc — his sumo win
makes him famous, everyone drags the pacifist into the springs **TEAM RUMBLE**
(real mode) where he's sweetly useless… until GUS flattens Ralph's ice cream.
Signature weapon = the **WAR HAMMER, held in his MOUTH** (bronto grab
anatomy); cliffhanger = hammer at apex over gulping Gus. Arena: beach beat 1 →
**SUNNY SPRINGS** beats 2-5 (location change = composite start frame, the v2
recipe, from the painterly `assets/tilesets/sunny_springs_bg.png`).
Everything staged in `wip/ep3_steve/`: `seedance_prompts.md` (beats +
identity locks for Steve AND Gus + VO lines), `beat0_end.png` (Ep2's final
freeze = cold-open start), `beat2_start.png` (+`make_ep3_start.py`),
`cap1..5.png` + `tbc_card.png` (+`make_ep3_overlays.py`),
`build_ep3_tight.sh` (pacing-rule cut, trim windows marked TUNE), picnic bed.
VO not yet generated (5 lines ≈ the entire remaining 3.5 cr — no retake
headroom; first step after top-up).

**SEASON HANDOFF CHAIN (locked pattern):** each episode's co-star becomes the
next protagonist — **Ralph → Max → Steve → Gus → Jessie → Frank** — and each
cold open resolves the previous cliffhanger. Ep4 = GUS (co-star Jessie),
Ep5 = JESSIE (co-star Frank), Ep6 = FRANK (everyone; season finale).

**The other three (loglines, script on demand):**
- **GUS — "THE WALL MOVES" (Ep4):** cold open = Steve's one (1) gentle bonk
  lands (Gus faints from anticipation; the scoop plops back on Ralph's cone).
  Then: immovable Gus won't budge for anyone — until Jessie's egg-basket
  rolls toward the lava; the unstoppable charge, for once, is FOR someone.
  (Laughing Lava arena, EGGS mode.)
- **JESSIE — "GROUNDED" (Ep5):** show-off sky ace clips a palm mid-stunt and
  has to win a scrap on foot; discovers the ground game. Ends: dusts off,
  flies low.
- **FRANK — "ONE MORE ROUND" (Ep6):** the old veteran hangs up his club; the
  kids beg for one last lesson. He blocks everything they throw (spikeback!),
  taps each on the head, retires happy. (Iciest Age; season finale.)

Post per story: per-dino label (beat 1-2), light captions, the LOCKED audio
template (picnic bed → battle drop at the turn, Arthur+energy narration),
ALWAYS the closing graphic.

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
