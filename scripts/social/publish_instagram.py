#!/usr/bin/env python3
"""Publish TINY DINOS photos + reels to Instagram, driven by post_calendar.json.
Pure stdlib.

Uses **Instagram API with Instagram Login** (`graph.instagram.com`) — the same
surface GoldFix authenticates against. That path needs NO Facebook Page and no
Business-Manager linkage: a Professional (Creator/Business) account authorizes
directly through Instagram. Tokens look like `IGAA…`, not `EAA…`.

Instagram ingests media from a PUBLIC URL (there is no local file upload for
feed media), so the file must be hosted first — pass any public URL with --url.

Setup (once):
  1. Instagram app -> switch the account to PROFESSIONAL (Creator).  [done]
  2. Meta app dashboard (the existing "GoldFix Publisher" app is fine — one app
     can serve several IG accounts) -> Instagram product -> add the Tiny Dinos
     account -> generate a token. Permissions on THIS path are named
     `instagram_business_basic` + `instagram_business_content_publish`
     (the `instagram_basic` / `instagram_content_publish` pair belongs to the
     older Facebook-Login path and will not work here).
  3. Save the pair into scripts/social/.ig_auth.json  (git-ignored):
     {"ig_user_id": "1784...", "access_token": "IGAA...", "created": "2026-07-19"}

Then:
  python3 publish_instagram.py --check          # who am I posting as?
  python3 publish_instagram.py --refresh        # extend the 60-day token
  python3 publish_instagram.py --post mosaic-1 --url https://cdn.../tile1.png
  python3 publish_instagram.py --post reel-sumo --url https://cdn.../reel.mp4

Always --check before the first post of a session: it prints the account the
token resolves to, which is the cheap way to never publish to the wrong brand.

Instagram allows 100 API-published posts per rolling 24h. Not a concern here.
"""
import argparse
import datetime
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
AUTH = os.path.join(HERE, ".ig_auth.json")
CAL = os.path.join(HERE, "post_calendar.json")
G = "https://graph.instagram.com/v23.0"

POLL_TRIES = 60
POLL_WAIT = 5


def _open(req):
    """urlopen, but surface Meta's JSON error body instead of a bare HTTPError."""
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()[:500]
        raise SystemExit(f"Instagram API {e.code}: {body}")


def post(path, params):
    return _open(urllib.request.Request(
        f"{G}/{path}", data=urllib.parse.urlencode(params).encode()))


def get(path, params):
    return _open(urllib.request.Request(
        f"{G}/{path}?{urllib.parse.urlencode(params)}"))


def auth():
    if not os.path.exists(AUTH):
        sys.exit(f"no {AUTH} — see the setup steps in this file's header")
    a = json.load(open(AUTH))
    made = datetime.date.fromisoformat(a.get("created", "2000-01-01"))
    age = (datetime.date.today() - made).days
    if age > 50:
        print(f"WARNING: token is {age} days old (60-day life) — "
              f"run --refresh now; an EXPIRED token can only be re-minted by hand.")
    return a["ig_user_id"], a["access_token"]


def whoami(tok):
    return get("me", {"fields": "user_id,username", "access_token": tok})


def await_container(cid, tok):
    """Block until the container is FINISHED; abort loudly on anything else."""
    for _ in range(POLL_TRIES):
        s = get(cid, {"fields": "status_code", "access_token": tok})
        code = s.get("status_code")
        if code == "FINISHED":
            return
        if code in ("ERROR", "EXPIRED"):
            sys.exit(f"container {cid} came back {code} — media rejected, not published")
        time.sleep(POLL_WAIT)
    sys.exit(f"container {cid} still not FINISHED after "
             f"{POLL_TRIES * POLL_WAIT}s — nothing published")


def publish(p, url):
    uid, tok = auth()
    me = whoami(tok)
    print(f"posting as @{me.get('username')} ({me.get('user_id')})")
    if p["type"] == "photo":
        c = post(f"{uid}/media", {"image_url": url,
                                  "caption": p.get("caption", ""),
                                  "access_token": tok})
    else:
        c = post(f"{uid}/media", {"media_type": "REELS", "video_url": url,
                                  "caption": p.get("caption", ""),
                                  # launch month: keep reels off the grid mosaic
                                  "share_to_feed": "false",
                                  "access_token": tok})
    await_container(c["id"], tok)
    r = post(f"{uid}/media_publish", {"creation_id": c["id"], "access_token": tok})
    print(f"published {p['id']} -> media id {r['id']}")


def refresh():
    """Swap a still-valid (>24h old) token for a fresh 60-day one."""
    _, tok = auth()
    r = get("refresh_access_token",
            {"grant_type": "ig_refresh_token", "access_token": tok})
    a = json.load(open(AUTH))
    a["access_token"] = r["access_token"]
    a["created"] = datetime.date.today().isoformat()
    json.dump(a, open(AUTH, "w"), indent=1)
    print(f"token refreshed — valid ~{r.get('expires_in', 0) // 86400} more days")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--post", metavar="ID")
    ap.add_argument("--url", metavar="PUBLIC_URL",
                    help="public URL of the media (host the file first)")
    ap.add_argument("--check", action="store_true",
                    help="resolve the token to an account and exit")
    ap.add_argument("--refresh", action="store_true",
                    help="extend the 60-day token")
    a = ap.parse_args()

    if a.check:
        uid, tok = auth()
        me = whoami(tok)
        print(f"token resolves to @{me.get('username')} "
              f"(user_id={me.get('user_id')}, configured ig_user_id={uid})")
        if str(me.get("user_id")) != str(uid):
            sys.exit("MISMATCH: token's account != configured ig_user_id — fix .ig_auth.json")
        return
    if a.refresh:
        return refresh()
    if not a.post or not a.url:
        ap.error("--post and --url are both required (or use --check / --refresh)")

    cal = json.load(open(CAL))
    p = next((x for x in cal["posts"] if x["id"] == a.post), None)
    if not p:
        sys.exit(f"no post '{a.post}' in calendar")
    if "ig" not in p["platforms"]:
        sys.exit(f"'{a.post}' is not an IG post")
    publish(p, a.url)


if __name__ == "__main__":
    main()
