# PLAN — make in-game fighter sprites match the trailer (painterly chibi)

**Goal:** the dinos you fight with in-match should look like the dinos in the
trailer. Right now they don't: the trailer uses the painterly-chibi **hero
PNGs**, but the game loads **3D-toon-baked** sprite sheets — a different art
lineage. Rebuild the fighter sheets from **Seedance painterly motion clips**
(the same look as the trailer), starting with **Ralph as a prototype**, then
roll out to all 6.

Read first: `CLAUDE.md`, then memory files `trailer-progress`,
`seedance-motion-pipeline`, `blender-sprite-pipeline`, `dino-chibi-restyle-plan`.
This plan is the source of truth for this task.

---

## Why they mismatch (diagnosis, already done)

- In-match fighters load `*_fighter_3d.png`, referenced in `scripts/dino.gd:14-19`
  (`SHEET_RALPH`…`SHEET_ANKY`). These were **Meshy 3D → Blender toon-baked**
  (stamped 2026-07-06 18:47). Real posed frames, but a different style from the
  painterly heroes.
- The **trailer** uses the painterly hero PNGs: `assets/concept/<dino>/<dino>_hero.png`
  (ralph, raptor, trike, pterry, bronto, anky).
- The motion pilots **already generated** and proven-clean this session:
  `assets/concept/ralph/motion/walk.mp4` and `attack.mp4` — 720p, ~4s, Seedance
  2.0, locked-off grey-blue studio, Ralph facing 3/4 front-right, moving in place.
  These are the proof that Seedance produces painterly-hero-style motion we can
  slice into frames.

## Target sheet format (exact — from `dino.gd` ANIM_LAYOUTS, lines 21-68)

Each fighter sheet is ONE horizontal strip, **height = 168px**, **9 frames**
left-to-right in this order, each frame `W × 168`:

| frames | anim | count | notes |
|---|---|---|---|
| 0–1 | idle   | 2 | `loop:true, speed:4` |
| 2–5 | walk   | 4 | `loop:true, speed:8` — one full cycle |
| 6–8 | attack | 3 | `loop:false, speed:12` — windup/strike/recover |

Per-dino cell width `W` (current): ralph 138, raptor 130, trike 169, pterry 155,
bronto 143, anky 191. Character ~132px tall inside the 168 cell, **feet baseline
constant across all 9 frames**, **facing RIGHT** (dino.gd flips for left-movers;
no per-sheet faces_left flag — sheets must be authored facing right). `"motion":
true` makes the game play the frames via AnimatedSprite2D. You may change `W`
per dino as long as you update the Rect2 cells in ANIM_LAYOUTS to match.

---

## Pipeline (per dino)

1. **Get 3 motion clips** in painterly-hero style: walk, attack, idle.
   - Ralph: walk + attack already exist. Still need an **idle** (subtle
     breathing/bob loop) — or slice two near-neutral frames from the walk clip.
   - Other 5 dinos: generate all three via Higgsfield Seedance 2.0. Recipe is
     PROVEN (see `trailer-progress` memory): `<dino>_hero.png` as **start_image**,
     locked-off studio prompt (adapt PASTE 13/14 in `PASTE_ME.md`), 720p / std /
     16:9 / 4s / `generate_audio:false`, **decline the "IN THE DARK" preset**
     (pass `declined_preset_id`). ~18 credits/clip.
2. **Extract frames** with ffmpeg: 4 walk frames evenly spaced across ONE cycle
   (walk clip ~2 cycles/sec), 3 attack frames (windup/strike/recover), 2 idle.
3. **Cut out the studio background** → transparent PNG. Two options: Higgsfield
   `remove_background` per frame, OR reuse the PIL corner-key logic already in
   `scripts/tools/gen_ralph_fighter.py` (`sample_bg`, alpha ramp) — the grey-blue
   studio keys cleanly.
4. **Normalize**: trim to content, scale so character ≈132px tall, align every
   frame to a **constant feet baseline** and horizontal center inside a `W×168`
   cell, flip to face RIGHT if needed.
5. **Pack** the 9 cells into one horizontal `(9·W)×168` strip →
   `assets/sprites/<dino>_fighter_paint.png`.
6. **Wire in**: update `dino.gd` `SHEET_<DINO>` to the new file + its ANIM_LAYOUTS
   `idle/walk/attack` Rect2 cells (keep `"motion": true`).
7. **Validate**: `/opt/homebrew/bin/godot --headless --import` then
   `--headless --quit-after 120 2>&1 | grep -iE "error|invalid|parse"`.
8. **Eyeball**: run windowed, drop into a beach match (or reuse
   `scripts/tools/capture_gameplay.gd` — boots a 4-CPU beach FFA) and compare the
   dino against its trailer shot.

**Prototype Ralph end-to-end first.** Only once one dino clearly matches the
trailer in-engine, roll the same pipeline across the other 5. Consider writing a
reusable `scripts/tools/bake_paint_fighter.py` (frames-dir → cutout → normalize →
pack → print Rect2 block) so dinos 2-6 are one command each — mirror the ergonomics
of `gen_ralph_fighter.py`, which already prints the ANIM_LAYOUTS block.

---

## Decisions to confirm with Charlie EARLY

1. **Smooth vs dither.** Trailer look = smooth painterly (no Bayer dither). The
   existing `gen_ralph_fighter.py` deliberately dithers so dinos read as pixel art
   on the **pixel** islands. Going smooth to match the trailer implies the islands
   should move painterly too (the restyled `assets/concept/islands/restyle/beach.png`
   already exists but may NOT be wired into `scenes/arena_beach.tscn` yet).
   → Recommend: **smooth, no dither**, and treat island-restyle as the natural
   follow-up (it's already in the chibi-restyle program). Confirm before baking.
2. **Idle source:** generate a dedicated idle clip per dino, or derive idle from
   the walk clip's neutral frames? (Cheaper: derive.)

## Gotchas

- **Facing:** author every sheet facing RIGHT. Per `gen_ralph_fighter.py` notes +
  `grab-anatomy-per-dino` memory, native hero facings are mixed; some need a flip.
  The motion prompts asked for 3/4 front-right, so most clips should already read
  right — verify per dino.
- **Skins:** `assets/shaders/skin_recolor.gdshader` recolors the DEFAULT sprite by
  hue. Keep the baked art clean/neutral so the recolor still reads (see
  `MatchConfig.skin_material`).
- **Cell width changes** are fine but MUST be reflected in every Rect2 in that
  dino's ANIM_LAYOUTS block, and the sheet total width must equal `9 × W`.
- Old `*_fighter.png` (2D dither) and `*_fighter_3d.png` (toon) stay on disk as
  history — just repoint the `SHEET_` const.

## Budget / tools

- Higgsfield Seedance 2.0 via MCP. ~18 cr per 4s 720p std clip. 5 dinos × 3 clips
  ≈ 270 cr, + Ralph idle ≈ 18. Balance was ~900+ after the trailer run — plenty.
- `remove_background` (Higgsfield) or PIL keying for cutouts. ffmpeg for frame
  extraction + packing. All available locally.

## Definition of done

All 6 dinos in-match render in the painterly-chibi trailer style with working
idle/walk/attack, pass headless validation, and read cleanly against their island
(island-restyle may be a follow-up task). Commit atomically per theme
(`Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`).
