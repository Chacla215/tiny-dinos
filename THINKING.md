# THINKING.md — How we make decisions on Tiny Dinos

Our shared reasoning process (Charlie's call, 2026-06-15). These are six lenses
adapted from Sun Tzu / Munger prompt frameworks. They are **decision tools**, not
coding rules — pull the right one when a call is bigger than "write this function."
Use the lens that fits the decision; don't run all six on everything.

A standing bias these are meant to catch on THIS project: we ship **breadth on
snapshot-validation** (more modes/systems, tests green) while the inner loop's
**feel** stays deferred ("nobody has felt it yet" recurs almost every session).
When in doubt, the lens that fights that bias wins.

---

## 1. The Advantage Identifier — *what's our unfair, hard-to-copy edge?*
Before adding/cutting, ask: does this strengthen the one thing competitors can't
copy in 6 months? For Tiny Dinos that edge is the **combination** — painterly
real-art dinos + a live limb rig + couch-only gamepad chaos — not any single
mechanic. Generic "more combat depth" is copyable; the distinctive blend is not.

## 2. The Positioning Audit — *are we fighting on terrain we can win?*
Name the battlefield each feature competes on. Precise competitive combat =
Smash/Brawlhalla terrain (needs online + a ladder + a playerbase — we have none).
Party/failure-is-funny = Gang Beasts/Stumble Guys terrain (couch, 4 pads, laughs —
exactly what we are). A solo dev with no online wins on the *party* battlefield.
Ask of any feature: which terrain does this push us toward, and is it the one we win?

## 3. The Inversion Engine — *how would we guarantee this fails?*
Before building, state the worst outcome and list every path to it, then eliminate
the top few. "How do we make this floppy feature un-fun?" surfaces more than "how
do we make it fun?" Flag where our current plan already matches a failure path.

## 4. The Mental Model Installer — *am I using the right lens, or my favorite one?*
We default to the *engineering* lens (does it compile, do tests pass). Many calls
here are **game-feel** (timing, juice, readability) or **design-economy** (does
this dilute the roster's distinctness?) or **scope** (solo-dev bandwidth). Name the
discipline the decision actually belongs to before answering it.

## 5. The Stupidity Auditor — *is this driven by clear thinking or by a bias?*
Score decisions honestly regardless of outcome (a lucky call is still a bad call).
Our highest-frequency error: **shiny-system bias** — building the next system
because it's tractable and testable, while feel debt compounds. The cheap habit
that fixes it: every new system gets a *feel* exit-check, not just a green test.

## 6. The First Principles Stripper — *what's actually true under the assumptions?*
Strip a problem to what's verified. "Precise combat is our pillar" is an inherited
assumption from early builds — is it actually our edge, or just the first thing we
built? Rebuild the call from what's verifiably true (the genre study, what a solo
gamepad-only dev can win), not from what we've always said.

---

### How to apply in practice
- Surface which lens you're using when you make a non-trivial recommendation.
- Don't perform all six — that's theater. One sharp lens beats six shallow ones.
- The output should change what we DO, not just describe the situation.
- Charlie wants autonomous iteration on feel ([[charlie-experiment-autonomously]]);
  these lenses are how we decide *what* to iterate on, then we go do it.
