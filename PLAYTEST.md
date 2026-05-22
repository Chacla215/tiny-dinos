# Playtest #3 — what to check

Run the project (F5 in Godot, or the play button). It opens on the **character +
island select** screen. Pick dinos, pick an island (P1 up/down), confirm, fight.
First to 3 KOs wins; R / Enter / Start returns to select.

Get at least one other human on a controller — solo testing hides the problems.

## 1. Did playtest #2's fixes land?

- [ ] **T-Rex is no longer auto-win.** Can a skilled Raptor/Trike/Pterry player
      beat a T-Rex? T-Rex should feel strong-but-slow, not dominant.
- [ ] **Dodge isn't free transit.** Dodging drains the block bar, so spamming it
      leaves you with no defense. Does that tradeoff actually bite? If dodge now
      feels *too* rare/expensive, the cost is too high.
- [ ] **HUD reads at a glance.** HP bar + block bar in each corner — can you tell
      your state mid-fight without looking away from the action?
- [ ] **Dinos look like different characters**, not recolors of one.

## 2. Do the islands feel distinct? (new this build)

Play a round on each. The goal: every island should change how you play.

- [ ] **Iciest Age** — ice patches make you slide; movement is the challenge.
- [ ] **Laughing Lava** — lava *burns* (ticks damage + shoves you out) instead of
      instant death. Does knocking someone into lava feel like a real kill setup?
- [ ] **Sunny Springs** — the green pools slow you down and you *can't dodge* while
      standing in them. Does getting caught in one feel dangerous but fair?
- [ ] **White Water Falls** — everything constantly drifts toward the bottom water.
      Do you feel the current? Is it pressure, or just annoying?
- [ ] **Beauty Beach / Purple Fields** — water ring-out + obstacles for cover. Do
      the obstacles create interesting positioning, or just get in the way?

## 3. Capture for each finding

What happened → why it felt bad/good → which knob might fix it (below).

## Live-tuning knobs (change between rounds, no code needed)

- **Per-dino stats** — `scripts/match_config.gd`, the `DINOS` dictionary. Speed,
  damage, HP, block, dodge cost, etc. all live here.
- **Island hazards** — open the arena scene, click the root `Main` node, see the
  **Hazards** group in the Inspector:
  - `lava_tick_damage` / `lava_tick_interval` / `lava_knockback` (arena_lava)
  - `global_current` (arena_falls) — bigger Y = stronger pull
  - Springs slow strength lives in `scripts/dino.gd`: `SLOW_MOVE_FACTOR` (0.4 = 40%
    speed). Lower = stickier.
- **KOs to win** — `Main` node, `kos_to_win` (default 3).

For desktop dev convenience, `project.godot` is set to fullscreen
(`window/size/mode=3`). Set it to `0` for a window.
