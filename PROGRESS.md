# Tiny Dinos — Progress Log

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

> Next candidates flagged but not built: remove dead hand-drawn-Ralph assets
> (`art_preview.gd`, `trex_hd`, `trex_handdrawn.png`); deeper CPU tactics; then the
> bigger beyond-melee systems (ranged/Bow, power-ups, status kits, grab/throw).

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
