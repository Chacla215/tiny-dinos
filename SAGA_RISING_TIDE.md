# SAGA BRIEF — "RISING TIDE" (the series reboot)

**Charlie, 2026-07-19.** The shorts season restarts on a new dynamic: an
endless story where *something always happens at the end of the scene*, every
episode ends on a cliffhanger nobody saw coming, and the saga has no natural
end. This supersedes the standalone "Ep1: The Leaf" framing — the leaf story
survives, but only as act one of a much bigger problem.

Read alongside `CUTSCENE_KIT.md` § STRUCTURE (the craft rules Ep1's failures
taught us) and `CAREER_MODE_PLAN.md` (the saga's spine).

---

## 1. The premise

**The tide is rising and the island is running out.**

`RISING TIDE` is a real game mode — *"THE TIDE RISES — LAST DINO ON DRY LAND
WINS."* That single rule is the whole series engine, and it fixes the two
problems the old Ep1 had:

- **It connects the story to the game.** The old story was about a leaf, which
  is not in the game. This story is about a game mode.
- **It explains why anyone leaves home.** Career mode tours six islands. Now
  there's a reason: home is going under.

### They are NOT on the same team — this is the important part

A shared threat normally makes enemies into allies, which would kill a game
about hitting each other. Here it does the opposite:

| | before the tide | after the tide |
|---|---|---|
| what they fight over | a leaf | **ground** |
| stakes | petty, funny | existential |
| why brawl at all | "they're dinosaurs" | **there is one dry rock left** |

The water does not unite them. It makes the island smaller, and there isn't
room for both. The leaf fight was practice.

**This also gives the rival a reason.** In career mode the same rival keeps
turning up across the islands. Under this premise Max isn't a villain who
follows Ralph around — he's running from the same water. He reappears because
they're both hunting the same dry land. That never runs out: every island is
temporary, so every island has one more fight on it.

Stays **all-ages**: nobody drowns. It's a scramble for higher ground, played
as much for comedy as for tension.

---

## 2. Saga structure

```
  EP1  the last good day        home island — the tide arrives
  EP2+ one island per episode   career-mode journey, Ralph's POV
       each ends on a new problem the viewer can't predict
  ...  the rival keeps turning up, because he's fleeing too
  LATER  MAX SPINOFF            the same saga from Max's POV —
                                where he went, what he was running from
```

**Ralph's POV runs the main line and finishes first.** The Max spinoff comes
after, and re-frames episodes the audience has already seen — which is only
possible once they know the events. Do not start it early.

**Format must vary between episodes.** Not a preference: YouTube's 2026
monetization policy names "repetitive character scenarios" and videos that
"feel interchangeable" as demonetization triggers, **assessed at channel
level** — a same-beach/same-structure series is the exact flagged profile.
See memory `social-research-2026-07`. Vary location (six islands do this for
free), vary who narrates, vary cold-open type, vary length 20-40s.

### Two episode types, alternating (Charlie, 2026-07-19)

The saga runs on **two formats**, not one — modelled on **NBA 2K MyCareer
cutscenes**, where the drama between games is what makes you care about the
player. Alternating them is also the cleanest answer to the interchangeability
risk above: consecutive uploads don't share a shape.

**TYPE A — ISLAND (the fights).** The tide, the rival, the scramble for dry
land. Narrated, action-climaxed, ends on a problem. ~25-35s.

**TYPE B — DEN (the cutscenes).** *Nobody fights.* Quiet character scenes in
the den between islands — Ralph eating, sulking, failing to train, patching a
scar, being visited. This is the `CAREER_MODE_PLAN.md` home loop (FEED / REST /
TRAIN, mood + bond) told as story. ~15-25s.

What Type B is for:
- **attachment.** Nobody roots for a fighter they haven't seen off-duty.
- **plot without action.** The water advances via news, rumour, and a
  waterline mark on the den wall that is higher every episode. Tension rises
  with nothing happening.
- **the supporting cast.** Steve, Gus, Jessie, and the rival get to exist as
  characters instead of opponents. 2K's agent/coach/teammate function.
- **cheap generation.** One location, two characters, no choreography — the
  least demanding clips in the series.

**Type B uses SPEECH BUBBLES and no narrator.** This is where the bubble idea
(rejected earlier for the narrated episodes) belongs: with no VO competing,
bubbles are the only text on screen, so there's no attention pile-up of
narrator + subtitles + bubbles. They also rhyme with the game's own
`MatchConfig.EMOTES` language (`HI!`, `ROAR!`, `HUH?`, `ZZZ`, `TA-DA!`), which
is another true-to-game tie.

Type B ALSO sidesteps the dead narrator problem: the original VO voice
(Arthur) can't be regenerated, so every new narrated line is blocked. Den
episodes need no narration at all.

**Cadence:** A, B, A, B… Each Type B ends on its own small hook (someone
missing, the waterline higher, the rival at the door) so it isn't filler.

---

## 3. EP1 — "THE LAST GOOD DAY"

### Beat sheet

| act | content | source |
|---|---|---|
| **0. hook** | Ralph mid-leap, sword high, over Max | EXISTING `beat5.mp4` @6.9-8.2s |
| **1. the leaf** | Max takes the leaf; Ralph is small; the island sends a sword | EXISTING beats 1-4 |
| **2. the win** | Ralph charges, leaps, lands on Max. He gets the leaf back. | EXISTING `beat5.mp4` to 8.30s |
| **3. THE TIDE** | He turns. The water is at the tree line. It wasn't there before. Max stops gloating. | **NEW — generate** |
| **4. the button** | Both look at the water → at the last dry sand → **at each other**. Cut. | **NEW — generate** |

**The last frame is the look between them.** Not friendship — arithmetic.
That is the cliffhanger.

### The narrator goes silent

The narrator is light and chatty through acts 1-2. **When the tide arrives, he
stops talking.** No VO over act 3 at all — just music dropping out and water.

This is a creative choice that also solves a hard constraint: the original
narrator voice (macOS **Arthur**) is not installed and cannot be regenerated;
the Daniel substitute was rejected. So no new narration is possible. Silence is
better than a voice mismatch, and better than narrating a gut-punch.

Existing VO lines 1-4 carry acts 1-2 (~19s). Line 5 is **cut entirely** — it
set up a "second rule" payoff that no longer happens.

### Sound design for act 3

- music **cuts out** the moment Ralph turns (not a fade — a stop)
- water, then wind, then nothing
- no battle theme in this episode at all; save the drop for the win in act 2

---

## 4. Generation kit (act 3 only)

Proven recipe per clip: **12s, 9:16, 720p std, `generate_audio:false`,
DECLINE the recommended preset** (pass its id as `declined_preset_id` and
resubmit). Chain continuity by extracting the previous clip's last frame
(`ffmpeg -sseof -0.1 -i X.mp4 -frames:v 1 X_end.png`) as the next
`start_image`.

**Start frame for TIDE-1:** the last clean frame of `beat5.mp4` at **8.15s**
(one sword, no cape — the break starts ~8.4s, never read past 8.30):
```
ffmpeg -ss 8.15 -i beat5.mp4 -frames:v 1 tide1_start.png
```

### Identity locks (both dinos in frame — highest clone risk)

- **RALPH:** "small round chibi green dinosaur, sage-green body, cream belly
  plates, teal-blue back spikes and tail tip, big amber eyes, pink blush
  cheeks, one small leaf tucked behind his head, holding ONE golden-hilted
  sword". Guard: *"exactly ONE green dinosaur in the entire scene"*.
- **MAX:** "small chibi red raptor, brick-red body with darker red stripes,
  cream belly, tiny white feather tufts at the elbows, yellow eyes, toothy
  grin". Guard: *"exactly ONE red raptor in the entire scene"*.
- Pass `../../ralph/ralph_hero.png` and `../../raptor/raptor_hero.png` as
  `image_references`. **Ep2's lesson: identity refs can clone the hero into
  the background — if a duplicate appears, re-roll with the guard strengthened.**
- **Continuity guard, learned the hard way:** *"Ralph carries exactly ONE
  sword and wears NO cape"* — the quarantined beat5 tail failed on precisely
  this.

Style anchor every prompt: *"painterly chibi cartoon dinosaurs, storybook
picture-book style, vivid colors, bright sunny tropical beach with palm trees
and turquoise sea"*.

### Prompts

**TIDE-1 — the reveal** (start frame `tide1_start.png`)
> Painterly chibi cartoon dinosaurs, storybook picture-book style, vivid
> colors. A small round sage-green chibi dinosaur with teal back spikes, cream
> belly and a leaf behind his head stands on a sunny tropical beach holding ONE
> golden-hilted sword, panting after a fight. He slowly turns his head to look
> behind him — and freezes. Seawater has crept far up the sand, swallowing the
> footprints and lapping at the base of the palm trees. The water is calm, not
> stormy, which makes it worse. His triumphant expression drains into wide-eyed
> alarm; the sword lowers. Slow push in on his face, then a slow tilt to the
> waterline. Exactly ONE green dinosaur in the entire scene. He carries exactly
> ONE sword and wears NO cape. No other creatures.

**TIDE-2 — the look** (start frame = TIDE-1's end frame)
> Painterly chibi cartoon dinosaurs, storybook picture-book style, vivid
> colors. A small sage-green chibi dinosaur with teal spikes and a leaf behind
> his head, and a small brick-red chibi raptor with darker red stripes and
> yellow eyes, stand side by side on a shrinking patch of dry sand as calm
> seawater rises around it, palm trees half-submerged behind them. Neither is
> fighting. They both look out at the water, then down at the small dry patch
> they are standing on, then slowly turn their heads to look at EACH OTHER —
> wary, calculating, the fight not over but changed. Hold on that look. Exactly
> ONE green dinosaur and exactly ONE red raptor in the entire scene. Ralph
> carries exactly ONE sword and wears NO cape. All-ages, no peril, no drowning.

### Budget

Clip regen preflighted at **~54 cr**. Two clips ≈ 108 cr with no re-roll
headroom; **~160 cr is the safe number** (2 clips + one re-roll). Balance at
brief time: **76.5** — funds ONE clip. Options: generate TIDE-2 only (the look
IS the cliffhanger; the reveal could be implied by a slow push on existing
footage plus sound), or top up.

---

## 5. Build plan

1. `tide1_start.png` from beat5 @8.15s
2. generate TIDE-1 → QA for cape/dual-sword/clones before spending on TIDE-2
3. chain TIDE-2 from TIDE-1's end frame
4. build with the proven chain (see `wip/ep1/build_ep1_v7.sh` — reuse verbatim
   for acts 0-2, extend for act 3):
   - punch-in sub-cuts (`crop=0.78`) so nothing sits longer than ~3s
   - **no outro card** — it breaks the loop
   - music **stops** at the turn; no battle theme after
   - master to **-14 LUFS**
5. verify before shipping: transcribe the finished file (local faster-whisper
   in `goldfix-studio/.venv`, `base.en` cached), motion/cut profile, loop seam

**Loop note:** Ep1's old loop trick (last frame == first frame) does NOT apply
here — the episode now ends somewhere it didn't begin. That is correct: a
cliffhanger shouldn't loop back to the start, it should stop dead.

---

## 6. EP2 — first DEN cutscene (Type B, sketch)

Runs straight off Ep1's cliffhanger, and deliberately refuses to resolve it.

> Ralph's den, that night. He's soaked. He sets the leaf down to dry on a
> rock — it's the first time we've seen him put it down. He scratches a mark
> on the wall at the waterline. Below it are older marks; the new one is
> higher than all of them. He eats without appetite. Then a shadow in the
> doorway — **Max**, also soaked, holding nothing, not attacking. He doesn't
> come in. Neither of them speaks. Ralph looks at the mark on the wall, then
> at Max. Cut.

Bubbles only, no narrator. Ends on a hook that isn't a fight. Establishes the
waterline mark as the series' recurring dread-meter — it appears in every
subsequent den episode, always higher, and the audience will start looking for
it. That's a serialization device that costs nothing to produce.

Generation: one location, two characters, no action — the cheapest clip type
in the saga.

---

## 7. Open decisions

- [ ] Reuse acts 1-2 footage, or regenerate the whole episode? Reuse is ~160cr,
      full regen is ~400cr. **Recommend reuse** — the footage is fine, it was
      the *structure* that failed.
- [ ] One clip now (TIDE-2 only) or top up for both?
- [ ] Does the leaf survive the tide? (A leaf floating on the water in the last
      frame is free to add in post and would land hard.)
