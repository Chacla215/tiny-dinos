# ROADMAP — Tiny Dinos v1.0

Decided 2026-07-08 (Charlie). This is the master plan; sessions steer by it.
When a phase lands, mark it here and log details in `PROGRESS.md`.

## Destination

**TINY DINOS v1.0 — public itch.io release** (free or pay-what-you-want, price
decided at Phase 3) with a launch trailer + a full dino-shorts social campaign.
Why itch: gamepad-only couch game, no online — zero-cost storefront that fits
the shape. Steam is a **post-launch option**, not a v1.0 goal.

## Phases

### Phase 0 — Land the branch  `[x]` (2026-07-08, PR #17 → `057f15f`)
- PR `feat/feel-sweep` → master (≈60 commits), headless validation, merge.
- Everything after this branches clean off master.

### Phase 1 — The playtest gate  `[ ]`  (Charlie's hands — the one thing Claude can't do)
One structured controller session:
- **Career full run**: grind pacing + economy (XP / pip cost / mood knobs in
  `meta_save.gd` / `match_config.gd` are ready to turn).
- **Pending auditions**: idle-bob amplitude (`dino.gd _update_motion_anim`
  COMBO consts), CC0 combat SFX picks, fall-feel (clip + live), beat-drop
  match intro live.
- **Regression sweep**: all 7 modes + season + gauntlet, 2+ pads.
- Claude turns every finding into an atomic fix.

### Phase 2 — Release-quality polish  `[~]` (Claude-side done 2026-07-08)
- ~~**Real UI SFX**~~ `[x]` Kenney Interface Sounds + Music Jingles (CC0),
  first-guess picks — Charlie's ear check folds into Phase 1.
- ~~**Settings screen**~~ `[x]` SETTINGS on the title: MUSIC/SFX 10-step
  knobs, persisted in MetaSave, applied via the Audio buses.
- ~~**First-run onboarding**~~ `[x]` (2026-07-09) The title opens HOW TO PLAY
  once on the very first launch (`MetaSave.seen_howto`); A/B dismisses. Fixes
  discoverability on a gamepad-only game where the item sat 8th of 10.
- ~~**UI text sweep**~~ `[x]` (2026-07-09) The seven end-of-match START prompts
  were lowercase; now ALL CAPS per the convention.
- Win/quit flows: audited — the win screen is START-only (pause is deliberately
  gated off once `match_over`), and START → select → B → title, so it is two
  hops home, not a dead end. Left as-is; confirm the feel in Phase 1.
- The Phase 1 fix list.

### Phase 2.5 — Arena & mode overhaul  `[~]` (Charlie-directed 2026-07-10; Claude-side done)
Charlie's pre-launch call: graphics/gameplay depth before shipping. Audit found
the 6 arenas mechanically identical (hazard system coded, never wired) and the
CPU objective-blind in 4 of 7 modes. On `feat/arena-overhaul`:
- ~~Arena expansion~~ `[x]` all islands 1.25x via world-scale (`ARENA_SCALE`),
  painting pixel-identical, no art regen.
- ~~Island identity~~ `[x]` lava rim burns / frozen-lake ice / falls current /
  springs geyser pools / purple tree+rock collision; beach stays the beginner
  island.
- ~~Sumo rework~~ `[x]` real dohyo: rope ring scores, bout resets, first to 5.
- ~~Mode-aware AI~~ `[x]` bots play the objective in sumo/bombtag/beast/flood.
- REMAINING: hurt/KO fighter frames (nice-to-have); all new tunings
  (DOHYO_RADIUS, burn rate, current strength, bounce power) are first-guess —
  they fold into the Phase 1 controller session. Re-export builds after this
  lands (zips now stale again).

### Phase 3 — Package v1.0  `[~]` (builds + kit done 2026-07-08; page = Charlie)
- ~~Export presets~~ `[x]` macOS (universal, ad-hoc signed) + Windows + Linux
  in `export_presets.cfg`; templates installed; all three exported clean to
  `build/` (zips ready). ~~Icon~~ `[x]` `icon.png` (Ralph head, beach gradient).
- ~~Page kit~~ `[x]` `ITCH_PAGE.md` (copy + checklist + rebuild commands) and
  `assets/concept/itch/` (8 stills + 3 GIFs from the trailer).
- REMAINING (Charlie): create the itch project, price call (free vs PWYW),
  upload the three zips, trailer to YouTube.

### Phase 4 — Hype campaign  `[ ]`  (parallel with 2–3)
- **Final trailer cut** over the shipped music.
- **Shorts full batch** (greenlit): Charlie reviews `ralph_action_short.mp4`
  → lock the action-level template → batch the other 5 dinos (varied weapon +
  signature move) + a 2-dino rival clash. Recipe proven in
  `assets/concept/shorts/wip/` (~650 Higgsfield credits on hand covers it).
- Drip-post cadence around launch.

### Phase 5 — Post-launch backlog  (pick by reception)
- Depth axes: skill ceiling / meter / stage tech (see memory `game-depth-directions`).
- Career act 2, more islands/dinos.
- Steam port.

## Standing gates
- Feel/ear calls are **Charlie's**; Claude iterates via probes/captures but
  doesn't ship tuning as final without his hands (memory: experiment
  autonomously, surface the reasoning).
- Ship quality bar: headless boot clean, no placeholder assets in the
  player-facing path, pick == play everywhere.
