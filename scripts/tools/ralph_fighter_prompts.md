# Ralph — IN-MATCH (gameplay-tier) pixel-fighter art

**Supersedes** the old "tier-2 stays procedural flat sprite" note in
`ralph_art_prompts.md`. Direction (2026-06-09): the in-match fighters should look
like **Ralph**, and live natively on the islands' **high-fidelity pixel-art**
dioramas (e.g. `assets/tilesets/laughing_lava_bg.png`). So the gameplay tier is now
**AI-generated pixel-art chibi**, not procedural.

Two tiers, one character:
- **Brand tier** (menus / character screen / portraits): the smooth painterly Ralph
  — keep `ralph_art_prompts.md` + `assets/concept/ralph/`.
- **Gameplay tier** (THIS doc): a crunchy pixel-art chibi Ralph that reads at ~88px
  in a fight and matches the pixel islands.

## Why we DON'T ask the AI for a sprite sheet directly

Image gens can't produce clean, pixel-aligned, consistent multi-frame sheets. So:

> **Generate ONE pixel-art Ralph base figure. Derive the animation frames from it
> programmatically** (squash/stretch idle, waddle-rock walk, lunge attack — the
> proven `gen_ralph.py` transform approach, but on the pixel base), then pack them
> into a sheet with known cells.

This reuses the "AI = base, algorithmic = multiplier" pipeline and sidesteps the
sheet-consistency problem entirely. One good image → a full animated fighter.

## The base-figure prompt

Prepend the **CHARACTER BIBLE** block from `ralph_art_prompts.md` verbatim (so the
design stays identical to the brand Ralph), then this gameplay-tier override:

```
Render as a small PIXEL-ART game sprite, not painterly. Clean limited-palette
pixel art with crisp pixel edges and subtle ordered dithering for shading, in the
exact same pixel-art rendering style and fidelity as a polished 2D action-game
character sprite that would stand on a detailed pixel-art lava/forest battlefield.
FULL BODY, standing, weight on both feet, in a 3/4 SIDE view FACING RIGHT (camera
slightly to his right so the snout and near eye read in profile-ish 3/4 — this is
a side-scrolling brawler). Neutral ready stance, arms relaxed, tail out behind.
Centered on a FLAT SOLID magenta (#FF00FF) background for easy cutout. No ground
shadow baked in. Readable at small size: bold shapes, high contrast between the
mint body / cream belly / turquoise spikes / amber eyes, broken horn still legible
as a silhouette notch.
```

Append the **NEGATIVE** block from `ralph_art_prompts.md`, plus:
`painterly, smooth gradients, anti-aliased soft edges, 3d, isometric, front-facing,
ground shadow, drop shadow, motion blur`.

- **Target size:** render ~512×512 (or 768), magenta bg. We downscale + key out the
  magenta to a transparent ~96–128px sprite (nearest-neighbor, keeps pixels crisp).
- **Facing:** RIGHT. The engine flips per-player; the other 5 species' sheets mix
  `faces_left` flags, so just be consistent (right) and we set the flag in code.

## After the base lands

1. Drop it at `assets/concept/ralph/ralph_fighter_base.png`.
2. A packer tool (to write: `scripts/tools/gen_ralph_fighter.py`) keys out magenta,
   trims, and emits frames:
   - **idle** (2): base + a 1px squash/breath.
   - **walk** (4): waddle-rock (rotate ±~4°, bob ±1–2px, alternate near-foot lift).
   - **attack** (2): wind-back + forward lunge (translate snout-ward + slight scale).
   It packs them left-to-right into `assets/sprites/ralph_fighter.png` and prints the
   `Rect2(x,y,w,h)` cells.
3. Wire-in (mirrors the old removed `SHEET_RALPH` work, see
   [[project_tiny_dinos_ralph]]): add `SHEET_RALPH := preload(...)` + a `"ralph"`
   entry to `ANIM_LAYOUTS` in `scripts/dino.gd` with the printed rects; point a dino
   slot's `sprite_role`/`sprite_scale`/`sprite_offset_y` in `match_config.gd` at it.
4. Validate headless (import + arena run, exit 0, no script errors).

## The other 5 species (later, keep distinct)

Same workflow, same bible body, **swap the species silhouette + palette** so each
still reads as a distinct fighter (per the distinct-dinos rule), e.g.:
- **Raptor** — leaner, longer snout + tail, two head feather-quills; teal/yellow.
- **Trike** — three horns + neck frill; orange/cream.
- **Pterry** — beak + folded wings, stubby; sky-blue.
- **Bronto** — long neck, round body; warm red.
- **Anky** — wide low body + club tail + back plates; mossy green.
Keep Ralph's chibi proportions (oversized head, big eyes, blush, one tooth) as the
family DNA so the whole roster reads as "Ralph's world." Generate Ralph first, lock
the look, then reuse it as the `--cref`/seed reference for the rest.
