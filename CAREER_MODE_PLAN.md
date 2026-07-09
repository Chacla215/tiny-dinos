# PLAN — CAREER MODE (raise one dino, run the journey)

**Charlie's vision:** a MIX — *bond with one dino* (raise / level / personality,
care for it between fights) + a *roguelike run* + a *story journey*. One dino you
grow attached to and carry the whole way. Persist via `MetaSave`.

Read first: `CLAUDE.md`, `PROGRESS.md`, and memory `combat-feel-arena-overhaul`
(this is queued item #2 there). This doc is the source of truth for the feature.

---

## The core loop (what makes it "yours")

```
  PICK your dino (once) ─▶ it's YOURS for the whole career
        │
        ▼
   ┌── HOME / DEN ──────────────────────────────┐
   │  care between fights:                       │   ← the "bond" beat
   │   • FEED  (mood ↑, small stat day-buff)     │
   │   • REST  (heal + fatigue ↓)                │
   │   • TRAIN (spend XP → permanent stat pip)    │
   │  mood + bond level shown; dino reacts        │
   └──────────────┬──────────────────────────────┘
                  ▼
          NEXT STOP on the journey map
                  ▼
             FIGHT (a match)  ── win → XP, coins, bond ↑, story beat
                  │                loss → still XP, but a scar / setback
                  ▼
          back to HOME (care) ─▶ loop until the journey's final boss
```

It reuses the **match engine unchanged** — a career fight is just a versus match
your bonded dino is in. Everything new is the *wrapper*: a persistent dino, a
home screen, and a journey structure.

## What we build ON (don't reinvent)

- **GAUNTLET** (`match_config.gd` ~744) = the roguelike-run spine: rising foes,
  HP carry, between-fight **UPGRADES draft**. Career borrows the run cadence but
  swaps the throwaway upgrade pick for **permanent leveling + care**.
- **SEASON** (~530) = the journey/schedule spine: a `*_schedule` array of stops
  (foes/mode/island/difficulty), a division ramp to a BRUTAL finale, coin rewards.
  Career borrows the "authored ladder of stops" shape.
- **MetaSave** (`meta_save.gd`, `ConfigFile` at `user://gauntlet_save.cfg`) = the
  persistence. Career adds a `[career]` section (or a sibling `career_save.cfg`).
- **Per-dino stat overrides** live in `MatchConfig.DINOS[id]` and apply at spawn
  via `@export`s. Career's leveling = a **stat delta layered on top** of the base
  dino at spawn (a new `career_stat_bonus` the dino reads, like season fatigue).

## Data model (the persistent dino)

New on `MatchConfig` (mirrors the `gauntlet_*` / `season_*` block), saved by MetaSave:

```
career_active     : bool
career_dino       : String        # the bonded dino id — chosen ONCE
career_name       : String        # player-named (optional, cute)
career_level      : int           # bond/growth level
career_xp         : int           # toward next level
career_stat_pips  : Dictionary    # {power, speed, toughness, ...} permanent pips
career_mood       : int           # 0..100, drifts; FEED raises, losses lower
career_hp_carry   : int           # current HP into the next fight (REST heals)
career_stop       : int           # index into the journey map
career_scars      : Array         # setbacks/flavor from losses (story texture)
career_coins      : int           # spent on care actions (reuse MetaSave coins?)
```

`career_stat_bonus()` → a small multiplier/flat set the dino applies at spawn
(same pattern as `season_fatigue_*`), so TRAIN visibly makes YOUR dino stronger
than the base roster — reinforces attachment without breaking "each dino distinct".

## Screens (all gamepad-driven, ALL CAPS UI)

1. **CAREER START** — pick your dino from the roster (reuse `select.gd` grid),
   name it, see its starting personality blurb. Writes `career_dino`.
2. **HOME / DEN** — the between-fights hub. Your dino idles (its in-match
   AnimatedSprite2D, big), mood face, bond level bar. Three care actions
   (FEED / REST / TRAIN) + **GO TO NEXT FIGHT**. This is the new screen to build.
3. **JOURNEY MAP** — a simple node path of stops (like season matchdays) showing
   where you are and what's next (rival, mode, island). Can start as a list.
4. **FIGHT** — hand off to the normal match (`main.gd`) with your dino as P1 and
   the stop's foe(s) as CPUs; on `report_ko`/match-over, route back to HOME with
   XP/coins/mood deltas + a one-line story beat.

## Story journey (light, not a novel)

A short authored arc of ~8–12 stops: leave home island → tour the 6 islands →
face a recurring RIVAL a few times → final showdown. Each stop carries one line
of flavor (win-line / loss-line). Data-driven in a `CAREER_STOPS` const so it's
easy to tune. Rival = a specific dino at rising difficulty (reuses CPU brain).

## Build order (incremental, each step validates + is committable)

1. **Data + persistence** — `career_*` vars on MatchConfig, MetaSave `[career]`
   load/save, `career_stat_bonus()`, `start_career()/career_advance()`. No UI yet;
   headless-validate.
2. **Fight hookup** — from a career stop, configure MatchConfig and launch a match;
   on match end, apply XP/coins/HP-carry and advance the stop. Prove the loop with
   a temporary debug entry (skip the pretty screens).
3. **HOME/DEN screen** — the care hub with FEED/REST/TRAIN + GO. The heart of the
   "bond." Wire mood/level/HP visuals.
4. **JOURNEY MAP + START screen** — pick-your-dino + name, the stop path, title
   route in (`title.gd` new CAREER entry).
5. **Story beats + polish** — win/loss lines, rival arc, mood reactions, a final
   boss + an ending card. Balance the XP/care economy.

Commit atomically per step (`Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`).

## Decisions to confirm with Charlie

1. **Care actions** — is FEED / REST / TRAIN the right trio, or do you want more
   depth (play/pet minigame, personality that shifts with how you treat it)?
2. **Permadeath?** roguelike-classic (a bad loss ends the run, start over with meta
   unlocks) vs forgiving (losses = scars/setbacks but the journey continues).
   → Recommend **forgiving with stakes** (losses cost progress + leave a scar, but
   your dino persists) — matches "grow attached," a permadeath wipe fights that.
3. **Journey length** — a tight ~1-sitting arc (8–10 fights) or a longer grind?
4. **Coins** — reuse the existing MetaSave coin wallet for care, or a separate
   career currency?
