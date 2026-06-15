extends Node
## Throwaway functional test for the floppy GRAB chain (stage 3). Instances a real
## arena, drives Player1 to grab/carry/throw Player2, and asserts each transition.
## Headless:  /opt/homebrew/bin/godot --headless scenes/grab_test.tscn
## Delete with the other floppy throwaways once grabs are tuned.

var _fails: Array = []

func _ready() -> void:
	MatchConfig.floppy_mode = true
	MatchConfig.player_count = 2
	MatchConfig.teams_enabled = false
	# p1 spawns as a CPU so it has an `ai` for the autonomous-grab phase; we disable
	# its is_cpu during the manual phases below.
	MatchConfig.cpu_players = {"p1": true, "p2": false, "p3": false, "p4": false}
	var arena: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var p1: Node = arena.get_node("Player1")
	var p2: Node = arena.get_node("Player2")
	# Take the AI out of it so facing/positions hold still for the test.
	p1.is_cpu = false
	p2.is_cpu = false
	await _phys(4)

	# --- set up: P2 just in front of a right-facing P1 ---
	p1.global_position = Vector2(600, 360)
	p2.global_position = Vector2(672, 360)
	p1.facing = Vector2.RIGHT
	await _phys(1)

	var foe: Node = p1._foe_in_grab_range()
	_check("foe detected in front", foe == p2)
	_check("can_grab() true", p1.can_grab())

	# --- grab ---
	p1.begin_grab(p2)
	_check("p1 is grabbing p2", p1.grabbing == p2)
	_check("p2 grabbed_by p1", p2.grabbed_by == p1)
	_check("p2 can't act while held", not p2.can_attack())
	_check("p1 can't attack while holding", not p1.can_attack())

	# --- carry: p2 should be pulled to the hold point in front of p1 ---
	await _phys(14)
	var hold: Vector2 = p1.global_position + p1.facing.normalized() * p1.GRAB_HOLD_DIST
	_check("p2 carried to hold point", p2.global_position.distance_to(hold) < 40.0)
	_check("still held after carrying", p2.grabbed_by == p1)

	# --- throw ---
	p1.throw_grabbed()
	_check("p1 no longer grabbing", p1.grabbing == null)
	_check("p2 no longer grabbed", p2.grabbed_by == null)
	_check("thrown p2 is floored (downed)", p2.is_downed)
	_check("thrown p2 has launch velocity", p2.velocity.length() > 500.0)

	# --- anti-juggle: once you scramble up you can't be re-floored for a beat ---
	await _phys(60)                                   # p2 gets up (~0.85s)
	_check("p2 got up after the throw", not p2.is_downed)
	p2.knock_down(Vector2.RIGHT, 1.2)
	_check("immune to re-knockdown just after getup", not p2.is_downed)
	await _phys(70)                                   # immunity window (0.9s) lapses
	p2.knock_down(Vector2.RIGHT, 1.2)
	_check("can be floored again once immunity lapses", p2.is_downed)

	# --- escape path: re-grab, then mash free ---
	await _phys(70)            # let p2 get up (DOWN_DURATION 0.85s @ 60fps)
	p2.global_position = p1.global_position + Vector2(70, 0)
	p1.facing = Vector2.RIGHT
	await _phys(1)
	if p1.can_grab():
		p1.begin_grab(p2)
		p2.grab_escape = 1.0   # simulate a full mash
		await _phys(2)
		_check("mashing breaks the grab", p2.grabbed_by == null and p1.grabbing == null)
	else:
		_fails.append("could not re-grab for escape test")

	# --- autonomous: a CPU should grab AND throw a foe on its own ---
	await _phys(70)
	if p1.ai != null:
		p1.is_cpu = true
		p1.ai.apply_difficulty("hard")
		p1.ai.grab_chance = 1.0          # force the grab roll for a deterministic test
		p1.ai._grab_cd = 0.0
		p2.is_downed = false
		p2.grabbed_by = null
		p2.invuln_timer = 0.0
		p2.global_position = p1.global_position + Vector2(64, 0)
		var grabbed_seen := false
		var threw_seen := false
		for i in 150:
			await get_tree().physics_frame
			if p1.grabbing == p2:
				grabbed_seen = true
			if grabbed_seen and p1.grabbing == null:
				threw_seen = true
				break
		_check("CPU grabbed a foe on its own", grabbed_seen)
		_check("CPU threw the held foe", threw_seen)
	else:
		_fails.append("p1 had no ai for the CPU-grab test")

	# --- stress: two floppy CPUs brawl for a while; just shouldn't crash/deadlock ---
	if p1.ai != null:
		if p2.ai == null:
			p2.ai = load("res://scripts/dino_ai.gd").new()
		p2.ai.apply_difficulty("hard")
		p2.is_cpu = true
		p1.ai.grab_chance = 0.34
		p1.global_position = Vector2(540, 360)
		p2.global_position = Vector2(740, 360)
		var saw_downed := false
		var ok := true
		for i in 700:
			await get_tree().physics_frame
			if not (is_instance_valid(p1) and is_instance_valid(p2)):
				ok = false
				break
			if p1.is_downed or p2.is_downed:
				saw_downed = true
		_check("two floppy CPUs survived a 700-frame brawl", ok)
		_check("a knockdown occurred during the brawl", saw_downed)

	_report()

func _phys(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _check(label: String, cond: bool) -> void:
	if cond:
		print("  PASS  ", label)
	else:
		print("  FAIL  ", label)
		_fails.append(label)

func _report() -> void:
	if _fails.is_empty():
		print("\nGRAB TEST: ALL PASS")
	else:
		print("\nGRAB TEST: %d FAILED -> %s" % [_fails.size(), _fails])
	get_tree().quit()
