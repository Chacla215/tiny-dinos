extends Node
## Throwaway: snapshot the select screen (with a CPU opponent so the difficulty
## line shows) to verify the FLOPPY MODE toggle line lays out without overlap.
##   /opt/homebrew/bin/godot scenes/ui_shot.tscn -- --shot
## Delete after verifying.

func _ready() -> void:
	if "--shot" not in OS.get_cmdline_user_args():
		return
	MatchConfig.player_count = 4          # show teams + difficulty lines too
	MatchConfig.cpu_players = {"p1": false, "p2": true, "p3": true, "p4": true}
	MatchConfig.floppy_mode = true        # so the line reads ON (lit)
	var sel: Node = load("res://scenes/select.tscn").instantiate()
	get_tree().root.add_child.call_deferred(sel)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = sel
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("/tmp/ralph")
	img.save_png("/tmp/ralph/select_floppy.png")
	print("shot -> /tmp/ralph/select_floppy.png")
	get_tree().quit()
