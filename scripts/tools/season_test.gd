extends Node
## Throwaway functional test for SEASON MODE (Phase 1). Exercises the state machine
## (schedule build, mode cycle, matchday seating, advance->champion) + the unlock,
## and the main.gd matchday end flow on a real arena instance.
## Headless:  /opt/homebrew/bin/godot --headless scenes/season_test.tscn
## Delete once season feel is locked.

var _fails: Array = []

func _ready() -> void:
	# Don't pollute the real save: snapshot + restore the season meta around the test.
	var saved_seasons: int = MetaSave.seasons_won
	var saved_div: int = MetaSave.best_division
	var saved_titles: Array = MetaSave.season_titles_by_division.duplicate()

	# --- 2v2 season: schedule + seating ---
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "raptor", "human": true}], 2, 0)
	_check("season flag set", MatchConfig.season)
	_check("schedule has 5 matchdays", MatchConfig.season_schedule.size() == 5)
	var modes: Array = []
	for md in MatchConfig.season_schedule:
		modes.append(md["mode"])
	_check("modes cycle rounds->koth->eggs->sumo->flood", modes == ["rounds", "koth", "eggs", "sumo", "flood"])
	# --- Phase 2 A: named rival teams on their home islands, in escalating order ---
	var rivals: Array = []
	var rival_islands_ok := true
	for i in MatchConfig.season_schedule.size():
		var md: Dictionary = MatchConfig.season_schedule[i]
		rivals.append(md.get("rival", ""))
		if md["island"] != MatchConfig.RIVAL_TEAMS[i]["island"]:
			rival_islands_ok = false
	_check("each matchday names a rival team", rivals.size() == 5 and not ("" in rivals))
	_check("rivals fought on their home islands", rival_islands_ok)
	_check("finale is the boss rival", rivals[4] == MatchConfig.RIVAL_TEAMS[4]["name"])
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
	MatchConfig.start_season([{"dino": "anky", "human": true}], 1, 0)
	_check("1v1 = 2 fighters", MatchConfig.player_count == 2)
	_check("1v1 teams off", not MatchConfig.teams_enabled)
	_check("1v1 foe is CPU", MatchConfig.cpu_players["p2"])

	# --- CPU ally (human flag false) ---
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "trike", "human": false}], 2, 0)
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

	# --- Phase 2 C: perk draft options exclude HP-carry-only heal perks ---
	var opts: Array = MatchConfig.season_draft_options()
	_check("draft offers 3 team perks", opts.size() == 3)
	var no_heal := true
	for id in opts:
		if MatchConfig.UPGRADES[id].has("heal_now") or MatchConfig.UPGRADES[id].has("wave_heal"):
			no_heal = false
	_check("draft excludes heal-only perks", no_heal)

	# --- Phase 3: divisions raise the difficulty floor + record per-division titles ---
	MetaSave.best_division = 2   # unlock LEGEND so we can start a campaign there
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "raptor", "human": true}], 2, 2)
	_check("season starts in the chosen division", MatchConfig.season_division == 2)
	# SEASON_DIFFS base shifted +2 along DIFF_LADDER: matchday 0 "easy" -> "hard".
	_check("division raises the difficulty floor", MatchConfig.season_schedule[0]["difficulty"] == "hard")
	_check("finale stays brutal at the top division", MatchConfig.season_schedule[4]["difficulty"] == "brutal")
	MetaSave.best_division = 1
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "raptor", "human": true}], 2, 2)
	_check("requested division clamps to what's unlocked", MatchConfig.season_division == 1)
	MetaSave.best_division = 0
	MetaSave.season_titles_by_division = [0, 0, 0]
	MetaSave.seasons_won = 0
	MetaSave.record_season(0)
	_check("championship tallied in its division", MetaSave.season_titles_by_division[0] == 1)
	_check("winning a division promotes you", MetaSave.best_division == 1)

	# --- Phase 3: persistent squad + fatigue ---
	MetaSave.best_division = 0
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "raptor", "human": true}], 2, 0)
	_check("squad = fielded + 1 reserve", MatchConfig.season_squad.size() == 3)
	_check("starters fielded for matchday 1", MatchConfig.season_field == [0, 1])
	_check("reserve isn't a starter", not (MatchConfig.season_squad[2]["dino"] in ["ralph", "raptor"]))
	_check("everyone fresh at kickoff", MatchConfig.season_field_fatigue["p1"] == 0)
	MatchConfig.season_advance()
	_check("fielded fighter tires after a matchday", int(MatchConfig.season_squad[0]["fatigue"]) == 1)
	_check("benched reserve stays rested", int(MatchConfig.season_squad[2]["fatigue"]) == 0)
	_check("matchday 2 seats the new fatigue", MatchConfig.season_field_fatigue["p1"] == 1)
	MatchConfig.season_set_field([2, 1])   # rest the tired starter, field the reserve
	MatchConfig.season_advance()
	_check("rotation lets the rested starter recover", int(MatchConfig.season_squad[0]["fatigue"]) == 0)
	_check("fatigue speed penalty is mild", MatchConfig.season_fatigue_speed_mult(1) > 0.9 and MatchConfig.season_fatigue_speed_mult(1) < 1.0)
	_check("fatigue penalty is floored", MatchConfig.season_fatigue_speed_mult(99) >= 0.70)

	# --- Phase 3: 3v3 seating (Feature 5) ---
	MetaSave.best_division = 0
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "raptor", "human": false}, {"dino": "trike", "human": false}], 3, 0, "bronto")
	_check("3v3 fields six fighters", MatchConfig.player_count == 6)
	_check("3v3 squad = 4 (three + reserve)", MatchConfig.season_squad.size() == 4)
	_check("3v3 your side is A", MatchConfig.teams["p1"] == "a" and MatchConfig.teams["p2"] == "a" and MatchConfig.teams["p3"] == "a")
	_check("3v3 foes are B", MatchConfig.teams["p4"] == "b" and MatchConfig.teams["p5"] == "b" and MatchConfig.teams["p6"] == "b")
	_check("3v3 you pilot p1, allies are CPU", MatchConfig.cpu_players["p1"] == false and MatchConfig.cpu_players["p2"] and MatchConfig.cpu_players["p3"])
	_check("3v3 all foes are CPU", MatchConfig.cpu_players["p4"] and MatchConfig.cpu_players["p5"] and MatchConfig.cpu_players["p6"])
	var foe_dinos: Array = [MatchConfig.dino_choices["p4"], MatchConfig.dino_choices["p5"], MatchConfig.dino_choices["p6"]]
	_check("3v3 seats three foes from the rival roster", foe_dinos == MatchConfig.RIVAL_TEAMS[0]["dinos"])

	# --- main.gd matchday end flow + perk application + fatigue on a real arena ---
	MetaSave.seasons_won = saved_seasons   # restore before the in-engine bit
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "raptor", "human": true}], 2, 0)
	MatchConfig.season_perks = ["sharp_claws"]   # +25% attack dmg — your side only
	MatchConfig.season_field_fatigue["p1"] = 3   # field p1 tired to verify the in-arena dip
	var arena: Node = load("res://scenes/arena_beach.tscn").instantiate()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = arena
	var p1: Node = arena.get_node("Player1")
	var p2: Node = arena.get_node("Player2")
	var p3: Node = arena.get_node("Player3")
	var ralph_base: int = int(MatchConfig.DINOS["ralph"]["attack_damage"])
	var raptor_base_speed: float = float(MatchConfig.DINOS["raptor"]["max_speed"])
	_check("team perk boosts your side", p1.attack_damage > ralph_base)
	_check("team perk skips foes", p3.attack_damage == ralph_base)
	_check("a fatigued fielded fighter is slower", p1.max_speed < float(MatchConfig.DINOS["ralph"]["max_speed"]))
	_check("a rested ally is unslowed", is_equal_approx(p2.max_speed, raptor_base_speed))
	arena.end_match(p1, "P1")
	_check("matchday win -> advance state", arena.season_end == "advance")

	MetaSave.seasons_won = saved_seasons
	MetaSave.best_division = saved_div
	MetaSave.season_titles_by_division = saved_titles
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
