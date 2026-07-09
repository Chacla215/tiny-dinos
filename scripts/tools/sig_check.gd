extends SceneTree
## Throwaway verification: boot real arenas with a chosen roster and assert each
## dino's signature passive actually fires in the live combat code.
##   godot --headless -s scripts/tools/sig_check.gd
## Delete after use.

const IDLE := 0
const RECOVERY := 3
const NORMAL := 0
const BLOCKING := 1

var _mc: Node
var _stage := 0
var _frames := 0
var _arena: Node
var _pass := 0
var _fail := 0

func _initialize() -> void:
	_mc = root.get_node_or_null("MatchConfig")
	_mc.player_count = 4
	_mc.teams_enabled = false
	_mc.cpu_players = {"p1": true, "p2": true, "p3": true, "p4": true}
	_load({"p1": "ralph", "p2": "raptor", "p3": "trike", "p4": "pterry"})

func _load(choices: Dictionary) -> void:
	_mc.dino_choices = choices
	_arena = load("res://scenes/arena_beach.tscn").instantiate()
	root.add_child(_arena)
	_frames = 0

func _ck(name: String, cond: bool) -> void:
	if cond: _pass += 1
	else: _fail += 1
	print(("  PASS " if cond else "  FAIL ") + name)

func _p(n: int) -> Node:
	return _arena.get_node("Player%d" % n)

func _process(_dt: float) -> bool:
	_frames += 1
	if _frames < 8:
		return false
	if _stage == 0:
		print("=== SET A: ralph raptor trike pterry ===")
		var ralph := _p(1); var raptor := _p(2); var trike := _p(3); var pterry := _p(4)
		print("  signatures: ", ralph.signature, " ", raptor.signature, " ", trike.signature, " ", pterry.signature)
		_ck("ralph=combo_king", ralph.signature == "combo_king")
		_ck("raptor=dash_cancel", raptor.signature == "dash_cancel")
		# combo_king: combo=3 → faster light than combo=0
		ralph.attack_phase = IDLE; ralph.combo_count = 0; ralph.start_attack(false)
		var t0: float = ralph.attack_phase_dur
		ralph.attack_phase = IDLE; ralph.combo_count = 3; ralph.start_attack(false)
		var t3: float = ralph.attack_phase_dur
		_ck("combo_king speeds up light (%.3f<%.3f)" % [t3, t0], t3 < t0)
		ralph.attack_phase = IDLE; ralph.combo_count = 0
		# dash_cancel: raptor can dodge in RECOVERY, trike cannot
		for d in [raptor, trike]:
			d.attack_phase = RECOVERY; d.defense_state = NORMAL
			d.dodge_cooldown_timer = 0.0; d.block_durability = d.max_block
			d.slow_overlap_count = 0; d.timed_slow_timer = 0.0
		_ck("raptor dodges in recovery", raptor.can_dodge() == true)
		_ck("trike locked in recovery", trike.can_dodge() == false)
		raptor.attack_phase = IDLE; trike.attack_phase = IDLE
		# charger: trike shrugs shove during its heavy
		trike.velocity = Vector2.ZERO; trike.invuln_timer = 0.0
		trike.defense_state = NORMAL; trike.current_is_special = false
		trike.current_is_heavy = true; trike.attack_phase = RECOVERY
		trike.take_damage(20, Vector2(600, 0), null)
		_ck("charger keeps footing in heavy", trike.velocity.length() < 1.0)
		trike.attack_phase = IDLE; trike.current_is_heavy = false
		# flighty: pterry landing a hit refunds dodge cooldown
		pterry.dodge_cooldown_timer = pterry.dodge_cooldown
		pterry.current_attack_damage = 8; pterry.current_attack_knockback = 100.0
		pterry.current_is_special = false; pterry.hit_targets_this_swing = []
		var before: float = pterry.dodge_cooldown_timer
		pterry.try_hit(ralph)
		_ck("flighty refunds dodge cd (%.2f<%.2f)" % [pterry.dodge_cooldown_timer, before], pterry.dodge_cooldown_timer < before)
		_arena.queue_free()
		_stage = 1; _frames = -4
		_load({"p1": "bronto", "p2": "anky", "p3": "ralph", "p4": "raptor"})
		return false
	if _stage == 1:
		print("=== SET B: bronto anky ralph raptor ===")
		var bronto := _p(1); var anky := _p(2); var src := _p(3)
		print("  signatures: ", bronto.signature, " ", anky.signature)
		_ck("bronto=bulwark", bronto.signature == "bulwark")
		_ck("anky=spikeback", anky.signature == "spikeback")
		# bulwark: weak jab can't shove, strong blow does
		bronto.velocity = Vector2.ZERO; bronto.invuln_timer = 0.0
		bronto.defense_state = NORMAL; bronto.attack_phase = IDLE
		bronto.take_damage(18, Vector2(700, 0), null)
		_ck("bulwark planted vs jab", bronto.velocity.length() < 1.0)
		bronto.velocity = Vector2.ZERO; bronto.invuln_timer = 0.0
		bronto.take_damage(34, Vector2(700, 0), null)
		_ck("bulwark shoved by real blow", bronto.velocity.length() > 1.0)
		# spikeback: blocking anky reflects chip at the source
		anky.defense_state = BLOCKING; anky.block_durability = anky.max_block
		anky.invuln_timer = 0.0
		var hp0: int = src.hp
		anky.take_damage(20, Vector2(400, 0), src)
		_ck("spikeback reflects at attacker (%d<%d)" % [src.hp, hp0], src.hp < hp0)
		print("=== RESULT: %d passed, %d failed ===" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
		return true
	return false
