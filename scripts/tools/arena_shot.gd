extends Node
## Throwaway art-cohesion audit: drop 4 idle fighters into each island and snapshot
## the real in-match composite (painterly fighters on the pixel-art arena bg) so the
## style read can be judged from actual pixels, not guesswork.
## Run WINDOWED (headless can't draw):
##   /opt/homebrew/bin/godot scenes/arena_shot.tscn -- --shot
## Saves /tmp/ralph/arena_<name>.png. Delete after the audit.

const ARENAS := {
	"lava": "res://scenes/arena_lava.tscn",
	"beach": "res://scenes/arena_beach.tscn",
	"springs": "res://scenes/arena_springs.tscn",
	"falls": "res://scenes/arena_falls.tscn",
	"purple": "res://scenes/arena_purple.tscn",
	"floes": "res://scenes/arena_floes.tscn",
}

func _ready() -> void:
	if "--shot" not in OS.get_cmdline_user_args():
		return
	get_window().size = Vector2i(1280, 720)
	MatchConfig.player_count = 4
	MatchConfig.cpu_players = {"p1": false, "p2": false, "p3": false, "p4": false}
	MatchConfig.teams_enabled = false
	MatchConfig.dino_choices = {"p1": "ralph", "p2": "raptor", "p3": "trike", "p4": "pterry"}
	for name in ARENAS:
		await _shoot(name, ARENAS[name])
	get_tree().quit()

const ISLAND_ID := {
	"lava": "laughing_lava", "beach": "beauty_beach", "springs": "sunny_springs",
	"falls": "white_water_falls", "purple": "purple_fields", "floes": "iciest_age",
}

func _shoot(name: String, path: String) -> void:
	MatchConfig.island = ISLAND_ID.get(name, "")  # so the per-island play-calm strength is right
	var arena: Node = load(path).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	await get_tree().process_frame
	await get_tree().process_frame
	# Freeze the fighters in a readable idle spread so the shot is clean.
	var spots := [Vector2(420, 360), Vector2(640, 320), Vector2(820, 380), Vector2(540, 300)]
	var i := 0
	for pid in ["Player1", "Player2", "Player3", "Player4"]:
		var p: Node = arena.get_node_or_null(pid)
		if p != null and p.visible:
			p.is_cpu = false
			p.global_position = spots[i % spots.size()]
			i += 1
	await get_tree().create_timer(0.6).timeout   # let layout + rig settle
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("/tmp/ralph")
	img.save_png("/tmp/ralph/arena_%s.png" % name)
	print("shot -> /tmp/ralph/arena_%s.png" % name)
	arena.queue_free()
	await get_tree().process_frame
