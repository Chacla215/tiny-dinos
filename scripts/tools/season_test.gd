extends Node
## Throwaway functional test for SEASON MODE (Phase 1). Exercises the state machine
## (schedule build, mode cycle, matchday seating, advance->champion) + the unlock,
## and the main.gd matchday end flow on a real arena instance.
## Headless:  /opt/homebrew/bin/godot --headless scenes/season_test.tscn
## Delete once season feel is locked.

var _fails: Array = []

func _ready() -> void:
	# Don't pollute the real save: snapshot + restore seasons_won around the test.
	var saved_seasons: int = MetaSave.seasons_won

	# --- 2v2 season: schedule + seating ---
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "raptor", "human": true}], 2, "")
	_check("season flag set", MatchConfig.season)
	_check("schedule has 5 matchdays", MatchConfig.season_schedule.size() == 5)
	var modes: Array = []
	for md in MatchConfig.season_schedule:
		modes.append(md["mode"])
	_check("modes cycle rounds->koth->eggs->sumo->flood", modes == ["rounds", "koth", "eggs", "sumo", "flood"])
	_check("matchday 0 mode applied", MatchConfig.game_mode == "rounds")
	_check("2v2 = 4 fighters", MatchConfig.player_count == 4)
	_check("teams enabled", MatchConfig.teams_enabled)
	_check("your team on side a", MatchConfig.teams.get("p1") == "a" and MatchConfig.teams.get("p2") == "a")
	_check("foes on side b", MatchConfig.teams.get("p3") == "b" and MatchConfig.teams.get("p4") == "b")
	_check("p1/p2 are your humans", MatchConfig.cpu_players["p1"] == false and MatchConfig.cpu_players["p2"] == false)
	_check("p3/p4 are CPU foes", MatchConfig.cpu_players["p3"] and MatchConfig.cpu_players["p4"])
	_check("your dinos seated", MatchConfig.dino_choices["p1"] == "ralph" and MatchConfig.dino_choices["p2"] == "raptor")

	# --- advance through the season -> champion ---
	var advanced := 0
	var seen_modes: Array = [MatchConfig.game_mode]
	while MatchConfig.season_advance():
		advanced += 1
		seen_modes.append(MatchConfig.game_mode)
	_check("advanced exactly 4 times (5 matchdays)", advanced == 4)
	_check("each matchday a distinct mode", seen_modes == ["rounds", "koth", "eggs", "sumo", "flood"])
	_check("final matchday is the finale", MatchConfig.season_is_final())

	# --- 1v1 season: solo seating ---
	MatchConfig.start_season([{"dino": "anky", "human": true}], 1, "")
	_check("1v1 = 2 fighters", MatchConfig.player_count == 2)
	_check("1v1 teams off", not MatchConfig.teams_enabled)
	_check("1v1 foe is CPU", MatchConfig.cpu_players["p2"])

	# --- CPU ally (human flag false) ---
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "trike", "human": false}], 2, "")
	_check("CPU ally -> p2 is CPU", MatchConfig.cpu_players["p2"])

	# --- unlock: winning a season grants the CHAMPION skin ---
	MetaSave.seasons_won = 0
	var champ_idx := -1
	for i in MatchConfig.SKINS.size():
		if MatchConfig.SKINS[i].get("unlock", "") == "champion":
			champ_idx = i
	_check("CHAMPION skin exists", champ_idx >= 0)
	_check("CHAMPION locked before a win", not MatchConfig.skin_unlocked(champ_idx))
	var first := MetaSave.record_season()
	_check("first season win flagged", first)
	_check("seasons_won incremented", MetaSave.seasons_won == 1)
	_check("CHAMPION unlocked after a win", MatchConfig.skin_unlocked(champ_idx))

	# --- main.gd matchday end flow on a real arena ---
	MetaSave.seasons_won = saved_seasons   # restore before the in-engine bit
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "raptor", "human": true}], 2, "")
	var arena: Node = load("res://scenes/arena_beach.tscn").instantiate()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = arena
	var p1: Node = arena.get_node("Player1")
	arena.end_match(p1, "P1")
	_check("matchday win -> advance state", arena.season_end == "advance")

	MetaSave.seasons_won = saved_seasons
	MetaSave._save()

	if _fails.is_empty():
		print("SEASON TEST: ALL PASS")
	else:
		for f in _fails:
			print("  FAIL  %s" % f)
		print("SEASON TEST: %d FAILED" % _fails.size())
	get_tree().quit()

func _check(label: String, ok: bool) -> void:
	if ok:
		print("  PASS  %s" % label)
	else:
		_fails.append(label)
