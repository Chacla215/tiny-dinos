#!/usr/bin/env python3
"""Keep the social tokens alive, and shout before either one dies.

Both publishing tokens expire silently, and one of them expires PERMANENTLY:

  INSTAGRAM (.ig_auth.json)  long-lived IGAA token, valid 60 days, refreshable
      via GET /refresh_access_token once it is >24h old. Meta: "Tokens that
      have not been refreshed in 60 days will expire and can no longer be
      refreshed." There is NO recovery from a lapse short of a full manual
      re-authorisation. This is the one worth automating.

  YOUTUBE (.yt_token.json)   refresh token. NOTE: while the Google Cloud
      consent screen is in "Testing" publishing status, Google issues refresh
      tokens that expire after SEVEN DAYS. Setting the consent screen to
      "In production" removes that. This script cannot fix it — it can only
      tell you the token has stopped working.

Run daily from cron. It is idempotent and does nothing when nothing is due.

  python3 scripts/social/token_health.py           # check, refresh if due
  python3 scripts/social/token_health.py --force   # refresh IG regardless
  python3 scripts/social/token_health.py --quiet   # only speak up on problems

Exit codes: 0 healthy, 1 action needed (a token is dead or nearly dead).
"""
import datetime
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
IG_AUTH = os.path.join(HERE, ".ig_auth.json")
LOG = os.path.join(HERE, ".token_health.log")

IG_LIFETIME = 60          # days, per Meta
IG_REFRESH_AFTER = 7      # refresh once the token is this old — huge margin
IG_WARN_AT = 14           # days remaining before we escalate to a hard warning


def say(msg, quiet=False, always=False):
    if not quiet or always:
        print(msg)
    with open(LOG, "a") as fh:
        fh.write(f"{datetime.datetime.now().isoformat(timespec='seconds')} {msg}\n")


def check_instagram(quiet=False, force=False):
    """Refresh the IG token well inside its window. Returns True if healthy."""
    if not os.path.exists(IG_AUTH):
        say("IG: no .ig_auth.json — never authorised", quiet, always=True)
        return False
    a = json.load(open(IG_AUTH))
    created = datetime.date.fromisoformat(a["created"])
    age = (datetime.date.today() - created).days
    left = IG_LIFETIME - age

    if age < 1 and not force:
        say(f"IG: token is {age}d old — too new to refresh (needs >24h), {left}d left", quiet)
        return True
    if age < IG_REFRESH_AFTER and not force:
        say(f"IG: {age}d old, {left}d left — nothing due", quiet)
        return True

    say(f"IG: {age}d old ({left}d left) — refreshing", quiet)
    r = subprocess.run([sys.executable, os.path.join(HERE, "publish_instagram.py"),
                        "--refresh"], capture_output=True, text=True)
    if r.returncode == 0:
        say(f"IG: refreshed. {r.stdout.strip()}", quiet)
        return True
    # A failed refresh inside the window is recoverable; outside it is not.
    say(f"IG: REFRESH FAILED with {left}d left — {r.stderr.strip()[:200]}",
        quiet, always=True)
    if left <= IG_WARN_AT:
        say("IG: ACT NOW — past 60 days the token cannot be refreshed at all, "
            "and Instagram publishing will need a full manual re-auth.",
            quiet, always=True)
    return False


def check_youtube(quiet=False):
    """Can the stored refresh token still mint an access token?"""
    sys.path.insert(0, HERE)
    try:
        import publish_youtube as y
        tok = y.access_token()
        cid, title = y.channel(tok)
        if cid != y.EXPECTED_CHANNEL_ID:
            say(f"YT: WRONG CHANNEL — token resolves to '{title}' ({cid})",
                quiet, always=True)
            return False
        say(f"YT: ok — '{title}'", quiet)
        return True
    except SystemExit as e:
        say(f"YT: TOKEN DEAD — {str(e)[:160]}", quiet, always=True)
        say("YT: re-run  python3 scripts/social/publish_youtube.py --auth\n"
            "    If this keeps happening weekly, the Cloud consent screen is "
            "still in 'Testing' — refresh tokens expire after 7 days there. "
            "Set it to 'In production' to stop it.", quiet, always=True)
        return False
    except Exception as e:
        say(f"YT: check failed — {type(e).__name__}: {str(e)[:160]}", quiet, always=True)
        return False


def main():
    quiet = "--quiet" in sys.argv
    force = "--force" in sys.argv
    ig = check_instagram(quiet, force)
    yt = check_youtube(quiet)
    if ig and yt:
        say("all tokens healthy", quiet)
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
