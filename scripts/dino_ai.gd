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
var throw_chance: float = 0.22   # P(hurl the weapon) on a clean mid-range opening
var punish_chance: float = 0.55  # P(it capitalizes when you whiff / get guard-broken)
var pressure: float = 0.5        # 0..1: how relentlessly it stays in your face after trading
var edge_caution: float = 0.6    # 0..1: how hard it refuses to be pinned against a lethal edge

const THROW_RANGE := 540.0       # max distance it will throw a weapon from
const WEAPON_SEEK_RANGE := 440.0 # how far it'll detour to reclaim a dropped weapon
const EDGE_LOOK := 96.0          # how far ahead it probes for the island edge

# Knob presets per difficulty (the select screen picks one for all CPUs). NORMAL
# matches the original hand-tuned defaults above. EASY hangs back, reacts slowly,
# and rarely defends; HARD closes hard, answers swings fast, and defends often.
# BRUTAL sits above HARD: near-instant reads, all-but-guaranteed whiff-punishes,
# reads heavy-vs-light to pick dodge-vs-block, and refuses to be edged out.
const DIFFICULTY_PRESETS := {
	"easy":   {"aggression": 0.50, "reaction_time": 0.30, "block_chance": 0.22, "dodge_chance": 0.10, "heavy_chance": 0.20, "special_chance": 0.18, "throw_chance": 0.12, "punish_chance": 0.20, "pressure": 0.15, "edge_caution": 0.30},
	"normal": {"aggression": 0.70, "reaction_time": 0.16, "block_chance": 0.40, "dodge_chance": 0.22, "heavy_chance": 0.30, "special_chance": 0.30, "throw_chance": 0.22, "punish_chance": 0.55, "pressure": 0.5, "edge_caution": 0.60},
	"hard":   {"aggression": 0.92, "reaction_time": 0.09, "block_chance": 0.55, "dodge_chance": 0.36, "heavy_chance": 0.34, "special_chance": 0.42, "throw_chance": 0.30, "punish_chance": 0.90, "pressure": 0.85, "edge_caution": 0.85},
	"brutal": {"aggression": 0.98, "reaction_time": 0.045, "block_chance": 0.62, "dodge_chance": 0.40, "heavy_chance": 0.40, "special_chance": 0.55, "throw_chance": 0.34, "punish_chance": 1.0, "pressure": 0.95, "edge_caution": 1.0},
}

# Stamp one difficulty preset onto this brain's knobs. Called by the owning dino
# at spawn from MatchConfig.cpu_difficulty. Unknown level falls back to NORMAL.
func apply_difficulty(level: String) -> void:
	var p: Dictionary = DIFFICULTY_PRESETS.get(level, DIFFICULTY_PRESETS["normal"])
	aggression = p["aggression"]
	reaction_time = p["reaction_time"]
	block_chance = p["block_chance"]
	dodge_chance = p["dodge_chance"]
	heavy_chance = p["heavy_chance"]
	special_chance = p["special_chance"]
	throw_chance = p["throw_chance"]
	punish_chance = p["punish_chance"]
	pressure = p["pressure"]
	edge_caution = p.get("edge_caution", 0.6)

# --- Outputs read by the owning dino each frame ---
var move_dir: Vector2 = Vector2.ZERO
var block_held: bool = false

var _attack_q: bool = false
var _heavy_q: bool = false
var _special_q: bool = false
var _dodge_q: bool = false
var _throw_q: bool = false
var _pickup_q: bool = false

# --- internal timers / decisions ---
var _decide_t: float = 0.0
var _attack_cd: float = 0.0
var _throw_cd: float = 0.0
var _react_cd: float = 0.0
var _block_t: float = 0.0
var _strafe: float = 1.0
var _make_space: bool = false
var _punish_t: float = 0.0   # >0 while committed to rushing an opening
var _was_vuln: bool = false  # target was punishable last frame (rising-edge latch)
var _dash_cd: float = 0.0    # gate on the gap-closer dodge so it doesn't burn block
var _retreat_t: float = 0.0  # >0 = a skirmisher peeling off after a hit (hit-and-run)

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

func consume_throw() -> bool:
	var v := _throw_q
	_throw_q = false
	return v

func consume_pickup() -> bool:
	var v := _pickup_q
	_pickup_q = false
	return v

func think(owner: Node, target: Node, delta: float) -> void:
	move_dir = Vector2.ZERO
	block_held = false
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_throw_cd = maxf(0.0, _throw_cd - delta)
	_react_cd = maxf(0.0, _react_cd - delta)
	_block_t = maxf(0.0, _block_t - delta)
	_punish_t = maxf(0.0, _punish_t - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_retreat_t = maxf(0.0, _retreat_t - delta)
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

	# Archetype from stats: a fast, fragile dino (Raptor) is a "skirmisher" — it
	# can't win trade wars, so it must hit-and-run. skittish (0..1) widens its
	# stand-off and makes it peel off after every hit instead of brawling. Tanks
	# stay at 0 and fight in your face. This is why a CPU Raptor now plays like a
	# Raptor, not a slow dino with a fast walk — distinct kit, distinct AI.
	var skittish: float = clampf((owner.max_speed - 300.0) / 160.0, 0.0, 1.0)
	var gap: float = standoff_gap + skittish * 50.0

	# Closer instinct: when the target is nearly dead, stop playing patient neutral and
	# press for the kill — even a skirmisher commits when one solid hit ends the round.
	# Tightens its stand-off and feeds the attack/special path below (via `finisher`).
	var target_low: bool = ("hp" in target) and ("max_hp" in target) and target.max_hp > 0 \
		and float(target.hp) / float(target.max_hp) < 0.30
	var finisher: bool = target_low and aggression > 0.6
	if finisher:
		gap = standoff_gap * 0.4  # crowd in for the finish instead of circling

	# Ranged kit (bow): a projectile-weapon dino KITES — pokes from arrow range and
	# holds its distance instead of closing to a melee swing. `attack_reach` is the
	# range it fires within; `kite_dist` is the pocket it tries to hold (in range,
	# outside the enemy's melee). reach/heavy_reach stay the true melee values so it
	# still reads and dodges incoming swings by real threat range. Everyone else: the
	# attack_reach is just the melee reach, so this is a no-op for non-ranged dinos.
	var ranged: bool = ("wpn_projectile" in owner) and owner.wpn_projectile
	var attack_reach: float = reach
	var kite_dist: float = 0.0
	if ranged:
		attack_reach = clampf(owner.projectile_speed * owner.projectile_lifetime * 0.5, 260.0, 460.0)
		kite_dist = attack_reach * 0.72

	# Ring-out hunting (arenas with a lethal edge). `ro` carries the push direction
	# (arena centre -> target), whether the target is near the edge, and whether our
	# current facing would shove it off-stage. Empty on confined arenas.
	var ro: Dictionary = _ringout_intent(owner, target, dir)

	# Committed to a block from a previous frame: hold it through the swing.
	if _block_t > 0.0:
		block_held = true
		move_dir = _avoid(owner, -dir * 0.3)  # ease back a touch while guarding
		return

	# React to an incoming swing: dodge or raise guard. The choice is read, not a
	# flat coin-flip — a glass cannon can't eat a heavy and a near-empty guard can't
	# afford to block (a guard-break is a free KO), so we bias toward the survivable
	# option for the situation.
	if target.is_swinging() and dist < heavy_reach + 50.0 and _react_cd <= 0.0:
		_react_cd = reaction_time + randf_range(0.0, 0.1)
		var incoming_heavy: bool = ("current_is_heavy" in target) and target.current_is_heavy
		# Block-bar health: when it's low, blocking risks a guard-break, so lean on
		# dodging (or just bail) instead of turtling into a stun.
		var block_frac: float = owner.block_durability / maxf(1.0, owner.max_block)
		var low_guard: bool = block_frac < 0.34
		# Would dodging shove us toward a lethal edge? If so, don't — block in place.
		var dodge_to_edge: bool = not ro.is_empty() \
			and _near_edge(owner.get_parent(), owner.global_position, -dir, _ai_center(owner.get_parent()))
		var p_dodge: float = dodge_chance
		var p_block: float = block_chance
		if incoming_heavy and block_frac > 0.45:
			# Heavies hit hard and chew guard — when we still have block to spend on the
			# dodge, slip the i-frames rather than eat the chip + knockback (skirmishers
			# especially must avoid it). If block's already thin we fall through to a
			# normal read so we don't strip our own guard chasing perfect defense.
			p_dodge = clampf(p_dodge + 0.22 + skittish * 0.18, 0.0, 0.92)
		if low_guard:
			# Almost out of guard: blocking is a trap, so dodge if we still can.
			p_block *= 0.25
			if owner.block_durability >= owner.dodge_block_cost:
				p_dodge = clampf(p_dodge + 0.25, 0.0, 0.95)
		if dodge_to_edge:
			p_dodge = 0.0      # never i-frame ourselves off the stage
			p_block = clampf(p_block + 0.30, 0.0, 0.95)
		var roll := randf()
		if roll < p_dodge and owner.can_dodge():
			# Dodge away from the attacker, but bend inward when near the edge so the
			# escape never doubles as a self-ring-out.
			var esc: Vector2 = -dir
			if not ro.is_empty() and ro["threatened"]:
				esc = (-ro["self_out"] + (-dir) * 0.3).normalized()
			move_dir = _avoid(owner, esc)
			_dodge_q = true
			return
		elif roll < p_dodge + p_block and owner.can_start_block():
			_block_t = randf_range(0.25, 0.45)
			block_held = true
			move_dir = _avoid(owner, -dir * 0.3)
			return

	# --- Offense: punish an opening ---
	# A target locked in attack recovery or guard-broken can't block or dodge, so a
	# hit is essentially free. On the rising edge of that window we roll once
	# (punish_chance) whether to commit, then bee-line in for a beat and throw the
	# biggest move that reaches. This is the main thing separating HARD (nearly
	# always punishes) from EASY (mostly lets you off the hook) — real whiff-punish.
	var target_open: bool = target.is_recovering() or target.is_guard_broken()
	if target_open and not _was_vuln and _punish_t <= 0.0 and randf() < punish_chance:
		_punish_t = 0.55
	_was_vuln = target_open

	if _punish_t > 0.0:
		# Close a big gap instantly by dodging through it — a deliberate gap-closer,
		# not a panic. Gated on a cooldown and a healthy block bar so it never strips
		# the defense it still needs, and never fired toward a lethal edge.
		# Melee gap-closer dash — ranged dinos skip it; they shoot from where they are.
		if not ranged and dist > heavy_reach + 120.0 and _dash_cd <= 0.0 and owner.can_dodge() \
				and owner.block_durability > owner.max_block * 0.6 and randf() < 0.5 \
				and _dash_safe(owner, dir):
			move_dir = _avoid(owner, dir)
			_dodge_q = true
			_dash_cd = randf_range(0.8, 1.4)
			return
		# Close on the opening — but a ranged dino only closes until it's in shot range.
		if not ranged or dist > attack_reach:
			move_dir = _avoid(owner, dir)  # bee-line for the opening
		# Punish from shot range (ranged) or heavy reach (melee, unchanged).
		if dist <= (attack_reach if ranged else heavy_reach) + 16.0 and owner.can_attack() and _attack_cd <= 0.0:
			move_dir = dir
			# A guard-broken target is stunned for a long beat — the surest moment to
			# cash the signature for max damage. A recovery whiff is a shorter window,
			# so favour the heavy there and save the special for the guaranteed one.
			var hard_open: bool = target.is_guard_broken()
			if owner.can_special() and randf() < (0.75 if hard_open else 0.40):
				_special_q = true  # biggest punish when the signature is up
			elif dist <= heavy_reach + 8.0:
				_heavy_q = true
			else:
				_attack_q = true
			_attack_cd = randf_range(0.3, 0.6)
			_punish_t = 0.0  # opening spent
			if skittish > 0.3:
				_retreat_t = 0.30 + skittish * 0.20  # land the punish, then bail
		return

	# Coarse movement decision, refreshed periodically (less twitchy than per-frame).
	if _decide_t <= 0.0:
		_decide_t = randf_range(0.35, 0.8)
		_strafe = 1.0 if randf() < 0.5 else -1.0
		# Pressure makes it less willing to peel off — it hangs in your face and
		# keeps trading rather than resetting to neutral after every exchange.
		_make_space = randf() > clampf(aggression + pressure * 0.3, 0.0, 1.0)
		# Never back off when a ring-out is set up — close in and shove them off.
		if not ro.is_empty() and ro["near_edge"]:
			_make_space = false

	# Hit-and-run: a skirmisher that just landed/threw a blow peels out to its
	# stand-off rather than lingering in trade range. This is the whole point of a
	# glass cannon — touch and go, never stand and bang.
	var perp := Vector2(-dir.y, dir.x) * _strafe
	if ranged:
		# Kite: hold the pocket — close in if out of shot range, back off (always, not
		# just on _make_space) if the enemy creeps into melee, otherwise strafe and poke.
		if dist > kite_dist + 30.0:
			move_dir = (dir + perp * 0.3).normalized()
		elif dist < kite_dist - 24.0:
			move_dir = (-dir + perp * 0.45).normalized()
		else:
			move_dir = (perp * 0.7 + dir * 0.05).normalized()
	elif _retreat_t > 0.0 and dist < reach + gap + 30.0:
		move_dir = (-dir + perp * 0.4).normalized()
	# Spacing: approach, peel off if too close, otherwise circle.
	elif dist > reach + gap + 24.0:
		move_dir = (dir + perp * 0.35).normalized()
	elif dist < reach * 0.55 and _make_space:
		move_dir = (-dir + perp * 0.5).normalized()
	else:
		move_dir = (perp * 0.6 + dir * 0.2).normalized()

	# Edge-aware neutral: when we're loitering near a lethal edge (and NOT actively
	# setting up a ring-out push), fold a pull toward arena centre into the heading so
	# we fight with the stage at our back instead of the void. Keeps every dino off
	# the shoreline during the circling/spacing phase, not just at the last step where
	# _avoid takes over. Scaled by edge_caution so EASY still wanders.
	if not ro.is_empty() and not (ro["near_edge"] or (ro.has("threatened") and ro["threatened"])):
		var arena_c: Vector2 = _ai_center(owner.get_parent())
		var self_out2: Vector2 = ro.get("self_out", Vector2.ZERO)
		if self_out2 != Vector2.ZERO \
				and _near_edge(owner.get_parent(), owner.global_position, self_out2, arena_c):
			var inward: Vector2 = (arena_c - owner.global_position).normalized()
			var w: float = 0.35 * edge_caution
			move_dir = (move_dir * (1.0 - w) + inward * w)
			if move_dir.length() > 0.05:
				move_dir = move_dir.normalized()

	# Stay glued through the target's hit-invulnerability so the next swing connects
	# the instant their i-frames drop, instead of drifting out and resetting neutral.
	if target.invuln_timer > 0.0 and pressure > 0.4 and dist < reach + standoff_gap + 60.0:
		move_dir = (perp * 0.5 + dir * 0.3).normalized()

	# Ring-out positioning: slide to the centre side of the target so our facing
	# (toward it) points off-stage and a hit shoves it toward the edge instead of
	# harmlessly inward. Strong pull once the target is near the edge — a short push
	# finishes it; this is what breaks the open-arena circling stalemate.
	if not ro.is_empty():
		# Self-preservation now applies to EVERY dino, scaled by edge_caution — a tank
		# that lets itself get pinned on the shoreline is the cheapest way for the AI
		# to lose, so even heavies peel toward centre when lined up to be shoved off.
		# Fragile dinos (skittish) bail harder and burn a dodge to break the pin.
		if ro["threatened"] and randf() < edge_caution:
			move_dir = (-ro["self_out"] + perp * 0.2).normalized()
			if skittish > 0.3 and owner.can_dodge() and _dash_cd <= 0.0 and randf() < 0.4:
				move_dir = _avoid(owner, -ro["self_out"])
				_dodge_q = true
				_dash_cd = randf_range(0.6, 1.0)
		else:
			var inside: Vector2 = target.global_position - ro["outward"] * (reach * 0.85)
			var to_inside: Vector2 = inside - owner.global_position
			if to_inside.length() > 10.0:
				var w: float = 0.6 if ro["near_edge"] else 0.28
				move_dir = move_dir * (1.0 - w) + to_inside.normalized() * w
				if move_dir.length() > 0.05:
					move_dir = move_dir.normalized()

	# Weapon scavenging: snatch a dropped weapon underfoot, and when disarmed go
	# fetch the nearest one rather than fist-fighting for the rest of the round.
	var disarmed: bool = owner._active_weapon_id() == "fists"
	var loot: Node = _nearest_pickup(owner)
	if loot != null:
		var loot_d: float = owner.global_position.distance_to(loot.global_position)
		if loot_d <= owner.PICKUP_RADIUS and (disarmed or "fists" in owner.weapons):
			_pickup_q = true
		elif disarmed and loot_d <= WEAPON_SEEK_RANGE:
			move_dir = _avoid(owner, (loot.global_position - owner.global_position).normalized())

	# Ranged poke: hurl the weapon at mid range, but only when it won't clear the
	# platform edge on a miss and be wasted (see _throw_safe).
	if not disarmed and not ranged and _throw_cd <= 0.0 and owner.can_throw() \
			and dist > reach + standoff_gap and dist < THROW_RANGE \
			and target.invuln_timer <= 0.0 \
			and randf() < throw_chance and _throw_safe(owner, dir, dist):
		move_dir = dir  # face the target on the release frame
		_throw_q = true
		_throw_cd = randf_range(2.2, 3.6)

	# Attack when in range and off cooldown (shot range for ranged). Mostly avoid
	# swinging/firing into i-frames.
	if dist <= attack_reach + 16.0 and _attack_cd <= 0.0 and owner.can_attack():
		if target.invuln_timer <= 0.0 or randf() < 0.25:
			move_dir = dir  # face the target on the commit frame
			var edge_kill: bool = not ro.is_empty() and ro["near_edge"] and ro["aligned"]
			if edge_kill or finisher:
				# Lined up at the edge OR the target is one hit from death: throw the
				# hardest-hitting move available, not a light poke that barely nudges
				# them. This is what actually closes rounds instead of chip-stalling.
				if owner.can_special() and randf() < (0.6 if finisher else 0.5):
					_special_q = true
				elif dist <= heavy_reach + 8.0:
					_heavy_q = true
				else:
					_attack_q = true
			else:
				var roll := randf()
				if roll < special_chance:
					_special_q = true  # dino gates this on cooldown via can_special()
				elif roll < special_chance + heavy_chance and dist <= heavy_reach + 8.0:
					_heavy_q = true
				else:
					_attack_q = true
			_attack_cd = randf_range(0.4, 0.85) / clampf(aggression, 0.25, 1.0)
			if skittish > 0.3 and not finisher:
				_retreat_t = 0.35 + skittish * 0.25  # touch and go (but never bail a kill)

	# Objective modes: when not mid-exchange, drift toward the hill / nearest egg so
	# a CPU actually contests King of the Hill and Egg Grab instead of only brawling.
	_apply_objective(owner, dist)

	# Never steer itself off a ledge / out of bounds.
	move_dir = _avoid(owner, move_dir)

# Ring-out plan for arenas with a lethal edge (ledge ring-out or floe drown). The
# knockback shoves the victim along the attacker's facing, so to push it off-stage
# we line up on the centre side and hit outward. Returns {} on confined arenas.
func _ringout_intent(owner: Node, target: Node, dir: Vector2) -> Dictionary:
	var arena := owner.get_parent()
	if arena == null:
		return {}
	var is_ring: bool = ("ledge_kill_enabled" in arena and arena.ledge_kill_enabled) \
		or ("drown_off_floes" in arena and arena.drown_off_floes)
	if not is_ring:
		return {}
	var center: Vector2 = _ai_center(arena)
	var ov: Vector2 = target.global_position - center
	var outward: Vector2 = ov.normalized() if ov.length() > 1.0 else Vector2.RIGHT
	# Mirror it for ourselves: are WE near the edge with the foe lined up to shove us
	# off? (their hit pushes us along our own outward dir). Fragile dinos flee this.
	var sv: Vector2 = owner.global_position - center
	var self_out: Vector2 = sv.normalized() if sv.length() > 1.0 else Vector2.ZERO
	var opp_to_me: Vector2 = owner.global_position - target.global_position
	var threatened: bool = self_out != Vector2.ZERO \
		and _near_edge(arena, owner.global_position, self_out, center) \
		and opp_to_me.normalized().dot(self_out) > 0.2
	return {
		"outward": outward,
		"near_edge": _near_edge(arena, target.global_position, outward, center),
		"aligned": dir.dot(outward) > 0.25,  # a hit now would push the target off-stage
		"self_out": self_out,
		"threatened": threatened,
	}

func _ai_center(arena: Node) -> Vector2:
	if "safe_polygon" in arena and arena.safe_polygon.size() >= 3:
		var s := Vector2.ZERO
		for p in arena.safe_polygon:
			s += p
		return s / arena.safe_polygon.size()
	if "safe_rect" in arena:
		return arena.safe_rect.get_center()
	return Vector2(640, 360)

# True when a short outward push from `pos` would clear the safe area — i.e. the
# target is close enough to the edge that one solid hit rings it out.
func _near_edge(arena: Node, pos: Vector2, outward: Vector2, center: Vector2) -> bool:
	var probe: Vector2 = pos + outward * 130.0
	if "safe_polygon" in arena and arena.safe_polygon.size() >= 3:
		return not Geometry2D.is_point_in_polygon(probe, arena.safe_polygon)
	if "ledge_kill_enabled" in arena and arena.ledge_kill_enabled and "safe_rect" in arena:
		return not arena.safe_rect.has_point(probe)
	return pos.distance_to(center) > 180.0  # floe/drown arenas: distance proxy

# Blend the current heading toward the active mode's objective. Pull is strong
# when the enemy is far (free to grab) and weak when they're close (fighting wins).
func _apply_objective(owner: Node, dist_to_target: float) -> void:
	var arena := owner.get_parent()
	if arena == null or not ("game_mode" in arena):
		return
	var goal := Vector2.INF
	if arena.game_mode == "koth":
		if owner.global_position.distance_to(arena.hill_center) > arena.HILL_RADIUS * 0.6:
			goal = arena.hill_center
	elif arena.game_mode == "eggs":
		goal = _nearest_egg(arena, owner)
	if goal == Vector2.INF:
		return
	var to_goal: Vector2 = goal - owner.global_position
	if to_goal.length() < 6.0:
		return
	var w: float = 0.7 if dist_to_target > 260.0 else 0.3
	move_dir = move_dir * (1.0 - w) + to_goal.normalized() * w
	if move_dir.length() > 0.05:
		move_dir = move_dir.normalized()

func _nearest_egg(arena: Node, owner: Node) -> Vector2:
	if not ("eggs" in arena):
		return Vector2.INF
	var best := Vector2.INF
	var best_d := INF
	for egg in arena.eggs:
		if not is_instance_valid(egg):
			continue
		var d: float = owner.global_position.distance_squared_to(egg.position)
		if d < best_d:
			best_d = d
			best = egg.position
	return best

# Bends a desired direction away from the arena edge when near it. Islands ring
# out on the painted safe_polygon (an oval/irregular shoreline), so prefer that
# exact shape; only fall back to the rectangular safe_rect / play_bounds on
# arenas that never set a polygon.
func _avoid(owner: Node, desired: Vector2) -> Vector2:
	var arena := owner.get_parent()
	if arena == null:
		return desired
	if "ledge_kill_enabled" in arena and arena.ledge_kill_enabled \
			and "safe_polygon" in arena and arena.safe_polygon.size() >= 3:
		return _avoid_polygon(owner, arena.safe_polygon, desired)
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

# Polygon-shaped ledge avoidance: probe a step ahead along the desired heading;
# if that point would be off the island, blend the heading back toward the
# island center. A near miss (1.7x lookahead) eases inward while keeping
# momentum so the bot circles the shoreline instead of veering off it.
func _avoid_polygon(owner: Node, poly: PackedVector2Array, desired: Vector2) -> Vector2:
	var pos: Vector2 = owner.global_position
	var inward: Vector2 = _polygon_center(poly) - pos
	var inward_dir: Vector2 = inward.normalized() if inward.length() > 1.0 else Vector2.RIGHT
	if desired.length() <= 0.05:
		# Idle/drifting: only correct if somehow already over the edge.
		return inward_dir if not Geometry2D.is_point_in_polygon(pos, poly) else desired
	var dir: Vector2 = desired.normalized()
	if not Geometry2D.is_point_in_polygon(pos + dir * EDGE_LOOK, poly):
		var steer: Vector2 = dir + inward_dir * 1.6
		return steer.normalized() if steer.length() > 0.05 else inward_dir
	if not Geometry2D.is_point_in_polygon(pos + dir * (EDGE_LOOK * 1.7), poly):
		var steer: Vector2 = dir + inward_dir * 0.6
		return steer.normalized() if steer.length() > 0.05 else dir
	return desired

func _polygon_center(poly: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for p in poly:
		sum += p
	return sum / poly.size()

# True when an i-frame dodge along `dir` would still land on-stage. The dodge is a
# fixed burst that ignores normal steering, so unlike walking it can punch the bot
# clean off a ledge — gate gap-closer dodges on this so the AI never i-frames
# itself into the lava/water chasing a punish. Confined arenas always pass.
const DASH_REACH := 150.0
func _dash_safe(owner: Node, dir: Vector2) -> bool:
	var arena := owner.get_parent()
	if arena == null:
		return true
	var landing: Vector2 = owner.global_position + dir.normalized() * DASH_REACH
	if "safe_polygon" in arena and arena.safe_polygon.size() >= 3:
		return Geometry2D.is_point_in_polygon(landing, arena.safe_polygon)
	if "ledge_kill_enabled" in arena and arena.ledge_kill_enabled and "safe_rect" in arena:
		return arena.safe_rect.has_point(landing)
	if "drown_off_floes" in arena and arena.drown_off_floes:
		return landing.distance_to(_ai_center(arena)) < 200.0
	return true  # confined arena: no lethal edge to dash off

# Nearest weapon resting on the ground (a thrown one that came to rest), or null.
func _nearest_pickup(owner: Node) -> Node:
	var best: Node = null
	var best_d := INF
	for item in owner.get_tree().get_nodes_in_group("weapon_pickups"):
		if not is_instance_valid(item) or not item.is_grounded():
			continue
		var d: float = owner.global_position.distance_squared_to(item.global_position)
		if d < best_d:
			best_d = d
			best = item
	return best

# True when a weapon thrown toward the target would still come down on the
# platform (a miss stays recoverable) rather than sailing off the edge. Tests
# against the island's real shoreline (safe_polygon) where one exists.
func _throw_safe(owner: Node, dir: Vector2, dist: float) -> bool:
	var landing: Vector2 = owner.global_position + dir * (dist + 140.0)
	var arena := owner.get_parent()
	if arena and "safe_polygon" in arena and arena.safe_polygon.size() >= 3:
		return Geometry2D.is_point_in_polygon(landing, arena.safe_polygon)
	return _get_arena_rect(owner).has_point(landing)

func _get_arena_rect(owner: Node) -> Rect2:
	var arena := owner.get_parent()
	if arena:
		if "ledge_kill_enabled" in arena and arena.ledge_kill_enabled:
			return arena.safe_rect
		if "play_bounds" in arena:
			return arena.play_bounds
	return Rect2(-100000, -100000, 200000, 200000)  # unbounded arena: always safe
