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
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
CLIENT = os.path.join(HERE, ".yt_client.json")
TOKEN = os.path.join(HERE, ".yt_token.json")
CAL = os.path.join(HERE, "post_calendar.json")
SCOPE = "https://www.googleapis.com/auth/youtube.upload"


def _post(url, data, headers=None, raw=False):
    body = data if raw else urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(url, data=body, headers=headers or {})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode() or "{}")


def auth():
    c = json.load(open(CLIENT))
    d = _post("https://oauth2.googleapis.com/device/code",
              {"client_id": c["client_id"], "scope": SCOPE})
    print(f"\n  1. Open {d['verification_url']}\n  2. Enter code: {d['user_code']}\n")
    while True:
        time.sleep(d["interval"])
        try:
            t = _post("https://oauth2.googleapis.com/token", {
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


def upload(post, publish_at=None):
    path = os.path.join(ROOT, post["file"])
    tok = access_token()
    status = {"privacyStatus": "public", "selfDeclaredMadeForKids": False}
    if publish_at:
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
    print(f"uploaded {post['id']} -> https://youtube.com/shorts/{vid['id']}"
          + (f" (goes live {publish_at})" if publish_at else " (LIVE now)"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--auth", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--post", metavar="ID")
    ap.add_argument("--at", metavar="ISO", help="schedule time UTC, e.g. 2026-07-21T17:00")
    a = ap.parse_args()
    if a.auth:
        return auth()
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
        return upload(p, a.at)
    ap.print_help()


if __name__ == "__main__":
    main()
