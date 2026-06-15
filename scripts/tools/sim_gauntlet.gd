extends Node
## Throwaway balance sim for the SOLO gauntlet under floppy. The gauntlet keeps late
## waves threatening via enemy HP + damage scaling — but floppy kills by RING-OUT
## (throw/knockdown-slide off the edge), which bypasses HP entirely and the enemy's
## knockback never scales. So the curve should be FLAT under floppy on a ring-out
## arena and only bite on a confined (HP) arena. This pits a fixed player-proxy
## (normal AI, no upgrades) vs a wave-scaled foe (real gauntlet difficulty + mults),
## floppy vs precise, low wave vs high wave, and tallies the win share.
## Headless:  /opt/homebrew/bin/godot --headless --quit-after 40000 scenes/sim_gauntlet.tscn
## Delete with the other throwaway probes once balance is locked.

const SECS := 40.0
const WAVES := [0, 8, 16]
# Set to [true] to focus the floppy curve (the broken case) within the frame cap.
const MODES := [true]
const ARENAS := {"RINGOUT(beach)": "res://scenes/arena_beach.tscn", "CONFINED(lava)": "res://scenes/arena_lava.tscn"}

func _wave_diff(w: int) -> String:
	return "easy" if w < 2 else ("normal" if w < 5 else "hard")

func _ready() -> void:
	print("gauntlet balance — player-proxy(normal) vs wave-scaled foe, %ds, win%% for the FOE" % int(SECS))
	print("(foe win%% should RISE with wave if the curve works; flat = broken)")
	print("%-16s %-8s %6s %10s" % ["arena", "mode", "wave", "foe_win%"])
	for arena_name in ARENAS:
		for floppy in MODES:
			for w in WAVES:
				await _run(arena_name, ARENAS[arena_name], floppy, w)
	get_tree().quit()

func _run(arena_name: String, scene_path: String, floppy: bool, wave: int) -> void:
	MatchConfig.floppy_mode = floppy
	MatchConfig.player_count = 2
	MatchConfig.teams_enabled = false
	MatchConfig.cpu_players = {"p1": true, "p2": true, "p3": false, "p4": false}
	MatchConfig.gauntlet = true
	MatchConfig.gauntlet_wave = wave
	MatchConfig.gauntlet_player_dino = "ralph"
	MatchConfig.gauntlet_upgrades = []        # player proxy carries no draft
	MatchConfig.gauntlet_player_hp = -1
	MatchConfig.dino_choices = {"p1": "ralph", "p2": "raptor", "p3": "trike", "p4": "pterry"}

	var arena: Node = load(scene_path).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena          # KOs route via current_scene.report_ko
	await get_tree().process_frame
	await get_tree().process_frame
	if "kos_to_win" in arena:
		arena.kos_to_win = 999                 # never end; just tally KOs over the window
	# p1 = the player proxy (fixed middling skill); p2 = the foe at the wave's tier.
	var p1: Node = arena.get_node("Player1")
	var p2: Node = arena.get_node("Player2")
	if p1.ai != null:
		p1.ai.apply_difficulty("normal")
	if p2.ai != null:
		p2.ai.apply_difficulty(_wave_diff(wave))

	var t := 0.0
	while t < SECS:
		await get_tree().physics_frame
		t += 1.0 / 60.0

	var pw: int = int(arena.round_wins.get("p1", 0))
	var fw: int = int(arena.round_wins.get("p2", 0))
	var total: int = pw + fw
	var foe_pct := (100.0 * fw / total) if total > 0 else 0.0
	print("%-16s %-8s %6d %9.0f%%   (foe %d : %d player, %d KOs)" % [
		arena_name, "floppy" if floppy else "precise", wave, foe_pct, fw, pw, total])
	MatchConfig.gauntlet = false
	arena.queue_free()
	await get_tree().process_frame
