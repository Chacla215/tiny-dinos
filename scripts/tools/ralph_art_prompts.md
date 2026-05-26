# Ralph — AI character-art generation prompts

Prompt kit for the high-fidelity **Ralph** art seen in the creator-screen target
(`assets/concept/ralph_creator_target.png`). This is the **tier-1 menu/portrait
art** (creator screen, skins carousel, emotes, signature-move card). Tier-2 = the
simple in-match gameplay sprite, which stays procedural (`gen_ralph.py`).

## How to use this kit (READ FIRST — consistency is everything)

1. **Generate the DEFAULT hero first** (the "Ralph — base" prompt). Iterate until
   it's perfect. This single image becomes your **character reference** for
   everything else.
2. For every other asset (skins, emotes, move icon), **reuse the CHARACTER BIBLE
   block verbatim** + the per-asset override, AND feed the approved hero back in as
   a reference image so the design stays identical:
   - **Midjourney:** add `--cref <hero_image_url> --cw 80` (lower `--cw` lets the
     outfit/color change while keeping the face/shape). Reuse `--seed` for repeats.
   - **DALL·E 3 / GPT image:** attach the hero as a reference and say "same
     character, same style, keep face/proportions identical, change only X."
   - **Stable Diffusion:** same seed + IP-Adapter / reference-only ControlNet on the
     hero, denoise ~0.5–0.6.
3. **Pipeline choice (recommended):** render each Ralph as a **full-body figure on a
   FLAT plain background** (easy to cut out → transparent PNG via remove.bg / SD
   transparency), and render the **diorama backdrop separately, once** (no
   character). The game composites skins over the same backdrop and shows clean
   busts in the carousel. (The target image bakes them together — don't; keep them
   separable so skins can swap.)
4. Targets: hero/skin figures **1024×1024** (or portrait 832×1216); emotes **512×512**;
   move icon **512×512**; backdrop **1536×864** 16:9.

---

## CHARACTER BIBLE — prepend to EVERY Ralph prompt (do not edit)

```
A cute chibi baby dinosaur character named Ralph. Polished mobile-game creature
art: semi-painterly cartoon with subtle pixel-art-influenced detailing, soft
cinematic lighting, rich saturated colors, smooth clean shading, crisp readable
silhouette. Chunky rounded body, OVERSIZED head (about 1.5 heads tall total),
short stubby arms, thick little feet, a short stubby tail. Smooth SOFT MINT-GREEN
scales, a CREAMY off-white belly, a row of LIGHT TURQUOISE rounded spikes running
over his head and down his back, WARM TAN foot pads. LARGE expressive AMBER-GOLD
eyes with bright catchlights (his standout feature), ROSY PINK blush on both
cheeks, a wide gentle closed smile showing ONE tiny tooth, tiny nostrils on a soft
rounded snout. SIGNATURE DETAILS (always present): ONE small BROKEN, snapped-off
horn on the LEFT side of his head (flat jagged tip, pale bone center), and ONE
tiny green LEAF tucked behind a spike. Brave, curious, slightly goofy, big-hearted
expression.
```

## NEGATIVE — append to EVERY prompt

```
text, words, letters, numbers, logo, watermark, signature, UI, HUD, health bar,
buttons, frame, border, multiple characters, duplicate, twins, extra limbs, extra
horns (only ONE broken horn), missing leaf, deformed, mutated, blurry, lowres,
jpeg artifacts, photorealistic, 3d plastic render, harsh black outline, sticker
outline, cluttered background
```

---

## HERO — Ralph (default / base) — GENERATE THIS ONE FIRST

```
[CHARACTER BIBLE]
Full body, standing confidently in a cute heroic pose, 3/4 front view facing
slightly right, centered, weight on both feet. NEUTRAL design: plain mint Ralph,
no hat, no outfit, just the leaf and broken horn. Friendly proud smile.
Background: a single FLAT soft neutral background (light grey-blue), even studio
lighting, soft contact shadow under the feet. Clean cut-out-ready figure.
```

> Want the showcase version that matches the target image? Swap the background line
> for: *"Background: standing on a small circular mossy stone platform in a lush
> fantasy waterfall-and-mountain diorama, soft clouds, depth-of-field."* — but keep
> a flat-background copy too, for compositing into the game.

---

## SKINS — same Ralph, override only the listed traits (use hero as `--cref`)

Each: `[CHARACTER BIBLE]` + the override block + the hero "Full body … FLAT neutral
background … cut-out-ready" framing from above. **Keep face, eyes, proportions,
broken horn, and leaf identical** — change ONLY what's listed.

**⭐ Common — Explorer Ralph**
```
OVERRIDE: wearing a tan explorer's PITH HELMET and a small RED ADVENTURER'S SCARF
around his neck. Keeps mint scales. Plucky little-explorer vibe.
```

**⭐⭐ Rare — Crystal Ralph**
```
OVERRIDE: his spikes are translucent faceted CRYSTAL GEMS (icy cyan-blue), faint
inner glow, a few small crystal shards on his back, cool aquamarine sheen on the
mint scales. Precious, sparkly.
```

**Volcano Ralph**
```
OVERRIDE: dark CHARCOAL-GREY scales, a glowing ORANGE belly, spikes like molten
FLAMES (orange-yellow), thin GLOWING LAVA CRACKS across his body, warm ember light.
Fierce but cute.
```

**Frozen Ralph**
```
OVERRIDE: PALE ICE-BLUE scales, a WHITE belly, sharp pale-blue ICE/CRYSTAL spikes,
a dusting of frost and tiny snowflakes, cool rim light. Chilly and adorable.
```

**Spring Ralph**
```
OVERRIDE: soft fresh-green scales, a little PINK FLOWER CROWN of blossoms around his
head, small flowers tucked by his spikes, a couple petals drifting, warm sunny
light. Gentle, bloom-y.
```

**Void Ralph**
```
OVERRIDE: deep COSMIC PURPLE scales speckled with tiny glowing STARS like a galaxy,
spikes glowing CYAN, faint cyan glow in the eyes and a soft nebula aura. Mysterious,
magical.
```

**Golden Ralph**
```
OVERRIDE: gleaming WARM GOLD scales, a white belly, ROYAL-BLUE spikes, small regal
gold trim, a soft luxurious shine. Regal, prized.
```

### Premium rarity skins (from the brief, beyond the target image)

**⭐⭐⭐ Epic — Robo Ralph**
```
OVERRIDE: a cute MECHANICAL/ROBOT Ralph — brushed-metal plating over the body,
glowing blue LED eyes, riveted panel seams, antenna, the broken horn replaced by a
short snapped metal rod. Still chunky and adorable, sci-fi toy feel.
```

**⭐⭐⭐⭐ Legendary — Galaxy Ralph**
```
OVERRIDE: his body is a living GALAXY — deep space-blue/violet scales filled with
swirling nebulae and bright stars, spikes made of pure starlight, a glowing cosmic
aura, sparkling stardust trail. Awe-inspiring, radiant.
```

**⭐⭐⭐⭐⭐ Mythic — Ancient Dragon Ralph**
```
OVERRIDE: a majestic ANCIENT DRAGON form — still chibi and cute, but with larger
tall JAGGED DRAGON SPIKES, small leathery dragon wings, glowing rune markings on the
scales, deeper emerald-and-gold coloring, tiny curved claws, an epic mythical aura.
Legendary boss energy in a tiny body.
```

---

## EMOTES — 8 small expressive poses (512×512, flat neutral bg)

Each: `[CHARACTER BIBLE]` + `"Small full-body emote pose, exaggerated cartoon
expression, centered, FLAT neutral background, cut-out-ready."` + the pose line.
Use the DEFAULT mint Ralph for all 8 so they read as one character.

1. **Happy wave** — `beaming open smile, one little arm raised in a friendly wave.`
2. **Excited** — `mouth wide open in delight, eyes sparkling, both arms up, tiny motion lines (!).`
3. **Confused** — `head tilted, one eyebrow up, a small question-mark, puzzled half-smile.`
4. **In love** — `blushing hard, eyes turned to little hearts (or a heart floating above), hands clasped.`
5. **Tiny roar** — `mouth open in a brave little roar, chest puffed, small squeaky sound lines.`
6. **Sleepy** — `eyes closed, content, a small sleep bubble, gently dozing/sitting.`
7. **Dizzy / fell over** — `flopped on his back, dazed swirl eyes, little stars/puffs around his head.`
8. **Proud sparkle** — `chest puffed proudly, chin up, confident grin, sparkles around him.`

---

## SIGNATURE MOVE icon — Tiny Meteor Stomp (512×512)

```
[CHARACTER BIBLE]
Ralph mid-move: leaping/curled into a spinning ball as he CRASHES down, a bright
circular SHOCKWAVE ring of energy bursting outward beneath him with little glowing
DINOSAUR FOOTPRINTS inside the ring, impact dust, dynamic action pose, glowing blue
energy. Centered, dark vignette-free flat backdrop. Heroic and fun.
```

---

## CUSTOMIZATION item icons (optional, 256×256 each, flat bg)

Single object, no character, same painterly style, soft icon lighting, centered:
- **Head:** a tan explorer pith helmet.
- **Spikes:** a single light-turquoise crystal spike.
- **Outfit:** a folded red adventurer's scarf.
- **Neck:** a small gold pendant necklace.
- **Tail:** a green leaf-shaped tail tip.
- **Color:** a round multi-color paint palette / color wheel.

---

## Notes / gotchas
- If skins drift off-model, lower `--cw` is NOT the fix — raise it and instead
  reword the override to be additive ("keeps mint Ralph's face and shape, only…").
- Always re-state "ONE broken horn on the left + one leaf" — generators love to add
  symmetric horns or drop the leaf.
- Generate 4, pick the most on-model, upscale that one.
- Keep a master folder of approved PNGs; drop them in `assets/concept/ralph/` and I
  wire them into the creator screen.
