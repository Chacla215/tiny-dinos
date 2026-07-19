# TikTok Content Posting API — audit kit

Goal: legitimate automated posting to **@_tinydinos**, replacing the manual
1-tap flow. TikTok gates this behind an audit; until it passes, every API
post is forced to `SELF_ONLY` (visible only to us), so this is a background
track — **keep posting manually while it runs.**

Expect **1–2 weeks** for a clean pass, 2–4 with feedback rounds. There are
**two sequential audits**: Upload (`push_by_file` → inbox, SELF_ONLY) first,
then Direct Post (`video.publish` → public). We want the second; the first
is the prerequisite.

Why we are not automating via browser instead: TikTok's ToS forbids it, and
a two-day-old account with no history is the worst possible profile to try
it on. GoldFix's Playwright uploader (`GoldFix/scripts/tiktok_upload.py`)
remains the fallback if this audit stalls AND the account has built history.

## Step 1 — register the app  (Charlie, ~15 min, needs TikTok login)

1. developers.tiktok.com → log in as **@_tinydinos** → **Manage apps** →
   **Connect an app**.
2. App name: `Tiny Dinos Publisher`. Category: the closest to
   "content publishing tool for own brand".
3. Add products: **Login Kit** and **Content Posting API**.
4. Under Content Posting API, request **Direct Post** (not just Upload).
5. Scopes to request: `user.info.basic`, `video.publish`, `video.upload`.
6. Redirect URI: `http://localhost:8723/callback` (our local OAuth catcher —
   TikTok accepts localhost for desktop/dev flows; if it rejects it, use the
   website domain and we will host a one-line callback page).
7. Save the **client key** and **client secret** → into
   `scripts/social/.tt_client.json` (git-ignored), shape:
   `{"client_key": "...", "client_secret": "..."}`
   Send them to Claude or paste them into that file directly.

## Step 2 — the two URLs TikTok demands

- **Privacy policy URL** — `PRIVACY.md` in this repo is the text. It must be
  reachable at a public URL before submitting. Fastest options:
  a) add a `/privacy` page to the tinydinos site, or
  b) enable GitHub Pages on this repo, or
  c) publish it as a public gist and use the raw URL (accepted, least pretty).
- **Terms of service URL** — TikTok usually accepts a privacy policy alone
  for a first-party publishing tool; if the form requires ToS separately,
  a two-paragraph "these tools are operated by their author, for their own
  accounts, with no third-party users" page satisfies it.

## Step 3 — the demo video (the part that fails audits)

TikTok wants an unedited screen recording showing the **whole** flow. What
reviewers reject for: jump cuts, a flow that doesn't obviously belong to the
app under review, and any step happening off-camera.

Record, in one take:
1. Start at the app's entry point — run `publish_tiktok.py --auth`.
2. Show the TikTok OAuth consent screen appearing, and the scopes on it.
3. Approve; show the callback succeeding.
4. Run a real post command; show the caption and file being sent.
5. Show the resulting video on the @_tinydinos profile.
6. Show where the token is stored locally, and how it is revoked.

Narrate what each step does. Length is fine at 2–4 minutes.

**Blocked on:** `publish_tiktok.py` does not exist yet — Claude writes it
once the client key/secret land (step 1). It will mirror
`publish_instagram.py`: stdlib, calendar-driven, `--check` first so we can
prove which account we are posting as.

## Step 4 — data-handling description (paste into the form)

> Tiny Dinos Publisher is a single-operator tool that publishes the
> developer's own promotional videos to the developer's own TikTok account.
> It has no end users other than the developer. It collects no personal
> data. It reads only the authenticated account's own basic profile
> information, and only to verify that a post is going to the intended
> account before uploading. Access tokens are stored in a local file on the
> developer's machine, excluded from version control, transmitted only to
> TikTok's own API, and never shared with any third party. No analytics,
> advertising, tracking, or data-broker services are used. Data is retained
> only while the token is valid and access can be revoked at any time from
> TikTok account settings.

## Status

- [ ] Step 1 — app registered, client key + secret saved  ← **Charlie, next**
- [ ] Step 2 — privacy policy live at a public URL
- [ ] Step 3 — `publish_tiktok.py` written (Claude, needs step 1), demo recorded
- [ ] Step 4 — submitted
- [ ] Upload audit passed
- [ ] Direct Post audit passed → flip TikTok to automated in the calendar
