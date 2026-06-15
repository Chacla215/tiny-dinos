extends Node
## Throwaway: snapshot the SEASON screens to verify layout.
##   /opt/homebrew/bin/godot scenes/season_shot.tscn -- --shot
## Saves /tmp/ralph/season_setup.png (team builder) + season_perkdraft.png
## (the between-matchday team-perk draft overlay). Delete after verifying.

func _ready() -> void:
	if "--shot" not in OS.get_cmdline_user_args():
		return
	get_window().size = Vector2i(1280, 720)
	await _shot_setup()
	await _shot_perkdraft()
	get_tree().quit()

func _shot_setup() -> void:
	MatchConfig.season_setup = true
	MatchConfig.gauntlet_setup = false
	var sel: Node = load("res://scenes/select.tscn").instantiate()
	get_tree().root.add_child.call_deferred(sel)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = sel
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	_save("season_setup")
	sel.queue_free()
	await get_tree().process_frame

func _shot_perkdraft() -> void:
	# Win a non-final matchday -> the team-perk draft overlay opens.
	MatchConfig.season_setup = false
	MatchConfig.start_season([{"dino": "ralph", "human": true}, {"dino": "raptor", "human": true}], 2, 0)
	var arena: Node = load("res://scenes/arena_beach.tscn").instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	await get_tree().process_frame
	await get_tree().process_frame
	arena.end_match(arena.get_node("Player1"), "P1")   # matchday 0 win -> _open_season_draft
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	_save("season_perkdraft")
	arena.queue_free()
	await get_tree().process_frame

func _save(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("/tmp/ralph")
	img.save_png("/tmp/ralph/%s.png" % name)
	print("shot -> /tmp/ralph/%s.png" % name)
