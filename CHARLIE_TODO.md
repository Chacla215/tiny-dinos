# Charlie's to-do list — the art-generation program

The super-simple version. Do the steps in order. After each step, just tell
Claude "I did step N" — Claude does ALL the wiring, baking, and checking.

Every step is the same three moves:
**open your AI tool → copy-paste a prompt from the kit file → save the
result to the folder the kit names.**

---

## STEP 1 — Make the 5 cute dinos  (do this first, everything needs it)

1. Open your **image** tool.
2. Open the kit: `scripts/tools/dino_chibi_restyle_prompts.md`.
3. For each dino (raptor, trike, pterry, bronto, anky):
   - Upload `assets/concept/ralph/ralph_hero.png` as the style reference.
   - Copy-paste: that dino's CHARACTER BIBLE (from
     `scripts/tools/dino_art_prompts.md`) + the RESTYLE directive + the
     NEGATIVE (both from the restyle kit).
   - Generate 4, pick the cutest one that keeps the dino's signature detail.
   - Save it as `assets/concept/<dino>/<dino>_hero.png` (overwrite the old one).
4. Tell Claude: **"I did step 1"** → Claude rebakes every fighter, rig, and
   portrait so the game matches.

## STEP 2 — Make ONE island (Beauty Beach) and stop

1. Open your **image** tool.
2. Open the kit: `scripts/tools/arena_bg_restyle_prompts.md`.
3. Upload TWO pictures: `assets/tilesets/beauty_beach_bg.png` (the layout to
   keep) and your new `ralph_hero.png` (the style to match).
4. Copy-paste the RESTYLE block + the NEGATIVE from the kit.
5. Save the result as `assets/concept/islands/restyle/beach.png`.
6. Tell Claude: **"I did step 2"** → Claude puts it in the game with the new
   dinos on top and shows you a screenshot. If you love it, Claude says go,
   and you repeat this step for the other 5 islands (same kit, same moves).

## STEP 3 — Shoot the trailer

1. Open **Seedance 2.0** (video tool).
2. Open the kit: `scripts/tools/trailer_prompts.md`.
3. Shoot the 6 shots in order (each one: upload the reference pictures the
   kit lists, copy-paste the STYLE BLOCK + that shot's prompt, 5-8 seconds).
4. Save each as `assets/concept/trailer/shot01_island.mp4` … `shot06_freeze.mp4`
   (exact names are in the kit).
5. Tell Claude: **"I did step 3"** → Claude edits the trailer (music, logo,
   cuts) AND makes the short version play when the game starts.

## STEP 4 — (later) Make the fighting-move clips

1. Open **Seedance 2.0** again.
2. Open the kit: `scripts/tools/dino_motion_prompts.md`.
3. Pilot first: just TWO clips — Ralph `walk` and Ralph `attack`.
4. Save to `assets/concept/ralph/motion/walk.mp4` and `attack.mp4`.
5. Tell Claude: **"I did step 4"** → Claude bakes them into the game so the
   dinos animate with real motion. If it looks great, the rest of the roster
   gets the same treatment.

---

**Rules of thumb**
- One step at a time; pilots before batches (that's why step 2 is ONE island).
- If a generation looks off-model (wrong colors, missing scar/feather/horn
  chip, too realistic), regenerate — never save a "close enough".
- Stuck or unsure? Just ask Claude and paste what you got.
