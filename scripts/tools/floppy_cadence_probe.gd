extends Node
## Throwaway FEEL probe for the floppy VERB cadence — do the Gang-Beasts moments
## (knockdowns, grabs, throws, KOs) actually fire at a fun rate in a real brawl, or
## is something pathological (every hit floors / nobody ever grabs)? Runs two HARD
## CPUs in floppy for ~40s on a couple of arenas and tallies the events per minute.
## Headless:  /opt/homebrew/bin/godot --headless --quit-after 6000 scenes/floppy_cadence_probe.tscn
## Delete with the other floppy throwaways once feel is locked.

const SECS := 40.0

func _ready() -> void:
	MatchConfig.floppy_mode = true
	MatchConfig.player_count = 2
	MatchConfig.teams_enabled = false
	MatchConfig.cpu_players = {"p1": true, "p2": true, "p3": false, "p4": false}
	MatchConfig.dino_choices["p1"] = "raptor"
	MatchConfig.dino_choices["p2"] = "ralph"
	print("floppy verb cadence (HARD vs HARD, %ds, per-minute rates; KO resolution NOT measured here)" % int(SECS))
	print("%-14s %7s %7s %7s" % ["arena", "knockdn", "grabs", "throws"])
	for scene in ["res://scenes/main.tscn", "res://scenes/arena_beach.tscn"]:
		await _run(scene)
	get_tree().quit()

func _run(scene_path: String) -> void:
	var arena: Node = load(scene_path).instantiate()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var p1: Node = arena.get_node("Player1")
	var p2: Node = arena.get_node("Player2")
	for p in [p1, p2]:
		if p.ai != null:
			p.ai.apply_difficulty("hard")
	var fighters := [p1, p2]
	var was_down := {p1: false, p2: false}
	var was_grab := {p1: false, p2: false}
	var knockdowns := 0
	var grabs := 0
	var throws := 0
	var frames := int(SECS * 60.0)
	for i in frames:
		await get_tree().physics_frame
		for f in fighters:
			var d: bool = f.is_downed
			if d and not was_down[f]:
				knockdowns += 1
			was_down[f] = d
			var g: bool = f.grabbing != null
			if g and not was_grab[f]:
				grabs += 1
			# a grab that ended while the foe is downed ~= a throw landed
			elif was_grab[f] and not g:
				throws += 1
			was_grab[f] = g
	var per_min := 60.0 / SECS
	print("%-14s %7.1f %7.1f %7.1f" % [
		scene_path.get_file().get_basename(),
		knockdowns * per_min, grabs * per_min, throws * per_min])
	arena.queue_free()
	await get_tree().process_frame
