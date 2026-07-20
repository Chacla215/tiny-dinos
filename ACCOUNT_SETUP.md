# Account setup — the manual half

Everything here is a hand job because **no API can do it**. Verified 2026-07-19
against Google, Meta and TikTok developer docs:

- YouTube: avatar, channel title and @handle are not writable. Everything else
  (banner, description, keywords, country, trailer, watermark) IS automated —
  see `scripts/social/brand_youtube.py`.
- Instagram: profile picture, bio, name and link are **read-only on every
  current API**, both the Instagram-Login and Facebook-Login paths.
- TikTok: profile fields are read-only, and we're behind the audit wall anyway.

Assets are already baked and correctly sized in `assets/concept/brand/`.
Copy is in `SOCIAL_KIT.md` under "Bios — paste verbatim".

---

## 1. Handles — DEFERRED TO 2026-08-17 (decided 2026-07-19)

**TikTok will not allow another handle change until 2026-08-17** (30-day
cooldown from claiming @_tinydinos on 2026-07-18). Charlie's call: **wait and
rename all three together on the 17th** rather than renaming YouTube and
Instagram now.

Why waiting won: renaming early means publicly advertising a handle nobody
owns on TikTok yet — a real, if small, squatting window — plus updating the
site, bios and kit twice. Four more weeks of mismatch costs almost nothing at
this follower count, and Ep1's links are ID-based so nothing breaks either way.

### Current state (until the 17th)
TikTok **@_tinydinos** · Instagram **@_tinydinos** · YouTube **@Thetinydinos**

### Still to decide — the NAME
Not chosen yet. A YouTube handle **cannot start with an underscore**, so
@_tinydinos is impossible there and the new name has to be free on all three.

Verified FREE on YouTube: `@playtinydinos`, `@tinydinosgame`,
`@tinydinosisland`, `@tinydinosbrawl`, `@tinydinosgg`, `@tiny_dinos`,
`@tinydinoshq`, `@tinydinosdev`, `@wearetinydinos`, `@thetinydinosgame`,
`@tinydinosco`. TAKEN: `@tinydinos`, `@tinydinosclub`.

⚠️ **TikTok and Instagram availability CANNOT be tested over HTTP** — both
return 200 for handles that do not exist (control-tested 2026-07-19). Only
YouTube 404s honestly. Check those two inside their apps.

### On the day
1. Confirm the chosen name is free on TikTok + Instagram (in-app).
2. Rename all three.
3. Tell Claude — the website `LINKS.youtube`, both bios, `SOCIAL_KIT.md` and
   the YouTube channel description all need the swap in one pass.
   ⚠️ The old YouTube handle stops resolving the moment it changes, taking the
   website link with it. Channel-ID URLs
   (`youtube.com/channel/UC-UHvpQe8FAPuq_HUmuC4Zg`) never break.

## 2. YouTube — avatar

**Studio → Customization → Branding → Picture → Upload**
File: `assets/concept/brand/avatar/avatar_1024.png`
(1024×1024; YouTube renders it at 98px and crops to a circle —
`avatar_preview_circle.png` shows the result.)

The banner is NOT here — that one is automated.

## 3. Instagram — profile

**Edit profile** on @_tinydinos:
- Profile picture: `assets/concept/brand/avatar/avatar_400.png`
- Name (30 chars): `Tiny Dinos 🦕`
- Bio (117/150) and link: copy verbatim from `SOCIAL_KIT.md`
- Link: `tinydinos.higgsfield.app` (swap to the itch page when it exists)
- Category: set it to a business/creator category — it's what makes the
  profile read as an account rather than a person.

## 4. TikTok — profile

**Edit profile** on @_tinydinos:
- Profile picture: `assets/concept/brand/avatar/avatar_400.png`
- Bio (75/80): copy verbatim from `SOCIAL_KIT.md`
- Add the Instagram link in the profile's social fields.

## 5. Same avatar everywhere

All three take the same square and crop it to a circle. Uploading the same
file to all three is what makes the accounts read as one brand — this is the
cheapest professionalism win available and takes about a minute.

---

## Then hand back to Claude

Once the handle is changed and `publish_youtube.py --auth` has been re-run
(the wider `youtube` scope is needed), Claude applies the automated half:

    python3 scripts/social/brand_youtube.py --check
    python3 scripts/social/brand_youtube.py --apply --dry-run
    python3 scripts/social/brand_youtube.py --apply
    python3 scripts/social/brand_youtube.py --banner assets/concept/brand/avatar/yt_banner_2048.png
    python3 scripts/social/brand_youtube.py --trailer 8RxeWgCDLoU
    python3 scripts/social/brand_youtube.py --watermark assets/concept/brand/avatar/avatar_400.png
