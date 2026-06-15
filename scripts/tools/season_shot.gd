extends Node
## Throwaway: snapshot the SEASON setup screen (team-size line + your-team panels,
## foes hidden) to verify the layout. Run windowed (headless can't draw):
##   /opt/homebrew/bin/godot scenes/season_shot.tscn -- --shot
## Saves /tmp/ralph/season_setup.png. Delete after verifying.

func _ready() -> void:
	if "--shot" not in OS.get_cmdline_user_args():
		return
	MatchConfig.season_setup = true
	MatchConfig.gauntlet_setup = false
	var sel: Node = load("res://scenes/select.tscn").instantiate()
	get_tree().root.add_child.call_deferred(sel)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = sel
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("/tmp/ralph")
	img.save_png("/tmp/ralph/season_setup.png")
	print("shot -> /tmp/ralph/season_setup.png")
	get_tree().quit()
