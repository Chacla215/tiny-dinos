#!/usr/bin/env python3
"""Upload + schedule TINY DINOS videos to YouTube (Shorts) from post_calendar.json.

Pure stdlib (urllib) — no pip installs. One-time auth uses the OAuth
"installed app" device flow, so no browser redirect server is needed.

Setup (once, ~10 min, needs Charlie's Google login):
  1. console.cloud.google.com -> new project "tiny-dinos-social" ->
     enable "YouTube Data API v3".
  2. OAuth consent screen: External, add Charlie's Gmail as test user.
  3. Credentials -> Create OAuth client ID -> type "TVs and Limited Input
     devices" -> save client id + secret into scripts/social/.yt_client.json
     as {"client_id": "...", "client_secret": "..."}   (git-ignored).
  4. python3 publish_youtube.py --auth   # prints a URL + code; Charlie
     approves on his phone; token cached to .yt_token.json (git-ignored).

Then:
  python3 publish_youtube.py --list                 # show calendar status
  python3 publish_youtube.py --post ep1             # upload now (public)
  python3 publish_youtube.py --post ep1 --at 2026-07-21T17:00  # scheduled
"""
import argparse
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
CLIENT = os.path.join(HERE, ".yt_client.json")
TOKEN = os.path.join(HERE, ".yt_token.json")
CAL = os.path.join(HERE, "post_calendar.json")

# readonly rides along with upload purely so the target channel can be VERIFIED
# before anything is sent. Charlie has several channels on one Google account
# (Tiny Dinos and GoldFix), and device-flow consent silently binds to whichever
# was picked at approval — an upload-only token cannot tell you which one it got.
# readonly rides along with upload purely so the target channel can be VERIFIED
# before anything is sent. Charlie has several channels on one Google account
# (Tiny Dinos and GoldFix), and device-flow consent silently binds to whichever
# was picked at approval — an upload-only token cannot tell you which one it got.
#
# DO NOT ADD youtube.force-ssl (or plain youtube) HERE. Tried 2026-07-19 to make
# --publish work: Google's DEVICE flow accepts only a fixed scope allowlist and
# rejects both with `invalid_scope`, which breaks --auth outright — you cannot
# even re-authorise. Flipping visibility over the API needs a different OAuth
# client type entirely (Desktop app + loopback redirect), not just a wider scope
# string. See publish() for what that would take.
SCOPE = ("https://www.googleapis.com/auth/youtube.upload"
         " https://www.googleapis.com/auth/youtube.readonly")

# Pinned target. Every upload asserts the token resolves here first.
# Set by running --check after --auth; None means "not yet verified", and
# uploading is blocked until it is. Never fill this in by hand from memory.
EXPECTED_CHANNEL_ID = "UC-UHvpQe8FAPuq_HUmuC4Zg"   # @thetinydinos, verified via --check
EXPECTED_CHANNEL_TITLE = "Tiny Dinos"


def _raw_post(url, data, headers=None, raw=False):
    """POST that lets HTTPError through — callers that need the error body."""
    body = data if raw else urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(url, data=body, headers=headers or {})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode() or "{}")


def _post(url, data, headers=None, raw=False):
    try:
        return _raw_post(url, data, headers, raw)
    except urllib.error.HTTPError as e:
        raise SystemExit(f"YouTube API {e.code}: {e.read().decode()[:500]}")


def _get(url, tok):
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {tok}"})
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        raise SystemExit(f"YouTube API {e.code}: {e.read().decode()[:500]}")


def channel(tok):
    """Which channel does this token actually publish to?"""
    d = _get("https://www.googleapis.com/youtube/v3/channels"
             "?part=snippet&mine=true", tok)
    items = d.get("items") or []
    if not items:
        sys.exit("token resolves to no channel at all — re-run --auth")
    return items[0]["id"], items[0]["snippet"]["title"]


def assert_target(tok):
    """Refuse to upload anywhere but the pinned channel."""
    cid, title = channel(tok)
    if EXPECTED_CHANNEL_ID is None:
        sys.exit(f"EXPECTED_CHANNEL_ID is unset — token currently resolves to "
                 f"'{title}' ({cid}). Confirm that is right, pin it in this "
                 f"file, then upload. Nothing uploaded.")
    if cid != EXPECTED_CHANNEL_ID:
        sys.exit(f"WRONG CHANNEL — token resolves to '{title}' ({cid}), "
                 f"expected '{EXPECTED_CHANNEL_TITLE}' ({EXPECTED_CHANNEL_ID}). "
                 f"Nothing uploaded. Re-run --auth and pick the right channel.")
    return cid, title


def auth():
    c = json.load(open(CLIENT))
    d = _post("https://oauth2.googleapis.com/device/code",
              {"client_id": c["client_id"], "scope": SCOPE})
    print(f"\n  1. Open {d['verification_url']}\n  2. Enter code: {d['user_code']}\n")
    while True:
        time.sleep(d["interval"])
        try:
            t = _raw_post("https://oauth2.googleapis.com/token", {
                "client_id": c["client_id"], "client_secret": c["client_secret"],
                "device_code": d["device_code"],
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
            json.dump(t, open(TOKEN, "w"))
            print("authorized — token saved.")
            return
        except urllib.error.HTTPError as e:
            if b"authorization_pending" in e.read():
                continue
            raise


def access_token():
    c, t = json.load(open(CLIENT)), json.load(open(TOKEN))
    r = _post("https://oauth2.googleapis.com/token", {
        "client_id": c["client_id"], "client_secret": c["client_secret"],
        "refresh_token": t["refresh_token"], "grant_type": "refresh_token"})
    return r["access_token"]


def upload(post, publish_at=None, unlisted=False):
    path = os.path.join(ROOT, post["file"])
    tok = access_token()
    _, title = assert_target(tok)          # never upload to the wrong channel
    print(f"uploading to '{title}'")
    status = {"privacyStatus": "public", "selfDeclaredMadeForKids": False}
    if unlisted:
        # link-shareable but not broadcast: the review step for a cut Charlie
        # hasn't watched yet. Flip to Public in Studio, or re-post without --unlisted.
        status = {"privacyStatus": "unlisted", "selfDeclaredMadeForKids": False}
    elif publish_at:
        status = {"privacyStatus": "private", "publishAt": publish_at + ":00Z",
                  "selfDeclaredMadeForKids": False}
    meta = {"snippet": {"title": post.get("title", "TINY DINOS"),
                        "description": post.get("caption", ""),
                        "categoryId": "20"},   # Gaming
            "status": status}
    init = urllib.request.Request(
        "https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status",
        data=json.dumps(meta).encode(),
        headers={"Authorization": f"Bearer {tok}",
                 "Content-Type": "application/json",
                 "X-Upload-Content-Type": mimetypes.guess_type(path)[0] or "video/mp4"})
    with urllib.request.urlopen(init) as r:
        loc = r.headers["Location"]
    with open(path, "rb") as fh:
        vid = _post(loc, fh.read(), raw=True,
                    headers={"Authorization": f"Bearer {tok}",
                             "Content-Type": "video/mp4"})
    state = ("UNLISTED — link works, not on the channel feed" if unlisted
             else f"goes live {publish_at}" if publish_at else "LIVE now")
    print(f"uploaded {post['id']} -> https://youtube.com/shorts/{vid['id']}  ({state})")


def publish(video_id):
    """Report an upload's visibility, and flip it to public IF the token can.

    The normal flow uploads UNLISTED so Charlie watches the cut on a real Shorts
    player before the world does. This was meant to be the second half of that.

    IT CANNOT ACTUALLY FLIP ANYTHING with the current auth, and that is not
    fixable by widening SCOPE. videos.update needs youtube.force-ssl, but the
    OAuth DEVICE flow this script uses (client type "TVs and Limited Input
    devices") only permits a fixed scope allowlist that excludes it — asking for
    it returns `invalid_scope` and breaks --auth completely.

    Making it work would mean re-doing auth as a Desktop-app OAuth client with a
    loopback redirect (a new client id in Cloud Console + a local redirect
    server). That is a real change, not a flag. Until then the flip is a manual
    Studio tap, which is arguably the better default anyway: a human eye on the
    cut immediately before it goes public.

    So this stays useful as a READ: it tells you exactly what is live and what
    is not, which is how the v6 upload was caught sitting unlisted while
    Instagram was already public.
    """
    tok = access_token()
    assert_target(tok)          # same pinned-channel guard as upload
    cur = _get("https://www.googleapis.com/youtube/v3/videos"
               f"?part=status,snippet&id={video_id}", tok)
    items = cur.get("items") or []
    if not items:
        sys.exit(f"no video '{video_id}' on this channel — check the id")
    title = items[0]["snippet"]["title"]
    was = items[0]["status"]["privacyStatus"]
    if was == "public":
        print(f"'{title}' is ALREADY public — nothing to do")
        return
    body = json.dumps({"id": video_id,
                       "status": {"privacyStatus": "public",
                                  "selfDeclaredMadeForKids": False}}).encode()
    req = urllib.request.Request(
        "https://www.googleapis.com/youtube/v3/videos?part=status",
        data=body, method="PUT",
        headers={"Authorization": f"Bearer {tok}",
                 "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        if e.code == 403:
            sys.exit(
                f"'{title}' is {was.upper()} and this token CANNOT change that.\n"
                f"  Flipping visibility needs the youtube.force-ssl scope, which\n"
                f"  Google's device flow refuses to grant (see publish() docstring).\n"
                f"  Flip it by hand instead:\n"
                f"    YouTube Studio -> Content -> '{title}' -> Visibility -> Public\n"
                f"    https://studio.youtube.com/video/{video_id}/edit")
        raise SystemExit(f"YouTube API {e.code}: {e.read().decode()[:500]}")
    print(f"'{title}' {was} -> PUBLIC")
    print(f"  https://youtube.com/shorts/{video_id}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--auth", action="store_true")
    ap.add_argument("--publish", metavar="VIDEO_ID",
                    help="flip an existing unlisted upload to public")
    ap.add_argument("--check", action="store_true",
                    help="resolve the token to a channel and exit")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--post", metavar="ID")
    ap.add_argument("--at", metavar="ISO", help="schedule time UTC, e.g. 2026-07-21T17:00")
    ap.add_argument("--unlisted", action="store_true",
                    help="upload unlisted (shareable link, not broadcast)")
    a = ap.parse_args()
    if a.auth:
        return auth()
    if a.publish:
        return publish(a.publish)
    if a.check:
        cid, title = channel(access_token())
        pinned = ("unset — pin it once confirmed" if EXPECTED_CHANNEL_ID is None
                  else ("MATCH" if cid == EXPECTED_CHANNEL_ID else "MISMATCH"))
        print(f"token resolves to '{title}' ({cid}) — pinned: {pinned}")
        return
    cal = json.load(open(CAL))
    if a.list:
        for p in cal["posts"]:
            print(f"  {p['id']:<18} day {p['day']:<3} {','.join(p['platforms']):<14} {p['status']}")
        return
    if a.post:
        p = next((x for x in cal["posts"] if x["id"] == a.post), None)
        if not p:
            sys.exit(f"no post '{a.post}' in calendar")
        if "yt" not in p["platforms"]:
            sys.exit(f"'{a.post}' is not a YouTube post")
        return upload(p, a.at, a.unlisted)
    ap.print_help()


if __name__ == "__main__":
    main()
