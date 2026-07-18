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
| pterry | ACE | THE SKY ACE | drops in on a wing, cocky landing, screech, dust settles |
| spino | JESSIE | THE DEEP DIVER | leaps high, tucks into a flawless cannonball, splash-lands, sunflower settles in her sail |
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
next protagonist — **Ralph → Max → Steve → Gus → Ace → Frank** — and each
cold open resolves the previous cliffhanger. Ep4 = GUS (co-star Ace),
Ep5 = ACE (co-star Frank), Ep6 = FRANK (everyone; season finale).
(2026-07-18: the pterodactyl was renamed JESSIE → ACE; the name JESSIE now
belongs to the new 7th roster dino, a spinosaurus diver. She's post-season
material — a "new challenger appears" episode or a devlog short.)

**FULL DRAFTS — Ep4-6 (written 2026-07-18, AWAITING CHARLIE'S READ before
any generation; same formula: cold open resolves the last cliffhanger,
deadpan beats 1-3, battle-drop turn at 4, freeze at 5):**

**GUS — "THE WALL MOVES" (Ep4). Laughing Lava, EGGS mode, co-star Ace.**
| beat | 12s clip | narrator line |
|---|---|---|
| 1 | COLD OPEN = Ep3 payoff: Steve's impossibly gentle bonk taps Gus on the noggin; Gus faints from sheer anticipation; a fresh scoop plops onto Ralph's cone; Steve picks his daisy back up. | "When we last saw Gus… he was one bonk away from bedtime. The bonk was very gentle. Gus fainted anyway." |
| 2 | EGG DAY on Laughing Lava: eggs everywhere, dinos scrambling to collect them. Gus stands dead-center like furniture; everyone bounces off him. Ace swoops laps, piling eggs into a basket, showing off. | "Egg day on Laughing Lava! Grab the eggs, keep them safe. Simple! …Unless you are a wall." |
| 3 | LOW POINT: eggs roll right past Gus's feet; he does not budge. Lava geysers pop behind. Ace stacks his overloaded basket on a rock ledge to take a bow — it wobbles. | "Gus does not chase. Gus does not scramble. Gus… stands. It's kind of his whole thing." |
| 4 | THE TURN (battle drop): the basket TIPS — a river of eggs rolls toward the lava. Ace dives but can't catch them all. Gus's eyes narrow. The ground SHAKES. The wall moves: full charge, horns down, scooping eggs as he goes. | "And then the basket tipped. And every single egg… rolled toward the lava." |
| 5 | CLIFFHANGER: Gus mid-charge, eggs balanced on frill and horns, as the LAST egg arcs out over the lava's edge — his horn-tip stretching for it — FREEZE → "TO BE CONTINUED…" | "That day, the island learned something brand new: the wall… MOVES!" |

Resolution (Ep5 cold open, do NOT show): the egg lands on the horn-tip; Ace
sweeps in and crowns Gus with the empty basket like a trophy.

**ACE — "GROUNDED" (Ep5). White Water Falls, co-star Frank.**
| beat | 12s clip | narrator line |
|---|---|---|
| 1 | COLD OPEN = Ep4 payoff: the last egg lands on Gus's horn-tip; crowd erupts; Ace crowns Gus with the basket, then launches into a celebratory airshow. | "When we last saw Ace… actually, when has anyone NOT seen Ace? He makes sure of it." |
| 2 | The airshow over the falls: loops, dives, wing-taps off the water — then CLIPS a palm frond, spins out, crash-lands through the rope-bridge planks. Sits up: one wing in his signature bandage. Grounded. | "One palm tree. ONE. And just like that… the sky ace was grounded." |
| 3 | LOW POINT: Frank offers a friendly ground scrap ("ground school"). On foot, Ace's dive-bomb instincts are useless — he bounces off Frank's armor, gets tail-swatted, wobbles dizzy. Frank waits, patient as rock. | "Down here there's no swooping. No diving. Down here there's just Frank. And Frank has seen… everything." |
| 4 | THE TURN (battle drop): Ace stops flapping and starts WATCHING. Reads the slow wind-up of Frank's tail, ducks under it ON FOOT, lands his first clean sidestep-jab. Frank's brow lifts — impressed. | "So Ace stopped flying… and started paying attention. Turns out the ground has moves too." |
| 5 | CLIFFHANGER: Frank's biggest tail-smash yet comes down; Ace crouches — not to take off, to DODGE — FREEZE with the club-tail mid-descent, sand rings spreading → "TO BE CONTINUED…" | "The old tail came down like thunder! And for the first time ever… Ace didn't need his wings!" |

Resolution (Ep6 cold open, do NOT show): the smash lands on empty sand — Ace
has already sidestepped; Frank nods the biggest nod of his life.

**FRANK — "ONE MORE ROUND" (Ep6, SEASON FINALE — resolves, no cliffhanger).
Iciest Age, co-stars: everyone.**
| beat | 12s clip | narrator line |
|---|---|---|
| 1 | COLD OPEN = Ep5 payoff: the tail-smash lands — Ace is already gone, standing to the side, bowing. Frank smiles… then walks to a palm and HANGS UP his axe. The island goes silent. | "The smash came down… and Ace was already gone. Frank smiled. Then Frank did something nobody expected. He quit." |
| 2 | Retirement at Iciest Age: Frank naps on a floe. The kids — Ralph, Max, Steve, Gus, Ace — slide across the ice begging for one last lesson. Head shake. More begging. Sadder head shake. | "Every legend hangs up the club someday. Frank figured… today. The kids figured… absolutely not." |
| 3 | LOW POINT: the kids train themselves. It goes terribly — Ralph slips, Max crashes into a snowbank, Gus skids into a berg, Steve apologizes to a snowman he flattened. Frank watches through one open eye. Sighs. | "Training without Frank went… honestly? About how you'd expect." |
| 4 | THE TURN (battle drop): Frank steps onto the ice ring and taps his club twice: one more round — ALL of you, at once. Five dinos rush him; he blocks everything (spikes flashing), pivots, deflects — a masterclass, grinning for the first time all season. | "So the old veteran stepped onto the ice for ONE more round. All of them. At once. He blocked… everything." |
| 5 | FINALE: snow settles; five happy dinos flopped in a pile. Frank taps each little head one by one… then places his club in tiny Ralph's arms. Sunset over the floes, group huddle — FREEZE → "SEASON ONE — THE END" card, then the closing graphic. | "And when the snow settled, Frank tapped each little head… and handed the club to the tiniest king of all. Class dismissed." |

Post per story: per-dino label (beat 1-2), light captions, the LOCKED audio
template (picnic bed → battle drop at the turn, Arthur+energy narration),
ALWAYS the closing graphic.

## POSTING RULES — true-to-game, retention, all-ages (Charlie, 2026-07-18)

Charlie's three asks, locked as rules for every clip we post:

**1. TRUE TO THE GAME.** Anything presented as gameplay must BE gameplay.
Real footage is now zero-effort with no controller: the capture harness
records CPU-vs-CPU matches in Movie Maker mode (smooth 60fps, faster than
real-time):
```
/opt/homebrew/bin/godot --write-movie /tmp/td_capture/<arena>.avi \
    scenes/_capture_gameplay.tscn -- --seconds 14 --arena <arena>
ffmpeg -i /tmp/td_capture/<arena>.avi -c:v libx264 -crf 20 -pix_fmt yuv420p \
    -movflags +faststart wip/captures/<arena>_gameplay.mp4     # + 9:16 crop
```
Seedance painterly clips stay legal for STORY shorts (they're cutscenes /
character content, clearly stylized) — but every trailer or "look at this
game" post leads with or cuts to real capture. Rule of thumb: hook may be
cinematic ≤2s; proof must be gameplay. (First captures live in
`wip/captures/` — git-ignored; regenerate any time.)

**2. RETENTION (hold them to the last frame).**
- Hook inside 1.5s: motion + an implicit question (a dino mid-flight, a bomb
  about to pass, "wait, the island floods?"). Never open on a logo.
- A new beat every 2–4s: camera change, KO, hazard fires, mode twist. If
  nothing changes for 4s, cut it.
- Escalate: save the biggest moment (ring-out, wave-KO, 4-dino pileup) for
  the final 3s so watch-through pays off.
- Loop-friendly: last frame ≈ first frame family, so the rewatch feels
  seamless (rewatches count as retention).
- Captions on everything (most viewers are muted); name-card LATE, not first.
**3. ALL AGES.** Cute cast + slapstick physics is already universal — protect
it: no niche memes, no text walls, no irony that needs context. Bright
readable action at phone size (zoom the crop tight on the fight, middle 80%
safe area). Music with a clean build/drop (the battle track's ~3.5s buildup →
drop is the FIGHT! beat — cut to it). Nothing scary, nothing edgy — the brand
is "Saturday-morning couch chaos."

**1b. CONTINUITY QA (Charlie, 2026-07-18 — from reviewing the cuts).** Two
real examples of clips that break trust, and the standing rule they set:
- *Ralph pulls a second sword from nowhere* — AI-generated shots hallucinate
  props. In-game a dino holds ONE weapon (and Ralph's is a hammer). QA every
  generated clip frame-by-frame: props/weapons must persist, nothing appears
  or vanishes, nobody wields gear their kit doesn't have. If a shot fails,
  regenerate it or replace it with real capture.
- *The sumo clip is confusing* — a mode moment must be SELF-EXPLANATORY to a
  first-time viewer. Test: could someone who's never seen the game say what
  happened and who won? Real sumo capture passes on its own (the dohyo ring +
  a shove-out reads instantly); add at most one caption ("LAST DINO IN THE
  RING WINS") — if it needs more explaining than that, cut it.

**New-dino angle:** market JESSIE purely in-universe — "A NEW CHALLENGER
DIVES IN" reveal: profile-card flash → real gameplay of the CANNONBALL splash
and a swan-dive KO. (Per Charlie: keep the personal story behind her OUT of
public clips.)

## Format spec (all)

- **9:16**, 720p, ~5–6s, `generate_audio:false` (we add stings/music in post).
- Consistent grade so the series reads as one brand (the painterly-chibi look).
- Safe margins: keep action + text in the middle 80% (platform UI eats edges).
- Each ships as its own file → `assets/concept/shorts/<name>.mp4`.

## Rollout — STORY-FIRST (Charlie, 2026-07-18, supersedes below)

Second strategy refinement the same day: **the shorts lead with STORY, not
gameplay.** Serialized character episodes draw the audience; the game
releases slowly behind them. True-to-game stays binding for anything framed
as gameplay (launch trailer, store page, the real-capture reels) but story
shorts are openly cinematic. Clarity rules still bind EVERYTHING (a beat a
first-time viewer can't follow gets fixed or cut).

**QA verdicts (2026-07-18 frame audit, corrected by Charlie):**
- **Ep1 — HELD.** Beat 4 (sky-sword arrival) is fine — staged AND narrated.
  But beat 5 (~37-49s, the leap at Max) breaks continuity: Ralph carries
  TWO swords (one raised + a second hilt behind his head) and sprouts an
  orange CAPE from nowhere (Charlie caught it). Fix = regenerate beat 5
  with an identity ref from beat 4 + guard line "exactly ONE sword, no
  cape" (~15-25cr), or end the episode on the beat-4 stand-tall moment
  with a re-cut freeze (0cr, loses the leap).
- **Ep2 — HELD.** Mid-episode beats (~16-30s) are OFF-MODEL: a toy-styled
  bronto w/ pink flower + non-roster crowd (orange-spot trike, purple ptero).
  Fix = regenerate those beats with Ep3-style identity locks (~40-80cr,
  needs Charlie's ok — it eats most of the 82.5cr balance) or trim to the
  on-model beats only.
- **PROCESS (Charlie, 2026-07-18): script read-through BEFORE generation.**
  No episode gets generated until Charlie has read its full beat table + VO
  lines and signed off. Ep4-6 full drafts below exist for exactly that.
- **QUARANTINED (never post):** act_sword.mp4, ralph_action_short*.mp4,
  v2_clash/v2_drop — colosseum/off-island sword content; wrong weapon,
  wrong world. Keep as style history only.

**Slow-release story cadence:** wk1 Ep1 → wk1 reel (sumo) → wk2 Ep2 (once
fixed) → wk2 reel (Jessie) → wk3 Ep3 (on credit top-up; it's fully
pre-produced) → then Ep4-6 loglines. Episodes carry the story hook; the
real-capture reels slot between as "oh, it's a real game" proof — story
draws them in, gameplay converts them.

## (superseded same-day) Rollout — SOCIAL-FIRST

Strategy call: **build the audience NOW, build the game alongside.** Reels
production is the priority track; game work continues underneath.

**The reel factory (zero credits, all true-to-game):** capture harness →
ffmpeg 9:16 assembly (blurred-fill + centered gameplay + Jersey25 caption
overlays + battle-theme audio, TINY DINOS end card). First three built
2026-07-18 in `wip/reels/`: `reel_sumo` ("LAST DINO IN THE RING WINS"),
`reel_chaos` ("4 PLAYERS. 1 ISLAND. 0 MERCY"), `reel_jessie` ("NEW
CHALLENGER — JESSIE THE DEEP DIVER"). Build script lives in the session
scratchpad; regenerate any time from fresh captures.

**Cadence:** 2–3 posts/week, same handle everywhere (IG Reels + TikTok +
YouTube Shorts — post natively to all three, the formats are identical).
Alternate content types: real-gameplay reel → story short (Ep1/Ep2) →
real-gameplay reel. Game name visible in every clip (end card). Track saves
+ completion rate over views; double down on whichever mode/island clips
retain best.

**Episode QA before posting** (Charlie's continuity review):
- Ep1 ~29–34s: the sky-sword beat — it's actually the game's real
  weapon-drop mechanic, but unexplained it reads as a continuity error.
  Fix on Charlie's edit pass: one caption ("WEAPONS RAIN FROM THE SKY.
  REALLY. IT'S A MODE.") or trim the beat.
- Ep2 (Max) mid-episode sumo/race beats: confusing per Charlie — consider
  swapping in real sumo capture or trimming to the race gag only.
1. Charlie posts Ep1 (post-QA) + the three reels to seed the account.
2. Batch A intro cards + Batch B teasers stay on the menu once credits
   allow — story content only, never framed as gameplay.
3. Track which format lands and double down.

Open question for Charlie: audio — reuse the battle/menu tracks for stings, or
source short CC0 stingers per clip? (Recommend: a 1–2s sting from the battle
track's drop for intro cards; menu track for teasers.)
