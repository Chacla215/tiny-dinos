# CLAUDE.md — Tiny Dinos

Orientation for Claude Code sessions. Read this first, then `PROGRESS.md` for
current state. Keep claims here verified against the code; don't let it drift.

## What this is

**Tiny Dinos** — a **gamepad-only** local couch dino brawler in **Godot 4.6**
(GL Compatibility renderer). Top-down arena fighter: up to 4 dinos brawl on an
island platform; you win by KOs / ring-outs depending on the mode. Built solo by
a designer (Charlie); Claude writes the code and integrates art. Charlie does NOT
write code or make art — generate art via the `scripts/tools/` pipeline and wire
everything yourself.

Other root docs: `DESIGN.md` (design bible), `PLAYTEST.md` (playtest notes),
`PROGRESS.md` (running state — update when a feature lands), `AGENTS.md` (short
stub; this file supersedes it for architecture).

## How to run / validate

Godot binary: **`/opt/homebrew/bin/godot`** (4.6.3 stable).

- **macOS has NO `timeout` command** — run `godot` directly, never wrapped in
  `timeout`.
- **Headless validate** (catch parse/script errors without a window):
  ```
  /opt/homebrew/bin/godot --headless --quit-after 120 2>&1 | grep -iE "error|invalid|parse"
  ```
  (`--quit-after N` quits after N frames.)
- **Import assets** headless: `/opt/homebrew/bin/godot --headless --import`
- **Headless CANNOT screenshot** — it uses a dummy renderer. To capture a frame,
  run **windowed** and use the in-engine snapshot trick: a scene that does
  `await RenderingServer.frame_post_draw`, then
  `get_viewport().get_texture().get_image().save_png(...)`. The character/creator
  screen has this built in — pass `-- --shot`:
  ```
  /opt/homebrew/bin/godot scenes/ralph_creator.tscn -- --shot [view] [dino_id]
  ```
  (see `ralph_creator.gd` `_screenshot`, gated on `"--shot" in OS.get_cmdline_user_args()`,
  saves to `/tmp/ralph/`).
- Main scene is `scenes/title.tscn` (set in `project.godot`).

## Architecture

### Autoloads (globals, see `project.godot [autoload]`)
- **`MatchConfig`** = `scripts/match_config.gd` — the hub. Holds the roster
  (`DINOS`, `ROSTER_ORDER`), weapons (`WEAPONS`), islands, modes, skins, emotes,
  team config, CPU difficulty, and the solo-mode state (arcade/gauntlet). Also
  **registers the entire gamepad input map** at startup
  (`_register_player_actions` / `_register_pause_action` / `_register_restart_action`).
  Select/title screens write into it; the match reads from it.
- **`MetaSave`** = `scripts/meta_save.gd` — persistent progression via
  `ConfigFile` at `user://gauntlet_save.cfg`. Tracks gauntlet `best_wave` + `runs`
  (milestone unlocks derived from best_wave), and per-dino cosmetic **skin**
  choices (`get_skin`/`set_skin`).
- **`Pause`** = `scripts/pause_manager.gd` — global pause overlay
  (`PROCESS_MODE_ALWAYS`). Start button mid-match → RESUME / HOW TO PLAY / EXIT.
  HOW TO PLAY reuses `controls_diagram.gd`.
- **`Audio`** = `scripts/audio_manager.gd` — music + UI sounds. Screens declare
  their track in `_ready` (`Audio.play_music("menu"/"battle")`; re-calling the
  current track is a no-op, changes crossfade). Menus call
  `Audio.ui("move"/"confirm"/"back")`. Buses (Master/Music/SFX) live in
  `default_bus_layout.tres`. Music = real **CC0** loops (`assets/music/*.ogg`,
  Juhani Junkala via OpenGameArt — see `assets/music/CREDITS.txt`); the Audio
  autoload forces `loop=true` at load. **Combat SFX** = real **CC0** sounds from
  Kenney (Impact Sounds + RPG Audio — see `assets/sfx/CREDITS.txt`), converted to
  WAV in place. **UI SFX** (ui_move/confirm/back, emote, win) are still the
  placeholder synths from `scripts/tools/gen_sfx.py` (swappable in place, next
  audio pass). `gen_music.py` remains as the old chiptune generator but no longer
  feeds the game.

### The match
- `scenes/main.tscn` + `scripts/main.gd`. The four fighters (`Player1`–`Player4`)
  are **baked directly into the scene** with `dino.gd` attached; `main.gd`
  configures/positions/hides them per `MatchConfig.player_count`.
- Each island is its **own standalone scene** (`scenes/arena_*.tscn`:
  beach, falls, floes, lava, purple, springs) — each runs `main.gd` with its own
  background + platform layout. `main.tscn` is the lava-flavored base. Picked via
  `MatchConfig.ISLAND_SCENES`.
- `main.gd` owns win/score state (`round_wins`, `match_over`, `kos_to_win`) and
  all **game-mode logic** (`_setup_game_mode` + per-mode `_update_*`).

### The fighter
- `scripts/dino.gd` (large, ~1500 lines) — movement, attacks (light/heavy/special),
  block, dodge (dodge spends the block bar), knockback, ring-out / sky-suction KO,
  weapons (pickup/throw via `weapon_item.gd`, projectiles via `spike_projectile.gd`),
  emotes, skins. Tunables come from `MatchConfig.DINOS[id]` via `@export`s like
  `sprite_role`, applied at spawn — this is how dinos stay **distinct** (see
  Conventions).
- `scripts/dino_ai.gd` (`extends RefCounted`) — the CPU brain. It does NOT touch
  movement/combat directly; it only emits the **same inputs a human would**
  (move dir, held-block, one-shot attack/heavy/dodge), which `dino.gd` consumes
  through the identical code path. So the bot obeys every rule the player does.
  Difficulty scales its tunables (`aggression`, `reaction_time`, `block_chance`…).

### Screens (front end, all gamepad-driven)
- `scripts/title.gd` (`scenes/title.tscn`) — front door: pick a mode, then go to
  select; also routes to the character/creator screen.
- `scripts/select.gd` (`scenes/select.tscn`) — character/weapon/island/mode/teams
  picker. Renders the **same** pixel art the match uses (pick == play).
- `scripts/ralph_creator.gd` (`scenes/ralph_creator.tscn`) — the
  **character / creator screen**. Roster grid → per-dino profile; cycles skins.
  (File kept named `ralph_*` for churn reasons; it now hosts all dinos.)
- `scripts/controls_diagram.gd` — the How-to-Play controller-map drawing (used by
  both the title and the pause overlay).

### How dinos render in-match
- `dino.gd` has `ANIM_LAYOUTS`: per-dino atlas definitions (a `SHEET_*` PNG under
  `assets/sprites/` + `idle`/`walk`/`attack` `Rect2` cells). These fighter sheets
  are **baked from painterly hero PNGs** by `scripts/tools/gen_ralph_fighter.py`
  (downscale + Bayer-dither so dinos read as pixel art on the pixel islands). That
  tool prints the exact `SHEET_` const + `ANIM_LAYOUTS` block to paste into
  `dino.gd`.

### Game modes
- Defined in `MatchConfig.MODE_ORDER` (`rounds, koth, eggs, sumo, bombtag, beast,
  flood`) with `MODE_NAMES` / `MODE_BLURBS` and targets like `KOTH_TARGET`,
  `EGG_TARGET`, `SUMO_TARGET`, `BOMB_FUSE`, `BEAST_TARGET`, `FLOOD_DURATION`,
  `ROUNDS_TO_WIN`. THE BEAST is hidden under 3 players (`BEAST_MIN_PLAYERS`).
  Mode behavior lives in `main.gd` (`_setup_game_mode`, `_update_koth`,
  `_update_eggs`, `_update_bombtag`, `_update_beast`, `_update_flood`).

### Skins (cosmetics)
- `MatchConfig.SKINS` (DEFAULT + recolors) drives the recolor shader
  `assets/shaders/skin_recolor.gdshader`. `MatchConfig.skin_material(idx)` returns
  a configured `ShaderMaterial` (null for DEFAULT). `dino.gd` applies it; choice
  persists per dino in `MetaSave`. No per-skin art needed in-match — it's a live
  hue/sat/val recolor.

### Emotes
- `MatchConfig.EMOTES` (text taunt bubbles). Tapping **Select/Back** in a match
  fires the next one via `dino.gd` `play_emote`.

### Solo modes (single-player spine)
- Flags live on `MatchConfig`:
  - **ARCADE** (`arcade*`) — climb a fixed ladder of CPU foes; optional `arcade_duo`
    co-op ally. `start_arcade` / `arcade_advance`. Snappier rungs (`kos_to_win=2`).
  - **GAUNTLET** (`gauntlet*`) — roguelike: rising waves, between-wave upgrade
    draft (`UPGRADES`), HP carries between waves. `start_gauntlet` /
    `_apply_gauntlet_wave`. Feeds `MetaSave` (`best_wave`, unlocks like HARDENED /
    EXTRA DRAFT / VETERAN START).

## Conventions

- **ALL CAPS** for all menu / UI text (the one exception is the readable
  How-to-Play panel body).
- **Gamepad-only.** Keyboard is intentionally NOT bound for gameplay/menus. The
  input map is built in `match_config.gd` `_register_player_actions` (per-player
  `p1_..p4_` actions). Mapping: **A** = confirm/dodge, **X** = attack, **B** =
  heavy/back, **Y** = block, **LB** = special, **RB** = swap weapon,
  **LT/RT** = pickup/throw (analog), **Start** = pause/restart, **Select/Back** =
  **emote**.
- **Each dino must FEEL distinct** — always wire per-dino stat overrides in
  `MatchConfig.DINOS`; never ship a recolored clone. (Recolor = cosmetic skins
  only.)
- **Atomic commits split by theme** — not one bundle. End every commit message
  with:
  ```
  Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
  ```

## Key tools (`scripts/tools/`)

- `gen_ralph_fighter.py` — bake a hero PNG into an in-match fighter sheet (any
  dino: `python3 scripts/tools/gen_ralph_fighter.py <dino>`; sources from
  `assets/concept/<dino>/<dino>_hero.png`). Prints the `dino.gd` ANIM_LAYOUTS block.
- `gen_music.py` — chiptune tracker synth for the music loops (pure stdlib;
  rerun + `--import`, then keep `edit/loop_mode=1` in the music `.import`s).
- `sim_ai.gd` — headless CPU-vs-CPU balance sim across matchups/arenas:
  `/opt/homebrew/bin/godot --headless -s scripts/tools/sim_ai.gd`. Throwaway tuning
  tool.
- Art/bg generators & prompt kits: `gen_island_bgs.py`, `gen_ralph.py`,
  `gen_title_logo.py`, `gen_safe_zone.py`, `gen_boulder_polys.py`,
  `integrate_arena_bg.py`, `dither_dino.py`, plus `*_prompts.md` kits
  (`dino_art_prompts.md`, `arena_bg_prompts.md`, `ralph_fighter_prompts.md`, …).

## Repo

Private GitHub: **`git@github.com:Chacla215/tiny-dinos`**, default branch
**`master`**. Work happens in git worktrees branched off master.
