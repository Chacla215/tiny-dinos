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
from mathutils import Vector, Matrix

# ---------- args (after the '--') ----------
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def argval(flag, default=None):
    return argv[argv.index(flag) + 1] if flag in argv else default
DINO  = argval("--dino", "ralph")
OUT   = argval("--out", "/tmp/dino3d")
MODEL = argval("--model", None)
YAW   = float(argval("--yaw", "270"))   # deg to spin an imported model to face screen-right (3/4)
TARGET_H = 2.1                          # imported model is scaled to this height (units)
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
# Blender 5 defaults to the AgX view transform, which desaturates on output and
# greys the flat stylized colours -- Standard renders them as-authored, matching
# the island's vivid storybook saturation.
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "None"
# Storybook toon outline via Freestyle (clean black contour that reads on the
# painterly islands, same silhouette-first language as the chibi heroes).
# Outline is done with an inverted hull (see add_outline) rather than Freestyle:
# Freestyle scribbles interior silhouette/crease lines all over a dense imported
# mesh, whereas an inverted hull gives one clean outer contour at any poly count.
scene.render.use_freestyle = False

# ---------- palette sampled from assets/concept/islands/restyle/beach.png ----------
# Warm golden key + WARM bounce (sand keeps shadows warm, R-B ~+117) + a cool
# cyan sky rim, so the dino sits in the island's exact light logic.
KEY_COLOR    = (1.00, 0.90, 0.70)   # warm sunlight
BOUNCE_COLOR = (1.00, 0.84, 0.60)   # warm sand bounce into the shadow side
SKY_COLOR    = (0.60, 0.80, 0.98)   # cool sky fill
RIM_COLOR    = (0.62, 0.88, 1.00)   # cool cyan rim (matches sea/sky), pops silhouette
AMBIENT      = (1.00, 0.95, 0.86)   # warm-cream world bounce
CEL_SHADOW   = 0.74                 # shadow band stays bright -- island reads light + saturated, not muddy

# ---------- world (warm ambient bounce) ----------
world = bpy.data.worlds.new("W"); scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes["Background"]
bg.inputs[0].default_value = (*AMBIENT, 1.0)
bg.inputs[1].default_value = 0.55

# ---------- 3-light rig matching the island: warm key + warm bounce + cool sky ----------
def sun(name, color, energy, elev, azim):
    d = bpy.data.lights.new(name, "SUN"); d.energy = energy; d.color = color
    o = bpy.data.objects.new(name, d); scene.collection.objects.link(o)
    o.rotation_euler = (math.radians(elev), 0, math.radians(azim))
    return o
sun("Key",    KEY_COLOR,    3.0, 52, 35)     # warm sun, upper front
sun("Bounce", BOUNCE_COLOR, 0.9, 118, 20)    # warm sand bounce from below -> warm shadows
sun("Sky",    SKY_COLOR,    0.8, 8, -110)    # cool sky fill from the side

# ---------- camera: right-facing, slight 3/4, orthographic ----------
cam_d = bpy.data.cameras.new("Cam"); cam_d.type = "ORTHO"; cam_d.ortho_scale = 3.4
cam = bpy.data.objects.new("Cam", cam_d); scene.collection.objects.link(cam)
scene.camera = cam
cam.location = (0.35, -6.0, 1.25)
_look = (Vector((0.1, 0.0, 1.05)) - cam.location)
cam.rotation_euler = _look.to_track_quat("-Z", "Y").to_euler()

# ---------- toon material ----------
# Cel look: the scene lights drive a Diffuse BSDF, Shader-to-RGB reads that
# lit value, a stepped ColorRamp crushes it into a soft 2-band shadow/light
# mask, that mask multiplies the base colour, and a Fresnel rim adds a cool sky
# edge -- so the dino reads hand-painted-flat like the island, not photographic.
# `base` is an RGB tuple (placeholder) or a texture node's Color output socket
# (imported model), so the SAME look applies to Meshy's textured Ralph.
def _toon_nodes(m, base_socket_or_rgb):
    m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    out  = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    diff = nt.nodes.new("ShaderNodeBsdfDiffuse")
    s2r  = nt.nodes.new("ShaderNodeShaderToRGB")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    mul  = nt.nodes.new("ShaderNodeMixRGB");  mul.blend_type = "MULTIPLY"; mul.inputs[0].default_value = 1.0
    fres = nt.nodes.new("ShaderNodeFresnel"); fres.inputs["IOR"].default_value = 1.35
    frmp = nt.nodes.new("ShaderNodeValToRGB")
    rim  = nt.nodes.new("ShaderNodeMixRGB");  rim.blend_type = "ADD"
    # cel ramp: soft 2-band (shadow -> light)
    cr = ramp.color_ramp
    cr.elements[0].position = 0.22; cr.elements[0].color = (CEL_SHADOW, CEL_SHADOW, CEL_SHADOW, 1)
    cr.elements[1].position = 0.44; cr.elements[1].color = (1, 1, 1, 1)
    # rim mask: only the grazing edge
    fr = frmp.color_ramp
    fr.elements[0].position = 0.55; fr.elements[0].color = (0, 0, 0, 1)
    fr.elements[1].position = 0.92; fr.elements[1].color = (*RIM_COLOR, 1)
    # base colour source
    if isinstance(base_socket_or_rgb, tuple):
        base = nt.nodes.new("ShaderNodeRGB"); base.outputs[0].default_value = (*base_socket_or_rgb, 1)
        base_out = base.outputs[0]
    else:
        base_out = base_socket_or_rgb
    nt.links.new(diff.outputs["BSDF"], s2r.inputs["Shader"])
    nt.links.new(s2r.outputs["Color"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], mul.inputs[1])
    nt.links.new(base_out, mul.inputs[2])
    nt.links.new(fres.outputs["Fac"], frmp.inputs["Fac"])
    nt.links.new(mul.outputs["Color"], rim.inputs[1])
    nt.links.new(frmp.outputs["Color"], rim.inputs[2])
    nt.links.new(rim.outputs["Color"], emit.inputs["Color"])
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])

def mat(name, rgb):
    m = bpy.data.materials.new(name); _toon_nodes(m, rgb); return m

# Re-skin an imported (Meshy) model's materials with the toon look, reusing each
# material's own base-colour texture so Ralph keeps his markings. Called after
# import when --model is given.
def toonify_imported():
    for m in bpy.data.materials:
        if not m.use_nodes or m.name in PLACEHOLDER_MATS:
            continue  # never touch our own already-toon placeholder materials
        # grab the base-colour texture (if any) BEFORE _toon_nodes clears the graph
        tex = next((n for n in m.node_tree.nodes if n.type == "TEX_IMAGE"), None)
        img = tex.image if tex else None
        print("MAT %-24s tex=%s img=%s" % (m.name, bool(tex), img.name if img else None))
        _toon_nodes(m, (0.72, 0.72, 0.72))   # flat grey base if the material is untextured
        if img is not None:
            nt = m.node_tree
            mul = next(n for n in nt.nodes if n.type == "MIX_RGB" and n.blend_type == "MULTIPLY")
            newtex = nt.nodes.new("ShaderNodeTexImage"); newtex.image = img
            nt.links.new(newtex.outputs["Color"], mul.inputs[2])

GREEN = mat("green", (0.42, 0.72, 0.34))   # fresh saturated grass green (matches island foliage)
LEAF  = mat("leaf",  (0.34, 0.61, 0.29))
CREAM = mat("cream", (0.97, 0.90, 0.70))
WHITE = mat("white", (0.98, 0.98, 0.98))
BLACK = mat("black", (0.05, 0.05, 0.06))
# Our own toon materials -- toonify_imported() must skip these so it only reskins
# the model's imported materials (never our placeholder green/etc).
PLACEHOLDER_MATS = {"green", "leaf", "cream", "white", "black"}

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
FIT_SCALE = Vector((1, 1, 1))   # imported model's fit transform, so per-frame
FIT_LOC = Vector((0, 0, 0))     # squash/lean stacks ON TOP of the fit (set below)

if MODEL and os.path.exists(MODEL):
    # Real path: import the rigged model, parent it under root. (Bone-driven
    # poses would replace the primitive posing below -- wired when a model lands.)
    ext = os.path.splitext(MODEL)[1].lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=MODEL)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=MODEL)
    # Bake the facing rotation into the MESH DATA (glTF sets rotation_mode=
    # QUATERNION, so object-level rotation_euler silently no-ops) and recalculate
    # normals (Meshy meshes import inverted, which renders the toon shader black).
    Rz = Matrix.Rotation(math.radians(YAW), 4, "Z")
    for o in [o for o in bpy.data.objects if o.type == "MESH"]:
        o.data.transform(Rz)
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.object.mode_set(mode="OBJECT")
        bpy.ops.object.shade_smooth()
    for o in list(bpy.context.selected_objects):
        if o.parent is None:
            parent_keep(o, root)
    # Auto-fit: scale to TARGET_H, centre in X, drop the feet to the ground so
    # the fixed game camera frames the dino.
    def _wbbox():
        mn = [1e9, 1e9, 1e9]; mx = [-1e9, -1e9, -1e9]
        for o in bpy.data.objects:
            if o.type != "MESH":
                continue
            for c in o.bound_box:
                w = o.matrix_world @ Vector(c)
                for i in range(3):
                    mn[i] = min(mn[i], w[i]); mx[i] = max(mx[i], w[i])
        return Vector(mn), Vector(mx)
    bpy.context.view_layer.update()
    mn, mx = _wbbox(); h = mx.z - mn.z
    if h > 0:
        s = TARGET_H / h
        root.scale = (s, s, s)
        bpy.context.view_layer.update()
        mn, mx = _wbbox()
        root.location.x += 0.10 - (mn.x + mx.x) / 2
        root.location.z += 0.05 - mn.z
        bpy.context.view_layer.update()
    FIT_SCALE = root.scale.copy(); FIT_LOC = root.location.copy()
    # Meshy's untextured base mesh has no materials at all -- drop a flat toon
    # green on so the SHAPE reads in-palette until the textured export lands.
    for o in bpy.data.objects:
        if o.type == "MESH" and len(o.data.materials) == 0:
            o.data.materials.append(GREEN)
    toonify_imported()  # re-skin Meshy's textured materials with the island toon look
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

# ---------- clean toon outline: inverted hull ----------
# A slightly-inflated dark shell with flipped normals + backface culling shows
# only as a crisp outer contour behind the real mesh -- density-independent, so
# no interior scribble on the dense Meshy geometry.
_outline = bpy.data.materials.new("outline"); _outline.use_nodes = True
_ont = _outline.node_tree; _ont.nodes.clear()
_oo = _ont.nodes.new("ShaderNodeOutputMaterial"); _oe = _ont.nodes.new("ShaderNodeEmission")
_oe.inputs[0].default_value = (0.13, 0.10, 0.08, 1)
_ont.links.new(_oe.outputs[0], _oo.inputs["Surface"])
_outline.use_backface_culling = True
for _ob in [x for x in bpy.data.objects if x.type == "MESH"]:
    if "outline" not in [m.name for m in _ob.data.materials if m]:
        _ob.data.materials.append(_outline)
    _idx = list(_ob.data.materials).index(_outline)
    _sol = _ob.modifiers.new("outline", "SOLIDIFY")
    _sol.thickness = 0.05; _sol.offset = 1.0
    _sol.use_flip_normals = True
    _sol.material_offset = _idx
    _sol.use_rim = False

# ---------- the 9 game frames (idle x2, walk x4, attack x3) ----------
# PLACEHOLDER poses articulate the primitive joints (deg about Y, body_z bob).
PLACEHOLDER_FRAMES = [
    dict(body_z=0.00, neck=3,  tail=0),
    dict(body_z=0.05, neck=6,  tail=8),
    dict(body_z=0.03, fleg=26, bleg=-22, neck=4, tail=9),
    dict(body_z=0.00, fleg=0,  bleg=0,   neck=2, tail=0),
    dict(body_z=0.03, fleg=-22, bleg=26, neck=4, tail=-9),
    dict(body_z=0.00, fleg=0,  bleg=0,   neck=2, tail=0),
    dict(rooty=-14, neck=16, jaw=0,  tail=-12),
    dict(rootx=0.20, rooty=18, neck=-14, jaw=40, tail=22, fleg=-16, bleg=22),
    dict(rootx=0.07, rooty=6,  neck=-4, jaw=14, tail=8),
]
# IMPORTED models are one solid mesh, so they're animated with whole-body
# SQUASH-AND-STRETCH + bob + lean/lunge (the chibi-mobile way to read as alive
# without a skeleton). sy/sx = vertical/horizontal scale (volume-preserving:
# tall+thin or short+wide), bob = rise, lean = pitch deg, lunge = forward slide.
IMPORT_FRAMES = [
    # idle: a soft breath
    dict(sy=1.00, sx=1.00),
    dict(sy=1.035, sx=0.985, bob=0.04, lean=2),
    # walk: bouncy squash on contact, stretch through the passing pose, tiny sway
    dict(sy=0.93, sx=1.06, bob=0.00, lean=-5),
    dict(sy=1.06, sx=0.96, bob=0.11, lean=0),
    dict(sy=0.93, sx=1.06, bob=0.00, lean=5),
    dict(sy=1.06, sx=0.96, bob=0.11, lean=0),
    # attack: anticipation crouch-back -> stretched lunge -> settle
    dict(sy=0.88, sx=1.10, lean=-15, bob=-0.03),
    dict(sy=1.10, sx=0.93, lean=22, lunge=0.28, bob=0.05),
    dict(sy=1.00, sx=1.00, lean=7,  lunge=0.09),
]
FRAMES = PLACEHOLDER_FRAMES if HAS_JOINTS else IMPORT_FRAMES

def apply(p):
    if HAS_JOINTS:
        root.location = Vector((p.get("rootx", 0.0), 0.0, 0.0))
        root.rotation_euler = (0.0, math.radians(p.get("rooty", 0.0)), 0.0)
        torso.location = Vector((0.0, 0.0, p.get("body_z", 0.0)))
        neck.rotation_euler = (0.0, math.radians(p.get("neck", 0.0)), 0.0)
        jaw.rotation_euler  = (0.0, math.radians(p.get("jaw", 0.0)), 0.0)
        fleg.rotation_euler = (0.0, math.radians(p.get("fleg", 0.0)), 0.0)
        bleg.rotation_euler = (0.0, math.radians(p.get("bleg", 0.0)), 0.0)
        tail.rotation_euler = (0.0, math.radians(p.get("tail", 0.0)), 0.0)
    else:
        sx, sy = p.get("sx", 1.0), p.get("sy", 1.0)
        root.scale = (FIT_SCALE.x * sx, FIT_SCALE.y * sy, FIT_SCALE.z * sx)
        root.location = Vector((FIT_LOC.x + p.get("lunge", 0.0), FIT_LOC.y,
                                FIT_LOC.z + p.get("bob", 0.0)))
        root.rotation_euler = (0.0, math.radians(p.get("lean", 0.0)), 0.0)

# ---------- render each frame ----------
for i, p in enumerate(FRAMES):
    apply(p)
    bpy.context.view_layer.update()
    scene.render.filepath = os.path.join(OUT, "frame_%02d.png" % i)
    bpy.ops.render.render(write_still=True)

print("RENDERED %d frames -> %s" % (len(FRAMES), OUT))
