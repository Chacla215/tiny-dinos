"""
Meshy text-to-3D for the weapons, fully headless.

    python3 scripts/tools/weapon_gen.py            # all weapons
    python3 scripts/tools/weapon_gen.py sword axe  # a subset

Two-stage (preview geometry -> refine texture), downloads the textured .glb to
assets/concept/weapons/<w>_model.glb for blender_render_weapon.py to bake into a
held sprite. Stdlib only; key from scripts/tools/.meshy_key. ~40 credits each.
"""
import sys, os, json, time, urllib.request, urllib.error

API = "https://api.meshy.ai/openapi/v2/text-to-3d"
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
STYLE = ("cute chunky stylized cartoon %s, a hand-held game weapon prop, bold "
         "simple shapes, smooth storybook shading, clean silhouette, single object")
PROMPTS = {
    "sword":     STYLE % "sword with a broad blade and round pommel",
    "dagger":    STYLE % "short dagger",
    "axe":       STYLE % "battle axe with a stone head on a wooden handle",
    "mace":      STYLE % "spiked ball mace on a short handle",
    "hammer":    STYLE % "big blocky war hammer",
    "nunchucks": STYLE % "pair of wooden nunchucks joined by a chain",
    "bow":       STYLE % "curved wooden bow with a taut string",
}
ALL = list(PROMPTS.keys())


def key():
    k = os.environ.get("MESHY_API_KEY")
    if not k and os.path.exists(os.path.join(HERE, ".meshy_key")):
        k = open(os.path.join(HERE, ".meshy_key")).read().strip()
    if not k:
        sys.exit("no MESHY_API_KEY / .meshy_key")
    return k


def req(url, k, method="GET", body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Authorization", "Bearer " + k)
    if data:
        r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r, timeout=120) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        sys.exit("Meshy %s: %s" % (e.code, e.read().decode()[:300]))


def poll(task, k):
    while True:
        time.sleep(8)
        st = req(API + "/" + task, k)
        s = st.get("status")
        print("  %s %d%%" % (s, st.get("progress", 0)))
        if s == "SUCCEEDED":
            return st
        if s in ("FAILED", "CANCELED"):
            print("  ! %s" % s); return None


def make(w, k):
    print("[%s] preview..." % w)
    pv = req(API, k, "POST", {"mode": "preview", "prompt": PROMPTS[w], "ai_model": "latest"})
    if not poll(pv["result"], k):
        return None
    print("[%s] refine (texture)..." % w)
    rf = req(API, k, "POST", {"mode": "refine", "preview_task_id": pv["result"], "enable_pbr": False})
    st = poll(rf["result"], k)
    if not st:
        return None
    glb = st.get("model_urls", {}).get("glb")
    if not glb:
        print("  ! no glb"); return None
    d = os.path.join(ROOT, "assets", "concept", "weapons")
    os.makedirs(d, exist_ok=True)
    out = os.path.join(d, "%s_model.glb" % w)
    urllib.request.urlretrieve(glb, out)
    print("  -> %s (%.1fMB)" % (out, os.path.getsize(out) / 1e6))
    return out


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    force = "--force" in sys.argv
    k = key()
    ws = args or ALL
    done = []
    for w in ws:
        out = os.path.join(ROOT, "assets", "concept", "weapons", "%s_model.glb" % w)
        if not force and os.path.exists(out) and os.path.getsize(out) > 3e6:
            print("[%s] already have a model -- skipping" % w); done.append(w); continue
        if make(w, k):
            done.append(w)
    print("\nDONE: %s" % ", ".join(done))
