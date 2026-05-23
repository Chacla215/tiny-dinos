# Tiny Dinos — Design: Specials, Roster, Weapons, Match Flow

Autonomous design pass (2026-05-22). Status tags: **[BUILT]** = implemented +
headless-validated this pass; **[DESIGNED]** = spec'd, not yet coded; **[?]** =
a decision I made that you should sanity-check, or an open question for you.

---

## 1. Signature Specials  **[BUILT for the 4 current dinos]**

Each dino gets a **signature move on its own button**, separate from light
(attack) and heavy. This is the deck's "signature non-weapon attack" hook. It's
a third move with a **cooldown** (no resource bar yet), so it's a committal,
identity-defining tool rather than spammable.

**Button:** new `special` action. Controller **LB**; keyboard **P1 = B**,
**P2 = L**. (Free slots; the controller LB is the intended input — keyboard is
getting crowded, see [?] below.)

**Framework (in `dino.gd`):** specials reuse the existing WINDUP→ACTIVE→RECOVERY
attack machinery. A `special_type` string dispatches the few unique behaviors;
everything else is a normal melee swing with its own damage/knockback/hitbox/
self-dash numbers (all in `match_config.gd`, per dino). Cooldown via
`special_cooldown_timer`. The CPU uses specials too (occasionally, when in range).

**Per-dino specials (deck identity):**

| Dino | Special | Effect | Notes |
|------|---------|--------|-------|
| T-Rex | **Chomp** | Lunge-bite, high dmg, **lifesteal** (heals ½ of dmg dealt) | apex-predator sustain |
| Velociraptor | **Dash Claw** | Fast forward dash + a quick claw | gap-closer / pressure |
| Triceratops | **Head Butt** | Big charging dash, heavy knockback | the "charge"; see [?] tangle |
| Pterodactyl | **Paralyzing Screech** | AoE pulse: nearby foes slowed + can't dodge briefly + shoved | control/zoning, no hitbox |

**[?] Identity tangle to resolve.** Right now `trike` (Triceratops) uses the
Horntopper sprite and its **heavy** is a *spike projectile* — that's really a
*Stegosaurus* mechanic (deck: Stegosaurus = Shooting Spikes). I gave Triceratops
its proper Head Butt **special**, but it still has spikes on heavy, which is
off-identity. Options: (a) leave it (playable, slightly weird); (b) add a real
**Stegosaurus** dino that owns Shooting Spikes, and give Triceratops a melee
heavy; (c) something else. **Your call.**

**[?] HUD cooldown indicator** not built yet — you currently learn special
readiness by feel. Easy add: a small "ready" pip by the block bar.

---

## 2. Roster growth  **[DESIGNED — needs your input before building]**

We have 4 of the deck's 7. Next two, with deck signatures:

| Dino | Stats archetype | Signature special |
|------|-----------------|-------------------|
| **Brontosaurus** | big, slow, high HP, long reach | **Neck Whip** — wide long-range sweep, knockback |
| **Ankylosaurus** | tanky, slow, armored | **Tail Smash** — AoE ground-pound (radial knockback + dmg) |

Both specials fit the framework above (Neck Whip = wide melee; Tail Smash = AoE
like Screech but damage-focused).

**[?] Blocker = sprites.** A new dino must look distinct (your rule: no recolored
clones). The current sheets are `playersprites_revision`, `rynosaurlandcharacters`,
`enemysprites_revision`. I'd need to hunt the enemy sheet for unused characters
and map their frame rects. **Questions:** which 1–2 to add first, and do you have
sprites in mind or should I dig through the existing sheets for candidates?

---

## 3. Weapons (Y-swap)  **[BUILT — scope A core; select-screen picking pending]**

Chosen scope: **A (loadout swap)**. Built: `WEAPONS` table in `match_config.gd`
(fists/sword/dagger/axe/mace/hammer/nunchucks — melee; Bow deferred, needs the
projectile path), a per-dino 2-weapon `weapons` loadout, the **swap** action
(controller **Y**; kbd P1 = V, P2 = ;), weapon modifiers applied to light+heavy
in `dino.gd:start_attack` (dmg/kb/range/windup/recovery; the special is
unaffected), and a live weapon name in the HUD score label. **Pending:** picking
your 2 weapons on the select screen (currently each dino has a fixed default
loadout, e.g. T-Rex = fists/war-hammer). Default loadouts are in DINOS.weapons.

Deck: 7 weapons (Sword, Axe, Bow, Dagger, Spiked Mace, Nunchucks, War Hammer),
**Y swaps** between equipped weapons mid-fight. Each changes your attacks.

This is the **biggest new system** and the riskiest, so I want your scope call
before building. Three scope levels:

- **A — Loadout swap (smallest):** each dino carries 2 weapons chosen at select;
  Y toggles between them; a weapon just overrides your light/heavy numbers +
  range. No pickups. Cleanest, reuses the attack system.
- **B — Map pickups (medium):** weapons spawn on the arena; walk over to equip;
  Y swaps held weapons; dropped on KO. Adds spawn/pickup/scatter systems.
- **C — Full deck (largest):** pickups + per-weapon movesets + durability +
  the social/kingdom layers. Out of scope for now.

**[?] Which scope?** My recommendation: **A** first (proves the swap + weapon-as-
moveset idea cheaply), then **B** once it feels good. Concept art exists in
`assets/concept/weapons/`.

---

## 4. Match flow + end screen  **[BUILT]**

Chosen: **best-of rounds**. Built: a KO ends the round (in FFA: first KO of the
round wins it), "X TAKES ROUND N" interstitial → reset all to full HP/spawns →
"ROUND N+1"; first to `kos_to_win` rounds wins the match. DinoPoints tracked
(+100 KO, +10 per hit landed) → end screen shows each player's DP + an A+→F
grade. Knobs: `kos_to_win` (rounds to win, default 3) on the Main node; DP
weights + grade thresholds in `main.gd`.

Current loop: first-to-N KOs → "X WINS" + restart-to-select. Make it feel like a
match:

- **Best-of rounds:** a round ends on a KO; first to N round-wins takes the
  match. Brief "ROUND 2" interstitial + reset positions/HP between rounds.
  (Currently KOs just tally with no round structure.)
- **DinoPoints (DP) end screen** (deck): tally per-player events during the match
  — Knockout +100, Hit/dmg, Ring-out, etc. — and show an **A+ → F grade** on the
  end screen alongside the winner. Hooks already exist (`on_hit_landed`,
  `award_ko`, `report_ko`) to feed a DP counter.
- **Rematch flow:** keep the current R/ENTER/START → select; optionally a
  "rematch same dinos" vs "change dinos" choice.

**[?] Round count + DP weights** — I'll use deck defaults (KO +100, Hit +10,
Ring-out credit +50, best-of-3 rounds) unless you want different numbers. This
one I can just build next; flagging the knobs only.

---

## Status (2026-05-22 build pass)
- ✅ **Specials** — built (now 7 dinos).
- ✅ **Match flow + DP end screen** — built (best-of rounds).
- ✅ **Weapons** — scope-A core built **+ select-screen weapon picking** (dino →
  weapon → ready flow; humans pick fists + one weapon; CPUs use defaults).
- ✅ **Roster** — built. **6-dino roster:** T-Rex, Raptor, Triceratops (now melee
  heavy), Pterodactyl, **Brontosaurus** (Goober sprite, Neck Whip), **Ankylosaurus**
  (Tortuka turtle sprite, Tail Smash). Stegosaurus was added then **removed** (no
  real stego art; placeholder blob wasn't wanted). Spike-volley mechanism kept
  dormant in code for a future Stego.

## Decisions locked by Charlie (2026-05-22)
- Match: best-of rounds. Weapons: scope A. Tangle: add a real Stegosaurus. Roster:
  add Bronto (Neck Whip) + Anky (Tail Smash), sprites mined from existing sheets.

---

## 6. Island redesign — Iciest Age: "Frozen Floes"  **[BUILT → CUT]**

> **Cut 2026-05-22.** Built (`arena_floes.tscn` + `Floe`/drown mechanic) but the
> flat-vector art clashed with the pixel-art tileset islands. Charlie's call:
> **remove Iciest Age from the roster** (now 5 islands, all pixel). Scene + code
> kept in-repo, unreferenced — revivable only as a **pixel** reskin. The
> floe-hop / drown-grace mechanic below is still a good idea for a future pixel arena.

Reframe Iciest Age from today's single rectangular ice slab into the deck /
concept-art vision: a **top-down frozen sea** where players fight on a scatter of
**floating ice floes** separated by deadly water. (The card
`assets/concept/islands/iciest_age.png` is a horizon *illustration*; this is its
top-down gameplay translation — the floes are the white ovals in the art.)

### Why it's distinct (and why it matters for balance)
It's the roster's **only true ring-out arena** — every other island confines you
with `clamp_to_bounds`. Here the edges are real water: knock a foe off a floe and
they're gone. Pair that with **slippery ice footing** and it's the game's premier
*spacing + knockback* stage. Critically, it's where **fast/fragile dinos earn
their pick** — Raptor's top speed + long dodge make it the best floe-hopper and
the best at recovering position, which directly answers the "why pick a low-HP
dino" problem we flagged. Heavyweights (T-Rex/Bronto) hit hard but a whiff near
an edge on ice can self-destruct them. Different island, different power curve.

### Three interlocking mechanics
1. **Floes are the only safe ground; the rest is water = ring-out.** A `Floe`
   Area2D group; each floe tracks overlap like the existing ice/slow zones. A
   player overlapping **zero** floes is *in the water*.
2. **Drowning with a grace beat.** Water isn't instant death — ~0.35s of
   "scrambling" before the ring-out, and **dodge i-frames suppress it entirely**.
   So a timed dodge becomes a **leap between floes** (feeds the mobility pillar):
   walk off lazily → drown; dash across the channel → survive. `[?]` tune grace.
3. **Floe tops are ice.** Each floe doubles as an ice patch (existing
   `Surface.ICE`), so footing is slidey right next to a lethal edge — knockback
   and self-dash specials become double-edged.

### Layout (1280×720, top-down)
- **Center floe** — large ~440×300, the main brawl stage.
- **4 corner floes** — medium ~260×190 (NW/NE/SW/SE); also the spawn pads
  (P1 NW, P2 SE, P3 NE, P4 SW) so nobody spawns in water.
- **2 stepping floes** — small ~150×120 between center and corners: risky shortcuts.
- **Water channels ~90–130px** — crossable with a dodge, fatal at a walk.

### Look (flat-vector — matches the hand-drawn flat direction, collision == art)
- Water = flat deep teal (darker than the concept so floes pop and read as
  *danger*).
- Floes = soft pale-blue rounded `Polygon2D` with a thin lighter rim, a faint
  inner-shadow oval, and 1–2 decorative crack `Line2D`s (echoing the card).
  Drawn as polygons so the safe zone *is* what you see (terrain-driven rule —
  no raster bg, stays crisp at any res).
- Optional drifting bergs (the card's triangles) as background flavor.

### Knobs / `[?]` for you
- **Moving floes?** v1 = **static** (clean, readable). Stretch: 1–2 floes slowly
  drift for a higher skill ceiling. *Recommend static first.*
- **Water = kill** here (it's the ring-out stage; deadly sea reads correctly) —
  unlike Sunny Springs' shallow spring (slow). Deaths match the art.
- **Grace window** 0.35s default; dodge fully suppresses.
- **Replace `main.tscn`** with this (Iciest Age *should be* this), vs. a new
  `arena_floes.tscn`. *Recommend replace.*

### Build steps (v1)
1. Background + floe polygons (rims, inner shadow, cracks) + corner spawn pads.
2. `Floe` Area2D group + `enter_floe/exit_floe` + `floe_overlap_count` in `dino.gd`.
3. Drowning grace + dodge-suppression in `main.gd` (extend the existing
   `Water` / `safe_rect` / `handle_environmental_kill` path).
4. Mark each floe as an ice surface; wire spawns onto the corner floes.
5. Headless-validate (`--headless --import`, scene run, exit 0).
