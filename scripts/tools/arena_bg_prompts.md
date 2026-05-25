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

## Purple Fields — regen with cover rocks (v2)

Replaces the v1 open-plaza art. Goal: same lavender cherry-blossom island, but the
field now carries **a few distinct rock formations** so the game can drop matching
**collision cover blocks on visible stone** (v1 was an open field — invisible walls
had nothing to anchor to). The play boundary is now an island-shaped `safe_polygon`
(see main.gd), so the painted island edge should read as a clean **rounded / oval
field** that fills the widescreen — wider than tall, NOT a small circle.

```
SCENE: a single rounded OVAL island that fills the frame width — a circular
stone-paved plaza ringed by lush grass and lavender/pink wildflowers, surrounded
on all sides by calm PURPLE-LAVENDER water with small waterfalls spilling off the
rim. A large blossoming cherry/sakura tree stands at the TOP-CENTER as the focal
landmark (pink canopy kept high and calm for the title). Two wooden bridges enter
from the left and right edges. Place 4 to 5 DISTINCT MOSSY BOULDER CLUSTERS on the
field as cover — sit them around the mid-ring of the plaza (roughly the four sides,
plus one lower-center), each a clear chunky knee-to-waist-high rock pile that reads
as solid blocking cover. KEEP THE EXACT CENTER OF THE PLAZA OPEN (no rock in the
middle) and keep the boulders clearly separated from each other so fighters can weave
between them. Soft purple dusk lighting, sakura petals drifting. High contrast
between the pale stone plaza, the boulders, and the dark water so everything reads.
```

**Integration (after generating):**
1. Drop the chosen image in, point `integrate_arena_bg.py` `SRC` at it, run it to
   resize + bake the `PURPLE FIELDS` title → `assets/tilesets/purple_fields_bg.png`,
   then `godot --headless --import`.
2. Re-trace the boundary: edit `gen_safe_zone.py` CENTER/RX/RY to the new oval,
   run it, paste the printed `safe_polygon` into `arena_purple.tscn`.
3. Add a `StaticBody2D` cover block per painted boulder (world coords from the
   `gen_safe_zone.py` preview's OBSTACLES overlay); these are the "blocks".
4. Turn `debug_draw_safe_zone` back off before shipping.

## Purple Fields — OPEN plaza, no rocks (v3, chosen 2026-05-25)

Charlie cut the cover rocks — wants the same gorgeous v2 island (full sakura tree,
waterfalls, bridges, the oval cliff-lip boundary he confirmed) but a CLEAN, OPEN
fighting field with NO rocks/boulders on it. Regenerate, then integrate (steps 1-2
above; skip the cover-block step). Feed the v2 image back as a style reference so it
matches, and append this to the shared style block:

```
SCENE: a single rounded OVAL island that fills the frame width — a large, fully OPEN
circular stone-paved plaza with a faint concentric ring/mandala motif, ringed by lush
grass and lavender/pink wildflowers, surrounded by calm PURPLE-LAVENDER water with
waterfalls spilling off the rim. A large blossoming cherry/sakura tree stands at the
TOP-CENTER as the focal landmark, with a low wooden fence + stone steps at its base,
and two purple sakura banners flanking it. Two wooden bridges enter from the left and
right edges. The plaza floor is COMPLETELY CLEAR AND UNOBSTRUCTED — NO rocks, NO
boulders, NO stones, NO obstacles anywhere on the playing field. Soft purple dusk
lighting, drifting sakura petals. High contrast between the pale stone plaza and the
dark water.
```

Negative prompt — ADD: `rocks, boulders, stones, rock formations, obstacles on the floor`.

## Beauty Beach — island reskin (1st of the 4 conversions, 2026-05-25)

Converting the 4 remaining arenas to match Purple Fields (island diorama + ring-out).
Beauty Beach is the bright daytime counterpoint to PF's dusk: a sandy island in a
turquoise ocean, open sand fighting floor, palms as the landmark, **water ring-out**
(fall off into the sea). Open field for now — no obstacles (cover can come later).
**Feed the current Purple Fields island in as a STYLE REFERENCE so the islands match.**

Prepend the shared style block (with `[HAZARD]` = "bright turquoise tropical ocean
water with gentle white-foam surf"), append the SCENE block below, then the negative.

```
SCENE: a single rounded OVAL tropical sandbar ISLAND that fills the frame width — a
large, fully OPEN arena of pale packed golden sand with a faint concentric ring pattern
raked into it, fringed by a thin rim of beach grass, seashells and small coral nubs,
surrounded on all sides by bright TURQUOISE tropical OCEAN with gentle white-foam surf
lapping the shore. A pair of leaning coconut PALM TREES stands at the TOP-CENTER as the
focal landmark, with a small driftwood arch / tiki torches and two beach banners. Two
wooden plank piers enter from the left and right edges as framing. The sand floor is
COMPLETELY CLEAR AND UNOBSTRUCTED — NO rocks, NO obstacles anywhere on the playing
field. Bright sunny midday lighting, soft shadows, drifting palm fronds and a gull or
two. High contrast between the pale sand arena and the deep turquoise water.
```

Negative prompt — ADD: `rocks, boulders, stones, obstacles on the floor, people on the beach`.

**Integration (per arena):** drop the image in → point `integrate_arena_bg.py` SRC at it,
set TITLE="BEAUTY BEACH" + beach title colors, run it → reimport → in `arena_beach.tscn`
flip `ledge_kill_enabled=true`, `clamp_to_bounds=false`, add a `safe_polygon` fit to the
sand edge (use `gen_safe_zone.py`), reposition spawns, remove the old procedural Water/
obstacle nodes. Keep `debug_draw_safe_zone=true` until the boundary is confirmed.

## Laughing Lava — island reskin (2nd conversion, 2026-05-25)

A volcanic island floating in a MOLTEN LAVA LAKE — ring-out = fall into the lava (the
existing fall-off-screen handles it; the surrounding lava replaces water). Dark cracked
basalt arena floor for high contrast so the colorful dinos pop. The old interior lava
pool (water_mode="lava") gets removed; lava becomes the surrounding hazard. OPEN field
(no obstacles). **Feed Purple Fields / Beauty Beach in as a STYLE REFERENCE so it matches.**

Prepend the shared style block (with `[HAZARD]` = "a glowing molten LAVA lake of bright
orange-red magma with a dark crust and bubbling hot spots"), append the SCENE block below,
then the negative.

```
SCENE: a single rounded OVAL volcanic ISLAND that fills the frame width — a large, fully
OPEN arena floor of dark cracked basalt / obsidian stone with a faint concentric ring
motif and thin glowing-orange lava cracks, fringed by a rim of charred rock and small
ember-lit vents, surrounded on all sides by a glowing molten LAVA LAKE (bright orange-red
magma with a darker crust and bubbling hot spots) with small LAVA-FALLS spilling off the
rim. A small smoking VOLCANIC SPIRE / obsidian shrine stands at the TOP-CENTER as the
focal landmark, with two dark iron banners and flaming braziers flanking it. Two
basalt-and-iron bridges enter from the left and right edges as framing. The arena floor
is COMPLETELY CLEAR AND UNOBSTRUCTED — NO rocks, NO obstacles anywhere on the playing
field. Hot moody lighting, drifting embers and sparks, a dark smoky sky with an orange
glow on the horizon. High contrast between the dark stone arena and the bright molten lava.
```

Negative prompt — ADD: `water, ocean, blue water, sea, snow, rocks, boulders, obstacles on the floor`.

## White Water Falls — island reskin (3rd conversion, 2026-05-25)

An island at the BRINK of a massive waterfall, ringed by whitewater rapids — ring-out =
swept off into the falls. KEEPS its signature mechanic: `global_current = (0, 110)` (a
constant downward push), so the bottom/front rim must read clearly as the waterfall brink
(you drift toward it and get swept over). Wet mossy-stone arena floor (pale, for contrast).
OPEN field. **Feed Purple Fields / Beauty Beach in as a STYLE REFERENCE so it matches.**

Prepend the shared style block (with `[HAZARD]` = "rushing turquoise-white whitewater
rapids pouring off into a misty waterfall gorge"), append the SCENE block below, then negative.

```
SCENE: a single rounded OVAL river ISLAND that fills the frame width — a large, fully
OPEN arena floor of wet, smooth pale mossy stone with a faint concentric ring motif and
trickling water channels, fringed by mossy rocks, reeds and small white wildflowers,
surrounded on all sides by rushing turquoise-white WHITEWATER RAPIDS. The FRONT / BOTTOM
rim is the BRINK of a massive WATERFALL pouring off into a misty gorge below (visible
cascading water, rising mist and a faint rainbow at the bottom). A mossy stone monument /
small shrine with a trickling spring stands at the TOP-CENTER as the focal landmark, where
the upstream river feeds in, flanked by two banners and lanterns. Two wet wooden plank
bridges enter from the left and right edges as framing. The arena floor is COMPLETELY
CLEAR AND UNOBSTRUCTED — NO rocks, NO obstacles anywhere on the playing field. Cool misty
daylight, drifting spray and a faint rainbow, lush and fresh. High contrast between the
pale wet-stone arena and the rushing white water.
```

Negative prompt — ADD: `lava, fire, snow, desert, rocks, boulders, obstacles on the floor`.

## Sunny Springs — island reskin (4th conversion, 2026-05-25)

Charlie chose FULLY OPEN (no slow-pools) — Sunny Springs becomes the bright green-meadow
counterpoint: a lush grassy island in crystal-clear spring water, sunny midday, water
ring-out. Drops its old slow-pools + blocking ruins. Distinct from Purple Fields (dusk
lavender) and Beach (sand) by being GREEN + sunny. **Feed Purple Fields / Beauty Beach in
as a STYLE REFERENCE so it matches.**

Prepend the shared style block (with `[HAZARD]` = "crystal-clear turquoise spring water
with gentle cascades spilling off the rim"), append the SCENE block below, then negative.

```
SCENE: a single rounded OVAL spring ISLAND that fills the frame width — a large, fully
OPEN arena of lush green meadow grass with a faint concentric ring of pale flagstones set
into it, fringed by mossy rocks, reeds and abundant colorful wildflowers, surrounded on
all sides by crystal-clear TURQUOISE SPRING WATER with gentle cascades spilling off the
rim. A mossy stone SPRING FOUNTAIN / natural spring source with bubbling clear water
stands at the TOP-CENTER as the focal landmark, flanked by two green banners and stone
lanterns. Two wooden plank bridges enter from the left and right edges as framing. Rolling
green hills and soft mountains on the bright horizon. The arena floor is COMPLETELY CLEAR
AND UNOBSTRUCTED — NO rocks, NO pools, NO obstacles anywhere on the playing field. Warm
sunny midday light, drifting pollen and a butterfly or two, fresh and lush. High contrast
between the green meadow arena and the bright spring water.
```

Negative prompt — ADD: `lava, fire, snow, desert, rocks, boulders, pools on the floor, obstacles on the floor`.

## Iciest Age — single ice island (LAST, regen 2026-05-25)

DESIGN CHANGE: the multi-floe / drown-off-floes version was DROPPED — the game has no jump
control, so separate floes you can't cross don't make sense (Charlie's call). Iciest Age is
now a normal SINGLE-ISLAND RING-OUT arena like the other 5: one big solid ICE island in dark
freezing water, fall off = KO. First gen (cache .../17.png) was the 5-floe layout — superseded.
Regenerate as ONE solid island. **Feed an existing island (Purple Fields/Beach) in as a STYLE
REFERENCE.** Integration = the standard pipeline (NOT the floe one): rewrite arena_floes.tscn
to drown_off_floes=false, ledge_kill=true, remove the Floe node + procedural drawings, add
safe_polygon fit to the ice edge, spawns on the ice. Title "ICIEST AGE", cold blue-white, icon_drop.

Prepend the shared style block (with `[HAZARD]` = "dark, freezing near-black water with
drifting ice chunks and small icicle-falls off the rim"), append the SCENE block, then negative.

```
SCENE: a single rounded OVAL ICE ISLAND that fills the frame width — a large, fully OPEN
arena floor of smooth pale blue-white ICE with a faint concentric ring motif and subtle
frost cracks, fringed by snowdrifts, jagged ice chunks and small purple ice-crystals,
surrounded on all sides by DARK freezing near-black water with thin drifting ice chunks and
small frozen icicle-falls spilling off the rim. A glowing AURORA-CRYSTAL SHRINE (a stone arch
holding a bright blue gem) stands at the TOP-CENTER as the focal landmark, flanked by two blue
snowflake banners and ice braziers. Two frosted wooden bridges enter from the left and right
edges as framing. Background: snowy mountains and a pale green-blue AURORA night sky, drifting
snow. The arena floor is COMPLETELY CLEAR AND UNOBSTRUCTED — NO rocks, NO obstacles anywhere
on the playing field. Cold moody lighting, high contrast between the bright ice arena and the
dark water.
```

Negative prompt — ADD: `lava, fire, desert, green grass, sand, several separate floes, multiple small islands, archipelago, rocks, obstacles on the floor`.
