# Session Summary — 2026-06-10

A very large day. Everything below is committed and **pushed to `origin/master`**
(session ran from `c7c1c67` → `9f2a205`). The game compiles + boots headless clean
throughout.

---

## 1. Roster art → in-match fighters
- Baked the 6 remaining dinos (trex/raptor/trike/pterry/bronto/anky) from their
  painterly heroes into in-match fighters via `gen_ralph_fighter.py <dino>`; the
  whole roster now renders Ralph-style art in match (replaced the old Rynosaur
  sprites). 6 atomic commits.
- **Fixed render scale** (old sprite scales were ~4× oversized for the new sheets)
  and gave each dino **size personality** (bronto 0.72 … raptor 0.52), footing held
  via `offset_y ≈ 7.6 − 66·scale`.
- **PAINTERLY IN-MATCH** (`4e4df51`): added `gen_ralph_fighter.py --smooth` (skips
  the pixel dither) and re-baked the roster SMOOTH — fighters are now painterly in
  match too, not pixel-dithered. Same frame geometry = drop-in; only the texture
  filter flips to LINEAR (in-match + menu previews + afterimage ghost, `b17650d`).
  This **reverses the old two-tier** (pixel in-match) plan.

## 2. Character creator — finished
- **Skin system** for all 7 dinos: live HSV recolor shader
  (`assets/shaders/skin_recolor.gdshader`) + `MatchConfig.SKINS` + `skin_material()`,
  persisted per-dino in `MetaSave`, equipped in the creator carousel (A equips),
  shown in match. **No per-skin art needed.** Hues tuned (Crystal/Volcano).
- **Emotes**: 8 quick-taunt bubbles on **Select** in-match (`MatchConfig.EMOTES`,
  `dino.gd play_emote`) + a creator gallery. Retired the last "COMING SOON".
- Cut the dead part-swap UI → unified to the WEAPONS loadout panel.

## 3. Modes — curated to 7 distinct verbs
- Cut LAST DINO STANDING (felt like a twin of ROUNDS). Kept rounds / koth / eggs /
  sumo / bombtag / beast / flood — each a distinct verb. **THE BEAST gated to 3-4
  players** (collapses in 1v1).
- Concrete win-condition blurbs on the select screen; mode-name banner at versus
  match start.
- **Solo**: arcade final rung is now **BRUTAL** with a "FINAL BOSS" banner.

## 4. Combat + CPU
- **BOW** ranged weapon (Pterry) — fires arrows reusing the projectile path.
- **Smarter CPU AI** + new **BRUTAL** tier: dodge-vs-block reads, edge-awareness
  (won't ring itself out), finisher instinct. **Ranged kiting** so bow-users poke
  from range instead of charging in.
- **Balance** (sim-driven, 2 passes): lifted Raptor (was never winning), trimmed
  T-Rex. ⚠️ **STILL PRE-PLAYTEST** — see Open Items.

## 5. Infra / process
- Added `CLAUDE.md` (architecture orientation). `sim_ai.gd` upgraded to a full
  round-robin KO matrix. Updated `PROGRESS.md`.
- Much of #1–4 ran as a **4-way parallel worktree-agent batch**. Lesson learned: one
  agent (balance) ran away and kept editing the main checkout after its worktree was
  removed; recovered via `pkill godot` + push-to-lock. Don't run long-sim agents.

## 6. Experiments (Charlie asked to "keep experimenting") — ALL PROVISIONAL
All additive, all `[experiment]`-tagged, **pending your in-motion keep/cut/tune**:
| # | Experiment | Area | Commit |
|---|-----------|------|--------|
| 1 | Impact-burst particles on hits | combat juice | `1ae134b` |
| 2 | KO shockwave flourish | combat juice | `e316690` |
| 3 | Per-island ambient particles | atmosphere | `30f6896` |
| 4 | Dodge dust | movement | `332b97c` |
| 5 | **Map power-up pickups** (HEAL/SPEED/POWER) | gameplay | `d30e39b` |
| 6 | Hit-combo counter | feedback | `9f2a205` |

Notes: the game was already well-juiced (shake, freeze-frame, swipe arcs, hit-flash)
— these fill the gaps. Power-ups are **gated to standard versus** (off in the tuned
solo ladders + party modes) since they affect balance. The combo popup's floating
Label is best-effort and wants a live look. Ambient particles are deliberately
subtle (tune `AMBIENT_STYLES` / drop a style to disable per island).

---

## OPEN ITEMS (need you)
1. **Combat balance — the real open item.** Two sim passes did NOT fix it: T-Rex
   still ~76% win rate, Raptor ~28% (post-AI round-robin). It's likely **structural**
   (T-Rex's lifesteal + gap-closer + HP; Raptor's fragility), not stats — so it needs
   your playtest feel + a design call (e.g. cut T-Rex's lifesteal/gap-closer, give
   Raptor a survival tool). Tell me the direction and I'll make a decisive change.
2. **Review the 6 experiments in motion** — keep / punch-up / cut each (especially
   power-ups for feel+balance, ambient for subtlety, combo popup placement).
3. **New playable dinos** (you wanted these) — **art-gated**: a new fighter needs a
   painterly hero baked into a sheet (same pipeline as the 6). Generate a hero (e.g.
   Stegosaurus) and I'll bake + wire it with a distinct kit.
