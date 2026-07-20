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

---

## ⚠️ 2026-07-19 RESEARCH — read before spending more effort here

Verified against developers.tiktok.com. Two findings change the plan.

### 1. The Direct Post audit is designed around a GUI, and we do not have one

TikTok's [content sharing guidelines] make these MANDATORY for audit approval:

- a **privacy selector with NO default value**, populated from
  `/v2/post/publish/creator_info/query/`, where the user cannot publish until
  they explicitly choose;
- a **commercial content disclosure toggle** (default off) which, when on,
  requires choosing "Your Brand" and/or "Branded Content", with at least one
  checked before publish is enabled;
- specific declaration text shown for each of those choices.

A headless single-operator CLI structurally cannot satisfy "a dropdown with no
default". **Assume Direct Post audit will not pass for a CLI.** This is not a
question of writing better code.

### 2. Unaudited clients cannot post publicly AT ALL

- "All content posted by unaudited clients will be restricted to private
  viewing mode." Max 5 posting users / 24h.
- There is an explicit error `403 unaudited_client_can_only_post_to_private_accounts`,
  which suggests **@_tinydinos itself may have to be set to private** to post
  via API pre-audit. Unverified whether this is enforced at init or only on
  publish — one throwaway test would settle it, but it is a bad trade to flip a
  public account private to find out.

### What this leaves

| path | outcome | verdict |
|---|---|---|
| Direct Post + audit | public posts, fully automated | **likely unreachable** (GUI requirements) |
| Inbox upload (`video.upload`) | video lands in TikTok drafts, Charlie captions + taps publish in-app | **the realistic ceiling** |
| Manual (today) | Charlie uploads the file by hand | works, ~1 min/episode |

The inbox path saves the file transfer but still needs Charlie in the app, so it
is a marginal gain over today's manual flow. **Recommendation: do not pursue the
audit.** Revisit only if TikTok ships an API posture for first-party CLI tools.

### If we build anything, build the inbox uploader

Endpoints confirmed for that path:
- OAuth: `GET https://www.tiktok.com/v2/auth/authorize/` (register app as
  **Desktop** platform — only then is `http://localhost:PORT/callback` a legal
  redirect; Web platform rejects localhost). PKCE mandatory; TikTok's desktop
  doc specifies a **hex-encoded** SHA256 challenge, which is non-standard —
  build that encoding as a one-line switch and fall back to base64url.
- Token: `POST https://open.tiktokapis.com/v2/oauth/token/`; access token lives
  **24h**, refresh token 365d, and the refresh response MAY return a new refresh
  token which must be persisted.
- Inbox init: `POST /v2/post/publish/inbox/video/init/` with `source_info` only
  (no `post_info`). Then `PUT` the file to the returned `upload_url` with
  `Content-Range`; single chunk is legal (`chunk_size = video_size`,
  `total_chunk_count = 1`) and our ~60s shorts are far inside the 128 MB
  single-chunk ceiling. Poll `POST /v2/post/publish/status/fetch/`.
- `--check` needs scope `user.info.profile` (NOT just `user.info.basic`) to read
  the **username** — basic only returns the display nickname.

Step 2 (privacy policy URL) is DONE: **https://tinydinos.higgsfield.app/privacy**


---

## ⚠️ 2026-07-19 — Ep1 REPEATEDLY REMOVED from TikTok, no reason given

Charlie uploaded Ep1 by hand several times; each upload vanished with **no
stated violation**. Ep1 is live and healthy on YouTube and Instagram, so this
is TikTok-specific.

**Most likely cause is stacked signals, not one rule.** At upload time the
account was **two days old with zero prior activity**, and its first post was a
polished 60s video that already existed publicly on two other platforms, built
from AI-generated footage, carrying embedded music. That reads to an automated
system as a repost/distribution bot: new account + unoriginal content +
undisclosed AIGC + fingerprintable audio.

Note the audio is legally clean — battle theme is "Eat" by HoliznaCC0 and the
SFX are Kenney, both CC0. But fingerprint matching does not check licences.

**DO NOT KEEP RE-UPLOADING.** Repeated re-uploads of flagged content escalate
from a video-level removal to an account-level penalty, and a days-old account
has no history to absorb that.

### The plan
1. Check **Settings → Account → Account status** for a strike or restriction.
   If one exists, stop entirely until it clears.
2. **Appeal** the removals — no-reason removals are often automated and
   sometimes reversed, and an appeal usually surfaces a real reason.
3. **Warm the account up for several days**: follow, watch, comment, and post
   one or two low-stakes things made natively in-app with TikTok's own audio.
   No shortcut exists for this; it is the dominant factor.
4. On the retry, change three things at once:
   - toggle **AI-generated content ON** (free, removes a whole risk category);
   - use **TikTok's in-app music** rather than the embedded track (kills the
     fingerprint risk and reads as native creation) — a music-free master can
     be exported from `scripts/social/build_ep1.sh` by dropping the music stems;
   - consider a **different, shorter cut** (hook-only, 15-20s) since the exact
     file has now been flagged repeatedly and may itself be fingerprinted.

### Strategic note
TikTok is one platform of three, it is the one where the posting API is already
a dead end for us, and it is now actively rejecting the content. Letting TikTok
receive **Ep2** — after the account has real history — is a better trade than
burning a young account forcing Ep1 onto it.
