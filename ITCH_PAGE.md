# ITCH.IO PAGE KIT — Tiny Dinos v1.0

Everything for the store page in one place (ROADMAP Phase 3). Page assets live
in `assets/concept/itch/` (stills + GIFs pulled from the trailer); builds come
from `export_presets.cfg` (macOS / Windows / Linux — see "Builds" below).

## Page setup (Charlie, ~20 min on itch.io)

1. Create the project at itch.io → "Upload new project".
2. **Title**: Tiny Dinos  ·  **Project URL**: tiny-dinos
3. **Classification**: Game  ·  **Kind**: Downloadable
4. **Pricing**: $0 or donate ("No payments" also fine — decide at upload).
5. **Uploads**: the three zips from `build/` (mark each with its platform icon).
6. **Cover image** (630×500): crop `icon.png` or `shot_friends.png`.
7. **Screenshots**: the 8 `shot_*.png` in `assets/concept/itch/`.
8. **Trailer**: upload `assets/concept/trailer/trailer.mp4` to YouTube, link it.
9. **Tags**: local-multiplayer, party-game, brawler, couch-co-op, dinosaurs,
   controller, godot, cute, arcade, singleplayer
10. **Custom noun**: "brawler". **AI disclosure**: itch asks — art was
    AI-generated (Seedance/Recraft/nano-banana), code hand-written; tick the
    generative-AI box for graphics.

## Page copy (paste as the description)

**Tagline** (short description field):
> A gamepad-only couch brawler where tiny dinos bonk each other off tropical islands. 1–4 players.

**Body:**

---

🦖 **GRAB A WEAPON. WIN THE ISLAND.**

Tiny Dinos is a top-down couch brawler for **1–4 players** — pick your dino,
scramble for the weapons raining onto the sand, and shove, smash, and CHOMP
your friends into the sea.

**🎮 CONTROLLERS REQUIRED** — this is a couch game. Keyboard is not supported.
One gamepad per player (any mix of common controllers).

**SIX DINOS, SIX PERSONALITIES.** Ralph the tiny king, speedy Max, armored
Gus, screeching Jessie, gentle-giant Steve, and spike-tailed Frank — every
dino has its own stats, signature special, and a passive that changes how
you play them. No recolored clones.

**SIX LIVING ISLANDS.** Beauty Beach, Laughing Lava, Iciest Age, White Water
Falls, Sunny Springs, Purple Fields — each a hand-painted arena that PLAYS
differently: the lava rim burns, the frozen lake sends you skating, the falls
drag you downstream, the geysers launch you skyward. And every island has a
signature EVENT that flips the fight mid-brawl — an eruption, a rogue wave, a
cold snap, a flash flood. Learn them or drown.

**SEVEN WAYS TO BRAWL.** Classic rounds, King of the Hill, egg hunts, sumo
shove-offs, bomb tag, THE BEAST, and the rising flood — plus team battles.

**PLAY IT SOLO, TOO.**
- **CAREER** — bond with ONE dino. Feed it, train it, keep its spirits up,
  and take it on a 21-stop journey to the final showdown with your rival.
- **SEASON** — build a team and climb three divisions of rival squads.
- **GAUNTLET** — a roguelike wave climb with upgrade drafts.

**FLOPPY BY DESIGN.** Momentum, knockdowns, grabs — carry your friend to the
edge and yeet them into the ocean. They'll come back. Probably angrier.

---

*Made by one designer and Claude (Anthropic's AI) writing every line of code.
Music & sounds are CC0 gems from Juhani Junkala, HoliznaCC0, and Kenney.*

## Builds

> **Before the release export, reinstall the export templates.** The three
> presets are configured and ready, but `~/Library/Application Support/Godot/
> export_templates/` is currently empty (a 4.6.3 build with no templates fails).
> Install via the editor (**Editor → Manage Export Templates → Download and
> Install**) or drop the `4.6.3.stable` `.tpz`. The `build/` zips on disk are
> **stale** (pre-overhaul, Jul 8) — re-export after the arena-overhaul merge.

Rebuild any time (from the repo root, once templates are installed):

    /opt/homebrew/bin/godot --headless --export-release "macOS" build/TinyDinos-macOS.zip
    /opt/homebrew/bin/godot --headless --export-release "Windows Desktop" build/TinyDinos-Windows/TinyDinos.exe
    /opt/homebrew/bin/godot --headless --export-release "Linux" build/TinyDinos-Linux/TinyDinos.x86_64

Then zip the Windows/Linux folders for upload:

    cd build && zip -r TinyDinos-Windows.zip TinyDinos-Windows && zip -r TinyDinos-Linux.zip TinyDinos-Linux

- macOS build is **ad-hoc signed, not notarized**: first launch needs
  right-click → Open (say so on the page under "Install instructions").
- Version lives in `project.godot` `config/version` + the macOS preset —
  bump both on release.
- Optional later: `butler push` for one-command updates (itch's CLI).

## Still wanted (gated on Charlie / later)

- Real 630×500 cover art + a banner (could be a shorts-pipeline generation).
- Fresher screenshots straight from a windowed `--shot` run (trailer pulls
  are 720p re-encodes — fine to launch, nicer to replace).
- The final trailer cut on YouTube.
