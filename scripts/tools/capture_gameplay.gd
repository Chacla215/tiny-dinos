extends Node2D
# Throwaway capture harness — boots a 4-CPU FFA on a chosen arena so we can record
# real gameplay footage (for the trailer + QA) with no gamepad + no menus.
# Run windowed with Movie Maker mode (fixes delta at 1/fps → smooth regardless of
# encode time):
#   /opt/homebrew/bin/godot --write-movie /tmp/td_capture/beach.avi \
#       scenes/_capture_gameplay.tscn -- --seconds 12 --arena beach
# --arena: beach|lava|floes|falls|springs|purple (default beach)
# --mode:  rounds|koth|eggs|sumo|bombtag|beast|flood (default rounds) — so mode
#          clips (the sumo dohyo, the flood tide) can be REAL footage too.

const ARENAS := {
	"beach": ["res://scenes/arena_beach.tscn", "beauty_beach"],
	"lava": ["res://scenes/arena_lava.tscn", "laughing_lava"],
	"floes": ["res://scenes/arena_floes.tscn", "iciest_age"],
	"falls": ["res://scenes/arena_falls.tscn", "white_water_falls"],
	"springs": ["res://scenes/arena_springs.tscn", "sunny_springs"],
	"purple": ["res://scenes/arena_purple.tscn", "purple_fields"],
}

func _arg(name: String, dflt: String) -> String:
	var args := OS.get_cmdline_user_args()
	var idx := args.find(name)
	if idx != -1 and idx + 1 < args.size():
		return args[idx + 1]
	return dflt

func _ready() -> void:
	var secs := float(_arg("--seconds", "12"))
	var arena_key := _arg("--arena", "beach")
	var entry: Array = ARENAS.get(arena_key, ARENAS["beach"])

	MatchConfig.player_count = 4
	MatchConfig.cpu_players = {"p1": true, "p2": true, "p3": true, "p4": true, "p5": false, "p6": false}
	MatchConfig.cpu_difficulty = "hard"
	# Spread signatures across the four so the passives show on camera (spino =
	# JESSIE up front so the newest dino features in every capture).
	MatchConfig.dino_choices = {"p1": "spino", "p2": "ralph", "p3": "raptor", "p4": "anky", "p5": "pterry", "p6": "trike"}
	MatchConfig.island = entry[1]
	MatchConfig.game_mode = _arg("--mode", "rounds")
	MatchConfig.teams_enabled = false

	var packed: PackedScene = load(entry[0])
	var arena := packed.instantiate()
	if "kos_to_win" in arena:
		arena.kos_to_win = 99  # never end the match mid-capture
	# current_scene must be a DIRECT child of root. Wait one frame so root finishes its
	# own setup (can't add_child to a node still setting up), then parent the arena to
	# root and promote it — otherwise Godot errors and can bail the record early.
	await get_tree().process_frame
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena

	await get_tree().create_timer(secs).timeout
	# --shot: save a single PNG screenshot (run WINDOWED, no --write-movie) — tiny file,
	# for quickly eyeballing arena layout without a giant uncompressed movie.
	if "--shot" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var img := get_tree().root.get_texture().get_image()
		img.save_png("/tmp/td_capture/shot_%s.png" % arena_key)
	get_tree().quit()
