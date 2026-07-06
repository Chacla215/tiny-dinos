"""
Blender -> 2D fighter-sprite renderer (the 3D-to-sprites pipeline).

Run headless:
    /opt/homebrew/bin/blender --background --python scripts/tools/blender_render_dino.py -- \
        --dino ralph --out /tmp/dino3d [--model path/to/model.glb]

Builds (or imports) a chibi dino, poses it into the exact 9 frames the game's
ANIM_LAYOUTS expects -- idle x2, walk x4, attack x3 -- and renders each to a
transparent PNG with a Freestyle toon outline, side-on / slight-3-4 to match the
right-facing fighter sheets. Then `pack_dino_sheet.py` (system Python + PIL)
crops + height-normalises + packs them into <dino>_fighter.png and prints the
ANIM_LAYOUTS block.

--model (a rigged .glb/.gltf from image->3D + Blender cleanup) is the real path;
without it we build a PLACEHOLDER primitive chibi so the whole pipeline can be
proven end-to-end before any real model exists. The placeholder is driven by the
SAME pose table a real model's bones would be, so swapping the model in is the
only change.
"""
import bpy, sys, math, os
from mathutils import Vector

# ---------- args (after the '--') ----------
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def argval(flag, default=None):
    return argv[argv.index(flag) + 1] if flag in argv else default
DINO  = argval("--dino", "ralph")
OUT   = argval("--out", "/tmp/dino3d")
MODEL = argval("--model", None)
os.makedirs(OUT, exist_ok=True)

# ---------- clean scene ----------
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---------- render / engine ----------
scene.render.engine = "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = 640
scene.render.resolution_y = 640
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
# Storybook toon outline via Freestyle (clean black contour that reads on the
# painterly islands, same silhouette-first language as the chibi heroes).
scene.render.use_freestyle = True
scene.render.line_thickness_mode = "ABSOLUTE"
scene.render.line_thickness = 2.6
vl = scene.view_layers[0]
vl.use_freestyle = True
# A fresh (factory-empty) view layer has no lineset/linestyle, which crashes the
# Freestyle pass -- create them explicitly so the toon contour actually draws.
fs = vl.freestyle_settings
if not fs.linesets:
    fs.linesets.new("ls")
_ls = fs.linesets[0]
if _ls.linestyle is None:
    _ls.linestyle = bpy.data.linestyles.new("LineStyle")
_ls.linestyle.color = (0.10, 0.11, 0.12)
_ls.linestyle.thickness = 2.6

# ---------- world (soft ambient fill) ----------
world = bpy.data.worlds.new("W"); scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes["Background"]
bg.inputs[0].default_value = (1.0, 0.98, 0.95, 1.0)
bg.inputs[1].default_value = 0.95   # flatter, storybook fill (less gradient)

# ---------- key + fill light ----------
sun_d = bpy.data.lights.new("Sun", "SUN"); sun_d.energy = 2.3
sun = bpy.data.objects.new("Sun", sun_d); scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(52), 0, math.radians(35))
fill_d = bpy.data.lights.new("Fill", "SUN"); fill_d.energy = 1.1
fill = bpy.data.objects.new("Fill", fill_d); scene.collection.objects.link(fill)
fill.rotation_euler = (math.radians(70), 0, math.radians(-120))

# ---------- camera: right-facing, slight 3/4, orthographic ----------
cam_d = bpy.data.cameras.new("Cam"); cam_d.type = "ORTHO"; cam_d.ortho_scale = 3.4
cam = bpy.data.objects.new("Cam", cam_d); scene.collection.objects.link(cam)
scene.camera = cam
cam.location = (0.35, -6.0, 1.25)
_look = (Vector((0.1, 0.0, 1.05)) - cam.location)
cam.rotation_euler = _look.to_track_quat("-Z", "Y").to_euler()

# ---------- helpers ----------
def mat(name, rgb, rough=0.85):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = rough
    return m

GREEN = mat("green", (0.34, 0.60, 0.30))
LEAF  = mat("leaf",  (0.28, 0.52, 0.26))
CREAM = mat("cream", (0.92, 0.87, 0.68))
WHITE = mat("white", (0.98, 0.98, 0.98))
BLACK = mat("black", (0.03, 0.03, 0.03), rough=0.4)

def empty(name, loc, parent=None):
    e = bpy.data.objects.new(name, None); e.empty_display_size = 0.1
    e.location = Vector(loc); scene.collection.objects.link(e)
    if parent: parent_keep(e, parent)
    return e

def parent_keep(child, parent):
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()

def sphere(name, loc, scale, m, parent):
    bpy.ops.mesh.primitive_uv_sphere_add(location=loc, segments=28, ring_count=14)
    o = bpy.context.active_object; o.name = name; o.scale = Vector(scale)
    o.data.materials.append(m); bpy.ops.object.shade_smooth()
    parent_keep(o, parent)
    return o

def cone(name, loc, scale, rot, m, parent):
    bpy.ops.mesh.primitive_cone_add(location=loc, vertices=20, radius1=1.0, depth=2.0)
    o = bpy.context.active_object; o.name = name
    o.scale = Vector(scale); o.rotation_euler = rot
    o.data.materials.append(m); bpy.ops.object.shade_smooth()
    parent_keep(o, parent)
    return o

# ---------- build placeholder chibi (or import real model) ----------
root = empty("root", (0, 0, 0))

if MODEL and os.path.exists(MODEL):
    # Real path: import the rigged model, parent it under root. (Bone-driven
    # poses would replace the primitive posing below -- wired when a model lands.)
    ext = os.path.splitext(MODEL)[1].lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=MODEL)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=MODEL)
    for o in bpy.context.selected_objects:
        if o.parent is None:
            parent_keep(o, root)
    torso = neck = jaw = fleg = bleg = tail = root  # no primitive joints to pose
    HAS_JOINTS = False
else:
    torso = empty("torso", (0, 0, 0), root)
    # body + cream belly
    sphere("body",  (0.00, 0.00, 0.92), (0.50, 0.40, 0.58), GREEN, torso)
    sphere("belly", (0.16, -0.20, 0.80), (0.34, 0.30, 0.42), CREAM, torso)
    # neck joint -> head, snout, eye, jaw
    neck = empty("neck", (0.18, 0.0, 1.24), torso)
    sphere("head",  (0.40, 0.00, 1.60), (0.52, 0.44, 0.50), GREEN, neck)
    sphere("snout", (0.82, 0.00, 1.50), (0.26, 0.24, 0.20), GREEN, neck)
    sphere("eyeL",  (0.60, -0.30, 1.72), (0.13, 0.13, 0.13), WHITE, neck)
    sphere("pupL",  (0.67, -0.37, 1.73), (0.06, 0.06, 0.07), BLACK, neck)
    sphere("browL", (0.58, -0.30, 1.85), (0.15, 0.05, 0.06), LEAF,  neck)
    jaw = empty("jaw", (0.60, 0.0, 1.42), neck)
    sphere("jaw",   (0.84, 0.00, 1.34), (0.24, 0.22, 0.09), GREEN, jaw)
    # tiny chibi arm
    sphere("arm",   (0.46, -0.26, 1.06), (0.11, 0.09, 0.15), LEAF, torso)
    # tail (cone pointing -X)
    tailj = empty("tailj", (-0.36, 0.0, 0.94), torso)
    cone("tail", (-0.82, 0.0, 0.98), (0.20, 0.20, 0.55),
         (0, math.radians(-90), 0), GREEN, tailj)
    tail = tailj
    # legs (near = -Y, far = +Y)
    fleg = empty("fleg", (0.18, -0.16, 0.56), root)
    sphere("fthigh", (0.18, -0.16, 0.34), (0.15, 0.15, 0.26), GREEN, fleg)
    sphere("ffoot",  (0.26, -0.16, 0.12), (0.17, 0.13, 0.09), LEAF,  fleg)
    bleg = empty("bleg", (-0.02, 0.16, 0.56), root)
    sphere("bthigh", (-0.02, 0.16, 0.34), (0.15, 0.15, 0.26), LEAF,  bleg)
    sphere("bfoot",  (0.06, 0.16, 0.12), (0.17, 0.13, 0.09), LEAF,  bleg)
    HAS_JOINTS = True

# ---------- the 9 game frames (idle x2, walk x4, attack x3) ----------
# deg values are joint rotations about Y (side-view pitch); body_z = upper-body
# bob; rootx/rooty = whole-body lunge/lean for the attack.
FRAMES = [
    # idle
    dict(body_z=0.00, neck=3,  tail=0),
    dict(body_z=0.05, neck=6,  tail=8),
    # walk (leg scissor + bob + counter tail)
    dict(body_z=0.03, fleg=26, bleg=-22, neck=4, tail=9),
    dict(body_z=0.00, fleg=0,  bleg=0,   neck=2, tail=0),
    dict(body_z=0.03, fleg=-22, bleg=26, neck=4, tail=-9),
    dict(body_z=0.00, fleg=0,  bleg=0,   neck=2, tail=0),
    # attack (windup lean-back -> lunge + mouth open -> recover)
    dict(rooty=-14, neck=16, jaw=0,  tail=-12),
    dict(rootx=0.20, rooty=18, neck=-14, jaw=40, tail=22, fleg=-16, bleg=22),
    dict(rootx=0.07, rooty=6,  neck=-4, jaw=14, tail=8),
]

def apply(p):
    root.location = Vector((p.get("rootx", 0.0), 0.0, 0.0))
    root.rotation_euler = (0.0, math.radians(p.get("rooty", 0.0)), 0.0)
    if not HAS_JOINTS:
        return
    torso.location = Vector((0.0, 0.0, p.get("body_z", 0.0)))
    neck.rotation_euler = (0.0, math.radians(p.get("neck", 0.0)), 0.0)
    jaw.rotation_euler  = (0.0, math.radians(p.get("jaw", 0.0)), 0.0)
    fleg.rotation_euler = (0.0, math.radians(p.get("fleg", 0.0)), 0.0)
    bleg.rotation_euler = (0.0, math.radians(p.get("bleg", 0.0)), 0.0)
    tail.rotation_euler = (0.0, math.radians(p.get("tail", 0.0)), 0.0)

# ---------- render each frame ----------
for i, p in enumerate(FRAMES):
    apply(p)
    bpy.context.view_layer.update()
    scene.render.filepath = os.path.join(OUT, "frame_%02d.png" % i)
    bpy.ops.render.render(write_still=True)

print("RENDERED %d frames -> %s" % (len(FRAMES), OUT))
