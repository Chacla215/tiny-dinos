# ROADMAP — Tiny Dinos v1.0

Decided 2026-07-08 (Charlie). This is the master plan; sessions steer by it.
When a phase lands, mark it here and log details in `PROGRESS.md`.

## Destination

**TINY DINOS v1.0 — public itch.io release** (free or pay-what-you-want, price
decided at Phase 3) with a launch trailer + a full dino-shorts social campaign.
Why itch: gamepad-only couch game, no online — zero-cost storefront that fits
the shape. Steam is a **post-launch option**, not a v1.0 goal.

## Phases

### Phase 0 — Land the branch  `[ ]`
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

### Phase 2 — Release-quality polish  `[ ]`
- **Real UI SFX** (last placeholder synths; same CC0 sourcing recipe as combat).
- **Settings screen**: music/SFX volume at minimum (couch rooms need to duck music).
- First-run onboarding check (how-to-play discoverability), win/quit flows.
- The Phase 1 fix list.

### Phase 3 — Package v1.0  `[ ]`
- Godot export presets: **macOS + Windows** (+ Linux, nearly free). Icon.
- "CONTROLLERS REQUIRED" front and center everywhere.
- itch.io page: screenshots, GIFs, trailer, controls diagram. Price call
  (free vs PWYW) made here.

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
