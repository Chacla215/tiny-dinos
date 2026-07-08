extends Node2D
# Throwaway DEV boot for CAREER mode (the real title->career entry is step 4).
# Begins a fresh test career, optionally pre-levels it, and launches the current
# journey stop's match. Run windowed to actually play it:
#   /opt/homebrew/bin/godot scenes/_career_boot.tscn -- --dino ralph --level 4
# Flags: --dino <id>  --level <pips of POWER to pre-buy>  --stop <index>
# NOTE: writes to the real save's [career] section (other progress is preserved).

func _arg(name: String, dflt: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(name)
	return a[i + 1] if i != -1 and i + 1 < a.size() else dflt

func _ready() -> void:
	var dino := _arg("--dino", "ralph")
	var lvl := int(_arg("--level", "0"))
	var stop := int(_arg("--stop", "0"))
	MetaSave.career_begin(dino, "REX")
	MetaSave.career_xp = 5000
	for i in range(lvl):
		MetaSave.career_train("power")
	MetaSave.career_stop = clampi(stop, 0, MatchConfig.CAREER_STOP_COUNT - 1)
	MatchConfig.career = true
	print("CAREER BOOT: %s (LV %d) at stop %d" % [dino, MetaSave.career_level(), MetaSave.career_stop])
	# Default: boot into the DEN (the full loop). Pass --fight to skip to a match.
	if "--fight" in OS.get_cmdline_user_args():
		MatchConfig.career_start_match()
		var packed: PackedScene = load(MatchConfig.career_scene())
		var arena: Node = packed.instantiate()
		await get_tree().process_frame  # let the arena run its own _ready first
		get_tree().root.add_child(arena)
		get_tree().current_scene = arena
		queue_free()
	else:
		get_tree().change_scene_to_file.call_deferred("res://scenes/career_home.tscn")
