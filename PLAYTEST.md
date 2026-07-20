# Playtest #4 — what to check

Run the project (F5 in Godot, or the play button). **Gamepad only** — no
keyboard bindings. It opens on the **title screen**: VERSUS for couch matches,
ARCADE / GAUNTLET for solo, CHARACTERS for the roster/creator screen.

You can playtest everything solo: in VERSUS, unplugged slots default to CPU
(cycle difficulty with P1 **RB** on select — EASY / NORMAL / HARD / BRUTAL).
The bot obeys every rule you do, so it's fair for balance reads.

Controls: **A** confirm/dodge · **X** attack · **B** heavy/back · **Y** block ·
**LB** special · **RB** swap weapon · **LT** pickup · **RT** throw ·
**Start** pause · **Select** emote.

This build is three big swings past playtest #3: a named roster with signature
kits, weapons that drop mid-round instead of being granted, and a color stage
on select. Those are the focus.

## 1. The weapon scramble (the big one)

Nobody spawns armed. A weapon falls onto the island ~3.5s into each round
(telegraphed by a growing landing shadow), then every ~9s after, max 3 on the
ground at once. CPUs race you to them.

- [ ] Does the opening race to the first drop feel like a **fun scramble** or a
      **coin flip**? (If whoever spawns closer just wins it, that's a flaw.)
- [ ] Is the **fist-fight opening** (first ~4s) interesting, or dead time
      spent waiting for the shadow?
- [ ] Does losing the race feel recoverable — can you contest the holder, or
      dodge until the next drop?
- [ ] Do the drops **read**? Shadow → landing → "that's a war hammer, I want
      it" at a glance. Weapons are real objects now (in-world and in-hand).
- [ ] Fast KO rounds can end before any weapon lands (hard CPUs do this on
      Beauty Beach). When it happens to humans, does it feel fine or cheated?

## 2. Do the six dinos feel like six characters?

Every signature (LB) has a mechanical hook now. Play each dino at least one
match — does the hook actually change how you fight?

- [ ] **RALPH** — CHOMP: lifesteal lunge. Do you fish for bites when low?
- [ ] **MAX** (raptor) — DASH CLAW refunds its cooldown on a clean hit. Does
      hit-and-run chaining feel like his game plan?
- [ ] **GUS** (trike) — HEADBUTT CHARGE is armored (can't be shoved out of
      it). Do you charge *through* attacks on purpose?
- [ ] **ACE** (pterry) — SCREECH radial + bow affinity. Does kiting feel
      distinct from the bruisers?
- [ ] **JESSIE** (spino) — SWAN DIVE: does dodge-then-strike feel like a
      deliberate game plan? Is the CANNONBALL splash readable? Is her hip-check
      heavy (biggest shove in the game) fun near ledges?
- [ ] **STEVE** (bronto) — NECK WHIP guard-crushes (2x block drain). Is it the
      answer to turtlers?
- [ ] **FRANK** (anky) — TAIL SMASH is a true radial shockwave, no safe side.
      Does standing next to Frank feel dangerous?
- [ ] Sanity check: nobody should feel like a recolor of anyone else.

## 3. Balance — the sim says the scramble preserved it; do you?

The CPU-vs-CPU sim (60s/match, both arenas) says the drop economy roughly
*kept* the pre-drop balance: everyone sits **37–63%**, with **Ralph on top
(~63%)** and **Max at the bottom (~37%)** — the same shape as before weapons
dropped. Bots aren't humans — these are the calls the playtest decides:

- [ ] Does Ralph feel strong-but-beatable, or oppressive? (He tops the sim,
      but a human can out-space CHOMP in ways the bot can't.)
- [ ] Does Max feel weak, or does his speed win the weapon races in human
      hands? (The bot undervalues scramble speed.)
- [ ] Does grabbing the first weapon beat raw stats? (It should — that's the
      point of the scramble.)
- [ ] **Gus vs Frank** went 0–7 in the sim — the worst matchup on the board
      (armored charge runs straight into the no-safe-side TAIL SMASH). Is it
      hopeless for a human Gus too?

## 4. The select flow

Pick flow per fighter is now DINO → COLOR → READY.

- [ ] Does the COLOR stage read instantly (◀▶ cycles, live preview on your
      sprite), or does it feel like a speed bump before the fight?
- [ ] Is your equipped creator skin the starting selection, as expected?
- [ ] Back out (B) through the stages — does it unwind cleanly?

## 5. Spot-checks (regression sweep, quick pass each)

- [ ] One round each of a few modes (P1 **Y** cycles): SUMO, BOMB TAG, RISING
      TIDE still play correctly with weapon drops in the mix.
- [ ] One 2v2 team match (P1 **X** cycles split) — friendly fire still off,
      team scoring sane.
- [ ] One ARCADE rung and one GAUNTLET wave — solo flow + draft screen intact.
- [ ] Emotes (Select), pause overlay (Start), skins visible in-match.
- [ ] **Audio (new, never heard by human ears)**: menu music on title/select/
      creator, battle music in-match, crossfade between them; UI blips on every
      cursor move/confirm/back; pickup/throw/drop-land/emote sounds. All
      machine-synthesized — flag anything grating or too loud (Music bus is
      -5 dB under SFX by default).

## Capture for each finding

What happened → why it felt bad/good → which knob might fix it (below).

## Live-tuning knobs (change between rounds, no code needed)

- **Weapon drop pacing** — `scripts/main.gd` top: `WEAPON_DROP_FIRST` (3.5s to
  first drop), `WEAPON_DROP_EVERY` (9s cadence), `WEAPON_DROP_MAX` (3 grounded),
  `WEAPON_DROP_TELEGRAPH` (0.8s shadow).
- **Per-dino stats** — `scripts/match_config.gd`, the `DINOS` dictionary: HP,
  damage, speed, block, dodge cost, and all `special_*` numbers per dino.
- **Weapon feel** — `scripts/match_config.gd`, the `WEAPONS` dictionary: dmg /
  kb / range / windup multipliers per weapon.
- **CPU difficulty** — cycle on the select screen (P1 RB); presets live in
  `scripts/dino_ai.gd` `apply_difficulty`.
- **Island hazards** — open the arena scene, click the root `Main` node, see
  the **Hazards** group in the Inspector (lava tick/knockback, falls current).
- **KOs to win** — `Main` node, `kos_to_win` (default 3).

For desktop dev convenience, `project.godot` is set to fullscreen
(`window/size/mode=3`). Set it to `0` for a window.
