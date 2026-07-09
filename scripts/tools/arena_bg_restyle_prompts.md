# Arena backgrounds — restyle to match the chibi cast

Charlie's call (2026-07-05): with the roster moving to Ralph's cute-cuddly
chibi look, the islands should match. This kit RESTYLES the six existing
arenas — **same islands, same layout, new render style** — from 16-bit
pixel-art dioramas to the soft storybook-painterly look of the cast.

**The one golden rule: KEEP THE COMPOSITION IDENTICAL.** Same island shape,
same position in frame, same bridges/landmark placement. The game's
collision boundaries, spawn points, and title placement are all traced to
the current art — if the new image keeps the layout, integration is a pure
art swap (Claude just re-runs `integrate_arena_bg.py`); if the island edge
moves, boundaries have to be re-traced per arena.

## How (image-to-image restyle, per arena)

1. Upload the arena's CURRENT background as the **composition reference**:
   - `assets/tilesets/beauty_beach_bg.png`
   - `assets/tilesets/purple_fields_bg.png`
   - `assets/tilesets/laughing_lava_bg.png`
   - `assets/tilesets/white_water_falls_bg.png`
   - `assets/tilesets/sunny_springs_bg.png`
   - `assets/tilesets/iciest_age_bg.png`
2. Also upload `assets/concept/ralph/ralph_hero.png` as the **style anchor**.
3. Prompt = the RESTYLE block below (+ the arena's SCENE block from
   `arena_bg_prompts.md` if the tool needs more description).
4. Generate 16:9 at 1536×864 or larger.
5. Save to `assets/concept/islands/restyle/<arena>.png`
   (beach / purple / lava / falls / springs / floes).

**Do BEAUTY BEACH first and stop** — it's also the trailer set. Claude
integrates it, drops restyled dinos on it, and screenshots the combo
in-game. Only batch the other five once that read is confirmed.

## RESTYLE block (prepend to every arena)

```
Re-render this exact scene in a soft STORYBOOK PAINTERLY style matching the
reference character: the same cute polished mobile-game art language as the
chibi dino — soft rounded shapes, smooth clean shading, rich saturated
colors, gentle cinematic lighting, minimal noisy texture, crisp readable
edges. Keep the EXACT SAME COMPOSITION as the reference image: same island
shape and position, same bridges, same landmark placement, same camera
angle. A wholesome, joyful, storybook island world — like a cutscene
background from a beloved family game.

COMPOSITION RULES (strict):
- Empty stage only. NO characters, NO creatures, NO people, NO dinosaurs.
- NO UI, NO text, NO words, NO HP bars, NO menu, NO buttons, NO numbers.
- Keep the TOP-CENTER area calm/uncluttered — reserved for the title.
- Keep all FOUR CORNERS simple and low-detail — reserved for HUD overlays.
- The central island floor stays fairly flat, OPEN and readable, with good
  contrast so the colorful dinos standing on it pop. No obstacles on it.
- 16:9 widescreen, full-bleed scene.
```

## Negative (append to every arena)

```
text, words, letters, numbers, logo, watermark, UI, HUD, health bar, menu,
buttons, characters, people, dinosaurs, creatures, animals, blurry, lowres,
jpeg artifacts, frame border, vignette letterboxing, harsh pixel dithering,
gritty realistic texture, photorealistic, dark gloomy mood, obstacles on
the playing field
```

## Integration (Claude's job)

Per arena: point `integrate_arena_bg.py` at the new image (SRC/DST/TITLE
per arena), run → `godot --headless --import` → arena_shot screenshots to
verify the read with fighters on top. Spot-check the island edge against
the existing `safe_polygon`; re-trace with `gen_safe_zone.py` only if the
painted edge moved. The 0-th check on Beauty Beach: restyled dinos + restyled
island + HUD, all in one screenshot, before greenlighting the other five.

## Gotchas

- Keep the hazard readable: the sea/lava/rapids around the island must stay
  high-contrast against the floor — soft style must NOT mean low stakes.
  If the ring-out edge stops reading, regenerate with "high contrast between
  the island floor and the surrounding water/lava" re-emphasized.
- Iciest Age uses `iciest_age_bg.png` (the single-island version), NOT the
  old `iciest_floes_bg.png`.
- If the model fights the "no characters" rule (they love adding a cute
  creature to cute scenes), regenerate — never accept a stowaway dino.
