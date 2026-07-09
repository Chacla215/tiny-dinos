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
   (`closing_card.png`: real title logos + "GRAB A WEAPON. WIN THE ISLAND." +
   "1-4 PLAYERS · COUCH BRAWLER").
7. **Longer clips** — 12s per Seedance clip (model caps at 15s). Action short =
   2×12s + card ≈ 27s. **Cost: 54 cr per 12s std 720p clip.**

## STORY SHORTS — 1-minute character arcs (Charlie, 2026-07-09)

One ~60s story per dino: **5 chained 12s clips + the closing graphic**. Chain =
extract the last frame of clip N (ffmpeg), composite/clean if needed, feed as
`start_image` of clip N+1 — the proven continuity recipe. Every story is a real
arc (want → struggle → change), built from GAME pieces (weapon drops, arenas,
passives, the career rivalry). ~270 cr per story → **current balance funds ONE
pilot (RALPH); the six-story season needs a credit top-up.**

**RALPH — "THE LEAF" (the pilot, fully scripted):**
| beat | 12s clip | arc function |
|---|---|---|
| 1 | Dawn on Beauty Beach. Ralph naps against a palm, his leaf tucked snug. A red blur (MAX) zips past and SNATCHES the leaf off his head; Ralph startles awake, pats his bare head, devastated. | the loss |
| 2 | Max struts and twirls the leaf, taunting. Ralph's sad face hardens into determination — he plants his feet and DEMANDS it back. Max sticks out his tongue and dashes off. | the want |
| 3 | The chase across the island — Ralph's stubby waddle-run vs Max's blur, through sand sprays and swaying palms; Max always just out of reach, Ralph tumbles, gets up, keeps coming. | the struggle |
| 4 | A sword drops from the sky and sticks in the sand between them (the game's weapon drop). Ralph grabs it — spin-slash flurry, glowing arcs — the shockwave trips Max mid-gloat; the leaf flutters free. | the turn |
| 5 | Ralph catches the leaf, tucks it back… then offers Max a paw up. Max takes it, sheepish. They grin — freeze-frame, cartoon stars. → closing graphic. | the heart |

**The other five (loglines, script on demand):**
- **MAX — "FAST ISN'T FIRST":** cocky speedster loses a beach race to slow-and-
  steady Steve after showboating; learns to finish. Ends: rematch handshake.
- **GUS — "THE WALL MOVES":** immovable Gus won't budge for anyone — until
  Jessie's egg-basket rolls toward the lava; the unstoppable charge, for once,
  is FOR someone. (Laughing Lava arena.)
- **JESSIE — "GROUNDED":** show-off sky ace clips a palm mid-stunt and has to
  win a scrap on foot; discovers the ground game. Ends: dusts off, flies low.
- **STEVE — "GENTLE GIANT":** everyone wants pacifist Steve on their team; he
  won't fight — until a bully knocks Ralph's ice cream over. One (1) gentle
  bonk. (Sunny Springs.)
- **FRANK — "ONE MORE ROUND":** the old veteran hangs up his club; the kids
  beg for one last lesson. He blocks everything they throw (spikeback!), taps
  each on the head, retires happy. (Iciest Age.)

Post per story: per-dino label (beat 1-2), light captions, music bed from the
game tracks, ALWAYS the closing graphic.

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
