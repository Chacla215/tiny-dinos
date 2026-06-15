extends Node
## Throwaway functional test for 3v3 (Phase 3, Feature 5A). Boots a real arena with
## player_count 6, asserts Player5/Player6 are cloned in + seated at distinct spawns,
## team helpers resolve across six, a 6-CPU brawl survives a burst of frames, and a
## KO aggregates to the right side. Headless:  godot --headless scenes/sixplayer_test.tscn
## Delete with the other Phase 3 probes once 3v3 is locked.

var _fails: Array = []

func _ready() -> void:
	MatchConfig.player_count = 6
	MatchConfig.teams_enabled = true
	MatchConfig.teams = {"p1": "a", "p2": "a", "p3": "a", "p4": "b", "p5": "b", "p6": "b"}
	MatchConfig.cpu_players = {"p1": true, "p2": true, "p3": true, "p4": true, "p5": true, "p6": true}
	MatchConfig.dino_choices = {"p1": "ralph", "p2": "raptor", "p3": "trike", "p4": "pterry", "p5": "bronto", "p6": "anky"}
	MatchConfig.game_mode = "rounds"

	var arena: Node = load("res://scenes/arena_beach.tscn").instantiate()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = arena
	arena.kos_to_win = 5   # keep a test KO from ending the match outright

	# --- six fighters spawned + seated ---
	_check("six active players", arena.active_players.size() == 6)
	var ids: Array = []
	for p in arena.active_players:
		ids.append(p.player_id)
	_check("p5 and p6 are in the match", ("p5" in ids) and ("p6" in ids))
	_check("Player5 node exists", arena.get_node_or_null("Player5") != null)
	_check("Player6 node exists", arena.get_node_or_null("Player6") != null)
	var seen: Dictionary = {}
	var distinct: bool = true
	for p in arena.active_players:
		var key: String = "%d,%d" % [int(p.global_position.x), int(p.global_position.y)]
		if seen.has(key):
			distinct = false
		seen[key] = true
	_check("six distinct spawn positions", distinct)
	var p5: Node = arena.get_node("Player5")
	var p6: Node = arena.get_node("Player6")
	# spawn_point was overridden by the 6-layout (not left at the cloned p4 position).
	_check("clone got a layout spawn_point", p5.spawn_point != Vector2.ZERO and p5.spawn_point != p6.spawn_point)
	_check("p5 is visible", p5.visible)

	# --- team helpers resolve across six ---
	_check("p1/p3 same side", MatchConfig.same_side("p1", "p3"))
	_check("p4/p6 same side", MatchConfig.same_side("p4", "p6"))
	_check("p1/p4 are enemies", not MatchConfig.same_side("p1", "p4"))
	_check("two alive sides", arena._alive_sides().size() == 2)

	# --- a six-CPU brawl runs without crashing ---
	for _i in range(120):
		await get_tree().process_frame
	_check("6-CPU brawl survived 120 frames", is_instance_valid(arena) and not arena.match_over)

	# --- a KO aggregates to the killer's side ---
	var a_before: int = int(arena.round_wins.get("a", 0))
	arena.award_ko(arena.get_node("Player1"), arena.get_node("Player4"))
	_check("KO credits side A's round tally", int(arena.round_wins.get("a", 0)) == a_before + 1)

	if _fails.is_empty():
		print("SIXPLAYER TEST: ALL PASS")
	else:
		for f in _fails:
			print("  FAIL  %s" % f)
		print("SIXPLAYER TEST: %d FAILED" % _fails.size())
	get_tree().quit()

func _check(label: String, ok: bool) -> void:
	if ok:
		print("  PASS  %s" % label)
	else:
		_fails.append(label)
