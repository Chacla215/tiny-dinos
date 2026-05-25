# Arena background — AI generation prompts

Prompt kit for replacing the procedural `gen_island_bgs.py` arena backgrounds with
lush illustrated pixel-art island dioramas (art-only direction set 2026-05-24;
Tiny Dinos stays a real-time gamepad brawler — the turn-based reference UI is NOT
adopted).

**Targets / rules (all biomes):**
- Render 16:9, **1536×864** (or larger 16:9, downscaled on import).
- Empty stage: no characters, no UI, no text — the title banner and HUD are drawn
  by the game over the top-center and the four corners.
- Composition: a self-contained island ringed by the biome hazard, bridges framing
  left/right, a focal landmark. Solid islands switch to rim ring-out on integration.
- To run: prepend the **shared style block**, append one **biome SCENE block**, then
  the **negative block**. Generate one biome first, then feed it back as a style
  reference so all islands match.

## Shared style + rules (prepend to every biome)

```
A lush, highly detailed pixel-art illustration of a fantasy BATTLE ARENA diorama,
16-bit JRPG style, high-angle 3/4 top-down view. A single self-contained floating
ISLAND platform sits in the center, surrounded on all sides by [HAZARD]. Two small
wooden bridges enter from the left and right edges as framing. Rich painted detail,
soft volumetric lighting, vibrant saturated palette, subtle dithered gradients,
crisp pixel clusters. Decorative banners/flags as set dressing.

COMPOSITION RULES (strict):
- Empty stage only. NO characters, NO creatures, NO people, NO dinosaurs.
- NO UI, NO text, NO words, NO HP bars, NO health bars, NO menu, NO buttons, NO numbers.
- Keep the TOP-CENTER area calm/uncluttered (sky or canopy) — reserved for a title.
- Keep all FOUR CORNERS simple and low-detail — reserved for HUD overlays.
- The central island surface is fairly flat, open and readable, with good contrast
  so characters placed on it later will stand out. Stone-path tiles mark the play space.
- 16:9 widescreen, full-bleed scene.
```

## Negative prompt (append to every biome)

```
text, words, letters, numbers, logo, watermark, signature, UI, HUD, health bar,
HP bar, menu, buttons, characters, people, dinosaurs, creatures, animals, blurry,
lowres, jpeg artifacts, frame border, vignette letterboxing
```

## Iciest Age — Frozen Floes (chosen: option B)

This arena keeps its unique `drown_off_floes` mechanic: the floes are the stage,
the water is the hazard. So its composition breaks the single-island rule above —
override `[HAZARD]`/island language with the SCENE block below.

```
SCENE: several distinct floating ICE FLOES / flat icebergs of varying size, clearly
separated by stretches of dark freezing water — the floes are the stage, the water
between and around them is the hazard. Snow-dusted ice surfaces, blue cracks, a few
icicles. Background: snowy mountains, pale aurora sky, drifting snow. Make the safe
ice plainly readable against the dark water (high contrast). Cold blue-white palette.
```

**Alternative not chosen — option A (solid icy island):** a snow-and-ice island
ringed by a frozen sea, same ring-out rule as the other five. Rejected in favor of
reviving the distinctive floe mechanic.

**Integration notes (Iciest Age):**
- Scene: `scenes/arena_floes.tscn`. Placeholder bg today = procedural
  `assets/tilesets/iciest_floes_bg.png`.
- On import: add the full-bleed `BackgroundImage` sprite, then **align the 5 `Floe`
  Area2D collision polygons to wherever the painted floes sit**, and hide the old
  procedural floe drawings (Rim/Fill/Inner/Crack) so only the art shows.
- Iciest Age does NOT use rim ring-out — it drowns (off all floes for `drown_grace`).

## Other biomes

Purple Fields, Sunny Springs, Beauty Beach, White Water Falls, Laughing Lava use the
single-island composition. Their SCENE blocks belong here too — add when finalized.
