# Tiny Dinos — Progress Log

## Session — 2026-06-09 (new game modes)

Four new versus modes, each a themed commit, all reusing the one-arena +
procedural-prop pattern (so every island plays every mode) and the central
`award_ko()` KO hook. Each validated by a throwaway test scene that instances a
real arena + asserts the rules, plus an all-scene headless boot sweep.

**Landed**
- **SUMO** — HP off; hits only shove (blocks/guard-breaks still matter), the edge
  does the KO-ing. First to 5 ring-outs. New `dino.ringout_only` flag gates HP
  loss/death in take_damage/apply_burn/take_reflect.
- **BOMB TAG** — a fused bomb rides one fighter and jumps to whoever they strike
  (pass hook in `take_damage`, so dodged/invuln hits don't count; a short catch
  grace stops ping-pong). Detonates on its holder → costs a life; last dino wins.
  Bomb flashes redder/faster as the fuse burns.
- **THE BEAST** — one crowned juggernaut (+HP pool, +40% dmg, +45% kb, bigger,
  gold glow) banks time; first to 25s crowned wins. KO the beast to steal the
  crown; `become_beast`/`clear_beast` swap the buff cleanly across respawns.
- **RISING TIDE** — the ring-out boundary closes in toward a small final platform
  over ~28s (a single shrink factor in `_in_safe_zone`). Going in the water is
  fatal (ring-out = eliminated, no respawn); HP-KOs just respawn, so you win by
  shoving foes into the tide. Last dino dry wins.

All four auto-appear on the select screen (P1 Y cycles `MODE_ORDER`).

**Wants a live Metal playtest to tune feel:** sumo knockback-to-target count;
bomb fuse length + pass-lock; beast buff strength vs. ring-out-ability and the
25s target (esp. snowball risk in 1v1).

## Session — 2026-06-09 (gauntlet depth)

Deepened the roguelike GAUNTLET across four themed commits — turning it from a
flat upgrade ladder into a run with attrition, build variety, and cross-run
stickiness. Each change validated headlessly (throwaway test scenes + full-scene
boots; no errors).

**Landed**
- **Mechanic upgrades** — VAMPIRE (lifesteal), SPIKED HIDE (thorns), EXECUTIONER
  (+dmg vs low-HP foes). `dino.gd` reads `effect` keys into `run_*` flags applied
  in `try_hit` / `take_damage`.
- **HP carries between waves** + heal upgrades. Wounds persist wave-to-wave (round
  respawns still refill); each wave heals a 20% breather. FIELD MEDIC (instant
  50%) + SECOND WIND (+20%/wave, stacks). Draft screen shows current HP/max.
- **Cross-run meta-progression** — new `MetaSave` autoload (user:// ConfigFile)
  tracks best wave; milestone unlocks auto-apply: wave 3 → EXTRA DRAFT (4 cards),
  wave 6 → VETERAN START (begin with an upgrade), wave 10 → HARDENED (+20 HP).
  Title shows best wave; RUN OVER reports best + newly-unlocked perks.
- **Solo starting-island pick** — P1 UP/DOWN chooses the opening island in
  gauntlet/arcade setup (gauntlet randomizes after wave 1; arcade rotates the
  ladder to open there).

**Possible next:** more mechanic upgrades (dash-on-KO, projectile riders);
meta currency/shop instead of pure milestones; per-run modifiers/curses for
higher-stakes waves; live in-engine Metal playtest of a full run.

## Session — 2026-06-09

Follow-up to the review pass: a cleanup + in-engine visual verification of the
three player-facing changes (run on the real Metal/OpenGL renderer, not just
headless — screenshots captured and inspected).

**Landed**
- **Removed the scrapped hand-drawn-Ralph experiment** — `art_preview.{gd,tscn}`,
  `trex_handdrawn.png`, and the dormant `SHEET_HD` const + `trex_hd` ANIM_LAYOUTS
  entry. Nothing in the game referenced them.
- **Brightened the charging special pip** — the dim olive read as muddy in-game;
  now a clearer muted gold, still distinct from the brighter ready color.

**Verified in-engine**
- **Special-cooldown pip** ✅ — charging state (forced 50% CD) shows a half-filled
  muted-gold square at the inboard end of the block bar; ready state shows a full
  bright-gold square. Placement mirrors correctly on left/right corners.
- **CPU difficulty selector** ✅ — `CPU DIFFICULTY: NORMAL (P1 RB)` renders under
  the island line (and hides in an all-human lobby); RB cycles it live
  (NORMAL → HARD confirmed via the real handler).
- **AI island-shape fix on Purple Fields** ✅ — traced two HARD CPUs for ~1100
  frames. They roamed up to **y≈233–302**, above the old `safe_rect` top (y=325)
  and far above the old margin-limited band (~y 405–595) — i.e. they now use the
  upper oval the inscribed rect walled them out of. p1 stayed 100% inside the
  oval, p2 97% (brief knockback excursions resolving as normal ring-outs, not
  steering failures).

### Balance + AI pass (market-research-driven)

Kicked off a roadmap from a market/PvP-design study (couch brawlers live on:
easy-to-learn, fast restart, failure-is-funny, *and* a solo-vs-CPU hook for
streamability since the game is local + gamepad-only, no online). Build order:
**balance → smarter CPU → modes → solo spine.** Online deferred but designed-open.

**Balance** (`match_config.gd`) — the combat has no true combos (a 0.15s i-frame
gates them), so strength = DPS traded against HP. Raptor's DPS only *tied* the
tanks while having the least HP, so it lost every even trade — the glass cannon
wasn't a glass cannon. Buffed Raptor's damage to make it the clear DPS king
(light 12→15, heavy 22→26, dash-claw 20→25); trimmed Bronto 165→158 HP (it was
double-dipping highest-HP + war-hammer).

**Smarter CPU** (`dino_ai.gd`) — the bot only reacted defensively; now it:
- **Whiff-punishes** — detects the target locked in attack-recovery / guard-break
  (new `dino.is_recovering()`) and commits the biggest move that reaches.
  `punish_chance` knob: EASY 0.20 → HARD 0.90.
- **Pressures** — stays glued through the target's hit-i-frames so the next swing
  lands the instant they wake (`pressure` knob), and a gated gap-closer dodge.
- **Plays its archetype** — a `skittish` factor from stats (fast+fragile = Raptor)
  makes it hover at range and peel off after each hit (hit-and-run) instead of
  brawling. CPU Raptor now *plays* like a Raptor.

**Self-tested via a headless CPU-vs-CPU sim** (`scripts/tools/sim_ai.gd`, a dev
tool — pits two bots, tallies KOs over a wall-clock window across matchups +
arenas). Findings: archetype AI flipped Raptor-vs-tank in a box from losses to
wins (Bronto 0–3→1–0, Anky 0–2→2–1); T-Rex now hard-counters Raptor because
Chomp is a lunge-gap-closer *with lifesteal* that eats the kite — a genuine
rock-paper-scissors layer, left intentional. T-Rex top / Anky strong / Bronto
mid; Raptor's true ceiling needs human playtests (the bot doesn't aim ring-outs).

### Game modes (stock / KotH / egg grab)

Three new modes on top of best-of-rounds, picked on select (P1 **Y** cycles
`MODE: …`). All four run on the same arena; the hill and eggs are built
**procedurally in `main.gd`** so every island plays every mode with no scene edits.
- **Last Dino Standing** (`stock`) — each fighter has `STOCK_LIVES` (3); a KO costs
  a life; out of lives = eliminated (hidden → AI auto-ignores it via the existing
  `visible` check); last one in wins.
- **King of the Hill** (`koth`) — a procedural ring at the safe-centre; the lone
  fighter inside banks time, contested/empty scores nobody; first to
  `KOTH_TARGET` (20s) wins. Ring glows the holder's colour.
- **Egg Grab** (`eggs`) — eggs trickle onto random safe ground; walk over one to
  bag it; first to `EGG_TARGET` (6) wins. KOs just respawn.

Flow: `award_ko` branches by mode (`_award_ko_stock` / KO-bounty / `_award_ko_rounds`);
KOTH+EGGS keep `round_active` true (continuous, no interstitial). Score HUD is
mode-aware via `_score_text` (LIVES n / `n s / 20s` / EGGS n / 6). CPUs now play
objectives — `dino_ai._apply_objective` drifts them to the hill / nearest egg when
not mid-exchange, so solo-vs-CPU party matches actually contest the goal.

Verified: headless mode smoke-sim reached winners for rounds + stock + eggs (koth
resolves too; two equal HARD bots stalemate the hill, a human breaks it). Live
render (real Metal) confirmed the hill ring + mode score HUD draw correctly (over
background, under fighters — fixed a z-order trap by inserting props before
Player1 rather than via z_index). Roadmap: [[project_tiny_dinos_roadmap_2026_06_09]].

### Arcade ladder (solo spine)

The commercial hook: a single-player gauntlet a lone player can pick up, stream,
and demo. New **ARCADE** entry on the title (PLAY renamed **VERSUS**; the five
items are re-stacked in code, no .tscn surgery). Picks your fighter on the select
screen in a constrained "arcade" mode (`MatchConfig.arcade_setup`): only P1 is
configurable, the p2 slot becomes a fixed **GAUNTLET** (CPU, auto-ready, not
host-editable); the versus-only selectors (island / +opponents / difficulty /
mode) are hidden.

Ladder (`MatchConfig.start_arcade` / `_build_ladder` / `arcade_advance`): every
dino but yours, difficulty ramping easy→easy→normal→normal→**HARD final boss**,
each rung on a different island. `main.gd` drives the between-rung flow —
`_end_match_arcade` shows STAGE CLEARED → next foe / CHAMPION / DEFEATED (reached
stage N), and START routes through `_arcade_continue` (advance reloads the next
island; champion/gameover clears `arcade` and returns to the title). Rungs are
best-of-2 (`kos_to_win` overridden to 2 in arcade).

Verified: headless functional sim built the 5-rung ladder correctly (anky HARD
boss, islands rotating) and ran a rung to resolution with `arcade_end` set + the
kos override applied. Live renders confirmed the title (5-item menu fits) and the
arcade select (GAUNTLET panel, hidden selectors) both draw clean.

### Roguelike gauntlet (solo spine v2)

The deeper solo mode: an endless, escalating run with **upgrade drafts between
waves** (permadeath). New **GAUNTLET** title entry (six items now; menu spacing
shrinks to fit). Reuses the arcade solo-setup (generalised select `arcade`→`_solo()`
with a `gauntlet` flag): pick your fighter, the p2 slot is the CPU opponent.

- **Upgrades** (`MatchConfig.UPGRADES`, 12) are pure data — `{stat: ["mul"|"add", v]}`.
  `dino._apply_run_upgrades()` applies them on spawn to the player only; they
  **stack** across the run. Foes scale instead (`gauntlet_enemy_hp/dmg_mult` grow
  ~8%/4% per wave) so the run stays threatening past the HARD difficulty cap.
- **Wave flow** (`main.gd`): each wave is a single decisive KO (`kos_to_win`=1) vs a
  random foe on a random island, difficulty easy→normal→HARD. Win →
  `_end_match_gauntlet` opens the **draft** (3 random upgrade cards, left/right +
  A, built in the HUD layer); pick → `gauntlet_next_wave` → reload. Lose → RUN
  OVER (reached wave N, upgrades taken) → START to title.

Verified: headless pipeline test confirmed upgrades stack on the player (trex
150→185 HP, 25→31 dmg with two cards) and enemy HP scales per wave (×1.0 wave0,
×1.8 wave10); live renders confirmed the 6-item title and the draft overlay
(header/cards/prompt) draw clean. Roadmap: [[project_tiny_dinos_roadmap_2026_06_09]].

### CPU ring-out aiming (open arenas)

Fixes the open-arena stalemate (two bots circling Iciest Age forever, never
committing a ring-out). The knockback shoves the victim along the attacker's
facing, so on a lethal-edge arena (`ledge_kill_enabled` or `drown_off_floes`) the
AI now: computes an outward push dir (arena centre → target), slides to the
**centre side** of the target so its facing points off-stage, stops retreating
when a ring-out is set up, and throws its **hardest-knockback move** (special/
heavy) when lined up at the edge. `dino_ai._ringout_intent/_ai_center/_near_edge`.

Verified headless: two HARD bots that used to circle Iciest Age indefinitely now
land ~6 KOs / 35s there (and resolve Beauty Beach cleanly) — the stalemate is
gone. Roadmap: [[project_tiny_dinos_roadmap_2026_06_09]].

### CPU ring-out self-preservation (fragile dinos)

Follow-up to ring-out aiming: a glass cannon (Raptor) was just trading shoves it
always loses to heavy dinos. Now `_ringout_intent` also flags when WE are near the
edge with the foe lined up to push us off (`threatened`); a skittish dino in that
spot bails toward centre + dodges inward instead of trading knockback. Restores
the design pillar that fast/fragile dinos earn ring-out stages.

Verified headless: raptor-vs-bronto on Iciest Age went 0-3 -> **3-4** (now
competitive, where the floe gaps reward mobility). Beauty Beach still tank-favored
0-4 — Bronto's hammer launches Raptor from mid-stage, a CPU-doesn't-dodge-heavies
issue (a human dodges the telegraphed swing), noted for a future evasion pass.

## Session — 2026-06-08

Source-wide review pass → four worktrees, all merged to master (headless-validated
across every scene).

- **CPU now plays the island, not a box** *(fix/ai-island-shape)*. Ledge-avoidance
  + throw-safety + projectile/weapon culling test the painted `safe_polygon`
  instead of the inscribed `safe_rect`. Fixes bots hugging a thin band on
  **Purple Fields** (its rect was a narrow strip of the real oval).
- ✅ **vs-CPU Phase 2 — CPU difficulty (Easy / Normal / Hard)** *(feat/cpu-difficulty)*.
  Presets in `dino_ai` (`apply_difficulty`), carried match-wide on
  `MatchConfig.cpu_difficulty`, applied per CPU at spawn. Host cycles it with **RB**
  on the select screen; NORMAL = the prior hand-tuned defaults. (Smarter-AI half of
  Phase 2 partly served by the island-shape fix; deeper tactics still open.)
- **Special-cooldown indicator** *(feat/special-cooldown-hud)* — the DESIGN `[?]`
  is closed. A pip by each block bar fills as the signature special recharges and
  glows gold when ready (code-built, so all 6 arenas inherit it).
- **Refactor** *(cleanup/sprite-frames)* — `dino.gd` gains `build_sprite_frames` /
  `first_frame` statics; the picker, title, and character screen now build dino
  art through them instead of 4 copy-pasted loops.

> Next candidates flagged but not built: deeper CPU tactics; then the bigger
> beyond-melee systems (ranged/Bow, power-ups, status kits, grab/throw).
> (Dead hand-drawn-Ralph assets — since removed, see 2026-06-09.)

## Session — 2026-05-22

### Where we are now
- **6 dinos**, **5 islands** (all pixel-art, consistent theme).
- Select screen overhauled: shows the **real in-game art** for both dinos and
  islands (pick == play), dinos face each other, names sit cleanly below.
- **Solo vs-CPU is a validated hit** (playtest #3) — you can now fight multiple
  computer opponents in a free-for-all.
- Game runs clean (headless-validated + launches with no errors).

### What we accomplished this session
**Fixes & feel**
- **Bronto facing bug** fixed — sprites drawn facing left now flip correctly
  (general `faces_left` flag in `dino.gd`).
- **Sunny Springs reworked**: reclaimed the right stone plateau (was instant-kill
  water over solid-looking ground), the **ruins now block movement**, and the
  **river slows you instead of killing you**.

**Select screen**
- Rebuilt as a versus screen: **island gameplay background** as the backdrop,
  each player's **actual dino sprite** shown big and **facing center**, names in a
  clean band below (no more overlapping bars).
- Locked the art direction: **pixel sprites are the character/island art** in the
  picker; the hand-drawn `assets/concept/` art is concept/marketing only.

**vs-CPU**
- **Right stick** (P1) cycles the **CPU opponent's dino** (keyboard fallback: `V`).
- **Multiple CPU opponents**: host presses **LB / B** to add bots (1-v-2, 1-v-3).

**Designed + built, then cut**
- **Iciest Age → "Frozen Floes"** ice-floe ring-out arena: fully designed
  (`DESIGN.md §6`), built (`arena_floes.tscn` + a `Floe`/drown-grace + floe-hop
  mechanic in `dino.gd`/`main.gd`). **Cut from the roster** because its flat-vector
  look clashed with the pixel islands. **Files kept** — revivable as a pixel reskin.

### What we have to look forward to (goals)
**vs-CPU expansion** (you greenlit all four; phased)
- ✅ Phase 1 — more CPU opponents *(done)*
- ⏭️ **Phase 2 — Difficulty (Easy/Normal/Hard) + smarter AI** *(next; `dino_ai.gd`
  already exposes the knobs)*
- 🔜 Phase 3 — CPU teammates / team modes

**Select screen — Stage 2 (still queued)**
- **Characters tab**: a roster screen with each dino's stat **bars** (HP / Speed /
  Power / Atk-Speed) + role tag, and the weapons with their stats + art. Goal:
  make **fast/fragile dinos read as worth picking** (surface Speed, not just HP).

**Beyond-melee combat** (all greenlit — see `DESIGN.md` + memory roadmap)
- **Ranged** (lowest-friction; projectile path half-built, Bow stubbed)
- **Power-ups / map pickups**
- **Elemental / status-effect kits** (freeze, poison, stun…)
- **Grab / throw** — with **weapons attached to the hand**, grab with the *other*
  hand *(open Q: visual-only, or two-handed weapons can't grab?)*
- **Traversal / mobility specials** (grapple, burrow, glide) — also helps fragile
  dinos earn their pick

> Resume hint: say "continue the CPU work" to jump to **Phase 2**.
