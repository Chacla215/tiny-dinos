extends Node2D
class_name DinoRig

## Runtime limb skeleton for the in-match fighters.
##
## Replaces the single baked AnimatedSprite2D with body + 4 limb sprites
## (back_leg / tail / front_leg / head) reassembled from the parts the bake tool
## exports (`gen_ralph_fighter.py <dino> --parts` -> assets/sprites/parts/<dino>/).
## The motion is driven LIVE here — idle breathing/sway, walk leg-scissor + bounce,
## attack lunge, and a spring-based HIT FLAIL where each limb gets an angular
## impulse and overshoots back to rest. So arms/legs/tail/head move on their own,
## not just on pre-rendered frames.
##
## Built entirely in code by dino.gd (`build_for`), so it needs no .tscn edits and
## works across every arena. Coordinates come from rig.json in "core space"
## relative to the core centre, matching where the centered sprite used to sit.

# Baseline feel — every value here is overridable per-dino in PROFILES below.
# Each dino's body plan reads differently: bipeds stride, quadrupeds barely swing
# their legs, pterry's "legs" are WINGS that flap, bronto's "head" is a long neck.
const DEFAULT := {
	"stiffness": 150.0,      # spring pull back to rest; higher = snappier
	"damping": 9.0,          # velocity bleed; higher = settles faster, less wobble
	"max_angle": 42.0,       # clamp so a big hit can't spin a limb all the way round
	"gait": "biped",         # biped | quad | wing
	# idle
	"idle_hz": 0.42,
	"idle_tail": 5.0,
	"idle_head": 2.5,
	"idle_wing": 0.0,        # wing flap amplitude at rest (pterry)
	# walk
	"phase_per_px": 0.022,   # step phase per px travelled -> faster = quicker steps
	"leg_swing": 13.0,
	"walk_tail": 7.0,
	"walk_head": 3.0,
	"bounce": 3.2,
	# attack lunge
	"atk_head": -34.0,
	"atk_leg": -22.0,
	"atk_tail": 14.0,
	# hit flail impulses (deg/s, scaled by power)
	"hit_head": 210.0,
	"hit_tail": 210.0,
	"hit_leg": 170.0,
	"body_recoil": 24.0,     # px the torso is knocked along the blow
	"body_squash": 0.16,
	# Gang-Beasts-flavoured WHOLE-BODY wobble (pivots around the feet). Pure look
	# — the CharacterBody2D control stays exact; only the sprite teeters/leans.
	"lean_stiff": 60.0,      # spring pulling the body back upright
	"lean_damp": 5.5,        # low-ish -> a hit makes it wobble a few times (drunk recover)
	"lean_per_speed": 0.020, # degrees of lean per px/s of run (momentum into motion)
	"lean_max": 13.0,        # cap so it leans, never face-plants
	"idle_teeter": 1.4,      # tiny standing sway so it's never frozen
	"teeter_hz": 0.5,
	"hit_stumble": 95.0,     # angular kick (deg/s) the body takes when struck
}

# Per-dino overrides. Only the keys that differ from DEFAULT are listed.
const PROFILES := {
	# Heavyweight king — calm, weighty, deliberate.
	"ralph": {"damping": 10.0, "idle_hz": 0.36, "leg_swing": 12.0, "bounce": 2.8,
		"hit_head": 200.0, "hit_tail": 200.0, "hit_leg": 160.0,
		"lean_per_speed": 0.018, "hit_stumble": 85.0},
	# Glass cannon — light, twitchy, long balancing tail, quick steps. Wobbliest.
	"raptor": {"stiffness": 132.0, "damping": 7.0, "idle_hz": 0.72, "idle_tail": 8.0,
		"idle_head": 3.5, "phase_per_px": 0.030, "leg_swing": 19.0, "walk_tail": 13.0,
		"walk_head": 4.5, "bounce": 4.2, "hit_head": 285.0, "hit_tail": 320.0,
		"hit_leg": 250.0, "body_recoil": 30.0, "body_squash": 0.20, "max_angle": 48.0,
		"lean_damp": 4.5, "lean_per_speed": 0.026, "lean_max": 16.0, "idle_teeter": 2.0,
		"hit_stumble": 130.0},
	# Armored charger — stiff, slow, heavy head, legs barely move.
	"trike": {"stiffness": 172.0, "damping": 12.0, "gait": "quad", "idle_hz": 0.30,
		"idle_head": 3.0, "phase_per_px": 0.016, "leg_swing": 8.0, "walk_tail": 5.0,
		"walk_head": 3.0, "bounce": 2.0, "hit_head": 150.0, "hit_tail": 175.0,
		"hit_leg": 110.0, "body_recoil": 18.0, "body_squash": 0.12,
		"lean_stiff": 85.0, "lean_damp": 8.0, "lean_per_speed": 0.012, "lean_max": 8.0,
		"idle_teeter": 0.8, "hit_stumble": 55.0},   # planted, hard to stagger
	# Flyer — "legs" are wings (flap), "tail" is the feet (small), big crest head.
	"pterry": {"stiffness": 112.0, "damping": 6.0, "gait": "wing", "max_angle": 56.0,
		"idle_hz": 0.85, "idle_wing": 9.0, "idle_head": 3.0, "idle_tail": 2.0,
		"phase_per_px": 0.028, "leg_swing": 17.0, "walk_tail": 3.0, "walk_head": 4.0,
		"bounce": 3.4, "hit_head": 240.0, "hit_leg": 330.0, "hit_tail": 120.0,
		"body_recoil": 22.0, "body_squash": 0.14,
		"lean_damp": 4.0, "lean_per_speed": 0.024, "lean_max": 17.0, "idle_teeter": 2.2,
		"hit_stumble": 120.0},   # airy, light, gets knocked around
	# Gentle giant — huge, slow, long swaying neck ("head" slot), tiny leg motion.
	"bronto": {"stiffness": 140.0, "damping": 12.0, "gait": "quad", "idle_hz": 0.26,
		"idle_tail": 6.0, "idle_head": 6.5, "phase_per_px": 0.014, "leg_swing": 7.0,
		"walk_tail": 6.0, "walk_head": 7.0, "bounce": 1.8, "hit_head": 175.0,
		"hit_tail": 160.0, "hit_leg": 90.0, "body_recoil": 15.0, "body_squash": 0.10,
		"lean_stiff": 80.0, "lean_damp": 8.5, "lean_per_speed": 0.010, "lean_max": 7.0,
		"idle_teeter": 1.0, "hit_stumble": 50.0},   # immovable
	# Tank — armored, low head, heavy club tail that lags and carries momentum.
	"anky": {"stiffness": 162.0, "damping": 11.0, "gait": "quad", "idle_hz": 0.28,
		"idle_tail": 5.0, "idle_head": 2.5, "phase_per_px": 0.015, "leg_swing": 7.0,
		"walk_tail": 6.0, "walk_head": 2.5, "bounce": 1.8, "hit_head": 130.0,
		"hit_tail": 265.0, "hit_leg": 90.0, "body_recoil": 15.0, "body_squash": 0.10,
		"tail_damping": 7.0,    # club tail under-damped so it swings heavy
		"lean_stiff": 90.0, "lean_damp": 9.0, "lean_per_speed": 0.009, "lean_max": 6.0,
		"idle_teeter": 0.7, "hit_stumble": 45.0},   # the rock — barely budges
}

class Limb:
	var joint: Node2D       # rotates around the pivot
	var sprite: Sprite2D
	var angle := 0.0        # current spring angle (deg), rest = 0
	var vel := 0.0          # angular velocity (deg/s)
	var target := 0.0       # where the spring is pulled toward this frame
	var damping := 9.0      # per-limb so a heavy club can lag the rest

var valid := false
var _cfg := {}             # resolved DEFAULT + profile for this dino
var _limbs := {}           # name -> Limb (back_leg/tail/front_leg/head)
var _body: Sprite2D
var _lean_node := Node2D.new()  # pivots the WHOLE body around the feet (the wobble)
var _flip := Node2D.new()       # scale.x flips the whole rig to face left
var _facing_right := true
var _feet_y := 60.0             # core-space y of the feet, the teeter pivot

var _t := 0.0              # global clock for idle oscillation
var _walk_phase := 0.0
var _walk_speed := 0.0
var _motion_x := 0.0       # signed horizontal velocity, for momentum lean
var _attack_t := -1.0      # >=0 while an attack envelope plays
var _state := "idle"
var _body_recoil := Vector2.ZERO
var _body_squash := 0.0
var _lean := 0.0           # whole-body lean angle (deg), spring
var _lean_vel := 0.0
var _down_t := 0.0         # >0 while toppled (floored); body lies over, limbs limp
var _down_sign := 1.0      # which way it tipped over
var _held := false         # carried by a grab — dangles limp

# ---------------------------------------------------------------------------

func _c(key: String) -> float:
	return _cfg.get(key, DEFAULT[key])

## Build the rig for `role`, returns false if the parts aren't on disk (caller
## then falls back to the old AnimatedSprite2D so nothing breaks).
func build_for(role: String, skin_mat: Material) -> bool:
	var manifest := _load_manifest(role)
	if manifest.is_empty():
		return false
	_cfg = DEFAULT.duplicate()
	for k in PROFILES.get(role, {}):
		_cfg[k] = PROFILES[role][k]
	# Teeter pivot = the feet (bottom of the core), so leaning rocks the body over
	# its feet like a balancing ragdoll instead of spinning around its middle.
	var core_size: Array = manifest.get("core_size", [90, 132])
	_feet_y = float(core_size[1]) * 0.5
	add_child(_lean_node)
	_lean_node.position.y = _feet_y
	_lean_node.add_child(_flip)
	_flip.position.y = -_feet_y
	var order: Array = manifest.get("order", ["body", "back_leg", "tail", "front_leg", "head"])
	var parts: Dictionary = manifest["parts"]
	for name in order:
		if not parts.has(name):
			continue
		var p: Dictionary = parts[name]
		var tex: Texture2D = load(p["tex"])
		if tex == null:
			continue
		var center := Vector2(p["center"][0], p["center"][1])
		if name == "body" or not p.has("pivot"):
			var bs := _make_sprite(tex, skin_mat)
			bs.position = center
			_flip.add_child(bs)
			if name == "body":
				_body = bs
			continue
		var pivot := Vector2(p["pivot"][0], p["pivot"][1])
		var joint := Node2D.new()
		joint.position = pivot
		_flip.add_child(joint)
		var spr := _make_sprite(tex, skin_mat)
		spr.position = center - pivot   # keep art put while the joint rotates it
		joint.add_child(spr)
		var limb := Limb.new()
		limb.joint = joint
		limb.sprite = spr
		limb.damping = _cfg.get("%s_damping" % name, _c("damping"))
		_limbs[name] = limb
	valid = true
	return true

func _make_sprite(tex: Texture2D, skin_mat: Material) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # painterly, matches old look
	if skin_mat != null:
		s.material = skin_mat
	return s

func _load_manifest(role: String) -> Dictionary:
	var path := "res://assets/sprites/parts/%s/rig.json" % role
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary and data.has("parts") else {}

# ---------------------------------------------------------------------------
# Driven by dino.gd each frame.

func set_facing(face_right: bool) -> void:
	_facing_right = face_right
	_flip.scale.x = 1.0 if face_right else -1.0

func set_walk_speed(px_per_s: float) -> void:
	_walk_speed = px_per_s

## Signed horizontal velocity so the body leans INTO a run (momentum) — the
## Gang-Beasts lean. Visual only; dino.gd keeps moving the body precisely.
func set_motion(vel_x: float) -> void:
	_motion_x = vel_x

func play(anim: String) -> void:
	if anim == "attack" and _state != "attack":
		_attack_t = 0.0
	_state = anim

func is_attacking() -> bool:
	return _attack_t >= 0.0

## Kick the springs on a hit. `world_dir` = knockback heading, `power` ~ 0..1+.
func hit(world_dir: Vector2, power: float) -> void:
	power = clampf(power, 0.2, 1.6)
	# Map the blow into the rig's facing frame so the head flies the way it's
	# actually thrown regardless of which way the dino faces.
	var fsign := 1.0 if _facing_right else -1.0
	var push := signf(world_dir.x) * fsign
	if push == 0.0:
		push = 1.0
	if _limbs.has("head"):
		_limbs["head"].vel += _c("hit_head") * power * push
	if _limbs.has("tail"):
		_limbs["tail"].vel -= _c("hit_tail") * power * push   # tail whips opposite the head
	# Legs buckle / wings flap apart.
	if _limbs.has("front_leg"):
		_limbs["front_leg"].vel += _c("hit_leg") * power
	if _limbs.has("back_leg"):
		_limbs["back_leg"].vel -= _c("hit_leg") * power
	# Torso recoil + squash, applied to the body sprite directly.
	_body_recoil = Vector2(_c("body_recoil") * power * signf(world_dir.x), -2.0 * power)
	_body_squash = _c("body_squash") * power
	# Whole-body STUMBLE: kick the lean spring so the dino reels and wobbles back
	# upright (low lean_damp = a few drunk oscillations before it recovers).
	_lean_vel += _c("hit_stumble") * power * signf(world_dir.x)

## FLOPPY stage 3: grabbed and carried — hang limp with a faint dangle sway.
func set_held(held: bool) -> void:
	_held = held

## Snap back to a clean neutral pose — called on respawn / round reset so a dino
## never comes back still toppled, held, or mid-wobble.
func reset_pose() -> void:
	_down_t = 0.0
	_held = false
	_lean = 0.0
	_lean_vel = 0.0
	_body_recoil = Vector2.ZERO
	_body_squash = 0.0
	for l in _limbs.values():
		l.angle = 0.0
		l.vel = 0.0
		l.joint.rotation_degrees = 0.0
	if _lean_node:
		_lean_node.rotation_degrees = 0.0

## FLOPPY stage 2: knocked off the feet — the body tips fully over and the limbs
## go limp/splayed until `secs` of floored time elapse, then it springs upright.
func topple(world_dir: Vector2, power: float, secs: float = 0.85) -> void:
	_down_t = secs
	_down_sign = signf(world_dir.x)
	if _down_sign == 0.0:
		_down_sign = 1.0
	hit(world_dir, clampf(power, 0.6, 1.6) * 1.2)   # extra flail as you go down

func _process(delta: float) -> void:
	if not valid:
		return
	_t += delta
	_resolve_targets(delta)
	_integrate_springs(delta)
	_integrate_lean(delta)
	_apply_body(delta)

# Pick this frame's rest target for each limb from the current state.
func _resolve_targets(delta: float) -> void:
	for l in _limbs.values():
		l.target = 0.0
	var head: Limb = _limbs.get("head")
	var tail: Limb = _limbs.get("tail")
	var fl: Limb = _limbs.get("front_leg")
	var bl: Limb = _limbs.get("back_leg")
	var gait := String(_cfg.get("gait", "biped"))

	# Floored (floppy stage 2): limp, splayed pose — overrides walk/idle/attack so
	# you don't paddle your legs while lying on the ground.
	if _down_t > 0.0:
		if head: head.target = -18.0 * _down_sign   # head lolls toward the fall
		if tail: tail.target = 22.0 * _down_sign
		if fl: fl.target = 30.0                      # legs splay out limp
		if bl: bl.target = -30.0
		return

	# Carried (floppy stage 3): hang limp with a small helpless dangle.
	if _held:
		var d := sin(_t * 6.0) * 4.0
		if head: head.target = -8.0 + d
		if tail: tail.target = 6.0 + d
		if fl: fl.target = 16.0 + d                  # legs dangle loosely
		if bl: bl.target = -16.0 + d
		return

	if _state == "walk":
		_walk_phase += _walk_speed * _c("phase_per_px") * delta
		var s := sin(_walk_phase)
		var swing := _c("leg_swing")
		if gait == "wing":
			# Both wings beat together (opposite signs read as a symmetric flap).
			if fl: fl.target = swing * s
			if bl: bl.target = -swing * s
		else:
			if fl: fl.target = swing * s
			if bl: bl.target = -swing * s
		if tail: tail.target = _c("walk_tail") * s
		if head: head.target = _c("walk_head") * sin(_walk_phase * 2.0)
	else:
		# idle sway/breathe
		var w := _t * TAU * _c("idle_hz")
		if tail: tail.target = _c("idle_tail") * sin(w)
		if head: head.target = _c("idle_head") * sin(w + 0.6)
		# pterry's wings idle with a slow flap so he never looks frozen.
		if gait == "wing":
			var flap := _c("idle_wing") * sin(w)
			if fl: fl.target = flap
			if bl: bl.target = -flap

	# Attack lunge overlays on top: a quick forward throw of head + front limb.
	if _attack_t >= 0.0:
		_attack_t += delta
		var u := _attack_t / 0.26
		if u >= 1.0:
			_attack_t = -1.0
		else:
			var env := sin(u * PI) * (1.0 - u * 0.4)
			if head: head.target += _c("atk_head") * env
			if fl: fl.target += _c("atk_leg") * env
			if tail: tail.target += _c("atk_tail") * env

# Semi-implicit spring toward target with a velocity impulse carryover (the hit).
func _integrate_springs(delta: float) -> void:
	var stiff := _c("stiffness")
	var max_a := _c("max_angle")
	for l in _limbs.values():
		var lm: Limb = l
		lm.vel += (lm.target - lm.angle) * stiff * delta
		lm.vel -= lm.vel * lm.damping * delta
		lm.angle += lm.vel * delta
		lm.angle = clampf(lm.angle, -max_a, max_a)
		lm.joint.rotation_degrees = lm.angle

# Whole-body teeter: a spring that leans into motion + idle-sways, and that a hit
# kicks into a wobbly stumble. Pivots around the feet (_lean_node), so the dino
# rocks like it's balancing instead of spinning. World-space, so it reads the
# same whichever way the dino faces.
func _integrate_lean(delta: float) -> void:
	var stiff := _c("lean_stiff")
	var damp := _c("lean_damp")
	var target: float
	if _down_t > 0.0:
		_down_t -= delta
		# Tipped fully over and lying there — soft spring so it flops down and the
		# last stretch eases up as the timer runs out (it's already scrambling up).
		target = _down_sign * 62.0
		stiff = 30.0
		damp = 6.5
	elif _held:
		# Carried: tilt a touch and bob helplessly.
		target = 10.0 + sin(_t * 5.0) * 5.0
		stiff = 40.0
		damp = 6.0
	else:
		var teeter := _c("idle_teeter") * sin(_t * TAU * _c("teeter_hz"))
		var momentum := clampf(_motion_x * _c("lean_per_speed"), -_c("lean_max"), _c("lean_max"))
		target = momentum + teeter
	_lean_vel += (target - _lean) * stiff * delta
	_lean_vel -= _lean_vel * damp * delta
	_lean += _lean_vel * delta
	_lean = clampf(_lean, -75.0, 75.0)   # headroom for a full topple
	_lean_node.rotation_degrees = _lean

func _apply_body(delta: float) -> void:
	if _body == null:
		return
	# Decay the hit recoil/squash back to rest.
	_body_recoil = _body_recoil.move_toward(Vector2.ZERO, 140.0 * delta)
	_body_squash = move_toward(_body_squash, 0.0, 0.9 * delta)
	# Idle breathing + walk bounce.
	var breathe := 0.0
	var bounce := 0.0
	if _state == "walk":
		bounce = -absf(sin(_walk_phase)) * _c("bounce")
	else:
		breathe = 0.035 * sin(_t * TAU * _c("idle_hz"))
	# _flip sits _feet_y above the lean pivot; bounce/recoil ride on top of that.
	_flip.position.y = -_feet_y + bounce + _body_recoil.y
	_flip.position.x = _body_recoil.x * (1.0 if _facing_right else -1.0)
	var sx := 1.0 + _body_squash
	var sy := 1.0 - _body_squash + breathe
	_body.scale = Vector2(sx, sy)
