extends SceneTree
## Throwaway smoke-sim for the ISLAND IDENTITY pass: one short CPU-vs-CPU match
## on each hazard island, with probes proving each mechanic actually fires
## (burn ticks, ice overlap, current push, spring launches, trunk collision).
## p1 gets teleported onto the hazard a couple of times so probes are
## deterministic even if the bots avoid it. Not shipped — delete when stale.
##   /opt/homebrew/bin/godot --headless -s scripts/tools/smoke_hazards.gd

const ISLANDS := ["laughing_lava", "iciest_age", "white_water_falls", "sunny_springs", "purple_fields"]
const SECONDS := 22.0
const TELEPORT_TIMES := [8.0, 14.0]

var _mc: Node
var _arena: Node
var _i := -1
var _t := 0.0
var _teleports_done := 0
var _spring_hits := 0
var _ice_frames := 0
var _current_frames := 0
var _hp_at_start := {}

func _initialize() -> void:
	_mc = root.get_node_or_null("MatchConfig")
	if _mc == null:
		push_error("MatchConfig missing")
		quit(1)
		return
	print("=== hazard smoke-sim (%.0fs per island) ===" % SECONDS)
	_next()

func _next() -> void:
	if _arena:
		_report()
		_arena.queue_free()
		_arena = null
	_i += 1
	if _i >= ISLANDS.size():
		print("SMOKE DONE")
		quit(0)
		return
	var island: String = ISLANDS[_i]
	_mc.island = island
	_mc.player_count = 2
	_mc.cpu_players = {"p1": true, "p2": true, "p3": false, "p4": false}
	_mc.cpu_difficulty = "hard"
	_mc.dino_choices = {"p1": "ralph", "p2": "raptor", "p3": "trike", "p4": "pterry"}
	_mc.game_mode = "rounds"
	var packed: PackedScene = load(_mc.ISLAND_SCENES[island])
	_arena = packed.instantiate()
	_arena.kos_to_win = 99
	root.add_child(_arena)
	current_scene = _arena
	_t = 0.0
	_teleports_done = 0
	_spring_hits = 0
	_ice_frames = 0
	_current_frames = 0
	_hp_at_start = {}
	for pool in _arena.spring_pools:
		pool.body_entered.connect(func(_b: Node) -> void: _spring_hits += 1)

func _hazard_point() -> Vector2:
	# A point ON the hazard for the current island.
	var island: String = ISLANDS[_i]
	var c: Vector2 = _arena._safe_center()
	match island:
		"laughing_lava":
			return c + (_arena.safe_polygon[0] - c) * 0.93  # on the hot rim band
		"sunny_springs":
			return _arena.spring_pools[0].position  # in a geyser pool
		_:
			return c

func _process(delta: float) -> bool:
	if _arena == null:
		return false
	_t += delta
	if _hp_at_start.is_empty() and _arena.active_players.size() > 0:
		for p in _arena.active_players:
			_hp_at_start[p.player_id] = p.hp
	for p in _arena.active_players:
		if p.current_push != Vector2.ZERO:
			_current_frames += 1
		if p.ice_overlap_count > 0:
			_ice_frames += 1
	if _teleports_done < TELEPORT_TIMES.size() and _t >= TELEPORT_TIMES[_teleports_done]:
		_teleports_done += 1
		var p1: Node = _arena.active_players[0]
		if not p1.is_falling:
			p1.global_position = _hazard_point()
	if _t >= SECONDS:
		_next()
	return false

func _report() -> void:
	var island: String = ISLANDS[_i]
	var bits: Array = []
	match island:
		"laughing_lava":
			var burned := 0
			for pid in _hp_at_start:
				for p in _arena.active_players:
					if p.player_id == pid and p.hp < _hp_at_start[pid]:
						burned += 1
			bits.append("hot_rim_pts=%d" % _arena.hot_rim_inner.size())
			bits.append("players_damaged=%d (burn or combat)" % burned)
		"iciest_age":
			bits.append("frozen_lake=%s" % str(_arena.get_node_or_null("FrozenLake") != null))
			bits.append("ice_frames=%d" % _ice_frames)
		"white_water_falls":
			bits.append("current=%s" % str(_arena.global_current))
			bits.append("current_frames=%d" % _current_frames)
		"sunny_springs":
			bits.append("pools=%d" % _arena.spring_pools.size())
			bits.append("spring_launches=%d" % _spring_hits)
		"purple_fields":
			var space: PhysicsDirectSpaceState2D = _arena.get_world_2d().direct_space_state
			var q := PhysicsPointQueryParameters2D.new()
			q.position = _arena._scaled_pt(Vector2(717, 252))
			q.collision_mask = 2
			q.collide_with_bodies = true
			bits.append("trunk_solid=%s" % str(space.intersect_point(q).size() > 0))
			bits.append("obstacle_circles=%d" % _arena.obstacle_circles.size())
	print("[%s] %s" % [island, "  ".join(PackedStringArray(bits))])
