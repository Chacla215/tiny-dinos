extends SceneTree

# Throwaway capture tool: boot straight into an arena (windowed — headless can't
# render), hold a couple of seconds, save a frame, quit. The debug safe-zone ring
# is forced ON so shots double as ring-out-boundary alignment checks.
#
#   /opt/homebrew/bin/godot -s scripts/tools/shot_arena.gd -- <island> [players]
#
# Islands: beauty_beach, laughing_lava, iciest_age, white_water_falls,
# sunny_springs, purple_fields. Saves to /tmp/arena_shots/<island>.png.
func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame  # let autoloads settle
	var args := OS.get_cmdline_user_args()
	var island: String = args[0] if args.size() > 0 else "beauty_beach"
	var mc: Node = root.get_node("/root/MatchConfig")
	mc.island = island
	mc.player_count = int(args[1]) if args.size() > 1 else 4
	var scene_path: String = mc.ISLAND_SCENES[island]
	var arena: Node = load(scene_path).instantiate()
	arena.debug_draw_safe_zone = true  # set BEFORE _ready builds the outline
	root.add_child(arena)
	for i in 150:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("/tmp/arena_shots")
	var out := "/tmp/arena_shots/%s.png" % island
	img.save_png(out)
	print("SAVED ", out)
	quit()
