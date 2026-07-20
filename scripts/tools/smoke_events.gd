extends SceneTree
## Throwaway smoke-sim for SIGNATURE ISLAND EVENTS + spawn-armed weapons +
## walkable piers/bridges. Forces the event clock (event_timer -> 1s) so each
## island's event fires early; prints probes. Not shipped.
##   /opt/homebrew/bin/godot --headless -s scripts/tools/smoke_events.gd

const ISLANDS := ["laughing_lava", "beauty_beach", "iciest_age", "white_water_falls", "sunny_springs", "purple_fields"]
const SECONDS := 18.0

var _arena: Node
var _i := -1
var _t := 0.0
var _saw_event := false
var _hp0 := {}

func _initialize() -> void:
	_next()

func _next() -> void:
	if _arena:
		_arena.queue_free()
		_arena = null
	_i += 1
	if _i >= ISLANDS.size():
		print("EVENTS SMOKE DONE")
		quit(0)
		return
	var island: String = ISLANDS[_i]
	var mc: Node = root.get_node_or_null("MatchConfig")
	mc.island = island
	mc.player_count = 3
	mc.cpu_players = {"p1": true, "p2": true, "p3": true, "p4": true}
	mc.cpu_difficulty = "hard"
	mc.dino_choices = {"p1": "ralph", "p2": "raptor", "p3": "anky", "p4": "trike"}
	mc.game_mode = "rounds"
	_arena = load(mc.ISLAND_SCENES[island]).instantiate()
	_arena.kos_to_win = 99
	root.add_child(_arena)
	current_scene = _arena
	_t = 0.0
	_saw_event = false
	_hp0 = {}
	# Probe 1: everyone spawned armed with their signature weapon.
	var armed := ""
	for p in _arena.active_players:
		armed += " %s=%s" % [p.player_id, p.weapons[p.active_weapon]]
	# Probe 2: walkway merge grew the polygon (beach/falls only).
	print("--- %s ---  armed:%s  poly_pts=%d" % [island, armed, _arena.safe_polygon.size()])
	_arena.event_timer = 1.0  # force the event to fire just after FIGHT

func _process(delta: float) -> bool:
	if _arena == null:
		return false
	_t += delta
	if _hp0.is_empty():
		for p in _arena.active_players:
			_hp0[p.player_id] = p.hp
	if _arena.event_active and not _saw_event:
		_saw_event = true
		print("[%4.1fs] EVENT LIVE: %s" % [_t, _arena.hud_hint.text])
	if _t >= SECONDS:
		var dmg := ""
		for p in _arena.active_players:
			dmg += " %s:%d->%d" % [p.player_id, _hp0.get(p.player_id, 0), p.hp]
		print("  event_seen=%s  hp:%s" % [str(_saw_event), dmg])
		_next()
	return false
