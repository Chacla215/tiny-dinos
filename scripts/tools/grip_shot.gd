extends Node
## Throwaway grip-anchor audit: drop fighters onto an island, arm each with a
## MACE, and snapshot so the per-dino grip_offset (held-weapon anchor) can be
## judged from real pixels — is it in the hand / wing-claw / mouth like it should?
## Run WINDOWED (headless can't draw):
##   /opt/homebrew/bin/godot scenes/grip_shot.tscn -- --shot
## Saves /tmp/ralph/grip_<set>.png. Delete once grip offsets are tuned.

const ARENA := "res://scenes/arena_beach.tscn"

# Two passes so all six dinos are covered (arena has 4 player slots).
const SETS := {
	"a": ["ralph", "raptor", "trike", "pterry"],
	"b": ["bronto", "anky", "trike", "pterry"],
}

func _ready() -> void:
	if "--shot" not in OS.get_cmdline_user_args():
		return
	get_window().size = Vector2i(1280, 720)
	MatchConfig.player_count = 4
	MatchConfig.cpu_players = {"p1": false, "p2": false, "p3": false, "p4": false}
	MatchConfig.teams_enabled = false
	MatchConfig.island = "beauty_beach"
	# Let the tree finish setting up before the first arena add_child (else the
	# first shot races the scene init and comes out blank).
	await get_tree().process_frame
	await get_tree().process_frame
	for set_name in SETS:
		await _shoot(set_name, SETS[set_name])
	get_tree().quit()

func _shoot(set_name: String, dinos: Array) -> void:
	MatchConfig.dino_choices = {"p1": dinos[0], "p2": dinos[1], "p3": dinos[2], "p4": dinos[3]}
	var arena: Node = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	await get_tree().process_frame
	await get_tree().process_frame
	# Spread them out so each held weapon is clearly visible, all facing right.
	var spots := [Vector2(320, 380), Vector2(560, 380), Vector2(800, 380), Vector2(1000, 380)]
	var i := 0
	for pid in ["Player1", "Player2", "Player3", "Player4"]:
		var p: Node = arena.get_node_or_null(pid)
		if p != null and p.visible:
			p.is_cpu = false
			p.global_position = spots[i]
			p.facing = Vector2.RIGHT
			# Force a mace into the hand so weapon_visual renders at grip_offset.
			p.weapons = ["mace", "mace"]
			p.active_weapon = 0
			p._refresh_weapon()
			i += 1
	# Let physics run a few frames so weapon_visual.position settles at grip_offset.
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("/tmp/ralph")
	img.save_png("/tmp/ralph/grip_%s.png" % set_name)
	print("shot -> /tmp/ralph/grip_%s.png" % set_name)
	arena.queue_free()
	await get_tree().process_frame
