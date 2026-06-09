extends SceneTree
## Throwaway headless balance/AI sim. Pits two CPU dinos against each other on a
## confined arena and tallies round wins (= KOs) over a fixed wall-clock window,
## across a few matchups. Run:  godot --headless -s scripts/tools/sim_ai.gd
## Not shipped — a self-test tool for tuning. Delete when done.

const ARENAS := {
	"CONFINED(lava)": "res://scenes/arena_lava.tscn",
	"RINGOUT(beach)": "res://scenes/arena_beach.tscn",
}
const SECONDS_PER_MATCH := 30.0
const MATCHUPS := [
	["raptor", "trex"],
	["raptor", "bronto"],
	["raptor", "anky"],
	["trex", "bronto"],
	["trex", "anky"],
	["bronto", "anky"],
]

var _mc: Node
var _arena: Node
var _t := 0.0
var _idx := -1
var _arena_keys: Array
var _arena_i := 0
var _difficulty := "hard"

func _initialize() -> void:
	_mc = root.get_node_or_null("MatchConfig")
	if _mc == null:
		push_error("MatchConfig autoload missing"); quit(1); return
	_arena_keys = ARENAS.keys()
	print("=== AI/balance sim  (%.0fs/match, %s) ===" % [SECONDS_PER_MATCH, _difficulty])
	_next_match()

func _next_match() -> void:
	if _arena != null:
		_report()
		_arena.queue_free()
		_arena = null
	_idx += 1
	if _idx >= MATCHUPS.size():
		_idx = 0
		_arena_i += 1
		if _arena_i >= _arena_keys.size():
			quit(0); return
		print("--- %s ---" % _arena_keys[_arena_i])
	elif _arena_i == 0 and _idx == 0:
		print("--- %s ---" % _arena_keys[0])
	var m: Array = MATCHUPS[_idx]
	_mc.player_count = 2
	_mc.cpu_players = {"p1": true, "p2": true, "p3": false, "p4": false}
	_mc.cpu_difficulty = _difficulty
	_mc.dino_choices = {"p1": m[0], "p2": m[1], "p3": "trike", "p4": "pterry"}
	_mc.weapon_choices = {}
	var packed: PackedScene = load(ARENAS[_arena_keys[_arena_i]])
	_arena = packed.instantiate()
	if "kos_to_win" in _arena:
		_arena.kos_to_win = 99  # never end the match; just keep counting KOs
	root.add_child(_arena)
	current_scene = _arena  # die()/effects route through current_scene; must be set
	_t = 0.0

func _report() -> void:
	var m: Array = MATCHUPS[_idx]
	var rw: Dictionary = _arena.round_wins if "round_wins" in _arena else {}
	var p1: int = rw.get("p1", 0)
	var p2: int = rw.get("p2", 0)
	print("[%s] %s(p1) %d  -  %d %s(p2)" % [_difficulty, m[0], p1, p2, m[1]])

func _process(delta: float) -> bool:
	if _arena == null:
		return false
	_t += delta
	if _t >= SECONDS_PER_MATCH:
		_next_match()
	return false
