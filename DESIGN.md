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
