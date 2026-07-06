# TINY DINOS — trailer / opening cutscene kit (Seedance 2.0)

One video, two jobs: a ~45s **trailer** whose first ~20s also cuts down to the
**in-game opening cutscene**. The cutscene player is already wired: the moment
`assets/video/opening.ogv` exists, the game plays it before the title screen
(any gamepad button skips). Claude handles all assembly (editing, music, logo
card, format conversion) — your job is the shots.

## PHASE 0 — the cast (DO THIS FIRST)

Charlie's call (2026-07-05): the current five non-Ralph dinos **don't capture
Ralph's cute-and-cuddly look** — so the trailer cast is the **chibi restyle**
we already planned in `dino_chibi_restyle_prompts.md`. Generate the five
restyled heroes per that kit (species bible + RESTYLE directive + negative,
with `ralph_hero.png` as the style reference) and drop them at
`assets/concept/<dino>/<dino>_hero.png`.

One effort, two payoffs: those heroes are the trailer cast **and** they fix
the in-game roster brand — Claude rebakes every fighter sheet, rig, and
portrait from them, so pick == play == trailer.

## HOW TO SHOOT (read once)

- Tool: Seedance 2.0, **image-to-video / multimodal** mode.
- **References are everything.** For every shot, upload: `ralph_hero.png`,
  the other dinos appearing in that shot (restyled heroes), and an island
  still (any `assets/concept/islands/` beach art). Re-use the SAME files
  every shot so the cast doesn't drift.
- **2–3 characters max per shot.** Consistency dies with crowds; the shot
  list is written so no shot needs more than 3 close-up dinos (the brawl shot
  hides everyone in a dust cloud on purpose).
- **Chain shots:** export the FINAL FRAME of the previous shot and add it as
  an extra reference for the next one — keeps lighting/scene continuous.
- Durations: shots are 5–8s. Generate 16:9, the biggest resolution you get.
- Save as `assets/concept/trailer/shot01_island.mp4` … `shot06_freeze.mp4`.
  Extra takes: `shot03_friends_take2.mp4` etc. — save every decent take,
  editing picks the best.

## STYLE BLOCK — prepend to every shot prompt

```
Polished mobile-game cinematic in the exact painterly-chibi style of the
reference character images: soft rounded cute baby dinosaurs with oversized
heads and big expressive eyes, rich saturated colors, smooth clean shading,
soft cinematic lighting. Setting: a small round tropical sand island arena
ringed by turquoise sea, palm trees, wooden torches (match the reference
island image). Bright, joyful, storybook mood. No text, no watermark, no UI,
no humans, no realistic dinosaurs.
```

## THE SHOTS

**shot01_island (5s)** — establishing
```
[STYLE BLOCK] Slow aerial push-in toward the little island from over the
sea, gentle waves rolling, palm leaves swaying, torch flames flickering,
seabirds drifting by. No characters yet. Calm before the storm.
```

**shot02_ralph (6s)** — the star
```
[STYLE BLOCK] The little green chibi T-rex (first reference character) walks
happily onto the center of the sand arena with a bouncy waddle, stops, looks
at the camera, and does a tiny adorable roar with his chest puffed out.
Ground-level camera, gentle slow push-in.
```

**shot03_friends (7s)** — the cast arrives (2 dinos + Ralph)
```
[STYLE BLOCK] The green chibi T-rex stands center as two more cute chibi
dinosaurs bound in to join him: [pick 2: the mustard triceratops with the
sage frill / the crimson raptor with the feather tuft / the orange pterodactyl
gliding in]. They gather around him excitedly, bouncing with joy, tails
wagging. Warm friendly reunion energy.
```
(Optional `shot03b` with the other 2–3 dinos if the first take reads well.)

**shot04_bonk (5s)** — the inciting incident
```
[STYLE BLOCK] Close on the green chibi T-rex smiling — then BONK, a coconut
lands square on his head from off-screen. His eyes go wide in comic shock,
a little dizzy-stars wobble, then his expression turns to playful cartoon
determination. Comedy beat, snappy timing.
```

**shot05_brawl (7s)** — chaos
```
[STYLE BLOCK] A huge comedic cartoon brawl erupts on the sand: a big rolling
DUST CLOUD with little dino tails, feet, and heads popping in and out,
coconuts and sticks flying out, stars and impact poofs, palm trees shaking.
Classic cartoon fight cloud, fast and funny, camera shakes slightly.
```

**shot06_freeze (5s)** — the button
```
[STYLE BLOCK] The dust settles instantly: the cute chibi dinosaurs all frozen
mid-action in a pile — one mid-swing with a stick, one biting a tail, one
sitting on another — all turning their heads to look at the camera with big
innocent grins. Held comedic freeze, tiny idle motions only (blinks, a
feather drifting down).
```

## ASSEMBLY (Claude's job — don't worry about it)

- Trailer cut: 01→06 + title-logo end card ("TINY DINOS" + "UP TO 4 PLAYERS.
  ONE ISLAND.") + CC0 music + SFX stings, via ffmpeg.
- Opening-cutscene cut: 01→04 + logo card, ~20s, converted to Theora
  (`opening.ogv`) and dropped at `assets/video/` — the wired player picks it
  up automatically.
- If a shot won't converge after ~3 takes, save the best take anyway and move
  on — editing can trim around a weak middle.

## Gotchas

- Re-state "chibi baby dinosaur, oversized head, cute" in EVERY prompt — video
  models drift toward realistic dinos fast, especially in action shots.
- The brawl shot will try to show clear characters — push the DUST CLOUD
  wording; the gag reads better and hides consistency errors.
- Keep the camera language simple (one move per shot). Multi-move prompts
  produce cuts, and we're doing our own cuts in the edit.
- Watch shot04: coconut physics + facial expression is the hardest ask here.
  It's also the most important beat. Budget the most retries for it.
