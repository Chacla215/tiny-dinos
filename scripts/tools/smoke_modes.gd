extends SceneTree
## Throwaway smoke-sim for mode-aware AI: CPU-only bombtag / beast / flood
## matches; prints state transitions proving the bots engage the objective.
##   /opt/homebrew/bin/godot --headless -s scripts/tools/smoke_modes.gd

const RUNS := [
	{"mode": "bombtag", "players": 3, "seconds": 45.0},
	{"mode": "beast", "players": 3, "seconds": 60.0},
	{"mode": "flood", "players": 3, "seconds": 60.0},
]

var _arena: Node
var _i := -1
var _t := 0.0
var _last_probe := ""

func _initialize() -> void:
	_next()

func _next() -> void:
	if _arena:
		_arena.queue_free()
		_arena = null
	_i += 1
	if _i >= RUNS.size():
		print("MODES SMOKE DONE")
		quit(0)
		return
	var run: Dictionary = RUNS[_i]
	var mc: Node = root.get_node_or_null("MatchConfig")
	mc.island = "beauty_beach"
	mc.player_count = run["players"]
	mc.cpu_players = {"p1": true, "p2": true, "p3": true, "p4": true}
	mc.cpu_difficulty = "hard"
	mc.dino_choices = {"p1": "ralph", "p2": "raptor", "p3": "trike", "p4": "anky"}
	mc.game_mode = run["mode"]
	_arena = load(mc.ISLAND_SCENES["beauty_beach"]).instantiate()
	root.add_child(_arena)
	current_scene = _arena
	_t = 0.0
	_last_probe = ""
	print("--- %s (%dp) ---" % [run["mode"], run["players"]])

func _probe() -> String:
	match RUNS[_i]["mode"]:
		"bombtag":
			return "holder=%s stocks=%s" % [_arena.bomb_holder, str(_arena.stocks)]
		"beast":
			# Only crown steals + whole banked seconds, or the log drowns.
			var banked := ""
			for pid in _arena.mode_score:
				banked += " %s=%ds" % [pid, int(_arena.mode_score[pid])]
			return "beast=%s%s" % [_arena.beast_pid, banked]
		"flood":
			return "shrink=%.1f out=%s" % [snappedf(_arena.zone_shrink, 0.1), str(_arena.eliminated.keys())]
	return ""

func _process(delta: float) -> bool:
	if _arena == null:
		return false
	_t += delta
	var probe := _probe()
	if probe != _last_probe:
		_last_probe = probe
		print("[%5.1fs] %s" % [_t, probe])
	if _arena.match_over:
		print("MATCH OVER at %.1fs" % _t)
		_next()
	elif _t >= RUNS[_i]["seconds"]:
		print("TIME UP (no crash)")
		_next()
	return false
