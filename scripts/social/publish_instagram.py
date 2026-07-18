#!/usr/bin/env python3
"""Publish TINY DINOS photos + reels to Instagram via the Graph API,
driven by post_calendar.json. Pure stdlib.

The Graph API ingests media from a PUBLIC URL (no local upload for feed
media), so `--host` first pushes the file to Higgsfield storage (permanent
CDN URL) using the session's media_upload flow — or pass any public URL
with --url.

Setup (once, ~30 min, needs Charlie's logins):
  1. Instagram app -> switch the account to PROFESSIONAL (Creator).
  2. Create a Facebook Page (can be bare) and link the IG account to it
     (IG Settings -> Sharing to other apps / Meta Business Suite).
  3. developers.facebook.com -> Create App (type: Business) ->
     add "Instagram Graph API" product.
  4. Graph API Explorer: select the app, grant instagram_basic,
     instagram_content_publish, pages_show_list -> Generate token ->
     extend to a long-lived token (60 days; script warns near expiry).
  5. Find the IG user id:  GET /me/accounts -> page id ->
     GET /{page-id}?fields=instagram_business_account
  6. Save both into scripts/social/.ig_auth.json  (git-ignored):
     {"ig_user_id": "1784...", "access_token": "EAAG...", "created": "2026-07-19"}

Then:
  python3 publish_instagram.py --post mosaic-1 --url https://cdn.../tile1.png
  python3 publish_instagram.py --post reel-sumo --url https://cdn.../reel.mp4
"""
import argparse
import datetime
import json
import os
import sys
import time
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
AUTH = os.path.join(HERE, ".ig_auth.json")
CAL = os.path.join(HERE, "post_calendar.json")
G = "https://graph.facebook.com/v21.0"


def call(path, params):
    req = urllib.request.Request(f"{G}/{path}",
                                 data=urllib.parse.urlencode(params).encode())
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode())


def publish(post, url):
    a = json.load(open(AUTH))
    made = datetime.date.fromisoformat(a.get("created", "2000-01-01"))
    if (datetime.date.today() - made).days > 50:
        print("WARNING: long-lived token is older than 50 days — refresh it soon.")
    uid, tok = a["ig_user_id"], a["access_token"]
    if post["type"] == "photo":
        c = call(f"{uid}/media", {"image_url": url,
                                  "caption": post.get("caption", ""),
                                  "access_token": tok})
    else:
        c = call(f"{uid}/media", {"media_type": "REELS", "video_url": url,
                                  "caption": post.get("caption", ""),
                                  "share_to_feed": "false",   # launch month: keep the grid mosaic intact
                                  "access_token": tok})
        # reels ingest async — poll the container until FINISHED
        for _ in range(60):
            s = call_get(f"{c['id']}?fields=status_code&access_token={tok}")
            if s.get("status_code") == "FINISHED":
                break
            time.sleep(5)
    r = call(f"{uid}/media_publish", {"creation_id": c["id"], "access_token": tok})
    print(f"published {post['id']} -> media id {r['id']}")


def call_get(path_qs):
    with urllib.request.urlopen(f"{G}/{path_qs}") as r:
        return json.loads(r.read().decode())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--post", metavar="ID", required=True)
    ap.add_argument("--url", metavar="PUBLIC_URL", required=True,
                    help="public URL of the media (host the file first)")
    a = ap.parse_args()
    cal = json.load(open(CAL))
    p = next((x for x in cal["posts"] if x["id"] == a.post), None)
    if not p:
        sys.exit(f"no post '{a.post}' in calendar")
    if "ig" not in p["platforms"]:
        sys.exit(f"'{a.post}' is not an IG post")
    publish(p, a.url)


if __name__ == "__main__":
    main()
