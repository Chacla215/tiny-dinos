extends SceneTree
## Throwaway headless balance/AI sim. Pits two CPU dinos against each other on a
## confined arena and tallies round wins (= KOs) over a fixed wall-clock window,
## across a full round-robin of the roster. Run:
##   godot --headless -s scripts/tools/sim_ai.gd
## Not shipped — a self-test tool for tuning. Delete when done.

const ARENAS := {
	"CONFINED(lava)": "res://scenes/arena_lava.tscn",
	"RINGOUT(beach)": "res://scenes/arena_beach.tscn",
}
const SECONDS_PER_MATCH := 18.0
const ROSTER := ["ralph", "raptor", "trike", "pterry", "bronto", "anky"]

var _mc: Node
var _arena: Node
var _t := 0.0
var _idx := -1
var _arena_keys: Array
var _arena_i := 0
var _difficulty := "hard"

# Full round-robin pair list (each unordered pair once per arena).
var _matchups: Array = []
# kos[a][b] = total KOs dino a scored vs dino b, summed over both arenas/sides.
var _kos: Dictionary = {}

func _initialize() -> void:
	_mc = root.get_node_or_null("MatchConfig")
	if _mc == null:
		push_error("MatchConfig autoload missing"); quit(1); return
	for a in ROSTER:
		_kos[a] = {}
		for b in ROSTER:
			_kos[a][b] = 0
	for i in range(ROSTER.size()):
		for j in range(i + 1, ROSTER.size()):
			_matchups.append([ROSTER[i], ROSTER[j]])
	_arena_keys = ARENAS.keys()
	print("=== AI/balance sim  (%.0fs/match, %s, %d pairs x %d arenas) ===" % [
		SECONDS_PER_MATCH, _difficulty, _matchups.size(), _arena_keys.size()])
	_next_match()

func _next_match() -> void:
	if _arena != null:
		_report()
		_arena.queue_free()
		_arena = null
	_idx += 1
	if _idx >= _matchups.size():
		_idx = 0
		_arena_i += 1
		if _arena_i >= _arena_keys.size():
			_print_matrix()
			quit(0); return
	if _idx == 0:
		print("--- %s ---" % _arena_keys[_arena_i])
	var m: Array = _matchups[_idx]
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
	var m: Array = _matchups[_idx]
	var rw: Dictionary = _arena.round_wins if "round_wins" in _arena else {}
	var p1: int = rw.get("p1", 0)
	var p2: int = rw.get("p2", 0)
	_kos[m[0]][m[1]] += p1
	_kos[m[1]][m[0]] += p2
	print("[%s] %s(p1) %d  -  %d %s(p2)" % [_difficulty, m[0], p1, p2, m[1]])

func _print_matrix() -> void:
	print("\n=== WIN MATRIX (row dino's KOs vs column dino, both arenas) ===")
	var header := "        "
	for b in ROSTER:
		header += "%7s" % b
	header += "   |  TOTAL  WIN%"
	print(header)
	var grand_for: Dictionary = {}
	var grand_against: Dictionary = {}
	for a in ROSTER:
		grand_for[a] = 0
		grand_against[a] = 0
	for a in ROSTER:
		for b in ROSTER:
			if a == b: continue
			grand_for[a] += _kos[a][b]
			grand_against[a] += _kos[b][a]
	for a in ROSTER:
		var line := "%8s" % a
		for b in ROSTER:
			if a == b:
				line += "%7s" % "-"
			else:
				line += "%7d" % _kos[a][b]
		var tot: int = grand_for[a] + grand_against[a]
		var winpct: float = (100.0 * grand_for[a] / tot) if tot > 0 else 0.0
		line += "   |  %4d  %5.1f%%" % [grand_for[a], winpct]
		print(line)
	print("\n=== PER-MATCHUP (a KOs - b KOs), a=row b=col ===")
	for a in ROSTER:
		var line := "%8s" % a
		for b in ROSTER:
			if a == b:
				line += "%9s" % "-"
			else:
				line += "%5d-%-3d" % [_kos[a][b], _kos[b][a]]
		print(line)

func _process(delta: float) -> bool:
	if _arena == null:
		return false
	_t += delta
	if _t >= SECONDS_PER_MATCH:
		_next_match()
	return false
