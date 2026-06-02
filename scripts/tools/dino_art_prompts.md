# Roster — AI character-art generation prompts (T-Rex, Raptor, Trike, Pterry, Bronto, Anky)

Companion to `ralph_art_prompts.md`. Same style, same workflow — this kit covers
the **other five dinos** so each gets a hero portrait that matches Ralph's
fidelity, plus the same skin system. Each species has its own CHARACTER BIBLE
(the recipe that keeps the dino on-model across every render); skin overrides
are shared because skins are palette/material/accessory swaps that read the
same on any chibi body.

## How to use this kit (READ FIRST)

1. **Generate each species' DEFAULT hero first** (the "Hero" prompt under each
   bible). Iterate until it nails the silhouette + signature detail (scar,
   feather tuft, chipped horn, etc.) — this is the reference for everything else.
2. Drop the approved hero PNGs into `assets/concept/<dino>/`:
   - `assets/concept/trex/trex_hero.png`
   - `assets/concept/raptor/raptor_hero.png`
   - `assets/concept/trike/trike_hero.png`
   - `assets/concept/pterry/pterry_hero.png`
   - `assets/concept/bronto/bronto_hero.png`
   - `assets/concept/anky/anky_hero.png`
   The character screen looks for those paths and auto-swaps the pixel-sprite
   placeholder once they exist (see `scripts/ralph_creator.gd`).
3. For SKINS, reuse the species CHARACTER BIBLE verbatim and append a skin
   override from the "Shared skin overrides" section. Feed the species hero in
   as a `--cref` / reference image so the silhouette + signature details survive.
4. **Style note:** keep every render in the same painterly-chibi style as Ralph
   — polished mobile-game creature art, semi-painterly cartoon with subtle
   pixel-art-influenced detailing, soft cinematic lighting, rich saturated
   colors, smooth clean shading, crisp readable silhouette. Targets: hero
   figures **1024×1024**, emotes **512×512**, FLAT plain background so they
   cut out clean.

## SHARED NEGATIVE — append to every prompt

```
text, words, letters, numbers, logo, watermark, signature, UI, HUD, health bar,
buttons, frame, border, multiple characters, duplicate, twins, extra limbs,
deformed, mutated, blurry, lowres, jpeg artifacts, photorealistic, 3d plastic
render, harsh black outline, sticker outline, cluttered background
```

---

# 1) T-REX — "The King"

## CHARACTER BIBLE (prepend to every T-Rex prompt)

```
A cute chibi baby T-rex character. Polished mobile-game creature art:
semi-painterly cartoon with subtle pixel-art-influenced detailing, soft
cinematic lighting, rich saturated colors, smooth clean shading, crisp
readable silhouette. Chunky rounded chibi body, OVERSIZED head (about 1.6
heads tall total), iconic comically TINY arms held up at the chest, two
sturdy thick legs, a thick stubby tail held off the ground for balance.
WARM SCARLET-RED scales across the body and head, a CREAM off-white belly
stripe down the chest, a row of SOFT DARK-GREEN dorsal stripes along the
back from neck to tail tip. LARGE expressive GOLDEN-YELLOW eyes with bright
catchlights, a wide brave grin showing a top AND bottom row of small white
teeth (the toothy smile is his charm), tiny nostrils on a broad rounded
snout. SIGNATURE DETAIL (always present): a small pale SCAR running diagonally
across the right side of the snout. Bold, swaggering, dramatic-but-soft
expression — a tiny king.
```

## HERO — T-Rex (default / base)

```
[CHARACTER BIBLE]
Full body, standing confidently in a heroic king-of-the-island pose, 3/4 front
view facing slightly right, chest puffed, tail counter-balancing back-left,
weight on both feet. NEUTRAL design — plain scarlet T-Rex, no hat, no outfit,
only the signature snout scar. Friendly brave smile.
Background: a single FLAT soft neutral background (light grey-blue), even
studio lighting, soft contact shadow under the feet. Clean cut-out-ready figure.
```

---

# 2) RAPTOR — "The Speedster"

## CHARACTER BIBLE (prepend to every Raptor prompt)

```
A cute chibi baby velociraptor character. Polished mobile-game creature art:
semi-painterly cartoon with subtle pixel-art-influenced detailing, soft
cinematic lighting, rich saturated colors, smooth clean shading, crisp
readable silhouette. Sleek streamlined chibi body (still chunky-cute, about
1.7 heads tall total), small forward-leaning posture poised on tippy-toes,
slim arms with three little claws, long counterbalancing tail held straight
back, sickle CLAW raised on each foot. Bright CRIMSON-RED scales, a WHITE
underside running from chin down the belly, CHARCOAL-GREY stripes running
horizontally across the back and tail. LARGE expressive YELLOW eyes with
bright catchlights, an eager toothy grin, tiny nostrils on a slim pointed
snout. SIGNATURE DETAILS (always present): a soft TUFT OF RED FEATHERS running
from the forehead down the spine, plus a single WHITE FEATHER tucked behind
the LEFT ear. Quick, clever, mischievous expression.
```

## HERO — Raptor (default / base)

```
[CHARACTER BIBLE]
Full body, mid-stride in a fast forward-leaning ready-to-pounce pose, 3/4 front
view facing slightly right, one foot forward sickle-claw raised, tail straight
back for balance. NEUTRAL design — plain crimson raptor, no hat, no outfit,
only the feather tuft + white feather. Eager mischievous grin.
Background: a single FLAT soft neutral background (light grey-blue), even
studio lighting, soft contact shadow under the feet. Clean cut-out-ready figure.
```

---

# 3) TRIKE — "The Bulwark"

## CHARACTER BIBLE (prepend to every Trike prompt)

```
A cute chibi baby triceratops character. Polished mobile-game creature art:
semi-painterly cartoon with subtle pixel-art-influenced detailing, soft
cinematic lighting, rich saturated colors, smooth clean shading, crisp
readable silhouette. Round chunky chibi body (about 1.5 heads tall), four
sturdy little legs, a short stubby tail. Wide BONY FRILL fanning behind the
head with scalloped edges, THREE horns on the face — TWO long curved brow
horns above the eyes plus ONE small horn on the nose — and a hooked beak-like
upper lip. SUNNY MUSTARD-YELLOW scales across the body, a CREAM belly, a
SOFT SAGE-GREEN frill with a warm tan rim, DEEP BROWN horns. LARGE expressive
BROWN eyes with bright catchlights, a calm friendly closed smile, rosy cheek
blush. SIGNATURE DETAIL (always present): a small CHIP missing from the tip
of the RIGHT brow horn (hardened from too many headbutts). Stubborn, friendly,
ground-loving expression.
```

## HERO — Trike (default / base)

```
[CHARACTER BIBLE]
Full body, standing four-square in a confident planted pose, 3/4 front view
facing slightly right, head lowered slightly so the frill catches the light
and the three horns read clearly. NEUTRAL design — plain mustard trike, no
hat, no outfit, only the chipped brow horn. Calm friendly smile.
Background: a single FLAT soft neutral background (light grey-blue), even
studio lighting, soft contact shadow under all four feet. Clean cut-out-ready
figure.
```

---

# 4) PTERRY — "The Sky Ace"

## CHARACTER BIBLE (prepend to every Pterry prompt)

```
A cute chibi baby pterodactyl character. Polished mobile-game creature art:
semi-painterly cartoon with subtle pixel-art-influenced detailing, soft
cinematic lighting, rich saturated colors, smooth clean shading, crisp
readable silhouette. Lean chibi flyer body (about 1.6 heads tall), small
rounded torso, leathery WINGS half-spread for balance, tiny clawed feet, a
short tail. Long swept-back CREST peak rising from the back of the head, a
narrow pointed BEAK (not a toothy snout). BURNT-ORANGE scales across the body
and crest, a CREAM belly and throat, RUBY-RED leathery wing skin stretched on
darker arm bones with a warm CREAM-PEACH membrane underside. LARGE expressive
SKY-BLUE eyes with bright catchlights, a confident closed beak-smile, pink
cheek blush. SIGNATURE DETAIL (always present): a small WHITE BANDAGE wrap
around the elbow of the RIGHT wing (clumsy lander, very proud of every
landing anyway). Cocky, breezy, aerial show-off expression.
```

## HERO — Pterry (default / base)

```
[CHARACTER BIBLE]
Full body, perched in a confident half-landed pose with wings half-spread
either side for balance, 3/4 front view facing slightly right, crest catching
the rim light, head tilted up a touch. NEUTRAL design — plain burnt-orange
pterry, no hat, no outfit, only the bandaged wing. Cocky beak-smile.
Background: a single FLAT soft neutral background (light grey-blue), even
studio lighting, soft contact shadow under the feet. Clean cut-out-ready
figure.
```

---

# 5) BRONTO — "The Gentle Giant"

## CHARACTER BIBLE (prepend to every Bronto prompt)

```
A cute chibi baby brontosaurus character. Polished mobile-game creature art:
semi-painterly cartoon with subtle pixel-art-influenced detailing, soft
cinematic lighting, rich saturated colors, smooth clean shading, crisp
readable silhouette. Chibi proportions but with a LONGER CURVED NECK rising
gracefully from a big round body, a tiny rounded head with a sweet sleepy
expression at the top of the neck, four pillar-soft little legs, a thick
swooshing tail trailing behind. DUSTY BLUE-VIOLET scales across the body and
neck, a LAVENDER pale belly, soft WHITE CLOUD-LIKE SPOTS dappled along the
back and neck. LARGE expressive LAVENDER eyes with long lashes and bright
catchlights, a tiny content closed smile, rosy cheek blush. SIGNATURE DETAIL
(always present): a single SMALL WHITE FLOWER held gently in the mouth (always
grazing). Dreamy, slow, kind expression — the sweetest dino on the island.
```

## HERO — Bronto (default / base)

```
[CHARACTER BIBLE]
Full body, standing peacefully four-square with the long neck curving up and
gently rightward, 3/4 front view facing slightly right, tail trailing back-
left, weight even on all four legs. NEUTRAL design — plain blue-violet bronto,
no hat, no outfit, only the little white flower in the mouth. Sleepy content
smile.
Background: a single FLAT soft neutral background (light grey-blue), even
studio lighting, soft contact shadow under all four feet. Clean cut-out-ready
figure.
```

---

# 6) ANKY — "The Armored Veteran"

## CHARACTER BIBLE (prepend to every Anky prompt)

```
A cute chibi baby ankylosaurus character. Polished mobile-game creature art:
semi-painterly cartoon with subtle pixel-art-influenced detailing, soft
cinematic lighting, rich saturated colors, smooth clean shading, crisp
readable silhouette. Low-slung chubby chibi body (about 1.4 heads tall),
broad and round, four sturdy short legs, a thick muscular tail ending in a
big rounded BONY TAIL CLUB. The back and head are covered in chunky rounded
ARMOR PLATES with small soft horn-spikes along the edges. WARM SANDY-TAN
scales underneath, a CREAM belly visible at the sides, DARK MOSSY-GREEN
armor plates and tail club, with subtle DEEPER-GREEN dappled markings on the
plates. LARGE expressive AMBER eyes with bright catchlights, a stubborn
closed half-smile, rosy cheek blush. SIGNATURE DETAIL (always present): one
hip-side armor plate has a small CRACK with a tiny green SPROUT growing out
of it (he's a survivor and a soft heart). Grumpy, loyal, dependable
expression.
```

## HERO — Anky (default / base)

```
[CHARACTER BIBLE]
Full body, standing planted four-square with the tail club resting visibly to
the back-left, 3/4 front view facing slightly right, head lowered a touch so
the plates catch the rim light. NEUTRAL design — plain sandy-and-mossy anky,
no hat, no outfit, only the cracked-plate sprout. Stubborn half-smile.
Background: a single FLAT soft neutral background (light grey-blue), even
studio lighting, soft contact shadow under all four feet. Clean cut-out-ready
figure.
```

---

# SHARED SKIN OVERRIDES (work on ANY species)

Each skin is a palette / material / accessory swap. Keep the SPECIES BIBLE's
silhouette + signature detail intact — change ONLY what the override lists.
Format: `[SPECIES BIBLE]` + `[hero "Full body … FLAT neutral background …
cut-out-ready" framing]` + the skin override below.

**⭐ Common — Explorer**
```
OVERRIDE: wearing a tan explorer's PITH HELMET sized to fit the head, and a
small RED ADVENTURER'S SCARF around the neck. Keeps the species' base scale
color. Plucky little-explorer vibe.
```

**⭐⭐ Rare — Crystal**
```
OVERRIDE: every horn / spike / spine / crest / armor plate on the species is
replaced with translucent faceted CRYSTAL GEMS (icy cyan-blue) with a faint
inner glow, plus a couple of small crystal shards on the back. Cool aquamarine
sheen overlay on the base scales. Precious, sparkly.
```

**Volcano**
```
OVERRIDE: scales recolored to dark CHARCOAL-GREY, belly recolored to glowing
ORANGE, every horn / spike / spine / crest is now a molten FLAME (orange-yellow
gradient with a soft glow), thin GLOWING LAVA CRACKS across the body, warm
ember rim light. Fierce but cute.
```

**Frozen**
```
OVERRIDE: scales recolored PALE ICE-BLUE, belly WHITE, every horn / spike /
spine / crest now sharp pale-blue ICE/CRYSTAL, a dusting of frost on the back
and tiny snowflakes floating around, cool blue rim light. Chilly and adorable.
```

**Spring**
```
OVERRIDE: scales recolored to a soft fresh SPRING-GREEN, a little ring of
PINK CHERRY-BLOSSOM FLOWERS around the head, small flowers tucked along the
back / spikes / frill / crest as appropriate, a couple of petals drifting in
the air, warm sunny golden-hour light. Gentle, bloom-y.
```

**Void**
```
OVERRIDE: scales recolored deep COSMIC PURPLE speckled with tiny glowing white
STARS like a galaxy, every horn / spike / spine / crest glowing CYAN, a faint
cyan glow in the eyes and a soft nebula aura around the body. Mysterious,
magical.
```

**Golden**
```
OVERRIDE: scales recolored to gleaming WARM GOLD, belly WHITE, every horn /
spike / spine / crest recolored ROYAL-BLUE, small regal gold trim on the
armor / frill / crest where applicable, soft luxurious shine. Regal, prized.
```

### Premium tiers (optional, ship later)

**⭐⭐⭐ Epic — Robo**
```
OVERRIDE: a cute MECHANICAL/ROBOT version of the species — brushed-metal
plating over the body, glowing blue LED eyes, riveted panel seams, a tiny
antenna, any horn / club / crest replaced by a matching metal version. Still
chunky and adorable, sci-fi toy feel.
```

**⭐⭐⭐⭐ Legendary — Galaxy**
```
OVERRIDE: the body is a living GALAXY — deep space-blue/violet scales filled
with swirling nebulae and bright stars, every spike / crest / club made of
pure starlight, a glowing cosmic aura, a sparkling stardust trail. Awe-
inspiring, radiant.
```

**⭐⭐⭐⭐⭐ Mythic — Ancient Dragon**
```
OVERRIDE: a majestic ANCIENT DRAGON version of the species — still chibi and
cute, but with larger jagged dragon spikes / plates, small leathery dragon
wings tucked at the shoulders (Pterry already has wings — make them larger and
dragon-style), glowing rune markings on the scales, deeper emerald-and-gold
coloring, tiny curved claws, an epic mythical aura. Legendary boss energy in
a tiny body.
```

---

# EMOTES (per species, 8 each, 512×512, flat bg)

Each: `[SPECIES BIBLE]` + `"Small full-body emote pose, exaggerated cartoon
expression, centered, FLAT neutral background, cut-out-ready."` + one of the
shared pose lines from `ralph_art_prompts.md` (Happy wave / Excited /
Confused / In love / Tiny roar / Sleepy / Dizzy / Proud sparkle). Use the
DEFAULT base skin for every emote so the species reads as one character.

---

# SIGNATURE MOVE icons (per species, 512×512)

Each dino's signature is wired in `match_config.gd` already. Use these icon
prompts for the SIGNATURE MOVE card:

**T-Rex — Chomp (lifesteal)**
```
[T-REX BIBLE]
Mid-move: lunging forward with jaws wide open chomping down, bright golden
energy bite-arc trailing, small red life-essence motes flowing from the bite
back into Ralph's body, dynamic action pose. Centered, flat backdrop. Heroic
and fun.
```

**Raptor — Dash Claw**
```
[RAPTOR BIBLE]
Mid-move: rocketing forward in a low blur with raised sickle claw leading,
streaks of crimson speed-lines behind, dust kicked up, dynamic action pose.
Centered, flat backdrop. Heroic and fun.
```

**Trike — Headbutt Charge**
```
[TRIKE BIBLE]
Mid-move: charging forward shoulder-down with the three horns aimed, frill
tilted, a glowing yellow impact arc just ahead of the horns, dust burst at the
feet, dynamic action pose. Centered, flat backdrop. Heroic and fun.
```

**Pterry — Screech (AoE slow)**
```
[PTERRY BIBLE]
Mid-move: wings flared, beak open in a wide screech, concentric cyan
sound-rings radiating outward from the head, a few startled motion-marks.
Centered, flat backdrop. Heroic and fun.
```

**Bronto — Neck Whip**
```
[BRONTO BIBLE]
Mid-move: body planted, long neck whipping in a sweeping horizontal arc with
a glowing violet motion-trail behind the head, a soft breeze of petals
following the arc. Centered, flat backdrop. Heroic and fun.
```

**Anky — Tail Smash**
```
[ANKY BIBLE]
Mid-move: tail club mid-swing crashing down to the ground, a bright impact
shockwave bursting out beneath it with cracked earth + dust, body braced low.
Centered, flat backdrop. Heroic and fun.
```

---

# Notes / gotchas

- Generators love to **straighten symmetric details** — always re-state the
  species' SIGNATURE asymmetry (T-Rex scar on the RIGHT, Raptor white feather
  behind the LEFT ear, Trike chip on the RIGHT brow horn, Pterry bandage on
  the RIGHT wing, Anky sprout on the hip).
- Bronto's long neck breaks "1.5 heads tall" — that's intentional; the BIBLE
  calls it out so the model doesn't shrink him to a Ralph-clone.
- Pterry has a **beak**, not a snout — re-state it in every prompt or you'll
  get teeth.
- If a skin drift loses the signature detail, raise `--cw` and add an
  *additive* line ("keeps the [species] base shape, snout scar, and tail club,
  changes only…") instead of fighting it with weight alone.
- Generate 4 per prompt, pick the most on-model, upscale that one. Save the
  approved PNGs in `assets/concept/<dino>/`; I'll wire them into the character
  screen.
