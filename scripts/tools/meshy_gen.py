"""
Meshy image-to-3D, fully headless -- Claude drives Meshy end to end via its API.

    python3 scripts/tools/meshy_gen.py ralph          # one dino
    python3 scripts/tools/meshy_gen.py all            # the whole roster

Takes assets/concept/<dino>/<dino>_hero.png, submits it to Meshy's image-to-3D
endpoint WITH texturing (steered by a per-dino prompt), polls until done, and
downloads the textured .glb to assets/concept/<dino>/<dino>_model.glb -- ready for
scripts/tools/blender_render_dino.py --model to bake into a fighter sheet.

API key (never committed): set MESHY_API_KEY, or drop it in scripts/tools/.meshy_key.
Uses only the Python stdlib (urllib/json/base64) -- no pip installs.
Meshy charges ~30 credits per model (+10 with a texture prompt); failed tasks refund.
"""
import sys, os, json, base64, time, urllib.request, urllib.error

API = "https://api.meshy.ai/openapi/v1/image-to-3d"
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

# Per-dino texture guidance -- colours + personality so Meshy paints each one
# on-brand (chibi, storybook, matching the hero art). Tweak freely.
PROMPTS = {
    "ralph":  "cute chubby green cartoon baby T-rex, soft cream belly, big friendly eyes, smooth storybook shading",
    "raptor": "cute crimson-red cartoon baby raptor with a bright red feather tuft, cream belly, big eyes, smooth storybook shading",
    "trike":  "cute mustard-yellow cartoon baby triceratops with a sage-green frill and three soft horns, cream belly, smooth storybook shading",
    "pterry": "cute teal cartoon baby pterosaur with wide friendly wings and a small crest, cream belly, smooth storybook shading",
    "bronto": "cute blue-green cartoon baby brontosaurus with a long gentle neck, cream belly, big eyes, smooth storybook shading",
    "anky":   "cute slate-grey cartoon baby ankylosaurus with a round armored back and a club tail, warm cream underside, smooth storybook shading",
}
ROSTER = list(PROMPTS.keys())


def api_key():
    k = os.environ.get("MESHY_API_KEY")
    if not k:
        p = os.path.join(HERE, ".meshy_key")
        if os.path.exists(p):
            k = open(p).read().strip()
    if not k:
        sys.exit("No API key. Set MESHY_API_KEY or write it to scripts/tools/.meshy_key")
    return k


def _req(url, key, method="GET", body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Authorization", "Bearer " + key)
    if data:
        r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r, timeout=120) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        sys.exit("Meshy API %s: %s" % (e.code, e.read().decode()[:400]))


def generate(dino, key):
    hero = os.path.join(ROOT, "assets", "concept", dino, "%s_hero.png" % dino)
    if not os.path.exists(hero):
        print("  ! no hero image at %s -- skipping" % hero); return None
    b64 = base64.b64encode(open(hero, "rb").read()).decode()
    print("[%s] submitting image-to-3D (textured)..." % dino)
    res = _req(API, key, "POST", {
        "image_url": "data:image/png;base64," + b64,
        "should_texture": True,
        "texture_prompt": PROMPTS.get(dino, "cute cartoon baby dinosaur, smooth storybook shading"),
        "target_formats": ["glb"],
        "ai_model": "latest",
    })
    task = res.get("result")
    print("  task %s -- polling..." % task)
    while True:
        time.sleep(8)
        st = _req(API + "/" + task, key)
        status, prog = st.get("status"), st.get("progress", 0)
        print("  %s %d%%" % (status, prog))
        if status == "SUCCEEDED":
            glb = st.get("model_urls", {}).get("glb")
            if not glb:
                print("  ! no glb in result"); return None
            out = os.path.join(ROOT, "assets", "concept", dino, "%s_model.glb" % dino)
            urllib.request.urlretrieve(glb, out)
            print("  -> %s (%.1f MB)" % (out, os.path.getsize(out) / 1e6))
            return out
        if status in ("FAILED", "CANCELED"):
            print("  ! task %s: %s" % (status, st.get("task_error"))); return None


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    force = "--force" in sys.argv
    key = api_key()
    dinos = ROSTER if (not args or args == ["all"]) else args
    done = []
    for d in dinos:
        out = os.path.join(ROOT, "assets", "concept", d, "%s_model.glb" % d)
        # A textured model is >10MB; the untextured base mesh is ~8MB. Only skip
        # when we already have a textured one (unless --force).
        if not force and os.path.exists(out) and os.path.getsize(out) > 10e6:
            print("[%s] already have a textured model -- skipping (use --force)" % d)
            done.append(d); continue
        if generate(d, key):
            done.append(d)
    print("\nDONE: %s" % (", ".join(done) if done else "nothing generated"))
