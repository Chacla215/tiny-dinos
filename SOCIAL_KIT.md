# SOCIAL KIT — ready-to-post copy + launch checklist

## AUTOMATED POSTING (Charlie asked Claude to make all the posts, 2026-07-18)

The pipeline lives in `scripts/social/`: `post_calendar.json` (the whole
season: files + captions + days + per-post status) drives
`publish_youtube.py` and `publish_instagram.py` (stdlib-only, secrets
git-ignored). Capability map, honestly:
- **YouTube Shorts — full auto** (upload + scheduled publish) after a
  one-time ~10-min OAuth (steps in the script header).
- **Instagram — full auto** (photos + reels; reels kept off-grid during
  launch month to protect the mosaic) after a one-time ~30-min Meta
  Professional-account + dev-app setup (steps in the script header).
- **TikTok — stays 1-tap manual**: their API needs an app audit for direct
  posting, so the calendar doubles as the prep pack (file + caption per
  post); Charlie taps publish.
Once tokens exist, Claude runs the calendar in-session (and can wire a
launchd timer for hands-off scheduling later).

The posting arm of `CUTSCENE_KIT.md` (rules + scripts live there). Everything
below is paste-ready. Post NATIVELY on each platform — IG Reels, TikTok,
YouTube Shorts — same handle, same file, three algorithms.

## GO-LIVE SEQUENCE (Charlie's ask, 2026-07-18)

**Principles:** no intro stings ever (the 1.5s hook is sacred — brand at the
END); the cast reveals EPISODE BY EPISODE, never all at once (Charlie's
call); photos seed the grid before the first video; the trailer waits for
the itch page.

**Stories lead, intro cards follow (Charlie asked, 2026-07-18):** no
character-intro campaign before the stories — cards to a cold audience are
announcements with nothing to retain; Ep1's opening line IS Ralph's intro.
The Batch-A character cards become PRE-EPISODE TEASERS instead: each card
posts a few days before its character's episode ("meet Steve" lands between
Ep2 and Ep3), one character at a time.

**Platforms (post natively to all three, same file, same day):**
1. **TikTok** — biggest cold reach for all-ages cartoon; priority one.
2. **Instagram Reels** — second algorithm + Charlie's IRL network seeds
   early engagement; the grid is why the photo posts exist. Creator
   account ON for analytics.
3. **YouTube Shorts** — permanent library; longform compilations + the
   season movie live here later.
Register the handle on X/Facebook too (squat protection) but don't post
there. Bio link from day 0 = tinydinos.higgsfield.app (the live site),
swapped to itch at launch.

- **Day 0 — set up + seed with the 3x3 GRID MOSAIC.** Accounts (checklist
  below). Avatar = Ralph crop. Banner = `assets/concept/brand/banner_cast.png`.
  Then the launch stunt Charlie asked for: the cast art sliced into 9 posts
  that assemble into one image on the profile —
  `assets/concept/brand/grid_mosaic/post_1_of_9.png … post_9_of_9.png`.
  **Post them in FILENAME ORDER, back-to-back** (IG shows newest first, so
  post_1 = bottom-right tile, post_9 = top-left; the files already encode
  this — just go 1→9). Captions: keep them tiny (`🦕`, or one word each);
  put the real caption on post_9 (top-left, posted last):
  `the whole island is here. episode one drops tomorrow. 🌋`
  Tiles are 1080x1350 with real bleed margins, so seams stay aligned in
  BOTH the feed and the 3:4 grid crop.
  **Mosaic upkeep:** never pin posts (pinning reshuffles the grid); future
  photo posts go up in multiples of 3; share reels WITHOUT the profile-grid
  placement during launch month so the mosaic stays whole — after the
  account has real followers, let reels on the grid and let the mosaic
  scroll down (it stays intact as long as photo posts come in threes).
- **Day 1 — Ep1 v3** (first video; copy below). Reply to every comment in
  the first hour — the algorithm reads early replies as a live account.
- **Day 4 — sumo reel** ("it's a real game" proof).
- **Week 2 — Ep2 (once fixed) + the JESSIE "new challenger" reel.**
- **Week 3 — Ep3 (top-up) + chaos reel.** From Ep3 the episode outro
  upgrades to `brand/outro_cast.png` (the all-cast card + NEW EPISODE EVERY
  WEEK) — by then most of the cast has appeared, so the group shot is a
  payoff, not a spoiler. The full-cast 4:5 (`grid_cast_4x5.png`) posts as a
  photo the same week ("the whole gang").
- **Season finale week** — the "whole gang" energy peaks; itch page live by
  then, real-capture TRAILER drops as its own post, link in bio flips on.

**LONGFORM (landscape) plan:** shorts stay the growth engine; longform is
the library. After Ep3 exists: "SEASON SO FAR" compilation on YouTube
(episodes back-to-back with the cold-opens as natural stitches; 720x1280
sources get a blurred-pillar-box 16:9 frame — same technique as the reels,
rotated). At season end: the full six-episode movie (~5 min) — and IF a
future top-up allows, key beats regenerate natively in 16:9 for a true
landscape master. Don't gate weekly posting on any of this.

## One-time account setup (15 min)

- [x] **Handles CLAIMED (2026-07-18):** TikTok **@_tinydinos** · Instagram
      **@_tinydinos** · YouTube **@Thetinydinos** (display name "Tiny
      Dinos"). Cross-links in every bio: point IG/TikTok bios at each
      other and at the YT channel so the underscore/The mismatch never
      loses anyone.
- [ ] Avatar: Ralph hero crop. Banner/bio image: the TINY DINOS closing card.
- [ ] Bio line: `tiny dinos. big feelings. a couch brawler for 1-4 players 🦕`
      + itch link when the page goes live (until then: "coming soon").
- [ ] Turn OFF "auto-add watermark" style options where offered; upload
      original files, never cross-share TikTok exports to Reels (the
      watermark tanks Reels reach).

## Post 1 — EP1 "THE LEAF" (`wip/ep1/ep1_v3_narrated.mp4`)

- **Cover frame:** the beat-4 stand-tall (sword up, wind) — scrub ~36s.
- **Caption:** `he has one rule. nobody touches the leaf. 🍃 (ep. 1)`
- **Hashtags:** `#indiegame #couchgames #dinosaur #animation #gamedev
  #cartoon #tinydinos`
- **Pin a comment:** `ep. 2 drops when this hits [pick a number] likes 👀`
  (cheap serialization engagement; pick a reachable number).
- Post the NARRATED mix first; if it underperforms after 48h, A/B the
  no-VO mix on TikTok only.

## Post 2 — SUMO REEL (`wip/reels/reel_sumo.mp4`)

- **Cover:** the POINT! moment (~7s).
- **Caption:** `sumo, but everyone is a dinosaur. last one in the ring wins 🥟`
- **Hashtags:** `#indiegame #couchcoop #partygame #gamedev #tinydinos`

## Post 3 — EP2 (HOLD until fixed — see CUTSCENE_KIT QA)

## Post 4 — JESSIE REEL (`wip/reels/reel_jessie.mp4`)

- **Cover:** her profile-card frame or first mid-fight frame with the hat.
- **Caption:** `new challenger: JESSIE. she was a champion diver. now she
  cannonballs people off islands 🌻`
- **Hashtags:** `#indiegame #newcharacter #couchgames #gamedev #tinydinos`

## Cadence (first 4 weeks)

| wk | posts |
|---|---|
| 1 | Ep1 + sumo reel |
| 2 | Ep2 (fixed) + Jessie reel |
| 3 | Ep3 (needs ~400cr top-up) + chaos reel |
| 4 | Ep4 (after script sign-off) + fresh capture reel |

2 posts/week minimum, same two weekdays, afternoon/evening US time. Read
the numbers weekly: **completion rate and follows-per-post beat raw views.**
Whatever retains best, make more of exactly that.

## Rules recap (full versions in CUTSCENE_KIT.md)

- Hook in 1.5s, beat every 2-4s, loop-friendly endings, captions always.
- Story shorts = openly cinematic. Anything framed as GAMEPLAY = real capture.
- Continuity QA before posting: one weapon per dino, nothing appears/vanishes,
  everyone on-model.
- All-ages: no memes-dependency, no edge; Saturday-morning energy.
- The personal story behind JESSIE stays out of public clips.
