extends RefCounted
## Basic fighting AI for a CPU-controlled dino.
##
## It never touches movement or combat directly — it only produces the same
## "inputs" a human would (a move direction, a held-block flag, and one-shot
## attack/heavy/dodge presses), which dino.gd consumes through the exact same
## code paths as keyboard/controller input. So the bot is bound by every rule
## the player is: dodge costs block, guard breaks stun it, etc.

# --- Tunables (basic-fighter defaults; raise/lower for difficulty) ---
var aggression: float = 0.7      # 0..1: higher = closes distance + attacks more
var reaction_time: float = 0.16  # delay before reacting to your swings (s)
var block_chance: float = 0.40   # P(block) when you swing at it in range
var dodge_chance: float = 0.22   # P(dodge instead) when you swing at it
var heavy_chance: float = 0.30   # fraction of its attacks that are heavy
var special_chance: float = 0.30 # how often it reaches for its signature special
var standoff_gap: float = 24.0   # buffer beyond attack reach it likes to hover at

# --- Outputs read by the owning dino each frame ---
var move_dir: Vector2 = Vector2.ZERO
var block_held: bool = false

var _attack_q: bool = false
var _heavy_q: bool = false
var _special_q: bool = false
var _dodge_q: bool = false

# --- internal timers / decisions ---
var _decide_t: float = 0.0
var _attack_cd: float = 0.0
var _react_cd: float = 0.0
var _block_t: float = 0.0
var _strafe: float = 1.0
var _make_space: bool = false

func consume_attack() -> bool:
	var v := _attack_q
	_attack_q = false
	return v

func consume_heavy() -> bool:
	var v := _heavy_q
	_heavy_q = false
	return v

func consume_special() -> bool:
	var v := _special_q
	_special_q = false
	return v

func consume_dodge() -> bool:
	var v := _dodge_q
	_dodge_q = false
	return v

func think(owner: Node, target: Node, delta: float) -> void:
	move_dir = Vector2.ZERO
	block_held = false
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_react_cd = maxf(0.0, _react_cd - delta)
	_block_t = maxf(0.0, _block_t - delta)
	_decide_t -= delta

	if target == null:
		return
	if owner.is_guard_broken():
		return  # stunned: inputs are ignored anyway

	var to_t: Vector2 = target.global_position - owner.global_position
	var dist: float = to_t.length()
	var dir: Vector2 = (to_t / dist) if dist > 0.001 else Vector2.RIGHT

	var reach: float = owner.attack_hitbox_offset + owner.attack_hitbox_size.x * 0.5
	var heavy_reach: float = owner.heavy_hitbox_offset + owner.heavy_hitbox_size.x * 0.5

	# Committed to a block from a previous frame: hold it through the swing.
	if _block_t > 0.0:
		block_held = true
		move_dir = _avoid(owner, -dir * 0.3)  # ease back a touch while guarding
		return

	# React to an incoming swing: dodge or raise guard.
	if target.is_swinging() and dist < heavy_reach + 50.0 and _react_cd <= 0.0:
		_react_cd = reaction_time + randf_range(0.0, 0.1)
		var roll := randf()
		if roll < dodge_chance and owner.can_dodge():
			move_dir = _avoid(owner, -dir)  # dodge away from the attacker
			_dodge_q = true
			return
		elif roll < dodge_chance + block_chance and owner.can_start_block():
			_block_t = randf_range(0.25, 0.45)
			block_held = true
			move_dir = -dir * 0.3
			return

	# Coarse movement decision, refreshed periodically (less twitchy than per-frame).
	if _decide_t <= 0.0:
		_decide_t = randf_range(0.35, 0.8)
		_strafe = 1.0 if randf() < 0.5 else -1.0
		_make_space = randf() > aggression

	# Spacing: approach, peel off if too close, otherwise circle.
	var perp := Vector2(-dir.y, dir.x) * _strafe
	if dist > reach + standoff_gap + 24.0:
		move_dir = (dir + perp * 0.35).normalized()
	elif dist < reach * 0.55 and _make_space:
		move_dir = (-dir + perp * 0.5).normalized()
	else:
		move_dir = (perp * 0.6 + dir * 0.2).normalized()

	# Attack when in range and off cooldown. Mostly avoid swinging into i-frames.
	if dist <= reach + 16.0 and _attack_cd <= 0.0 and owner.can_attack():
		if target.invuln_timer <= 0.0 or randf() < 0.25:
			move_dir = dir  # face the target on the commit frame
			var roll := randf()
			if roll < special_chance:
				_special_q = true  # dino gates this on cooldown via can_special()
			elif roll < special_chance + heavy_chance and dist <= heavy_reach + 8.0:
				_heavy_q = true
			else:
				_attack_q = true
			_attack_cd = randf_range(0.4, 0.85) / clampf(aggression, 0.25, 1.0)

	# Never steer itself off a ledge / out of bounds.
	move_dir = _avoid(owner, move_dir)

# Bends a desired direction away from the arena edge when near it. Uses the
# ledge safe_rect where one exists, otherwise the play bounds.
func _avoid(owner: Node, desired: Vector2) -> Vector2:
	var arena := owner.get_parent()
	if arena == null:
		return desired
	var rect: Rect2
	var have := false
	if "ledge_kill_enabled" in arena and arena.ledge_kill_enabled:
		rect = arena.safe_rect
		have = true
	elif "play_bounds" in arena:
		rect = arena.play_bounds
		have = true
	if not have:
		return desired
	var pos: Vector2 = owner.global_position
	var m := 80.0
	var steer := desired
	if pos.x < rect.position.x + m:
		steer.x += 1.0
	elif pos.x > rect.end.x - m:
		steer.x -= 1.0
	if pos.y < rect.position.y + m:
		steer.y += 1.0
	elif pos.y > rect.end.y - m:
		steer.y -= 1.0
	return steer.normalized() if steer.length() > 0.05 else Vector2.ZERO
