extends Node
## Throwaway probe for the open feel question: does a FLOPPY brawl actually END,
## or do two competent fighters just bounce off each other forever? Runs two HARD
## CPUs to a real match resolution (round_wins / match_over in main.gd) and reports
## time-to-first-KO, KOs/min, and whether the match resolved inside the cap — the
## SAME matchup in floppy vs precise, on a ring-out arena and an HP arena, so the
## question is answered by comparison, not a lone number.
## Headless:  /opt/homebrew/bin/godot --headless --quit-after 40000 scenes/floppy_ko_probe.tscn
## Delete with the other floppy throwaways once feel is locked.

const CAP := 60.0   # seconds; a match that doesn't resolve by here counts "unresolved"

func _ready() -> void:
	MatchConfig.player_count = 2
	MatchConfig.teams_enabled = false
	MatchConfig.cpu_players = {"p1": true, "p2": true, "p3": false, "p4": false}
	MatchConfig.dino_choices["p1"] = "raptor"
	MatchConfig.dino_choices["p2"] = "ralph"
	print("KO resolution — raptor vs ralph, HARD vs HARD, cap %ds" % int(CAP))
	print("%-14s %-8s %10s %8s %12s" % ["arena", "mode", "1stKO_s", "KOs/min", "match_end_s"])
	for scene in ["res://scenes/arena_beach.tscn", "res://scenes/main.tscn"]:
		for floppy in [true, false]:
			await _run(scene, floppy)
	get_tree().quit()

func _run(scene_path: String, floppy: bool) -> void:
	MatchConfig.floppy_mode = floppy
	var arena: Node = load(scene_path).instantiate()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	# dino.die() reports KOs via get_tree().current_scene.report_ko — without this the
	# arena never hears about a kill and every match falsely reads UNRESOLVED.
	get_tree().current_scene = arena
	for pid in ["Player1", "Player2"]:
		var p: Node = arena.get_node(pid)
		if p.ai != null:
			p.ai.apply_difficulty("hard")

	var t := 0.0
	var first_ko := -1.0
	var prev_kos := 0
	var total_kos := 0
	var end_t := -1.0
	while t < CAP:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var kos := 0
		for v in arena.round_wins.values():
			kos += int(v)
		if kos > prev_kos:
			if first_ko < 0.0:
				first_ko = t
			total_kos += (kos - prev_kos)
			prev_kos = kos
		if arena.match_over:
			end_t = t
			break

	var per_min := (total_kos / t) * 60.0 if t > 0.0 else 0.0
	var first_s := "%.1f" % first_ko if first_ko >= 0.0 else "none"
	var end_s := "%.1f" % end_t if end_t >= 0.0 else "UNRESOLVED"
	print("%-14s %-8s %10s %8.1f %12s" % [
		scene_path.get_file().get_basename(),
		"floppy" if floppy else "precise", first_s, per_min, end_s])
	arena.queue_free()
	await get_tree().process_frame
