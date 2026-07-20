extends SceneTree
## Throwaway smoke-sim for the hurt/KO clip pass: spawn one dino of each body
## plan on the beach with no inputs (no CPU brains), then force the two states
## and assert the motion sheet actually switches to the new clips:
##   t=2.0  take_damage(30) on everyone  -> sprite.animation == "hit"
##   t=5.0  knock_down() on everyone     -> sprite.animation == "ko"
##   t=5.0+ down_timer expires           -> back to grounded idle (held pose)
## Not shipped — delete when stale.
##   /opt/homebrew/bin/godot --headless -s scripts/tools/smoke_hurt.gd

const SECONDS := 9.0

var _arena: Node
var _t := 0.0
var _hit_done := false
var _ko_done := false
var _hit_ok := {}
var _ko_ok := {}
var _recover_ok := {}

func _initialize() -> void:
	var mc := root.get_node_or_null("MatchConfig")
	if mc == null:
		push_error("MatchConfig missing")
		quit(1)
		return
	mc.island = "beauty_beach"
	mc.player_count = 4
	mc.cpu_players = {"p1": false, "p2": false, "p3": false, "p4": false}
	mc.dino_choices = {"p1": "ralph", "p2": "raptor", "p3": "trike", "p4": "bronto"}
	mc.game_mode = "rounds"
	var packed: PackedScene = load(mc.ISLAND_SCENES[mc.island])
	_arena = packed.instantiate()
	_arena.kos_to_win = 99
	root.add_child(_arena)
	current_scene = _arena
	print("=== hurt/KO clip smoke-sim ===")

func _dinos() -> Array:
	return _arena.active_players

func _process(delta: float) -> bool:
	if _arena == null:
		return false
	_t += delta
	if _t > 2.0 and not _hit_done:
		_hit_done = true
		for d in _dinos():
			# > BULWARK_POISE_DMG (24) so even STEVE's poise staggers and flinches
			d.take_damage(30, Vector2(40, 0), null)
	if _hit_done and not _ko_done:
		for d in _dinos():
			if d.sprite.animation == "hit":
				_hit_ok[d.sprite_role] = true
	if _t > 5.0 and not _ko_done:
		_ko_done = true
		for d in _dinos():
			d.knock_down(Vector2.RIGHT, 300.0)
	if _ko_done:
		for d in _dinos():
			if d.is_downed and d.sprite.animation == "ko":
				_ko_ok[d.sprite_role] = true
			if not d.is_downed and _ko_ok.has(d.sprite_role) \
					and d.sprite.animation == "idle":
				_recover_ok[d.sprite_role] = true
	if _t >= SECONDS:
		var fails := 0
		for d in _dinos():
			var role: String = d.sprite_role
			var line := "%s: hit=%s ko=%s recover=%s" % [
				role, _hit_ok.has(role), _ko_ok.has(role), _recover_ok.has(role)]
			if _hit_ok.has(role) and _ko_ok.has(role) and _recover_ok.has(role):
				print("  OK   " + line)
			else:
				print("  FAIL " + line)
				fails += 1
		print("SMOKE DONE" if fails == 0 else "SMOKE FAILED (%d)" % fails)
		quit(0 if fails == 0 else 1)
	return false
