"""
Bake a Meshy weapon model into a held sprite (blade toward +X), toon-shaded to
match the dinos.

    blender --background --python scripts/tools/blender_render_weapon.py -- \
        --weapon sword --out /tmp/wpn/sword.png

Imports the .glb, aligns its LONGEST axis to +X (per-weapon roll/flip overrides
below), toon-shades with an inverted-hull outline, and renders ONE transparent
side-on frame, autocropped, ~256px long. Replaces assets/sprites/weapons/<w>.png.
"""
import bpy, sys, os, math
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def arg(f, d=None): return argv[argv.index(f) + 1] if f in argv else d
WPN = arg("--weapon", "sword")
MODEL = arg("--model", "assets/concept/weapons/%s_model.glb" % WPN)
OUT = arg("--out", "/tmp/wpn/%s.png" % WPN)
ROT = arg("--rot", None)   # "rx,ry,rz" deg -> explicit orient, replaces auto-align
os.makedirs(os.path.dirname(OUT), exist_ok=True)

# Per-weapon orientation tweaks after longest-axis->X (degrees, applied about X
# then Z), and whether to flip end-for-end. Tuned by eye.
ROLL = {}                     # after auto-align, extra roll about the long (X) axis
FLIP = {"dagger", "axe"}      # flip end-for-end so the business end points +X

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE"
sc.render.film_transparent = True
sc.render.resolution_x = sc.render.resolution_y = 512
sc.render.image_settings.file_format = "PNG"; sc.render.image_settings.color_mode = "RGBA"
sc.view_settings.view_transform = "Standard"; sc.view_settings.look = "None"

world = bpy.data.worlds.new("w"); sc.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (1, 0.97, 0.92, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.6
def sun(c, e, el, az):
    d = bpy.data.lights.new("s", "SUN"); d.energy = e; d.color = c
    o = bpy.data.objects.new("s", d); sc.collection.objects.link(o)
    o.rotation_euler = (math.radians(el), 0, math.radians(az))
sun((1, 0.9, 0.7), 3.0, 55, 35); sun((0.6, 0.8, 1.0), 1.0, 20, -120)

cam_d = bpy.data.cameras.new("c"); cam_d.type = "ORTHO"; cam_d.ortho_scale = 2.6
cam = bpy.data.objects.new("c", cam_d); sc.collection.objects.link(cam); sc.camera = cam
cam.location = (0, -6, 0); cam.rotation_euler = (Vector((0, 0, 0)) - cam.location).to_track_quat("-Z", "Y").to_euler()

# toon material (Shader-to-RGB cel + texture) -- same idea as the dino bake
def toon(m):
    tex = next((n for n in m.node_tree.nodes if n.type == "TEX_IMAGE"), None)
    img = tex.image if tex else None
    nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial"); emit = nt.nodes.new("ShaderNodeEmission")
    diff = nt.nodes.new("ShaderNodeBsdfDiffuse"); s2r = nt.nodes.new("ShaderNodeShaderToRGB")
    ramp = nt.nodes.new("ShaderNodeValToRGB"); mul = nt.nodes.new("ShaderNodeMixRGB")
    mul.blend_type = "MULTIPLY"; mul.inputs[0].default_value = 1.0
    cr = ramp.color_ramp; cr.elements[0].position = 0.25; cr.elements[0].color = (0.7, 0.7, 0.7, 1)
    cr.elements[1].position = 0.5; cr.elements[1].color = (1, 1, 1, 1)
    nt.links.new(diff.outputs["BSDF"], s2r.inputs["Shader"])
    nt.links.new(s2r.outputs["Color"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], mul.inputs[1])
    if img:
        t = nt.nodes.new("ShaderNodeTexImage"); t.image = img
        nt.links.new(t.outputs["Color"], mul.inputs[2])
    else:
        mul.inputs[2].default_value = (0.6, 0.6, 0.62, 1)
    nt.links.new(mul.outputs["Color"], emit.inputs["Color"])
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])

bpy.ops.import_scene.gltf(filepath=MODEL)
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
# join into one for simple handling
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
mesh = bpy.context.view_layer.objects.active
for m in mesh.data.materials:
    if m and m.use_nodes:
        toon(m)
if not mesh.data.materials:
    mm = bpy.data.materials.new("w"); mm.use_nodes = True; toon(mm); mesh.data.materials.append(mm)

# --- align longest bbox axis to X ---
bpy.context.view_layer.update()
bb = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
mn = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
mx = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
dims = mx - mn
if ROT:
    rx, ry, rz = [float(v) for v in ROT.split(",")]
    mesh.data.transform(Matrix.Rotation(math.radians(rx), 4, "X"))
    mesh.data.transform(Matrix.Rotation(math.radians(ry), 4, "Y"))
    mesh.data.transform(Matrix.Rotation(math.radians(rz), 4, "Z"))
else:
    longest = max(range(3), key=lambda i: dims[i])
    if longest == 2:      # long axis is Z -> rotate to X
        mesh.data.transform(Matrix.Rotation(math.radians(90), 4, "Y"))
    elif longest == 1:    # long axis is Y -> rotate to X
        mesh.data.transform(Matrix.Rotation(math.radians(90), 4, "Z"))
    roll = float(arg("--roll", ROLL.get(WPN, 0.0)))
    if roll:
        mesh.data.transform(Matrix.Rotation(math.radians(roll), 4, "X"))
    flip = arg("--flip", None) is not None or WPN in FLIP
    if flip:
        mesh.data.transform(Matrix.Rotation(math.radians(180), 4, "Z"))
# recenter + normalize length, recalc normals
bpy.context.view_layer.objects.active = mesh; mesh.select_set(True)
bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.normals_make_consistent(inside=False); bpy.ops.object.mode_set(mode="OBJECT")
bpy.ops.object.shade_smooth()
bpy.context.view_layer.update()
bb = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
mn = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
mx = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
ctr = (mn + mx) * 0.5; length = (mx.x - mn.x) or 1.0
mesh.location -= ctr
mesh.scale = (2.0 / length,) * 3

# inverted-hull outline
ol = bpy.data.materials.new("outline"); ol.use_nodes = True
nt = ol.node_tree; nt.nodes.clear()
o1 = nt.nodes.new("ShaderNodeOutputMaterial"); e1 = nt.nodes.new("ShaderNodeEmission")
e1.inputs[0].default_value = (0.12, 0.10, 0.08, 1); nt.links.new(e1.outputs[0], o1.inputs["Surface"])
ol.use_backface_culling = True
mesh.data.materials.append(ol)
sol = mesh.modifiers.new("outline", "SOLIDIFY"); sol.thickness = 0.04; sol.offset = 1.0
sol.use_flip_normals = True; sol.material_offset = len(mesh.data.materials) - 1; sol.use_rim = False

bpy.context.view_layer.update()
sc.render.filepath = OUT
bpy.ops.render.render(write_still=True)
print("WEAPON RENDERED -> %s" % OUT)
