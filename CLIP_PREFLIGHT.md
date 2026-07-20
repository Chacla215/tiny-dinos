# CLIP PREFLIGHT — run this before spending a single credit

Written 2026-07-20 after Ep2 v1 came back unusable: pasted-on sprite shadow,
blank happy faces in a scene about dread, and near-frozen animation. All three
defects were predictable from the inputs, and ~163cr was spent before anyone
looked.

**Why Ep1 was good and Ep2 was not:** Ep1 was a *sixth* draft. Four rejections
from Charlie each forced a real look at the footage, and that inspection is
where the quality came from. Ep2 was a first draft assembled from unverified
inputs and shown fully built. The gap is process, not talent.

---

## 1. VERIFY THE INPUTS — a start frame is not "ready" because a note says so

Video generation **continues its start frame**. Every defect in that image is
guaranteed to appear in every clip grown from it. So:

- [ ] Open the start frame and **crop in on each character at full size.**
      Not "is the composition right" — **is the FACE right, is the SHADOW
      right, is he on-model.**
- [ ] Specifically check for a **flat elliptical drop shadow** under a
      character. That is a game-sprite shadow and it makes them look pasted
      onto the painting. It killed Ep2. It is invisible at thumbnail size.
- [ ] Check the expression **matches the beat.** Ep2's Ralph smiled
      pleasantly through a scene about the sea rising higher than ever.
- [ ] Never trust "staged / ready to fire" from an older session. Look.

## 2. FIRE ONE CLIP FIRST. LOOK AT IT. THEN FIRE THE REST.

**This is the rule that would have saved Ep2 on its own.** All three clips
shared the same two defects; one pilot and five minutes of inspection would
have caught them before 108cr went out the door.

Firing several at once feels efficient because they are independent. They are
not independent — they share a style, a start-frame lineage and a prompt
grammar. If one is wrong they are all wrong.

- [ ] Generate the **single most representative** clip.
- [ ] QA it (§4) before generating anything else.
- [ ] Only then fire the remainder.

## 3. WRITE THE PROMPT LIKE A DIRECTOR, NOT A MOOD BOARD

Mood words ("quiet", "uneasy", "melancholy") are applied to **lighting and
pacing, not faces.** Ep1's clips have performances because its prompts were
mechanical:

> *"his eyes fly open huge and crossed, his cheeks puff, he wobbles dizzily on
> the rock with little stars circling his head, comically squashed"*

- [ ] Describe **eyes, cheeks, mouth, posture** explicitly.
- [ ] Describe the **specific physical action** the body performs.
- [ ] **NEVER ask for stillness.** "Slow, still, nothing else moves" gives a
      motion model nothing to render, and it answers with drift and morphing.
      A quiet scene still needs something physically moving — a head turn,
      water rising, dust settling, a hand reaching.
- [ ] A **wordless** episode needs MORE facial direction than a narrated one,
      not less. The faces are carrying the entire story.
- [ ] Keep the identity lock verbatim and the guards
      ("exactly ONE green dinosaur", "NO cape", "NO sword").
- [ ] **Un-losable beat FIRST** — Seedance renders front-to-back and drops the
      tail when it runs out of clip.

## 4. QA THE CLIP THAT COMES BACK

- [ ] Extract frames across the whole clip, not just the start.
- [ ] Crop in on faces. Off-model? Blank? Wrong emotion?
- [ ] Find where the usable window **ends** — models drift, add props, and
      melt subjects away entirely (Ep2's ice vanishes by 6.0s; Ep1's beat5
      grows a cape after 8.7s). **Write the window into the build script.**
- [ ] Confirm the un-losable beat actually landed inside the clip.

## 5. CHECK INHERITED CLAIMS BEFORE BUILDING ON THEM

Both of this session's worst errors were unverified inherited notes:

- *"Arthur cannot generate new lines, ever"* — **FALSE.** The Higgsfield preset
  `30fc8796-ceb6-4a66-b3a7-4a145ef7f346` is live in `list_voices`. The note was
  about the macOS voice not being installed locally and got generalised. This
  single wrong belief is why Ep2 was designed wordless.
- *"ep2_den is staged and ready to fire"* — **FALSE.** The start frame had a
  pasted sprite shadow and a blank expression, visible in one look.

If a note asserts a capability is impossible, **spend the one API call.**

## 6. COST DISCIPLINE

- A generation flagged **NSFW still bills.** Ep2 lost ~54cr to a false positive
  on a melting ice cube. On quiet, texture-heavy shots with no character to
  anchor them, write defensively.
- Budget the pilot clip separately. Assume the first one may be thrown away —
  that is the cost of finding out cheaply instead of expensively.
