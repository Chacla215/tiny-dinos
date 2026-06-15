extends Node
## Throwaway FEEL probe for FLOPPY locomotion constants (floppy_accel/friction/
## speed_mult on dino.gd). Drives a fighter with SIMULATED stick input (the real
## human code path) and measures the numbers that define "loose but controllable":
##   top speed reached, glide distance + stop time after release, reverse time.
## Runs per dino so we see the spread across the weight classes.
## Headless:  /opt/homebrew/bin/godot --headless --quit-after 6000 scenes/floppy_feel_probe.tscn
## Delete with the other floppy throwaways once feel is locked.

func _ready() -> void:
	MatchConfig.player_count = 2
	MatchConfig.teams_enabled = false
	MatchConfig.cpu_players = {"p1": false, "p2": false, "p3": false, "p4": false}
	print("floppy_mode=%s  (constants: see dino.gd floppy_*)" % MatchConfig.floppy_mode)
	print("%-8s %6s %8s %8s %9s" % ["dino", "top", "glide", "stop_s", "rev_s"])
	for dino in ["raptor", "ralph", "bronto"]:
		await _probe(dino)
	get_tree().quit()

func _probe(dino: String) -> void:
	MatchConfig.dino_choices["p1"] = dino
	var arena: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var p1: Node = arena.get_node("Player1")
	p1.is_cpu = false
	var p2: Node = arena.get_node("Player2")
	p2.is_cpu = false
	p2.global_position = Vector2(80, 80)
	var top: float = p1.max_speed * p1.floppy_speed_mult

	# --- GLIDE / STOP: inject top speed on uniform spawn ground (no accel-travel
	# into other surface zones), release, coast to rest. Small displacement = clean
	# locomotion-constant read, not an arena-surface read. ---
	p1.global_position = Vector2(300, 360)
	p1.velocity = Vector2(top, 0)
	await _phys(1)
	var rel_x: float = p1.global_position.x
	var surf0: int = p1.current_surface
	var stop_frames := 0
	while p1.velocity.length() > 10.0 and stop_frames < 240:
		await _phys(1)
		stop_frames += 1
	var glide := absf(p1.global_position.x - rel_x)
	var stop_s := stop_frames / 60.0

	# --- REVERSE: inject top speed right, hold left, time until vel.x crosses 0 ---
	p1.global_position = Vector2(300, 360)
	p1.velocity = Vector2(top, 0)
	Input.action_press("p1_left")
	await _phys(1)
	var rev_frames := 0
	while p1.velocity.x > 0.0 and rev_frames < 120:
		await _phys(1)
		rev_frames += 1
	Input.action_release("p1_left")
	var rev_s := rev_frames / 60.0

	print("%-8s %6.0f %8.0f %8.2f %9.2f   surf=%d" % [dino, top, glide, stop_s, rev_s, surf0])
	arena.queue_free()
	await get_tree().process_frame

func _phys(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
