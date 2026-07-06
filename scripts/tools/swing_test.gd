extends Node
## Throwaway audit for the held-weapon SWING: arm a dino with a mace, trigger a
## light attack, and snapshot the full arc so windup(cock)->active(chop)->recovery
## reads right (and mirrors when facing left).
## Run WINDOWED:  /opt/homebrew/bin/godot scenes/swing_test.tscn -- --shot [dino] [left]
## Saves /tmp/ralph/swing_<dino>_<n>.png. Delete after tuning.

func _ready() -> void:
	if "--shot" not in OS.get_cmdline_user_args():
		return
	var args := OS.get_cmdline_user_args()
	var dino := "raptor"
	var i := args.find("--shot")
	if i >= 0 and i + 1 < args.size() and not args[i + 1].begins_with("--"):
		dino = args[i + 1]
	var face_left := "left" in args
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
	for pid in ["Player2", "Player3", "Player4"]:
		var q: Node = arena.get_node_or_null(pid)
		if q: q.visible = false; q.set_physics_process(false)
	var p: Node = arena.get_node_or_null("Player1")
	p.is_cpu = false
	p.global_position = Vector2(640, 380)
	p.facing = Vector2.LEFT if face_left else Vector2.RIGHT
	p.weapons = ["mace", "mace"]
	p.active_weapon = 0
	p._refresh_weapon()
	var cam: Camera2D = arena.get_node_or_null("Camera2D")
	if cam: cam.position = Vector2(640, 360); cam.zoom = Vector2(2.2, 2.2)
	await get_tree().process_frame
	p.start_attack(false)
	# Sample the whole swing (~0.5s) so cock/chop/settle are all captured.
	for n in range(9):
		await get_tree().create_timer(0.05).timeout
		# keep facing pinned (no AI, but be safe)
		p.facing = Vector2.LEFT if face_left else Vector2.RIGHT
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute("/tmp/ralph")
		var tag := "L" if face_left else "R"
		img.save_png("/tmp/ralph/swing_%s_%s_%d.png" % [dino, tag, n])
	print("done swing shots")
	get_tree().quit()
