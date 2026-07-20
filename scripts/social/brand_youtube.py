#!/usr/bin/env python3
"""Apply the Tiny Dinos channel branding to YouTube, from the kit in SOCIAL_KIT.md.

More of the channel is automatable than we assumed. What this can and cannot do:

  AUTOMATABLE (this script)   banner image, channel description, keywords,
                              country, default language, the unsubscribed
                              channel trailer, the branding watermark

  The banner DOES work, despite Google's docs carrying a blanket deprecation
  notice on brandingSettings.image — verified end to end 2026-07-19:
  channelBanners.insert returned a url and bannerExternalUrl read back set.
  MANUAL, no API exists       the AVATAR, the channel TITLE, the @handle,
                              and every profile field on Instagram and TikTok
                              (both are read-only for profile data)

THE DESTRUCTIVE TRAP — the whole reason this script is careful:
channels.update behaves like videos.update. Google: "If you are submitting an
update request, and your request does not specify a value for a property that
already has a value, the property's existing value will be deleted." A naive
PUT of just `description` silently wipes keywords, country and the trailer. So
every write here is READ-MODIFY-WRITE: fetch brandingSettings, change only the
named fields, send the whole object back.

`brandingSettings.channel.title` is NOT writable — sending a different one
returns channelTitleUpdateForbidden. It is echoed back unchanged.

Usage (start with the first two — they are read-only and safe):
    python3 scripts/social/brand_youtube.py --check
    python3 scripts/social/brand_youtube.py --apply --dry-run
    python3 scripts/social/brand_youtube.py --apply
    python3 scripts/social/brand_youtube.py --banner assets/concept/brand/avatar/yt_banner_2048.png
    python3 scripts/social/brand_youtube.py --trailer 8RxeWgCDLoU
    python3 scripts/social/brand_youtube.py --watermark assets/concept/brand/avatar/avatar_400.png

Needs the `youtube` scope — run `publish_youtube.py --auth` once if you have
not since 2026-07-19, or every write returns 403 ACCESS_TOKEN_SCOPE_INSUFFICIENT.
"""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)

import publish_youtube as y  # noqa: E402  (auth + pinned-channel guard live there)

API = "https://www.googleapis.com/youtube/v3"

# Copy is the kit's, verbatim — SOCIAL_KIT.md "Bios — paste verbatim".
# NOTE the kit's own rule: "No cadence promise anywhere — episodes ship when
# they ship." The Ep1 outro card currently promises a weekly episode, which
# contradicts this. Flagged, not silently reconciled.
DESCRIPTION = """\
TINY DINOS is a couch brawler for 1-4 players — six little dinosaurs, one
island, and absolutely no personal space.

Here you get both halves: the story episodes (how each dino got the way they
are) and the real thing — actual gameplay, actual fights, captured straight out
of the game.

Made by one person. New dino, new island, new episode as they land.

🦕 tinydinos.higgsfield.app
📸 Instagram @_tinydinos
🎵 TikTok @_tinydinos"""

KEYWORDS = ("tinydinos \"tiny dinos\" \"couch co-op\" \"local multiplayer\" "
            "\"party game\" brawler dinosaur indiegame gamedev \"pixel art\" "
            "\"couch brawler\" shorts animation")
COUNTRY = "GB"
LANGUAGE = "en"


def _req(url, tok, method="GET", body=None, ctype="application/json"):
    data = body if isinstance(body, bytes) else (
        json.dumps(body).encode() if body is not None else None)
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={"Authorization": f"Bearer {tok}",
                                          **({"Content-Type": ctype} if data else {})})
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        detail = e.read().decode()[:400]
        if e.code == 403 and "SCOPE" in detail.upper():
            sys.exit("403 insufficient scope — this needs the `youtube` scope.\n"
                     "  Run: python3 scripts/social/publish_youtube.py --auth")
        sys.exit(f"YouTube API {e.code}: {detail}")


def fetch_branding(tok):
    d = _req(f"{API}/channels?part=brandingSettings,snippet"
             f"&id={y.EXPECTED_CHANNEL_ID}", tok)
    items = d.get("items") or []
    if not items:
        sys.exit("channel not found — is the token bound to Tiny Dinos?")
    return items[0]


def cmd_check(tok):
    it = fetch_branding(tok)
    bs = it.get("brandingSettings", {})
    ch = bs.get("channel", {})
    sn = it.get("snippet", {})
    print(f"channel : {sn.get('title')}  ({y.EXPECTED_CHANNEL_ID})")
    print(f"handle  : {sn.get('customUrl', '(none)')}")
    print(f"country : {ch.get('country') or '(unset)'}")
    print(f"language: {ch.get('defaultLanguage') or '(unset)'}")
    print(f"trailer : {ch.get('unsubscribedTrailer') or '(unset)'}")
    print(f"keywords: {(ch.get('keywords') or '(unset)')[:90]}")
    desc = ch.get("description") or ""
    print(f"description ({len(desc)} chars):")
    print("  " + ("\n  ".join(desc.splitlines()) if desc else "(unset)"))
    banner = (bs.get("image") or {}).get("bannerExternalUrl")
    print(f"banner  : {banner or '(unset)'}")
    print("\navatar / title / @handle are NOT settable via API — do those by hand.")


def _write_branding(tok, mutate, dry_run):
    """Read-modify-write. `mutate` receives brandingSettings and edits in place."""
    it = fetch_branding(tok)
    bs = it.get("brandingSettings", {})
    bs.setdefault("channel", {})
    before = json.dumps(bs, sort_keys=True)
    mutate(bs)
    # title is read-only; echo whatever the channel already has.
    bs["channel"]["title"] = it["snippet"]["title"]
    body = {"id": y.EXPECTED_CHANNEL_ID, "brandingSettings": bs}
    if dry_run:
        print("--- DRY RUN, nothing sent. Payload that WOULD be PUT:")
        print(json.dumps(body, indent=2, ensure_ascii=False))
        print("--- unchanged fields are included on purpose: channels.update "
              "deletes any property you omit.")
        return
    if json.dumps(bs, sort_keys=True) == before:
        print("no change needed")
        return
    _req(f"{API}/channels?part=brandingSettings", tok, "PUT", body)

    # "branding updated" is NOT proof. Read it back and confirm.
    #
    # THE ORDERING HAZARD, learned 2026-07-19: read-modify-write is only safe if
    # the READ is fresh. Running --trailer then --banner back to back, the
    # banner's read happened before the trailer had propagated, so it wrote back
    # a branding object with no trailer and silently DELETED it. The API
    # reported success both times. Applying the trailer again afterwards fixed
    # it. So: verify, and if you are setting several things, expect to re-check.
    time.sleep(6)
    fresh = fetch_branding(tok).get("brandingSettings", {})
    lost = []
    for key, want in (bs.get("channel") or {}).items():
        if want and (fresh.get("channel") or {}).get(key) != want:
            lost.append(f"channel.{key}")
    for key, want in (bs.get("image") or {}).items():
        if want and (fresh.get("image") or {}).get(key) != want:
            lost.append(f"image.{key}")
    if lost:
        print(f"branding written, but these did NOT read back: {', '.join(lost)}")
        print("  YouTube's read can lag a write by a few seconds — re-run --check")
        print("  shortly. If still missing, apply that field again LAST.")
    else:
        print("branding updated (verified)")


def cmd_apply(tok, dry_run):
    def mutate(bs):
        c = bs["channel"]
        c["description"] = DESCRIPTION
        c["keywords"] = KEYWORDS
        c["country"] = COUNTRY
        c["defaultLanguage"] = LANGUAGE
    _write_branding(tok, mutate, dry_run)


def cmd_trailer(tok, video_id, dry_run):
    def mutate(bs):
        bs["channel"]["unsubscribedTrailer"] = video_id
    print(f"trailer -> {video_id} (must be public/unlisted and owned by this channel)")
    _write_branding(tok, mutate, dry_run)


def cmd_banner(tok, path, dry_run):
    p = path if os.path.isabs(path) else os.path.join(ROOT, path)
    if not os.path.exists(p):
        sys.exit(f"no such file: {p}")
    size = os.path.getsize(p)
    print(f"banner: {os.path.relpath(p, ROOT)} ({size / 1e6:.2f} MB)")
    if size > 6_000_000:
        sys.exit("banner must be <= 6 MB")
    if dry_run:
        print("--- DRY RUN: would upload the banner, then set "
              "brandingSettings.image.bannerExternalUrl to the returned url")
        return
    # Step 1 — upload the image, get back a URL.
    ctype = "image/png" if p.lower().endswith(".png") else "image/jpeg"
    with open(p, "rb") as fh:
        up = _req("https://www.googleapis.com/upload/youtube/v3/channelBanners/insert"
                  "?uploadType=media", tok, "POST", fh.read(), ctype)
    url = up.get("url")
    if not url:
        sys.exit(f"upload returned no url: {up}")
    print(f"uploaded -> {url}")

    # Step 2 — point the channel at it.
    def mutate(bs):
        bs.setdefault("image", {})["bannerExternalUrl"] = url
    _write_branding(tok, mutate, False)


def cmd_watermark(tok, path, dry_run):
    p = path if os.path.isabs(path) else os.path.join(ROOT, path)
    if not os.path.exists(p):
        sys.exit(f"no such file: {p}")
    print(f"watermark: {os.path.relpath(p, ROOT)}")
    if dry_run:
        print("--- DRY RUN: would POST watermarks/set for this channel")
        return
    ctype = "image/png" if p.lower().endswith(".png") else "image/jpeg"
    with open(p, "rb") as fh:
        _req("https://www.googleapis.com/upload/youtube/v3/watermarks/set"
             f"?channelId={y.EXPECTED_CHANNEL_ID}&uploadType=media",
             tok, "POST", fh.read(), ctype)
    print("watermark set")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="show current branding (read-only)")
    ap.add_argument("--apply", action="store_true", help="write description/keywords/country/language")
    ap.add_argument("--banner", metavar="FILE")
    ap.add_argument("--trailer", metavar="VIDEO_ID")
    ap.add_argument("--watermark", metavar="FILE")
    ap.add_argument("--dry-run", action="store_true", help="print the payload, send nothing")
    a = ap.parse_args()

    tok = y.access_token()
    y.assert_target(tok)          # never brand the wrong channel

    if a.check:
        return cmd_check(tok)
    if a.apply:
        cmd_apply(tok, a.dry_run)
    if a.trailer:
        cmd_trailer(tok, a.trailer, a.dry_run)
    if a.banner:
        cmd_banner(tok, a.banner, a.dry_run)
    if a.watermark:
        cmd_watermark(tok, a.watermark, a.dry_run)
    if not any([a.check, a.apply, a.banner, a.trailer, a.watermark]):
        ap.print_help()


if __name__ == "__main__":
    main()
