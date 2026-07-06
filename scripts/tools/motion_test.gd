extends Node
## Throwaway feel audit: render ONE idle dino big and snapshot it at several
## moments so the rig's ambient motion (head/limb/breathe) can be SEEN as a strip.
## Run WINDOWED:  /opt/homebrew/bin/godot scenes/motion_test.tscn -- --shot [dino]
## Saves /tmp/ralph/motion_<dino>_<n>.png (n=0..3). Delete after tuning.

func _ready() -> void:
	if "--shot" not in OS.get_cmdline_user_args():
		return
	var dino := "raptor"
	var args := OS.get_cmdline_user_args()
	var i := args.find("--shot")
	if i >= 0 and i + 1 < args.size() and not args[i + 1].begins_with("--"):
		dino = args[i + 1]
	get_window().size = Vector2i(720, 720)
	MatchConfig.player_count = 1
	MatchConfig.cpu_players = {"p1": false, "p2": false, "p3": false, "p4": false}
	MatchConfig.teams_enabled = false
	MatchConfig.island = "beauty_beach"
	MatchConfig.dino_choices = {"p1": dino}
	await get_tree().process_frame
	await get_tree().process_frame
	var arena: Node = load("res://scenes/arena_beach.tscn").instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	await get_tree().process_frame
	await get_tree().process_frame
	# Keep only Player1, center it, scale up, freeze it idle.
	for pid in ["Player2", "Player3", "Player4"]:
		var q: Node = arena.get_node_or_null(pid)
		if q != null:
			q.visible = false
			q.set_physics_process(false)
	var p: Node = arena.get_node_or_null("Player1")
	p.is_cpu = false
	p.global_position = Vector2(640, 380)
	var cam: Camera2D = arena.get_node_or_null("Camera2D")
	if cam != null:
		cam.position = Vector2(640, 360)
		cam.zoom = Vector2(2.2, 2.2)
	# Snapshot at four different idle phases so the motion range is visible.
	for n in range(4):
		await get_tree().create_timer(0.45).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute("/tmp/ralph")
		img.save_png("/tmp/ralph/motion_%s_%d.png" % [dino, n])
		print("shot -> /tmp/ralph/motion_%s_%d.png" % [dino, n])
	get_tree().quit()
