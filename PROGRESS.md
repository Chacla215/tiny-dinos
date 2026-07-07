# Tiny Dinos — Progress Log

## Session — 2026-07-06 (islands restyled + per-dino depth + attack sync)

Three themes landed on `feat/feel-sweep`, each atomically committed + verified.

- **Islands restyled to painterly (`1462cfe`).** The 5 remaining pixel arenas
  (lava/falls/springs/purple/floes) re-rendered to the painterly beach/trailer
  look via nano-banana image-to-image (composition-locked to each current bg, so
  collision/spawns/safe_rect need no re-trace — pure art swap). New tool
  `integrate_restyle_bgs.py` fits each 16:9 restyle to 1536x864 + bakes the
  arena's own title banner. Verified in-match: fighters read on every floor incl.
  dark lava + pale ice. Whole game now one painterly world.
- **Per-dino signature passives (`cde3fd8`).** Real systemic depth — each dino
  gets a persistent passive beyond stats + its one special, all hooking the
  SHARED input/damage code (CPU inherits free): RALPH combo_king (light chains
  speed up), MAX dash_cancel (cancel recovery into dodge — also fixed a latent
  can_dodge gap), GUS charger (heavy super-armor), STEVE bulwark (jabs can't
  stagger), JESSIE flighty (hit refunds dodge cd), FRANK spikeback (reflects
  blocked dmg). Surfaced on the character screen's move card. Verified 12/12 by
  `scripts/tools/sig_check.gd`.
- **Attack swing synced to hitbox (`61cacfb`).** The restyle's 5-frame attack
  clip truncated on fast dinos (raptor light 0.14s showed ~2 of 5 frames). Now
  the clip's speed_scale stretches to fit windup+active, so the swing always
  completes + its strike frame lands on the live hitbox. Hitbox timing itself
  was always correct (driven by attack_active); this is the visual sync.

## Session — 2026-07-06 (chibi restyle rolling: raptor + trike integrated)

The art program is live and Charlie is generating. Driven by `PASTE_ME.md`
(14 assembled prompts) — Charlie pastes each winner into chat, Claude saves +
bakes + wires + screenshots + commits per dino.

- **Raptor "Max" (`9b26ba3`).** Chibi restyle integrated. The restyle turned
  him from a horizontal-lean body into an upright chibi biped, so the old
  `PART_DEFS_BY_DINO["raptor"]` rig override (which now sliced his FACE as the
  "tail") was removed — default chibi cut fits. Faces right natively; smooth
  sheet cell 133x168.
- **Trike "Gus" (`dd0b8f1`).** Chibi restyle integrated. Chunky quadruped,
  sage frill, chipped right brow horn; smooth sheet cell 134x168, faces right.
- Both verified via in-match beach screenshots next to Ralph. Learned:
  fighter sheets are baked **--smooth** (painterly, ~1400 colors/patch), NOT
  --pixel; re-check the rig part-cut after each restyle in case the body plan
  changed.

> Resume hint: `PASTE_ME.md` order — done: raptor(1), trike(2). NEXT: pterry(3,
> clipboard was left here), bronto(4), anky(5), Beauty Beach island(6), trailer
> shots(7-12), ralph motion pilot(13-14). Per-dino recipe in memory
> [[seedance-motion-pipeline]].

## Session — 2026-07-05 (Seedance pilot: engine half + trailer spine)

Continued the Seedance work while clips are still pending, and Charlie added a
new goal: a **full trailer** (Ralph + a cast that's ACTUALLY cute-cuddly like
him — his words: the current five dinos don't capture it) that doubles as the
**opening cutscene**.

- **Motion-sheet engine support (`6d5c898`).** `dino.gd`: `"motion": true`
  layout flag switches a dino from the DinoRig to its video-baked sheet
  (per-dino A/B); state-priority anim chooser (ko > hit flinch > dodge >
  heavy/attack > walk/idle), every state guarded by `has_animation` so old
  3-anim sheets and partial pilot sheets degrade cleanly; `hit_anim_timer`
  armed in `take_damage`. Validated: synthetic ralph motion sheet wired temp,
  10+ min of headless CPU matches error-free + arena screenshot confirmed
  sheet render/scale/flip; temp art then reverted (code is inert until a real
  motion layout is pasted).
- **Trailer spine (`88c2ba4`).** `scripts/tools/trailer_prompts.md`: 6-shot
  storyboard (~45s) — island push-in, Ralph entrance, friends arrive, coconut
  bonk, cartoon brawl-cloud, freeze-frame gag — shots 1-4 + logo = the ~20s
  opening cut. **Phase 0 = the chibi restyle** (`dino_chibi_restyle_prompts.md`):
  the restyled heroes are the trailer cast AND fix the roster brand.
  `scenes/opening.tscn`+`opening.gd` is now the boot scene: plays
  `assets/video/opening.ogv` when it exists (gamepad-skippable), boots straight
  to title until then (verified headless).

Later same session: a research sweep (GitHub + web) hardened the pipeline —
`gen_dino_motion.py` bg key is now connected-region flood-fill (FrameKit's
smart-chroma idea; protects bg-colored bellies) and `trailer_prompts.md`
gained proven Seedance consistency rules (never paraphrase character lines,
stress-test heroes on 3 bgs, first/end-frame chaining). Party Animals logged
as the closest commercial reference (cute physics brawler with a chibi dino).
Charlie then extended the restyle to the ISLANDS: `arena_bg_restyle_prompts.md`
(image-to-image, same composition so collisions survive, Beauty Beach pilot
first) + `CHARLIE_TODO.md` at root — his 4-step art-program checklist (dinos →
one island → trailer → motion clips).

> Resume hint: everything is now blocked on Charlie generations, in the order
> of `CHARLIE_TODO.md`: (1) 5 restyled heroes, (2) Beauty Beach restyle pilot,
> (3) trailer shots, (4) motion clips. All Claude-side tooling is built and
> validated; when Charlie says "I did step N", pick up from that kit.

## Session — 2026-07-04 (video-gen animation pipeline — Seedance 2.0)

Charlie greenlit using **Seedance 2.0** (image-to-video) to upgrade graphics +
fluidity. Root insight: every in-match frame today is a bake-time transform of
ONE still hero PNG (9 frames/dino: idle 2 / walk 4 / attack 3; block, dodge,
hit, KO have **no art at all** — just code effects). Video-gen from the same
heroes gives real motion and the missing states.

- **Prompt kit** `scripts/tools/dino_motion_prompts.md`: framing block (locked
  camera, in-place motion, flat keyable bg) + per-species look reminders + 8
  motion blocks (`idle walk attack heavy hit ko dodge win`). 4s clips suffice.
  Clips land at `assets/concept/<dino>/motion/<anim>.mp4`.
- **Bake tool** `scripts/tools/gen_dino_motion.py`: ffmpeg frame extraction →
  soft bg key (same ramp as the hero bake) → per-clip union bbox (keeps lunges/
  bounces) → one global scale + shared feet baseline (no pop between anims) →
  `assets/sprites/<dino>_motion.png` grid + printed ANIM_LAYOUTS block.
  `--trim/--pick/--frames/--fps/--pixel` for hand-tuning. **Validated
  end-to-end with synthetic clips** (fake Seedance footage built from the ralph
  hero) — keying, alignment, and the printed Rect2 block all check out.
- Engine side is nearly free: `dino.gd build_sprite_frames` already iterates
  arbitrary layout keys, so new anims auto-build once rects exist; the code
  change is *playing* hit/ko/dodge/win at the right moments (queued until real
  frames exist).

> Resume hint: **PILOT is blocked on Charlie** — generate ralph `walk` + `attack`
> per the prompt kit, drop them in `assets/concept/ralph/motion/`, then bake +
> wire + in-game check before batching the roster. Known open item: baked-in
> contact shadows survive the key (may double with in-game shadow — check in
> pilot; suppression can be added to the tool).

## Session — 2026-06-15 (FIRST hands-on playtest — feel fixes + real music)

Charlie played the build on a controller (the long-deferred feel check) and fired
rapid feedback; each item shipped as its own PR off master, all merged + boot-clean.

- **Title menu overflow (PR #14, `3f46687`).** Phase 3 grew the menu to 8 items;
  rows overlapped and the controls prompt covered HOW TO PLAY. `title.gd` now sizes
  the menu to the item count (spacing fits the band under the subtitle, font/outline
  derive from spacing — 36px when few, ~24px at 8) and parks the prompt below the
  last row. Verified by an in-engine title snapshot.
- **Floppy feel + dash (PR #15, `d7ba2cb`, commit `6200f13`).** "Ice-skating rink":
  tightened floppy locomotion (accel 850→1500, friction 360→620; coast ~0.89s→~0.52s,
  glide ~234→~137px). "Press B and fly off the map": self-dash lunges (dash_claw /
  headbutt charge) now bleed at a FIXED rate (`DASH_DECEL`, new `dash_active` flag)
  regardless of floppy — before, the lunge rode floppy's low friction ~1000px off the
  stage; now a ~300px gap-closer, knockback overrides it. **These constants are a
  first pass — still Charlie's ear/hands to confirm.**
- **CPU auto-pick + team colours (PR #15, commit `5399555`).** Versus CPUs now pick a
  random dino + colour and auto-ready ("CPU READY"); host only configures their own
  fighter (season teammates stay host-picked). Team mode: the whole side wears its
  team colour (RED/BLUE) in match so allies/teams read clearly. FFA untouched.
- **Bomb Tag bug (PR #15, commit `ec05a56`).** `award_ko` had no `bombtag` case, so a
  shove-off-the-edge fell through to the ROUNDS win path → premature "RALPH WINS". Now
  neutral (bounty only); only the bomb costs lives. Bomb Tag was already the
  elimination game (3 lives → out → rest fight on → last standing wins) — confirmed.
- **Real music (PR #16, `6429835`).** The synthesized chiptune (esp. the intro) was
  grating. Replaced both tracks with composed **CC0** loops by Juhani Junkala
  (OpenGameArt): menu = "Sunshine Coast", battle = "Army Approaching". Audio autoload
  loads `assets/music/*.ogg`, forces `loop=true`. Placeholder `.wav`s dropped;
  `gen_music.py` kept as tooling but no longer feeds the game (CLAUDE.md updated).
  **No one has HEARD it (headless = no audio)** — vibe/mix is Charlie's call; 5 more
  tracks in those packs to swap from. SFX still synthesized (Charlie didn't ask to
  change them this pass).

> Resume hint: master clean, no open PRs. NEXT UP still the **chibi restyle** (blocked
> on Charlie's 5 hero PNGs). Open feel calls now that it's been played once: confirm
> the new floppy tightness + dash distance, and the music vibe/volume. See memory
> [[audio-sourcing-pipeline]] for how the CC0 music got wired.

## Session — 2026-06-15 (Phase 3 merged + Season probes retired)

- **PR #12 merged → master** (`2925da1`, fast-forward). Season Mode Phase 3 —
  trophies, coins/shop, divisions, squad/fatigue, 3v3 — is now on master; the
  `feat/season-phase3` branch is deleted (remote + local). Headless boot clean.
- **Deleted the Season throwaway probes** (Charlie's standing TODO, called now —
  the human-played feel check is still deferred but he chose to retire the probes
  regardless): `season_test`, `sixplayer_test`, `season_shot` (script + scene each).
  **Kept** `grab_test` (functional grab/throw regression guard) and `sim_ai`
  (balance matrix). Headless boot clean after removal.

> **NEXT UP — CHIBI RESTYLE.** Ralph is cute painterly-chibi; the other 5 dinos
> (max/gus/jessie/steve/frank) drifted too detailed/realistic. Restyle them toward
> Ralph's chibi bar — the kit's intended brand (memory `dino-chibi-restyle-plan`).
> Prompts are ready in `scripts/tools/dino_chibi_restyle_prompts.md`. **Blocked on
> Charlie generating the 5 `<dino>_hero.png`** (Claude can't gen painterly images —
> memory `art-generation-pipeline`); once one lands in `assets/concept/<dino>/`,
> Claude rebakes via `gen_ralph_fighter.py <dino>` (+`--parts`) and wires
> ANIM_LAYOUTS into `dino.gd`.
>
> Also open (Charlie's call, no rush): a **human-played season** feel check
> (divisions pacing, fatigue feel, 3v3 readability — never hands-played). Master is
> clean, no Season probes left, no open PRs.

## Session — 2026-06-15 (SEASON MODE Phase 3 — ALL 5 FEATURES COMPLETE on `feat/season-phase3`)

Charlie greenlit ALL of Phase 3 ("we will be making all of it") and told Claude to
build it autonomously, making the embedded design calls. Branch `feat/season-phase3`
(off master after #11), pushed; **draft PR #12**. **All 5 features done + committed
+ validated.** Final state: full headless boot clean; season_test 38/38, sixplayer_test
13/13, grab_test 20/20. STILL no human-played season — the deferred feel check.

**DONE (committed, validated headless + snapshots):**
- **1 — MetaSave foundation + TROPHY CABINET.** New persisted fields: `coins`,
  `owned_skins` (bought EPIC skins), `continue_tokens`, `best_division`,
  `matchdays_won`, `season_titles_by_division[3]`. All additive ConfigFile keys.
  `scenes/trophies.tscn` + `trophies.gd` = read-only cabinet (titles, highest
  division, matchdays, best wave, coins, per-division championship breakdown). New
  TROPHIES title entry.
- **2 — COIN ECONOMY + SHOP.** Earn coins per matchday + championship bonus (both
  scale with division). `scenes/shop.tscn` + `shop.gd`: buy coin-priced EPIC skins
  (VOID 120 / GOLDEN 200; `skin_unlocked` now checks `MetaSave.owns_skin` for any
  SKINS entry with a `cost`) + CONTINUE TOKENS (80). A season gameover offers
  "A USE CONTINUE TOKEN — REVIVE" to replay the failed matchday. New SHOP title entry
  (shows coins). Title menu now 8 items (re-stacks, tight but clean).
- **3 — DIVISIONS (ROOKIE/PRO/LEGEND).** `start_season(team, size, division)` (the
  dead start_island arg is gone). Division shifts the whole schedule's difficulty
  floor up `DIFF_LADDER` (PRO +1, LEGEND +2, clamp BRUTAL) + scales coin payouts.
  Winning the finale promotes (`record_season` bumps `best_division`); replay any
  unlocked division. Select screen: freed UP/DOWN picks DIVISION (mode label +
  hint). Banners/standings name the division. `season_test` 23/23.

**DESIGN CALLS made (so a cold resume keeps them):** coins are cosmetic + soft-safety
only, never pay-to-win (sinks = EPIC skins + continue tokens). Divisions reuse the 5
RIVAL_TEAMS; the challenge comes from the difficulty-floor shift, not new fixtures.

- **4 — PERSISTENT SQUAD + FATIGUE** (3 sub-commits 4A/4B/4C). Your season is a SQUAD
  = fielded fighters + 1 reserve (`season_squad` `[{dino, fatigue}]`, `season_field`
  indices, `SEASON_BENCH` 1). Fielded fighters tire each matchday (`_age_squad`, cap
  `FATIGUE_MAX` 4); benched recover. dino.gd applies a mild capped dip at spawn (-6%
  speed / -5% dmg per point, floor 0.70) to your fielded side. Seating is slot-based
  (`season_humans` — pads fill low slots, so rotating the CPU reserve never drops a
  human). Pre-season RESERVE pick on the select screen (P1 RB). Between matchdays a
  "CHOOSE WHO RESTS" rotation overlay (after the perk draft) fields all-but-one;
  `season_advance(age)` decoupled so it ages once. season_test 30/30.

- **5 — 3v3+ (engine lift)** (3 sub-commits 5A/5B/5C). Up to SIX fighters, no per-arena
  scene edits. 5A: `_ensure_extra_players` clones Player4 → Player5/Player6 at runtime
  when `player_count` needs them (pid/name set before tree entry); `_layout_spawns`
  seats six in two team rows + overrides each dino's `spawn_point`; PLAYER_IDS/COLORS/
  TINTS + default dicts + input actions extended to p5/p6. 5B: `_build_extra_huds`
  code-builds mid-edge HUD corners for p5 (left) / p6 (right) named so the existing
  HUD code drives them; PIP_POS + plate rects extended. 5C: `start_season` clamps to
  3; `_apply_season_matchday` generalized to seat 2/4/6 (side A = p1..pN, foes = next
  N, pads fill low slots via `season_humans`); RIVAL_TEAMS got a 3rd dino each; select
  TEAM SIZE cycles 1v1/2v2/3v3. Fix: PLAYER_IDS→p6 broke select's 4-key per-slot loops
  → added `SLOT_IDS=[p1..p4]`. sixplayer_test 13/13, season_test 38/38.

> **Phase 3 COMPLETE.** Open items: (1) mark draft PR #12 ready + merge when Charlie's
> happy; (2) a human-played season feel check — divisions pacing, fatigue feel, 3v3
> readability (all snapshot/sim-validated, never hands-played); (3) per the standing
> TODO, delete the throwaway probes (`season_test`, `season_shot`, `sixplayer_test`)
> once the feel check passes. NOTE: kept the probes through the feel check rather than
> deleting on landing — 3v3 is brand new and unplayed, so the regression coverage earns
> its keep until Charlie confirms.

## Session — 2026-06-15 (merge backlog + balance re-check + probe cleanup)

Shipped the branch backlog, re-validated solo balance under default-floppy, and
retired the throwaway probes now that floppy + the rig are locked.

- **Merged the backlog.** PR #6 (Season Phase 2 — rival teams / standings / perk
  draft) → master. Then rebased `feat/arena-readability` onto post-#6 master
  (PROGRESS conflict resolved; code auto-merged), validated (headless clean +
  grab_test 20/20, diff readability-only), and merged it as PR #7.
- **Solo balance re-validated under default-floppy** (the open "sim-tuned balance
  needs re-checking" item). Re-ran `sim_gauntlet` on master: **no regression** — the
  gauntlet resolves at every wave. Confined (HP) arenas bite mid-run (foe peaks ~44%
  at wave 8); ring-out arenas stay flat-ish because floppy kills by throwing foes off
  the edge (bypasses HP scaling) — the *expected* floppy shape, not a bug. Wave-16
  dips are single-sample noise (the tool's own caveat). The real "is it fun" check
  still needs a controller.
- **Deleted the throwaway probes** (two chore PRs, headless-clean after each):
  - #8 — floppy feel/balance probes: `floppy_walk_probe`, `floppy_feel_probe`,
    `floppy_cadence_probe`, `floppy_ko_probe`, `sim_gauntlet` (script + scene each).
  - #9 — rig probes: `rig_test`, `rig_dynamics_probe` (script + scene), `montage_rig.py`;
    fixed the stale `rig_test` mention in the chibi-restyle prompt kit.
  - **Kept** `grab_test` (functional regression guard for the grab/throw chain),
    `sim_ai` (general balance matrix), `season_test`/`season_shot` (Season Phase 3
    still open), `arena_shot`/`ui_shot`, and all the `gen_*`/`bake_*` art-pipeline tools.
  - **TODO (Charlie's standing call):** delete `season_test`/`season_shot` once
    **Season Phase 3 lands** — they're the last throwaway probes still in flight.

> Resume hint: master is clean, no open PRs. Open work (all need Charlie):
> (1) **chibi restyle** — blocked on Charlie generating the 5 `<dino>_hero.png`;
> drop one in `assets/concept/<dino>/` → Claude bakes (`gen_ralph_fighter.py <dino>`
> +`--parts`) + wires ANIM_LAYOUTS; (2) **human-played season** + **floppy feel pass**
> — controller-only feel calls, not probe-able.

## Session — 2026-06-15 (arena readability + art-consistency direction)

Readability follow-ups + an art-direction decision, then branch cleanup.

- **Arena readability finished**: (1) **play-surface calm** — a soft dark radial over
  the play area (per-island `PLAY_CALM` strength; strong on busy Springs/Purple, light
  on Lava/Ice) so the busy painterly centres recede and fighters pop; (2) **grounded
  contact shadows** — the old separation halo sat in the body and looked like a
  float-glow; reworked into a flat dark oval cast at the feet (the 7.6 footing line).
  Both look-only, on top of the existing art. Validated by arena snapshots +
  grab_test 20/20.
- **Art-consistency call:** Ralph is cute painterly-CHIBI; the other 5 drifted too
  detailed/realistic. The kit's INTENDED style is Ralph's chibi, so Charlie chose to
  **restyle the 5 others toward Ralph**. Prompts ready in
  `scripts/tools/dino_chibi_restyle_prompts.md`. **Blocked on Charlie generating the 5
  heroes** (Claude can't gen painterly images — memory `art-generation-pipeline`); once
  a `<dino>_hero.png` lands, rebake via `gen_ralph_fighter.py <dino>` (+`--parts`) and
  wire ANIM_LAYOUTS into `dino.gd`.

> HANDOFF (branches/PRs after this session):
> - **PR #6 (`feat/season-phase2`) MERGED** — rival teams, standings, perk draft now on master.
> - `feat/arena-readability` rebased onto post-#6 master → pushed + PR'd.
> - master has: floppy-default, gauntlet rebalance, Season Phase 1+2.
> - **Next:** run the 5 chibi restyle prompts → rebake (blocked on Charlie's art);
>   re-validate solo arcade/gauntlet balance under the now-default floppy model;
>   STILL no human-played season/floppy session (deferred feel).

## Session — 2026-06-15 (SEASON MODE Phase 2 — identity + depth)

Planned (plan mode) + built behind `feat/season-phase2`. Three sub-steps, each
committed/validated, building on Phase 1.

- **A — Named rival teams + home islands.** `MatchConfig.RIVAL_TEAMS` (5 themed
  teams: BEACH BRAWLERS → TIDE RIDERS → SPRING STAMPEDE → FROST FANGS → MAGMA TYRANTS,
  the lava boss). `_build_season` now draws one rival per matchday on its **home
  island** in escalating order (fixed fixtures — no island pick; the campaign decides
  where you play, so the select start-island line is gone for season). Banners +
  NEXT lines name the rival ("MATCHDAY 2: KING OF THE HILL vs TIDE RIDERS").
- **B — Standings / fixtures.** `_season_standings_text` renders the fixture list with
  WON/▸/upcoming status; shown on the SEASON OVER / CHAMPION screens and (as the
  next-up line) in the perk draft. Reads as a season.
- **C — Between-matchday team perk draft.** Won a non-final matchday → the gauntlet
  draft overlay (generalized via `draft_mode`) opens as "PICK A TEAM PERK" — 3 perks
  from `season_draft_options()` (the `UPGRADES` set minus HP-carry-only heal perks).
  Picks stack in `MatchConfig.season_perks` and apply to your WHOLE side via
  `dino.gd _apply_run_upgrades` (refactored to share `_apply_upgrade_list` with the
  gauntlet); foes get nothing. Pick advances the season.
- **Validated:** `season_test` **31/31** (rivals + home islands + boss finale, draft
  options exclude heal perks, perks boost your side / skip foes, matchday-win→advance);
  perk-draft + setup snapshots clean; grab_test 20/20; headless boot clean.

> Resume hint (Phase 2 done on `feat/season-phase2`): Phase 3 remains —
> divisions/promotion, coin economy, trophy cabinet, persistent squad/fatigue, 3v3+
> (needs new fighter nodes). STILL no human-played season — the deferred feel check.

## Session — 2026-06-15 (SEASON MODE — Arcade reborn as a couch campaign)

Charlie: "arcade and versus seem the same no?" — they were. Arcade was a thin solo
CPU ladder barely distinct from Versus-vs-CPU. We reframed it into **SEASON MODE**
(Phase 1), a couch campaign. Planned + approved via plan mode, built behind
`feat/season-mode`.

- **Arcade → Season.** Replaced the arcade ladder wholesale (`arcade_*` symbols
  gone; co-op duo folded into season team setup). Three modes now read as three
  distinct experiences: **Versus** (configure one fight), **Season** (build a team,
  climb), **Gauntlet** (solo roguelike).
- **Build a team + pick size.** Pre-season: **TEAM SIZE 1v1 / 2v2** (engine caps at
  2v2 — only 4 fighter nodes). Your side is humans + CPUs; a 2nd pad auto-joins as a
  human ally (slot human/CPU is by controller presence), else a CPU teammate the host
  picks. Foes are season-driven + hidden in setup.
- **Mode-cycling matchdays.** 5 matchdays tour the team-compatible modes
  (`rounds → koth → eggs → sumo → flood`; Beast + Bomb Tag are FFA, excluded),
  rotating islands, difficulty ramping to a BRUTAL finale. Each matchday banners its
  mode. Your team seats side A, CPU foes side B — existing team win logic resolves
  solo AND co-op.
- **Climb + unlock.** Win the season → SEASON CHAMPION → `MetaSave.seasons_won`++ →
  unlocks an **additive CHAMPION skin** (shader recolor, no art, no gating of existing
  content; creator/select carousels skip it until earned). Title shows a trophy line.
- **Validated:** `season_test` 24/24 (schedule/mode-cycle/seating for 1v1+2v2,
  advance→finale, unlock gate, in-engine matchday-win→advance); setup-screen snapshot
  clean; grab_test 20/20; headless boot clean.

> Resume hint (2026-06-15, Season): Phase 1 complete on `feat/season-mode`. Open:
> (1) a **full human-played season** — logic asserted, 5-matchday feel/pacing not;
> (2) Phase 2 (named rival teams + home islands, standings screen, between-matchday
> team perk draft); (3) Phase 3 (divisions/promotion, coin economy, trophy cabinet,
> 3v3+ via new fighter nodes). Throwaways to delete when locked: `season_test`,
> `season_shot` (+ the floppy/rig probes).

## Session — 2026-06-15 ("new process of thinking" + AI floppy self-braking)

Charlie shared six `thinkgpt_ai` prompt frameworks (Sun Tzu / Munger) and said
"this is our new process of thinking" — then "want you to think for yourself."

- **Process is now durable.** `THINKING.md` (repo root) adapts the six into our
  decision lenses (Advantage Identifier / Positioning Audit / Inversion Engine /
  Mental Model Installer / Stupidity Auditor / First Principles Stripper) — tuned to
  this project's standing bias: *shipping breadth on snapshot-validation while feel
  stays deferred*. Memory: `thinking-process-frameworks`. Use ONE fitting lens per
  big call, not all six.
- **Live strategic read (logged, not yet acted on):** Positioning Audit + First
  Principles suggest **floppy may be our winning terrain** (Gang-Beasts/party,
  couch, no-online — what a solo dev wins) and precise-combat the *losing* one
  (Smash terrain, needs online). Open question for Charlie: should floppy graduate
  from opt-in toggle to the **default** couch experience? Gated on it feeling good.
- **First feel fix (autonomous): AI floppy momentum self-braking.** Closed the
  PROGRESS-flagged open soft spot ("walks a bit overshooty / deeper AI self-braking
  untuned"). `dino_ai.gd` `_floppy_brake` (+ `momentum_brake` flag): in floppy, a
  fast bot now *anticipates the slide* — releases the stick to coast onto its
  spacing pocket, counter-steers only once actually past it, leaving any strafe
  intact. Gated to `max_speed > 300` (the `skittish` breakpoint) so heavies, which
  don't oscillate, are untouched.
  - **Measured, not asserted** (`scripts/tools/floppy_walk_probe.gd` +
    `scenes/floppy_walk_probe.tscn`, 14-trial avg): raptor overshoot **46→7px**,
    reversals **1.57→0.79**; the probe also *caught* an early over-aggressive
    version that made the bot stop short of fighting range — fixed before shipping.
  - `grab_test.gd` (20 assertions incl. two-CPU floppy brawl) stays green; full
    headless boot clean.
- **Floppy is now the DEFAULT** (Charlie's call). `MatchConfig.floppy_mode` flipped
  false→true; the select Select-toggle now flips you TO the precise model. Global,
  so solo arcade/gauntlet are floppy too (their sim-tuned balance needs re-checking).
- **Floppy feel pass — locomotion constants (measured).** Built
  `floppy_feel_probe` (drives a fighter with simulated stick input, measures top
  speed / glide / stop / reverse). Found the real defect: with a FLAT
  `floppy_friction` (360 for all), glide = v²/2f made the fast dino (raptor, 484)
  slide **~325px on clean ground and ~673px across the lava arena's low-friction
  centre — it rings itself out of a sprint** — while 240-speed tanks slid ~100px
  (barely floppy). Fix: scale friction by top speed (`FLOPPY_REF_SPEED` 320) → every
  dino coasts the SAME ~0.89s. Clean re-measure: raptor glide **325→234px**
  (controllable), tanks ~100→~117 (still loose); band tightened 100–325 → 115–234.
  - **Honest scope:** the 673px lava figure is an arena-surface interaction
    (`minf(ice_friction, fric)` caps friction at 200 on slow/ice zones) — flagged,
    NOT chased; the locomotion constant itself is now sound.
- **Floppy feel pass — verb cadence (measured, inconclusive).** `floppy_cadence_probe`
  (two HARD CPUs, 40s, per-arena): knockdowns 3–7.5/min, grabs/throws 0–4.5/min —
  the verbs FIRE but the rate is very noisy across 40s samples, so it's not
  tune-able data. Deliberately did NOT twiddle `DOWN_*`/`GRAB_*`/`grab_chance` off
  noisy data — those + the exact glide target remain genuine hands-feel calls.
- **Floppy feel pass — KO resolution (measured, ANSWERED).** `floppy_ko_probe` runs
  two HARD CPUs to a real match end (`round_wins`/`match_over`), floppy vs precise,
  ring-out arena + HP arena. **Floppy resolves fine — faster than precise in every
  case:** beach floppy ends 13.7s vs precise 21.0s; lava floppy 21.6s vs precise
  **UNRESOLVED at 60s** (2 KOs/min). Floppy's knockdown-slides + throw-offs are a
  *decisive* mechanic, the opposite of the "does it even end?" worry. (That worry
  came from the cadence probe never detecting KOs — a probe bug: `dino.die()` reports
  via `get_tree().current_scene.report_ko`, so the probe must set `current_scene` to
  the arena or every match falsely reads UNRESOLVED. Caught + fixed before trusting.)

> Resume hint (2026-06-15): floppy is the DEFAULT, AI self-braking + locomotion
> friction-scaling landed & probe-validated; today's earlier work (THINKING.md, AI
> brake, default-flip) already committed + pushed; the locomotion fix + two new
> probes are NOT yet committed. Next: (1) commit the locomotion fix + feel probes;
> (2) genuine hands-feel pass on `DOWN_*`/`GRAB_*`/`dino_rig` PROFILES + the exact
> glide target — needs a controller, not a probe; (3) KO-resolution ANSWERED (floppy
> resolves faster than precise) via `floppy_ko_probe`; (4) re-validate solo
> arcade/gauntlet balance under floppy — note lava-PRECISE was UNRESOLVED in 60s,
> so precise pacing on HP arenas may itself be a separate issue; (5) delete throwaway
> probes (`floppy_walk_probe`, `floppy_feel_probe`, `floppy_cadence_probe`,
> `floppy_ko_probe`, `rig_test`, `montage_rig`, `grab_test`, `ui_shot`) when feel is
> locked.

## Session — 2026-06-14 (fighters come alive: runtime limb rig)

Charlie: "I want the animation to feel realistic, the characters arms and legs
should move as well as their head or body when hit" — and idle/walk should feel
alive too. He picked the most ambitious option (full runtime limb rig over the
cheaper procedural-only paths), then told Claude to **experiment, not playtest**
(new memory: iterate on feel via the snapshot tools, don't gate on his hands).

- **Each fighter is now a live skeleton, not one flat sprite.** Body + head +
  tail + front/back limbs, each on its own angular **spring**, reassembled in
  code at spawn (`scripts/dino_rig.gd`, a Node2D built by `dino.gd._setup_sprite`).
  No `.tscn` edits — it works across all 6 arenas automatically. The old baked
  `AnimatedSprite2D` stays as an auto-fallback (parts missing → old path) and
  still drives the menu previews.
- **Reused the painterly pipeline instead of replacing it.** New
  `gen_ralph_fighter.py --parts` mode exports each dino's `body + 4 limb` PNGs +
  a `rig.json` manifest (pivots/offsets in core-centre space), reusing the bake
  tool's existing `PART_DEFS_BY_DINO` boxes/pivots. All 6 exported.
- **Feathered partition of unity** kills the seams: limbs are cut with soft-edged
  masks and the body has the *matching* soft amount removed, so part+body sum to
  the original at rest and cross-fade (not crack) when a limb swings. First pass
  without it tore the tail off and showed a rectangular belly box; with it, even
  raptor's aggressive flail (max 48°) holds clean.
- **Live motion, per-dino character** (`PROFILES` in dino_rig.gd): idle breathing
  + sway, walk leg-scissor + bounce, attack lunge, and a **hit flail** (head snaps
  the way it's thrown, tail whips opposite, body recoils + squashes, legs splay,
  springs settle ~0.25s; impulse scales with damage so heavies throw harder).
  Bipeds (ralph/raptor) stride; quads (trike/bronto/anky) barely move their legs;
  **pterry's "legs" flap as wings**; **bronto's "head" is a long swaying neck**;
  **anky's club tail is under-damped so it lags + carries momentum**.
- **Validated by snapshot, not playtest** (per Charlie's ask): throwaway
  `scenes/rig_test.tscn` + `scripts/tools/{rig_test.gd,montage_rig.py}` shoot a
  fixed idle/walk/attack/hit frame set per dino and tile them into contact sheets
  (`/tmp/ralph/sheet_*.png`). All 6 reassemble seamlessly; all 6 arenas boot
  clean headless. **No human has felt it yet** — timing/feel is the open item.

- **Gang-Beasts pass** (Charlie: "look at the movement of Gang Beasts"): added a
  **whole-body wobble** the rig was missing. A lean spring pivots the body around
  its FEET (`_lean_node`) — it leans INTO a run (momentum, fed signed `velocity.x`
  via `set_motion`), idle-teeters so it's never frozen, and a hit **kicks it into
  a drunk stumble** (low `lean_damp` = it reels and wobbles back upright). Per-dino
  character: raptor/pterry wobble most, the armored quads (trike/bronto/anky) are
  near-immovable. Crucially it's **look-only** — the lean rotates the sprite, the
  CharacterBody2D control/hitboxes stay exact, so the precise-combat pillar is
  untouched. The bigger fork (actual floppy *control* like real Gang Beasts
  gameplay) was flagged to Charlie as a pillar-level redesign, NOT done.

- **FLOPPY GAMEPLAY** (Charlie: "make it actually play floppy like Gang Beasts").
  Committed to the direction but **staged behind `MatchConfig.floppy_mode`** (on by
  default) so it A/Bs against the precise model, since it fights the precise-combat
  pillar. Two stages landed:
  - **Stage 1 — momentum locomotion** (`dino.gd update_movement`): floppy uses low
    accel (850) + low friction (360) instead of 3000/3000, so you ramp up
    sluggishly, **glide ~170px after releasing**, and take **~0.4s to reverse**
    (numeric probe in the bash log; precise glides 14px / turns in 0.1s). The
    Gang-Beasts loose control. The visual lean reads `velocity.x`, so momentum makes
    the body wobble naturally with the slides.
  - **Stage 2 — losing your footing** (`knock_down`/`_process_downed`/`get_up` +
    `rig.topple`): a hit past `DOWN_KB_THRESHOLD` (420 kb, i.e. heavies/specials)
    floors you — you lose control for `DOWN_DURATION` (0.85s), slide with the blow
    (can ring yourself out, very Gang Beasts), and the rig tips fully over (~62°
    lean) with limbs splayed limp, then springs upright. Verified in stills: clean
    topple→limp→getup, no seam cracks even toppled.
  - **Stage 3 — GRAB / carry / throw** (the core Gang Beasts verb). Reuses the
    pickup/throw buttons: **LT** grabs a foe in front (`_foe_in_grab_range`, must be
    within 96px and in your facing arc) else picks up a weapon as before; **RT**
    hurls a held foe (`throw_grabbed` → 740 kb → they topple + skid off) else throws
    a weapon. The held foe (`_on_grabbed_by`) goes limp (`rig.set_held`), is dragged
    to a hold point in front, can't act, and **mashes any button to struggle free**
    (CPUs auto-build escape). Hold auto-releases after 1.7s. Grabs drop cleanly on
    knockdown / being-grabbed / death / ring-out (`_release_all_grabs`). Validated
    by `scripts/tools/grab_test.gd` (instances a real arena, drives the whole
    grab→carry→throw→topple→escape chain): **13/13 assertions PASS**.
  - **Stage 3b — the CPU grabs too** (`dino_ai.gd`): new `grab_chance` knob per
    difficulty (easy .10 → brutal .44). In reach it sometimes grabs instead of
    swinging, and **leans in hard when a ring-out is set up** (+0.5) — because
    grab→throw-off-the-edge is a KO the plain shove can't guarantee. While holding,
    the brain takes over: it turns to face the **nearest edge** (`_ai_center`
    outward) and hurls the foe off it. Emits via `consume_grab`/`consume_throw_grabbed`,
    same input pattern as everything else. `grab_test.gd` now also asserts a CPU
    **grabs and throws a foe autonomously** — 15/15 PASS.
  - **Stage 3c — hardening pass** (Claude advancing autonomously). Fixed three
    things that make floppy actually *fair/robust*:
    1. **Anti-juggle guard**: getting up grants `DOWN_IMMUNE_AFTER` (0.9s) where a
       hit still shoves you but **can't re-floor you** — so you can't be chain-
       knocked off an edge with no recovery.
    2. **Respawn/round-reset cleanup**: `respawn()` now clears downed/grab state and
       calls `rig.reset_pose()`, so a round never resets with someone still
       toppled, held, or mid-wobble (a dangling-link bug waiting to happen).
    3. **AI momentum-leading**: in floppy the bot aims where a *sliding* foe is
       heading (`target.velocity * 0.16`), so it stops chasing a drifting target's
       tail. (Deeper AI self-braking still untuned — a known soft spot.)
    `grab_test.gd` extended to 20 assertions incl. anti-juggle + a 700-frame
    two-CPU floppy brawl (no crash/deadlock, knockdowns confirmed): all PASS.
  - **Stage 3d — shipped as an opt-in mode.** `floppy_mode` now defaults **OFF**
    (the base game stays precise/balance-tuned) and is a **select-screen toggle**:
    P1 taps **Select** to flip `FLOPPY MODE: ON/OFF` (lit magenta when on), works in
    versus AND solo, hint lines updated. So floppy is a party-mode opt-in, not an
    override of the main game. Verified by a select-screen snapshot (clean layout,
    no overlap) + grab_test still green with it forced on.
  - **Still open:** deeper AI movement tuning for momentum (fights/grabs well, walks
    a bit overshooty). Feel pass on all floppy constants remains Charlie's call.

> Resume hint: FLOPPY MODE is feature-complete and shipped as an **opt-in select
> toggle** (default off; P1 Select). Full Gang-Beasts loop for humans AND CPUs —
> momentum locomotion, footing-loss, grab/carry/throw-off-the-edge, anti-juggle,
> clean resets, AI that grabs. Plus the live limb rig + wobble underneath it. The
> ONE thing left is a **live-hands feel pass** (Charlie's call) on the tunables
> (`dino.gd floppy_*`/`DOWN_*`/`GRAB_*`, `dino_ai.gd grab_chance`, `dino_rig.gd`
> DEFAULT+PROFILES) and deeper AI momentum-walk tuning. Housekeeping: menus could
> use the rig (pick==play); delete throwaway helpers `rig_test`/`montage_rig`/
> `grab_test`/`ui_shot` when done iterating.

## Session — 2026-06-11 (the game gets a voice: music + full-coverage sound)

Charlie said "start on audio." The game had 8 placeholder combat WAVs and
otherwise total silence — no music, no menu sounds, no audio buses.

- **Music exists now**: `gen_music.py` (pure-stdlib sibling of gen_sfx.py) is
  a 4-channel chiptune tracker — square lead with vibrato + dotted-8th echo,
  arp chords, triangle octave bass, kick/snare/hat. Two sample-exact loops:
  **TITLE THEME** (sunny C-major I-V-vi-IV bounce, 126 BPM, 30s) on
  title/select/creator, **BATTLE THEME** (driving A-minor Andalusian run,
  152 BPM, 25s) in every arena. New **`Audio` autoload** crossfades between
  declared tracks (screens just state their track in `_ready`); buses
  (Master / Music −5dB / SFX) in `default_bus_layout.tres`. Music loads with
  CACHE_MODE_IGNORE — the audio thread can hold a stream past tree teardown
  and a cached ref tripped "resources still in use" on every quit.
- **Menus aren't mute**: `Audio.ui("move"/"confirm"/"back")` blips wired at
  the central input handlers of title, select (all cycles + the
  DINO→COLOR→READY driver), creator (grid + skin carousel), pause overlay,
  and the gauntlet draft.
- **Events own their sounds**: PICKUP (weapon grabs + egg collects — was the
  dodge blip / block clink), THROW (was swing), DROP_LAND (the weapon-drop
  telegraph payoff — was the dodge blip), EMOTE (taunt bubbles were silent).
  `_load_sfx` now builds players in code for sounds without baked $SFX scene
  nodes (no .tscn churn) and routes all SFX to the SFX bus.
- All synthesized placeholders, swappable in place. **Nobody has heard any
  of it** — headless can't play audio — so playtest #4 gained a listen-check;
  expect a tuning pass on mix levels (and possibly melodies) after real ears.

## Session — 2026-06-11 (drop-economy sim validation + the playtest #4 script)

Consolidation day: validate the weapon-drop meta in sim, then package the
build for playtest #4. **No game code changed** — the sim said none was needed.

- **Balance sim re-run under the drop economy** (the item left pending on
  2026-06-10). A first 30s/match pass looked alarming (tanks at 70–75%) but
  was sample noise — the scramble slows kills, so 30s matches produced ~4x
  fewer KOs than pre-drop runs. Bumped `sim_ai.gd` to **60s/match**; the
  confirmed matrix: **everyone 36.7–62.8%**, Ralph high (62.8), Max low
  (36.7), rest clustered 41–60. That's the *same shape and band* as the
  pre-drop meta — **the drop economy preserved the balance**, so no stat
  changes; Ralph-high/Max-low stays a playtest-#4 call per the prior session.
  (Lesson re-learned twice now: short sim windows lie. 60s is the new floor.)
- **Watch item, not tuned**: Gus vs Frank went **0–7** across both arenas —
  armored HEADBUTT CHARGE feeds the no-safe-side TAIL SMASH. On the playtest
  sheet; if humans confirm, Gus likely needs an out (or Frank's radial a
  blind spot).
- **Kept `WEAPON_DROP_FIRST` at 3.5s** — the "round ends before any weapon
  lands" wrinkle only appeared in hard-CPU blitzes; whether it bothers humans
  is now a checklist item rather than a pre-emptive change.
- **PLAYTEST.md rewritten as the playtest #4 script** (was the stale #3:
  keyboard fallbacks, pre-mode-era checks). Focus: the weapon scramble
  (race-vs-coin-flip, the fist-fight opening), the six signature kits read,
  DINO→COLOR→READY flow, the sim's balance questions, and a quick regression
  sweep (modes/teams/solo/emotes). Tuning-knob list updated to the real
  constants (`WEAPON_DROP_*`, `WEAPONS` dict, select-screen difficulty).

> Resume hint: the build is playtest-#4-ready. Next session starts from
> Charlie's playtest findings; the queued fallback is audio (SFX are still
> synthesized placeholders, no music).

## Session — 2026-06-10 (weapons become found objects + pre-match colors)

Charlie's calls: colors picked before the match, and weapons earned
mid-round instead of granted at spawn ("they have to pick them up").

- **COLOR stage on the select screen**: pick flow per fighter is now
  DINO → COLOR → READY. ◀▶ cycles MatchConfig.SKINS with a live recolor
  preview on the select sprite (pick == play), seeded from the dino's
  creator-equipped skin; committed per-slot via `MatchConfig.skin_choices`
  (-1 = MetaSave fallback, used by inactive slots + solo CPU rungs).
- **Nobody starts armed**: the weapon pick stage is GONE. main.gd drops a
  weapon every ~9s (first 3.5s into each round, ≤3 grounded at once) at a
  random safe point, telegraphed by a growing landing shadow; rounds reset
  the clock so each opens with the same scramble. Fighters spawn
  ["fists","fists"]; LT grabs, RB swaps, RT throws (unchanged paths).
  Dead loadout plumbing (weapon_choices, *_player_weapon) stripped.
- **Weapons LOOK like objects now**: bake_weapon_sprites.py turns the
  concept weapon art into in-match sprites (alpha-keyed, blade-toward-+X,
  hand-sized) used in-world AND in-hand, with a soft contact shadow on the
  ground. Polygon silhouettes remain only as a fallback.
- **CPUs contest drops**: dino_ai's scavenge logic now seeks weapons at 720px
  (was 440 — tuned for reclaiming throws); since everyone starts unarmed,
  racing the player to a fresh drop is the round's opening move.
- Verified live: telegraph → landing → CPU grab on Laughing Lava (hard CPUs
  on Beauty Beach KO each other before the first drop lands — fast rounds
  may end weaponless, by design for now). Balance sim re-run pending below.
- Creator's loadout panel retitled FAVORITE WEAPONS (flavor only).

## Session — 2026-06-10 (the Ralph treatment: names, kits, balance)

Charlie's call: "change the other dinos to match Ralph" — named characters,
CHOMP-weight signature kits, balance to Ralph's level, art at Ralph's bar.

- **The roster has names now**: Raptor → **MAX**, Trike → **GUS**,
  Pterry → **JESSIE**, Bronto → **STEVE**, Anky → **FRANK** (Jessie was
  Charlie's pick — he moved it to the pterodactyl; the rest neighbor-generic
  like Ralph). `display_name` in MatchConfig drives select/HUD/banners;
  creator bios carry the species.
- **Every signature move has a mechanical hook** (was: only CHOMP + SCREECH):
  DASH CLAW refunds most of its cooldown on a clean hit; HEADBUTT CHARGE is
  armored (no shove mid-charge); NECK WHIP guard-crushes (2x block drain);
  TAIL SMASH is a true radial shockwave (`_do_radial_special` shared with
  screech) — no safe side. Creator move cards sell each hook.
- **Balance, sim-validated** (sim now 30s/match; 18s was noise): pre-session
  Ralph trim + Trike buff committed first (Ralph 62.5% → cluster), then the
  hooks shook the meta (anky 73%, raptor 13%) and round-2 numbers landed
  everyone at **39–61%** with every matchup interactive. Max (raptor) and
  Jessie (pterry) sit low, Ralph high — within sim noise; playtest #4
  decides further tuning.
- **Creator screen no longer lies**: Ralph profile stats + ALL move cooldowns
  derive live from MatchConfig (RALPH_STATS hardcode + stale "5s" gone).
- **Art audit passed**: 6/6 painterly heroes verified via creator `--shot`
  per dino; 6/6 fighter sheets articulated+smooth (same-day bakes); orphaned
  T-Rex art deleted (recoverable from history).

## Session — 2026-06-10 (solo stretch: living fighters)

Charlie asked for "body parts that move" then left Claude to build autonomously.

- **Bake-time articulation** in `gen_ralph_fighter.py`: each hero is sliced
  into head / tail / front+back legs (per-dino boxes+pivots: pterry's slots
  drive his WINGS, bronto's his NECK, anky's the CLUB) and parts rotate per
  frame — legs scissor, tails wag, heads rear + chomp on the strike. Seam-safe
  via 6px overlap margins + unrotated head backing. All six sheets rebaked
  (cells *x168), `dino.gd` ANIM_LAYOUTS updated. Still baked sheets in-engine —
  zero runtime changes.
- **Facing bug fixed**: the old unconditional hero-flip had raptor/trike/pterry
  facing LEFT in right-facing sheets — they walked backwards in-match. Flip is
  now per-dino (`HERO_FACES_LEFT`); every sheet faces right.
- **Painterly look preserved**: rebake initially went through the dither path;
  re-baked `--smooth` per Charlie's painterly-in-match call (same geometry).
- **Player tint softened**: full PLAYER_TINTS multiply crushed the painterly
  fighters (P2 red-raptor → near-black); now blended 35% toward white.
- Balance sim re-run on the 6-dino roster (results logged below when done).

## Session — 2026-06-10 (Ralph absorbs the T-Rex)

Charlie's call while reviewing the juice experiments: his original Ralph design
**was** the T-Rex concept — so the two near-clone slots merged into one.

- **Roster is now 6**: `ralph, raptor, trike, pterry, bronto, anky`. The
  standalone `trex` entry is gone everywhere (MatchConfig roster/defaults,
  dino.gd sheet + ANIM_LAYOUTS, title flank, creator grid/profile, sim_ai).
- **Ralph carries the heavyweight-king kit**: the old T-Rex stats wholesale
  (135 HP, slow/heavy, big hitboxes, fists + war hammer) and the **CHOMP**
  lifesteal lunge as his special. Ralph's old STOMP special retired with the
  merge. His art/identity (sprite, color, bio) is unchanged.
- Creator profile updated: subtitle "THE TINY KING", move = CHOMP. T-Rex
  assets (`trex_fighter.png`, `assets/concept/trex/`) kept on disk, unused.

## Session — 2026-06-10 (identity + content blitz)

A long multi-part day. All landed on `master` and pushed.

**Roster art → in-match**
- Baked the 6 remaining dinos (trex/raptor/trike/pterry/bronto/anky) from their
  painterly heroes into in-match fighters via `gen_ralph_fighter.py <dino>`; the
  whole roster now renders Ralph-style art in match (was old Rynosaur sprites).
- Corrected the in-match render scale (old sprite scales were ~4x oversized for
  the new sheets) and gave each dino **size personality** (bronto 0.72 … raptor
  0.52), footing held via `offset_y ≈ 7.6 − 66·scale`.
- **PAINTERLY IN-MATCH** (late in the day, Charlie's call): added
  `gen_ralph_fighter.py --smooth` (skips the pixel dither) and re-baked the roster
  SMOOTH — fighters are now painterly in match too, not pixel-dithered. Same frame
  geometry = drop-in; only texture filter flips to LINEAR (in-match + previews +
  afterimage ghost). Reverses the old two-tier (pixel in-match) plan.

**Character creator — finished**
- Real **SKIN system** for all 7 dinos: live HSV recolor shader
  (`assets/shaders/skin_recolor.gdshader`) + `MatchConfig.SKINS` + `skin_material()`,
  persisted per-dino in `MetaSave`, equipped via the creator carousel (A equips),
  shown in match. No per-skin art needed. Hues tuned (Crystal/Volcano).
- **EMOTES**: 8 quick-taunt bubbles on **Select** in-match (`MatchConfig.EMOTES`,
  `dino.gd play_emote`), plus a creator gallery. Retired the last "COMING SOON".
- Cut the dead part-swap UI → unified to the WEAPONS loadout panel.

**Modes — curated to 7 distinct verbs**
- Cut LAST DINO STANDING (twin of ROUNDS); kept rounds/koth/eggs/sumo/bombtag/
  beast/flood. THE BEAST gated to 3-4 players. Concrete win-condition blurbs on
  select; mode-name banner at versus match start.
- **Solo**: arcade final rung is now **BRUTAL** with a "FINAL BOSS" banner.

**Combat + CPU**
- **BOW** ranged weapon (Pterry) — fires arrows reusing the projectile path.
- **Smarter CPU AI** + new **BRUTAL** tier: dodge-vs-block reads, edge-awareness
  (won't ring itself out), finisher instinct. **Ranged kiting** so bow-users poke
  from range instead of charging in (sim: kiting Pterry beats T-Rex 2-0).
- **Balance** (sim-driven, 2 passes): lifted Raptor (was never winning), trimmed
  T-Rex. **Pre-playtest** — T-Rex still the one to watch; final call is feel.

**Misc**: added `CLAUDE.md` (architecture orientation); `sim_ai.gd` upgraded to a
full round-robin KO matrix. Most of the above was done via a 4-way parallel
worktree-agent batch (one agent ran away and had to be killed — see memory).

> Resume hint: everything compiles + boots headless clean. The open item is
> **balance feel** — playtest, then tune by feel.

## Session — 2026-06-09 (arcade co-op duo)

Merged the `feat/arcade-coop-duo` branch into master (fast-forward, clean) after
verifying it compiles under a full headless project load. Builds directly on the
existing arcade ladder; the gauntlet stays solo.

**Landed**
- **Co-op ladder** — `MatchConfig.start_arcade(.., duo)` seats P1 + a fixed CPU
  partner (rolled once per run, never the player's dino) on side A; each rung now
  fields TWO foes on side B, so the whole climb is a 2-v-2. Ladder rungs refactored
  from `{dino}` to `{foes: [..]}`; `_apply_arcade_rung` branches solo vs. duo for
  player_count / teams / cpu_players.
- **Select toggle** — on the arcade setup screen, P1 **X** flips `PARTNER (CO-OP):
  ON/OFF` (shown on the otherwise-hidden difficulty line); hint gains "X PARTNER".
  Gauntlet hides it.
- **Win/flow** — a win now counts when anyone on the player's side lands the KO
  (`same_side`), and the STAGE-CLEARED "NEXT" preview lists both upcoming foes.

Verified: full-project headless load reports no script errors. **Wants a live
playtest** to feel the 2-v-2 co-op pacing vs. the solo ladder.

## Session — 2026-06-09 (team play)

2v2 / uneven team support across the six team-friendly modes, in three themed
commits. Design calls (locked with Charlie): **friendly fire off**, **any split
allowed** (incl. 1v2 / 1v3 for solo-with-ally), **Beast & Bomb Tag stay FFA**.

**Landed**
- **Foundation** — `MatchConfig.teams_enabled` + a pid→side map with
  `side_of()`/`same_side()` (disabled = each fighter its own side, so FFA is
  untouched). Friendly fire off via one guard at the top of `take_damage` (covers
  every damage path); AI skips teammates; team-colored floating marker.
- **Win conditions** — scoring/elimination aggregate by side via
  `_side`/`_alive_sides`/`_any_alive_on_side`: rounds (killer's team takes it),
  stock (last team standing), KotH (banks only when one side holds), eggs + sumo
  (team totals), Rising Tide (last team dry). Score readouts get [RED]/[BLUE] tags.
- **Select UI** — P1 cycles the split with X (OFF / 2v2 / 1v3 / 1v2 by count +
  mode); applies live so cards preview team-colored headers. Beast/Bomb Tag and
  solo hide it; count/mode changes reset to OFF.

Each commit validated by a throwaway test scene (real arena/select instance +
rule assertions) and an all-scene boot sweep. **Wants a live 4-pad playtest** to
tune the team feel (esp. 2v2 KotH/Sumo and 1v3 underdog balance).

**Follow-ups (same day):**
- **UI polish** — in-engine screenshot pass over every screen caught two text
  overlaps, now fixed: HUD corner labels overflowed once the [RED]/[BLUE] tag was
  added (dropped the weapon-name suffix, smaller font, wider boxes); select
  MODE/TEAMS labels clashed with the island preview's baked watermark (dimmed the
  preview + deeper vignette). Title/how-to/character/draft verified clean.
- **CPU focus-fire** — in team mode the AI target search weights low-HP enemies as
  closer, so an allied team converges on the weakest foe. FFA unchanged.
- **Character stat bars** — the profile STATS panel now draws a bar per stat
  (HP/ATK/DEF/SPD/SPC) normalized to the cast max, so fast/fragile reads visually
  (Raptor = long SPD/short DEF, T-Rex = max HP/short SPD). Verified by screenshot.

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
