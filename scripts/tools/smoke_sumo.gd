extends SceneTree
## Throwaway smoke-sim for the SUMO dohyo rework: one CPU-vs-CPU sumo match,
## prints the dohyo config and the bout points as they land. Not shipped.
##   /opt/homebrew/bin/godot --headless -s scripts/tools/smoke_sumo.gd

const SECONDS := 40.0

var _arena: Node
var _t := 0.0
var _last_scores := {}

func _initialize() -> void:
	var mc: Node = root.get_node_or_null("MatchConfig")
	mc.island = "beauty_beach"
	mc.player_count = 2
	mc.cpu_players = {"p1": true, "p2": true, "p3": false, "p4": false}
	mc.cpu_difficulty = "hard"
	mc.dino_choices = {"p1": "ralph", "p2": "raptor", "p3": "trike", "p4": "pterry"}
	mc.game_mode = "sumo"
	_arena = load(mc.ISLAND_SCENES["beauty_beach"]).instantiate()
	root.add_child(_arena)
	current_scene = _arena

var _printed_state := false

func _process(delta: float) -> bool:
	_t += delta
	if not _printed_state and _t > 0.5:
		_printed_state = true
		print("dohyo: center=%s radius=%.0f  ring_node=%s  mode=%s" % [
			str(_arena.dohyo_center), _arena.dohyo_radius,
			str(_arena.get_node_or_null("Dohyo") != null), _arena.game_mode])
		for p in _arena.active_players:
			print("  %s at %s  in_dohyo=%s  ringout_only=%s" % [
				p.player_id, str(p.global_position.round()),
				str(_arena._in_dohyo(p.global_position)), str(p.ringout_only)])
	if _arena.mode_score != _last_scores:
		_last_scores = _arena.mode_score.duplicate()
		var where := ""
		for p in _arena.active_players:
			where += " %s@%s%s" % [p.player_id, str(p.global_position.round()),
				"(falling)" if p.is_falling else ""]
		print("[%5.1fs] POINT -> %s  %s" % [_t, str(_last_scores), where])
	if _arena.match_over:
		print("MATCH OVER at %.1fs  final=%s" % [_t, str(_arena.mode_score)])
		quit(0)
	elif _t >= SECONDS:
		print("TIME UP  final=%s  (no crash, scoring live)" % str(_arena.mode_score))
		quit(0)
	return false
