extends Node2D
# Throwaway capture harness — boots a 4-CPU FFA on a chosen arena so we can record
# real gameplay footage (for the trailer + QA) with no gamepad + no menus.
# Run windowed with Movie Maker mode (fixes delta at 1/fps → smooth regardless of
# encode time):
#   /opt/homebrew/bin/godot --write-movie /tmp/td_capture/beach.avi \
#       scenes/_capture_gameplay.tscn -- --seconds 12 --arena beach
# --arena: beach|lava|floes|falls|springs|purple (default beach)

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
	# Spread signatures across the four so the passives show on camera.
	MatchConfig.dino_choices = {"p1": "ralph", "p2": "raptor", "p3": "anky", "p4": "bronto", "p5": "pterry", "p6": "trike"}
	MatchConfig.island = entry[1]
	MatchConfig.game_mode = "rounds"
	MatchConfig.teams_enabled = false

	var packed: PackedScene = load(entry[0])
	var arena := packed.instantiate()
	if "kos_to_win" in arena:
		arena.kos_to_win = 99  # never end the match mid-capture
	add_child(arena)
	get_tree().current_scene = arena  # die()/effects route through current_scene

	await get_tree().create_timer(secs).timeout
	get_tree().quit()
