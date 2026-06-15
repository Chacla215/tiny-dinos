extends Node
## Throwaway feel probe for FLOPPY AI locomotion (momentum self-braking).
## A floppy CPU chases a stationary foe; we measure how far it overshoots its
## spacing pocket, how many times it reverses (the oscillation), and how tightly
## it finally settles. Runs the SAME scenario brake-OFF then brake-ON for an A/B.
## Headless:  /opt/homebrew/bin/godot --headless scenes/floppy_walk_probe.tscn
## Delete with the other floppy throwaways once tuned.

const TRIALS := 14   # the AI has randf() in its spacing — average to beat the noise

func _ready() -> void:
	MatchConfig.floppy_mode = true
	MatchConfig.player_count = 2
	MatchConfig.teams_enabled = false
	MatchConfig.cpu_players = {"p1": true, "p2": false, "p3": false, "p4": false}
	for dino in ["raptor", "ralph"]:   # fast (the problem case) + a tank (regression guard)
		await _probe_dino(dino)
	get_tree().quit()

func _probe_dino(dino: String) -> void:
	MatchConfig.dino_choices["p1"] = dino
	var arena: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var p1: Node = arena.get_node("Player1")
	var p2: Node = arena.get_node("Player2")
	p2.is_cpu = false
	if p1.ai != null:
		p1.ai.apply_difficulty("hard")
		p1.ai.grab_chance = 0.0   # isolate locomotion: don't let it grab mid-walk

	var off := await _avg(p1, p2, false)
	var on := await _avg(p1, p2, true)
	print("\n--- FLOPPY WALK: %s (speed %.0f, avg of %d, lower=calmer) ---" % [dino, p1.max_speed, TRIALS])
	print("                       brakeOFF   brakeON")
	print("overshoot past pocket   %6.1f    %6.1f  px" % [off.overshoot, on.overshoot])
	print("radial reversals        %6.2f    %6.2f" % [off.reversals, on.reversals])
	print("settle error (last 0.5s)%6.1f    %6.1f  px" % [off.settle, on.settle])
	arena.queue_free()
	await get_tree().process_frame

func _avg(p1: Node, p2: Node, brake: bool) -> Dictionary:
	var o := 0.0
	var r := 0.0
	var s := 0.0
	for t in TRIALS:
		var res := await _run(p1, p2, brake)
		o += res.overshoot
		r += res.reversals
		s += res.settle
	return {"overshoot": o / TRIALS, "reversals": r / TRIALS, "settle": s / TRIALS}

func _run(p1: Node, p2: Node, brake: bool) -> Dictionary:
	p1.ai.momentum_brake = brake
	# Reset the chase: foe stationary on the right, bot well to its left.
	p2.global_position = Vector2(820, 360)
	p2.velocity = Vector2.ZERO
	p1.global_position = Vector2(340, 360)
	p1.velocity = Vector2.ZERO
	p1.facing = Vector2.RIGHT
	await _phys(2)

	var reach: float = p1.attack_hitbox_offset + p1.attack_hitbox_size.x * 0.5
	var gap: float = p1.ai.standoff_gap
	var pocket: float = reach + gap
	var min_dist := 1e9
	var prev_dist := -1.0
	var prev_closing := 0
	var reversals := 0
	var settle_sum := 0.0
	var settle_n := 0
	var frames := 150
	for i in frames:
		p2.velocity = Vector2.ZERO   # keep the target a fixed post
		await _phys(1)
		var d: float = p1.global_position.distance_to(p2.global_position)
		min_dist = minf(min_dist, d)
		if prev_dist >= 0.0:
			var closing := 1 if d < prev_dist else -1
			if i > 8 and closing != prev_closing and absf(d - prev_dist) > 1.5:
				reversals += 1
			prev_closing = closing
		prev_dist = d
		if i >= frames - 30:
			settle_sum += absf(d - pocket)
			settle_n += 1
	return {
		"overshoot": maxf(0.0, pocket - min_dist),
		"reversals": reversals,
		"settle": settle_sum / maxf(1, settle_n),
	}

func _phys(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
