# ROADMAP — Tiny Dinos v1.0

Decided 2026-07-08 (Charlie). This is the master plan; sessions steer by it.
When a phase lands, mark it here and log details in `PROGRESS.md`.

## Destination

**TINY DINOS v1.0 — public itch.io release** (free or pay-what-you-want, price
decided at Phase 3) with a launch trailer + a full dino-shorts social campaign.
Why itch: gamepad-only couch game, no online — zero-cost storefront that fits
the shape. Steam is a **post-launch option**, not a v1.0 goal.

## Phases

### Phase 0 — Land the branch  `[x]` (2026-07-08, PR #17 → `057f15f`)
- PR `feat/feel-sweep` → master (≈60 commits), headless validation, merge.
- Everything after this branches clean off master.

### Phase 1 — The playtest gate  `[ ]`  (Charlie's hands — the one thing Claude can't do)
One structured controller session:
- **Career full run**: grind pacing + economy (XP / pip cost / mood knobs in
  `meta_save.gd` / `match_config.gd` are ready to turn).
- **Pending auditions**: idle-bob amplitude (`dino.gd _update_motion_anim`
  COMBO consts), CC0 combat SFX picks, fall-feel (clip + live), beat-drop
  match intro live.
- **Regression sweep**: all 7 modes + season + gauntlet, 2+ pads.
- Claude turns every finding into an atomic fix.

### Phase 2 — Release-quality polish  `[~]` (Claude-side done 2026-07-08)
- ~~**Real UI SFX**~~ `[x]` Kenney Interface Sounds + Music Jingles (CC0),
  first-guess picks — Charlie's ear check folds into Phase 1.
- ~~**Settings screen**~~ `[x]` SETTINGS on the title: MUSIC/SFX 10-step
  knobs, persisted in MetaSave, applied via the Audio buses.
- ~~**First-run onboarding**~~ `[x]` (2026-07-09) The title opens HOW TO PLAY
  once on the very first launch (`MetaSave.seen_howto`); A/B dismisses. Fixes
  discoverability on a gamepad-only game where the item sat 8th of 10.
- ~~**UI text sweep**~~ `[x]` (2026-07-09) The seven end-of-match START prompts
  were lowercase; now ALL CAPS per the convention.
- Win/quit flows: audited — the win screen is START-only (pause is deliberately
  gated off once `match_over`), and START → select → B → title, so it is two
  hops home, not a dead end. Left as-is; confirm the feel in Phase 1.
- The Phase 1 fix list.

### Phase 2.5 — Arena & mode overhaul  `[~]` (Charlie-directed 2026-07-10; Claude-side done)
Charlie's pre-launch call: graphics/gameplay depth before shipping. Audit found
the 6 arenas mechanically identical (hazard system coded, never wired) and the
CPU objective-blind in 4 of 7 modes. On `feat/arena-overhaul`:
- ~~Arena expansion~~ `[x]` all islands 1.25x via world-scale (`ARENA_SCALE`),
  painting pixel-identical, no art regen.
- ~~Island identity~~ `[x]` lava rim burns / frozen-lake ice / falls current /
  springs geyser pools / purple tree+rock collision; beach stays the beginner
  island.
- ~~Sumo rework~~ `[x]` real dohyo: rope ring scores, bout resets, first to 5.
- ~~Mode-aware AI~~ `[x]` bots play the objective in sumo/bombtag/beast/flood.
- ~~Signature island events~~ `[x]` (2026-07-10, Charlie's pick — always on):
  ERUPTION / ROGUE WAVE / COLD SNAP / FLASH FLOOD / ALL GEYSERS / FRUIT DROP,
  announced + telegraphed, ~34s cadence.
- ~~Walkable painted structures~~ `[x]` Beach's two piers + Falls' two rope
  bridges are real ground (selective by Charlie's call — not every island).
- ~~Spawn-armed~~ `[x]` every dino opens holding their signature weapon;
  drops stay as swap opportunities.
- REMAINING: hurt/KO fighter frames (nice-to-have); all new tunings
  (DOHYO_RADIUS, burn rate, current strength, bounce power, event cadence,
  fruit heal) are first-guess — they fold into the Phase 1 controller
  session. Re-export builds after this lands (zips now stale again).

### Phase 3 — Package v1.0  `[~]` (builds + kit done 2026-07-08; page = Charlie)
- ~~Export presets~~ `[x]` macOS (universal, ad-hoc signed) + Windows + Linux
  in `export_presets.cfg`; templates installed; all three exported clean to
  `build/` (zips ready). ~~Icon~~ `[x]` `icon.png` (Ralph head, beach gradient).
- ~~Page kit~~ `[x]` `ITCH_PAGE.md` (copy + checklist + rebuild commands) and
  `assets/concept/itch/` (8 stills + 3 GIFs from the trailer).
- REMAINING (Charlie): create the itch project, price call (free vs PWYW),
  upload the three zips, trailer to YouTube.

### Phase 4 — Hype campaign  `[ ]`  (parallel with 2–3)
- **Final trailer cut** over the shipped music.
- **Shorts full batch** (greenlit): Charlie reviews `ralph_action_short.mp4`
  → lock the action-level template → batch the other 5 dinos (varied weapon +
  signature move) + a 2-dino rival clash. Recipe proven in
  `assets/concept/shorts/wip/` (~650 Higgsfield credits on hand covers it).
- Drip-post cadence around launch.

### Phase 5 — Post-launch backlog  (pick by reception)
- Depth axes: skill ceiling / meter / stage tech (see memory `game-depth-directions`).
- Career act 2, more islands/dinos.
- Steam port.

## Standing gates
- Feel/ear calls are **Charlie's**; Claude iterates via probes/captures but
  doesn't ship tuning as final without his hands (memory: experiment
  autonomously, surface the reasoning).
- Ship quality bar: headless boot clean, no placeholder assets in the
  player-facing path, pick == play everywhere.

---

# THE NEXT FEW MONTHS — non-gameplay plan (Claude, 2026-07-19)

Charlie's ask: where the project moves **without touching gameplay**, since
every gameplay knob now waits on the Phase 1 controller session. Answer: the
repo has three parallel lanes that don't touch `scripts/*.gd` at all, plus a
release lane that only needs Charlie's hands twice. Sessions steer by this
section until Phase 1 happens; gameplay work resumes the moment it does.

## The four lanes

### LANE A — The saga (weekly, the heartbeat)
The RISING TIDE series (`SAGA_RISING_TIDE.md` + `SAGA_OUTLINE.md`) is written
through Ep6 and sketched through act three. The machine is now: write the ep
→ build the start-frame composite (free) → generate ONE clip (~54cr) → post
chain (free) → publish. The den standing set (`ep2_den/den_bg_A.png`) makes
every Type B episode near-zero marginal cost.

- **Cadence:** 1 episode/week sustained (2/week only if a clip lands clean
  first try). Alternate A/B per the brief; keep formats varied (YT
  channel-level repetition risk — memory `social-research-2026-07`).
- **Budget:** ~54-110cr per episode with re-roll headroom → **~250-450cr/month.**
- **Production rules now locked** (learned, in `NEXT_TWO_CLIPS.md`): one
  action per clip; the un-losable beat first; composite start frames always;
  world-changes happen in stills, not video; fragile props in post.
- **Write ahead:** Ep3 "SHARE THE ROCK" + Ep4 production kits are the next
  zero-credit writing tasks; each episode's kit should exist a week before
  its clip fires.

### LANE B — Channel & audience ops (daily-touch, near-zero cost)
- Publishing machinery DONE 2026-07-19: YouTube verified-pinned, Instagram
  authorized (@_tinydinos) + hosting solved (Higgsfield CDN, see
  `scripts/social/hosted_media.json`), TikTok stays 1-tap manual.
- **Remaining human steps:** Charlie eyeballs `ep1_final.mp4` → post; IG
  mosaic day-0 (5/9 tiles pre-hosted, rest host at post time).
- **Weekly ritual (Claude-runnable):** read completion rate + follows-per-post
  per platform, log to `PLAYTEST.md`-style notes in `scripts/social/`, adjust
  the calendar. Whatever retains, make more of exactly that.
- **Community once comments exist:** reply in-voice (all-ages, no memes),
  pin the serialization comment on each ep.

### LANE C — Store & web presence (one-time builds, then drip)
- **itch page:** kit is done (`ITCH_PAGE.md`); needs Charlie to create the
  project + price call. Claude: refresh the 8 stills/3 GIFs to painterly
  current-build art, re-export the 3 zips AFTER the overhaul merges.
- **Website:** live at tinydinos.higgsfield.app; swap real links in config.ts
  once itch + socials are public (task 7 of the site build), add an EPISODES
  page that embeds the saga as it grows.
- **Trailer:** stays channel furniture (YT channel trailer + itch header),
  NOT a feed post. A 9:16 recut becomes worth it around ~500 followers or
  the itch launch, whichever first.
- **Press-kit-lite** (zero cost, one session): logo pack + 6 hero PNGs + 10
  stills + boilerplate in `press/` — needed the day anyone asks, embarrassing
  to build the day someone asks.

### LANE D — Release management (the merge train)
The repo's actual blocker is that THREE branches of value sit unmerged:
1. **PR #18** (settings/onboarding/builds) — OPEN, clean, mergeable now.
2. **`feat/arena-overhaul`** — Claude-side complete, all tunings first-guess.
3. Master carries Phase 0-1 states.

**Order (as soon as Charlie has one controller evening):**
Phase 1 session on arena-overhaul build → fold findings as atomic fixes →
merge #18 → merge overhaul → re-export 3 platform zips → itch upload →
launch post = Ep-current + "the game is out" (the ONE allowed direct-promo
beat). Everything in lanes A-C survives this unchanged.

## Month-by-month sketch (calendar time, launch-relative)

- **Month 1 (now):** Ep1 posted (today, pending eyeball); Ep2 on top-up;
  Ep3-4 kits written; IG mosaic day-0 fired; weekly metrics ritual starts.
  Charlie: ONE controller evening (Phase 1) when life allows.
- **Month 2:** merge train + itch launch mid-month once Phase 1 lands; saga
  hits Ep5-6 (act one finale = the den floods = natural launch-week beat:
  "they had to leave home" ↔ "the game is out"); press-kit-lite.
- **Month 3:** saga act two opens (new islands = new visual variety, feeds
  the channel-repetition defense); read launch data; decide the first
  post-launch gameplay axis from Phase 5 by what players/viewers actually
  respond to; Max-spinoff greenlight check (needs act one fully public).
- **Steam stays post-launch** and only if itch+socials show real pull.

## Standing budget note
Episode credits are the ONLY recurring cost (~250-450cr/mo at 1 ep/week).
Everything else in lanes B-D is zero-credit. Image work (den sets, start
frames, ice-style props) runs 1.5-3cr and should never be batched into video
budget decisions — just do it.
