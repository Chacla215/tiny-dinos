# Roster restyle — bring the 5 other dinos to Ralph's chibi look

**Why:** the intended roster style (per `dino_art_prompts.md`) is "the same
painterly-CHIBI style as Ralph." During generation the other five (raptor, trike,
pterry, bronto, anky) **drifted too detailed / semi-realistic** — Ralph is the only
one still on the cute chibi brand. Decision (2026-06-15): re-render the five toward
Ralph so the roster is consistent. Reference: `assets/concept/ralph/ralph_hero.png`.

**Pipeline (who does what):** Claude can't generate the images in-tool. Charlie runs
each prompt in his image tool → drops `assets/concept/<dino>/<dino>_hero.png` →
Claude rebakes + wires:
```
python3 scripts/tools/gen_ralph_fighter.py <dino>           # in-match fighter sheet (prints ANIM_LAYOUTS)
python3 scripts/tools/gen_ralph_fighter.py <dino> --parts   # runtime-rig parts + rig.json
```
then paste the printed `SHEET_`/`ANIM_LAYOUTS` block into `dino.gd` and verify
(arena_shot snapshots). Skin-variant portraits (`<dino>_<skin>.png`) are
secondary — in-match skins are shader recolors, so only the base hero gates the look.

## How to build each prompt
For each dino, take **its CHARACTER BIBLE verbatim from `dino_art_prompts.md`** and
wrap it with the RESTYLE directive + NEGATIVE below. The bible keeps the species
on-model (silhouette + signature detail); the wrapper forces Ralph's flatter, cuter
chibi render instead of the over-detailed look they drifted to.

### RESTYLE directive (prepend after the bible)
```
RENDER STYLE — match Ralph (assets/concept/ralph/ralph_hero.png) exactly: cute
painterly-CHIBI mascot, SOFT and ROUNDED, chunky baby proportions, OVERSIZED head
(~1.5 heads tall), big simple expressive eyes with bright catchlights, gentle rosy
cheek blush, smooth CLEAN flat-ish shading with soft cinematic lighting, rich
saturated colors, minimal surface texture, crisp readable silhouette, friendly
big-hearted expression. Full body, heroic 3/4 front standing pose, FLAT plain
background. Sticker-clean cutout.
```

### NEGATIVE (append)
```
detailed realistic scales, heavy texture, photorealistic, semi-realistic, 3d
render, sharp teeth/claws menacing, gritty, dramatic harsh shadows, fine scale
detail, aggressive, lanky/realistic proportions, small head, harsh black outline,
text, watermark, multiple characters, extra limbs, deformed
```

## Per-dino quick reference (full bibles in dino_art_prompts.md)
- **raptor (MAX)** — keep red scales + feather tuft, but cute/chibi not fierce.
- **trike (GUS)** — keep three horns + frill, chunky-cute.
- **pterry (JESSIE)** — keep wings + crest, round baby flyer.
- **bronto (STEVE)** — keep long neck, gentle-giant chibi.
- **anky (FRANK)** — keep club tail + armor plates + the little leaf sprout, rounded-cute.

Keep each species' signature detail; change ONLY the render style toward Ralph.
