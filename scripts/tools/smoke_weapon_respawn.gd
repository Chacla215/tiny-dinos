extends SceneTree
## Throwaway check for the "signature weapon lost on respawn" fix. In a round-less
## mode (koth) a KO'd fighter respawns via die()->respawn() without _end_round ever
## re-granting; before the fix, respawn restored initial_weapons (captured as fists
## before the match-start grant), so the signature was gone for the rest of the match.
## Asserts each fighter still holds its signature weapon AFTER a respawn.
##   /opt/homebrew/bin/godot --headless -s scripts/tools/smoke_weapon_respawn.gd
const SECONDS := 2.0
var _arena: Node
var _mc: Node
var _t := 0.0
var _did := false
var _results := {}

func _initialize() -> void:
	var mc := root.get_node_or_null("MatchConfig")
	if mc == null:
		push_error("MatchConfig missing"); quit(1); return
	_mc = mc
	mc.island = "beauty_beach"
	mc.player_count = 4
	mc.cpu_players = {"p1": false, "p2": false, "p3": false, "p4": false}
	mc.dino_choices = {"p1": "ralph", "p2": "raptor", "p3": "trike", "p4": "bronto"}
	mc.game_mode = "koth"  # round-less: never calls _end_round
	var packed: PackedScene = load(mc.ISLAND_SCENES[mc.island])
	_arena = packed.instantiate()
	root.add_child(_arena)
	current_scene = _arena
	print("=== signature-weapon respawn smoke ===")

func _process(delta: float) -> bool:
	if _arena == null:
		return false
	_t += delta
	if _t > 0.5 and not _did:
		_did = true
		for d in _arena.active_players:
			var sig: String = _mc.signature_weapon(
				_mc.dino_choices.get(d.player_id, ""))
			var held_before: bool = sig in d.weapons
			d.respawn()  # simulate a mid-match KO recovery
			var held_after: bool = sig in d.weapons
			_results[d.sprite_role] = {"sig": sig, "before": held_before, "after": held_after}
	if _t >= SECONDS:
		var fails := 0
		for role in _results:
			var r = _results[role]
			var ok: bool = r.before and r.after
			print("  %s %s: sig=%s before=%s after=%s" % [
				"OK  " if ok else "FAIL", role, r.sig, r.before, r.after])
			if not ok:
				fails += 1
		print("SMOKE DONE" if fails == 0 else "SMOKE FAILED (%d)" % fails)
		quit(0 if fails == 0 else 1)
	return false
