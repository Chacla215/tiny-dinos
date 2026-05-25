extends Node2D

const SFX_PATHS := {
	"swing": "res://assets/sfx/swing.wav",
	"hit_chomp": "res://assets/sfx/hit_chomp.wav",
	"hit_claw": "res://assets/sfx/hit_claw.wav",
	"block": "res://assets/sfx/block.wav",
	"guard_break": "res://assets/sfx/guard_break.wav",
	"dodge": "res://assets/sfx/dodge.wav",
	"ko": "res://assets/sfx/ko.wav",
	"win": "res://assets/sfx/win.wav",
}

@export var safe_rect: Rect2 = Rect2(160, 100, 960, 520)
## Island-shaped ring-out boundary in WORLD coords. When this has 3+ points it
## REPLACES safe_rect: ring-out becomes point-in-polygon, so a round/irregular
## island reads true to its painted shoreline instead of a rectangle inscribed
## in it. Generate the points with scripts/tools/gen_safe_zone.py.
@export var safe_polygon: PackedVector2Array = PackedVector2Array()
## Outline the live ring-out boundary on-screen (red) for tuning. Leave off in builds.
@export var debug_draw_safe_zone: bool = false
@export var kos_to_win: int = 3
@export var ledge_kill_enabled: bool = true
@export var clamp_to_bounds: bool = false
@export var play_bounds: Rect2 = Rect2(24, 24, 1232, 672)

@export_group("Hazards")
## "kill" = touching Water is an instant ring-out (default).
## "lava" = Water burns: repeated damage + a shove back toward center.
@export_enum("kill", "lava") var water_mode: String = "kill"
@export var lava_tick_damage: int = 7
@export var lava_tick_interval: float = 0.3
@export var lava_knockback: float = 220.0
## Constant drift applied to every player each frame (White Water Falls current).
@export var global_current: Vector2 = Vector2.ZERO
## Frozen Floes: ring-out when a player isn't standing on any Floe Area2D.
## Dodge i-frames and post-respawn invuln suppress it (a dodge = a floe-hop).
@export var drown_off_floes: bool = false
@export var drown_grace: float = 0.35

## Players don't physically collide (that caused latching); instead they're
## softly pushed apart in code so you can shove against each other, not stick.
const PLAYER_SEPARATION := 56.0

## Dark backing plate behind each HUD corner so name/bars read on bright stages.
const HUD_PANEL_COLOR := Color(0.06, 0.07, 0.11, 0.55)

@onready var ice_patches: Node2D = $IcePatches
@onready var camera: Camera2D = $Camera2D
@onready var hud_win: Label = $HUD/WinMessage
@onready var hud_hint: Label = $HUD/RestartHint

@onready var all_players: Array[CharacterBody2D] = [
	$Player1, $Player2, $Player3, $Player4,
]

var active_players: Array[CharacterBody2D] = []
var round_wins: Dictionary = {}   # rounds won this match (the displayed score)
var dp: Dictionary = {}           # DinoPoints accrued this match (for the grade)
var match_over: bool = false
var round_active: bool = true
var current_round: int = 1

var shake_amount: float = 0.0
var shake_remaining: float = 0.0

var _pause_until_ms: int = 0
var _pause_active: bool = false

var lava_area: Area2D = null
var lava_tick_timers: Dictionary = {}
var drown_timers: Dictionary = {}  # pid -> seconds spent off all floes

var sfx: Dictionary = {}

func _ready() -> void:
	# Safety net: a scene change mid hit-pause can leave time_scale stuck low.
	Engine.time_scale = 1.0
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	for child in ice_patches.get_children():
		if child is Area2D:
			child.body_entered.connect(_on_ice_entered)
			child.body_exited.connect(_on_ice_exited)
	var water := get_node_or_null("Water")
	if water is Area2D:
		if water_mode == "lava":
			lava_area = water
		else:
			water.body_entered.connect(_on_water_entered)
	var slow_zone := get_node_or_null("SlowZone")
	if slow_zone is Area2D:
		slow_zone.body_entered.connect(_on_slow_entered)
		slow_zone.body_exited.connect(_on_slow_exited)
	# Frozen Floes: each floe is both safe ground (floe) and slippery (ice).
	var floe_group := get_node_or_null("Floe")
	if floe_group:
		for child in floe_group.get_children():
			if child is Area2D:
				child.body_entered.connect(_on_floe_entered)
				child.body_exited.connect(_on_floe_exited)
	hud_win.text = ""
	hud_hint.text = ""
	_setup_active_players()
	_apply_match_colors()
	_style_hud()
	update_score_display()
	_load_sfx()
	_build_debug_boundary()  # red ring-out outline when debug_draw_safe_zone is on

func _setup_active_players() -> void:
	var count: int = MatchConfig.player_count
	for i in range(all_players.size()):
		var p: CharacterBody2D = all_players[i]
		if i < count:
			active_players.append(p)
			round_wins[p.player_id] = 0
			dp[p.player_id] = 0
		else:
			p.visible = false
			p.set_process_input(false)
			p.set_physics_process(false)
			p.set_process(false)
			_hide_hud_for(p.player_id)

func _hide_hud_for(pid: String) -> void:
	var key := pid.to_upper()
	for suffix in ["Score", "HPBack", "HPFill", "BlockBack", "BlockFill"]:
		var node := get_node_or_null("HUD/%s%s" % [key, suffix])
		if node:
			node.visible = false

func _apply_match_colors() -> void:
	for p in active_players:
		var pid: String = p.player_id
		var color: Color = MatchConfig.PLAYER_COLORS.get(pid, Color.WHITE)
		var key := pid.to_upper()
		var score_label := get_node_or_null("HUD/%sScore" % key)
		if score_label:
			score_label.add_theme_color_override("font_color", color)
		var hp_fill := get_node_or_null("HUD/%sHPFill" % key)
		if hp_fill:
			hp_fill.color = color

# Backing plate behind each active corner's HUD + dark text outlines, so the
# name/score/bars and the win+restart text read on bright stages. Done in code
# (not the scenes) so all 6 arenas get it from the one shared script.
func _style_hud() -> void:
	var rects := {
		"p1": Rect2(12, 8, 300, 98),
		"p2": Rect2(968, 8, 300, 98),
		"p3": Rect2(12, 604, 300, 80),
		"p4": Rect2(968, 604, 300, 80),
	}
	for p in active_players:
		var pid: String = p.player_id
		var panel := ColorRect.new()
		panel.color = HUD_PANEL_COLOR
		var r: Rect2 = rects.get(pid, Rect2(12, 8, 300, 98))
		panel.position = r.position
		panel.size = r.size
		panel.z_index = -1
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$HUD.add_child(panel)
		var label: Label = get_node_or_null("HUD/%sScore" % pid.to_upper())
		if label:
			label.add_theme_constant_override("outline_size", 8)
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	for l in [hud_win, hud_hint]:
		l.add_theme_constant_override("outline_size", 8)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		print("Joypad connected: device %d  name=%s" % [device, Input.get_joy_name(device)])
	else:
		print("Joypad disconnected: device %d" % device)

func _load_sfx() -> void:
	sfx = {
		"swing": $SFX/Swing,
		"hit_chomp": $SFX/HitChomp,
		"hit_claw": $SFX/HitClaw,
		"block": $SFX/Block,
		"guard_break": $SFX/GuardBreak,
		"dodge": $SFX/Dodge,
		"ko": $SFX/KO,
		"win": $SFX/Win,
	}
	for key in SFX_PATHS:
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			sfx[key].stream = load(path)

func _process(delta: float) -> void:
	if shake_remaining > 0.0:
		var s := shake_amount
		camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s))
		shake_remaining -= delta
		shake_amount *= 0.90
		if shake_remaining <= 0.0:
			camera.offset = Vector2.ZERO
			shake_amount = 0.0
	else:
		camera.offset = Vector2.ZERO
	_update_hud_bars()
	if match_over and Input.is_action_just_pressed("restart"):
		get_tree().change_scene_to_file("res://scenes/select.tscn")

func _update_hud_bars() -> void:
	for p in active_players:
		var key: String = p.player_id.to_upper()
		var hp_fill := get_node_or_null("HUD/%sHPFill" % key)
		var block_fill := get_node_or_null("HUD/%sBlockFill" % key)
		if hp_fill:
			hp_fill.scale.x = clamp(float(p.hp) / float(p.max_hp), 0.0, 1.0)
		if block_fill:
			block_fill.scale.x = clamp(p.block_durability / p.max_block, 0.0, 1.0)
		var label := get_node_or_null("HUD/%sScore" % key)
		if label:
			var wn: String = p.weapon_name() if p.has_method("weapon_name") else ""
			var wsuffix: String = ("   " + wn) if wn != "" else ""
			label.text = "%s  %d / %d%s" % [_dino_name(p.player_id), round_wins.get(p.player_id, 0), kos_to_win, wsuffix]

func _physics_process(delta: float) -> void:
	if match_over or not round_active:
		return
	_separate_players()
	for p in active_players:
		if p.is_falling:
			continue  # tumbling off-screen; its own _physics_process drives it
		p.current_push = global_current
		if ledge_kill_enabled and not _in_safe_zone(p.global_position):
			_ringout(p)
			continue
		if clamp_to_bounds:
			p.global_position = p.global_position.clamp(play_bounds.position, play_bounds.end)
	if lava_area:
		_process_lava(delta)
	if drown_off_floes:
		_process_drowning(delta)

func _process_lava(delta: float) -> void:
	var overlapping := lava_area.get_overlapping_bodies()
	var center := play_bounds.get_center()
	for p in active_players:
		if not (p in overlapping):
			lava_tick_timers[p.player_id] = 0.0
			continue
		var t: float = lava_tick_timers.get(p.player_id, 0.0) - delta
		if t <= 0.0:
			t = lava_tick_interval
			var dir: Vector2 = (center - p.global_position).normalized()
			var lethal: bool = p.apply_burn(lava_tick_damage, dir * lava_knockback)
			play_sfx("hit_claw", 0.12)
			shake(6.0, 0.08)
			if lethal:
				handle_environmental_kill(p)
		lava_tick_timers[p.player_id] = t

# Soft body separation: nudge any overlapping players apart so they can press
# against each other without the hard-collision latch. move_and_collide keeps
# the nudge from shoving anyone through a wall/obstacle.
func _separate_players() -> void:
	var count := active_players.size()
	for i in range(count):
		var a: CharacterBody2D = active_players[i]
		if a.is_falling:
			continue
		for j in range(i + 1, count):
			var b: CharacterBody2D = active_players[j]
			if b.is_falling:
				continue
			var diff := b.global_position - a.global_position
			var dist := diff.length()
			if dist >= PLAYER_SEPARATION:
				continue
			var dir := diff / dist if dist > 0.01 else Vector2.RIGHT
			var push := dir * (PLAYER_SEPARATION - dist) * 0.5
			a.move_and_collide(-push)
			b.move_and_collide(push)

func _on_ice_entered(body: Node) -> void:
	if body.has_method("enter_ice"):
		body.enter_ice()

func _on_ice_exited(body: Node) -> void:
	if body.has_method("exit_ice"):
		body.exit_ice()

func _on_slow_entered(body: Node) -> void:
	if body.has_method("enter_slow"):
		body.enter_slow()

func _on_slow_exited(body: Node) -> void:
	if body.has_method("exit_slow"):
		body.exit_slow()

func _on_floe_entered(body: Node) -> void:
	if body.has_method("enter_floe"):
		body.enter_floe()
	if body.has_method("enter_ice"):
		body.enter_ice()

func _on_floe_exited(body: Node) -> void:
	if body.has_method("exit_floe"):
		body.exit_floe()
	if body.has_method("exit_ice"):
		body.exit_ice()

# Frozen Floes ring-out: off every floe for longer than the grace beat = drown.
# Dodge i-frames and post-respawn invuln keep you safe (a dodge is a floe-hop).
func _process_drowning(delta: float) -> void:
	for p in active_players:
		var safe: bool = p.floe_overlap_count > 0 or p.is_dodging() or p.invuln_timer > 0.0
		if safe:
			drown_timers[p.player_id] = 0.0
			continue
		var t: float = drown_timers.get(p.player_id, 0.0) + delta
		if t >= drown_grace:
			drown_timers[p.player_id] = 0.0
			shake(7.0, 0.12)
			play_sfx("ko", 0.1)
			handle_environmental_kill(p)
		else:
			drown_timers[p.player_id] = t

func _on_water_entered(body: Node) -> void:
	if match_over or not round_active:
		return
	if body in active_players:
		# Deferred: this fires during physics-query flush, and the kill respawns
		# the body (toggling collision shapes), which isn't allowed mid-flush.
		handle_environmental_kill.call_deferred(body)

# True while a player is standing on safe ground. A 3+ point safe_polygon (an
# island-shaped boundary) wins over the rectangular safe_rect when present.
func _in_safe_zone(pos: Vector2) -> bool:
	if safe_polygon.size() >= 3:
		return Geometry2D.is_point_in_polygon(pos, safe_polygon)
	return safe_rect.has_point(pos)

# Public alias so a sky-launched dino can test when it has clawed back in.
func is_in_safe_zone(pos: Vector2) -> bool:
	return _in_safe_zone(pos)

# Center of the play area — picks the side a ring-out launches toward.
func _safe_center() -> Vector2:
	if safe_polygon.size() >= 3:
		var sum := Vector2.ZERO
		for p in safe_polygon:
			sum += p
		return sum / safe_polygon.size()
	return safe_rect.get_center()

# Tuning aid: trace the live ring-out boundary so you can see exactly where the
# island ends versus where the art's shoreline is painted. A high-z Line2D (not
# _draw, which renders under the background sprite). Off in real builds.
func _build_debug_boundary() -> void:
	if not debug_draw_safe_zone:
		return
	# Floe arena (drown-off-floes): outline each safe floe, not a ring-out boundary.
	if drown_off_floes:
		var floes := get_node_or_null("Floe")
		if floes:
			for f in floes.get_children():
				if not (f is Area2D):
					continue
				for c in f.get_children():
					if c is CollisionPolygon2D and (c as CollisionPolygon2D).polygon.size() >= 2:
						var fp: PackedVector2Array = (c as CollisionPolygon2D).polygon
						var fl := PackedVector2Array()
						for v in fp:
							fl.append(f.position + c.position + v)
						fl.append(f.position + c.position + fp[0])
						_add_debug_outline(fl)
		return
	# Ring-out boundary.
	var loop := PackedVector2Array()
	if safe_polygon.size() >= 3:
		loop = safe_polygon.duplicate()
		loop.append(safe_polygon[0])
	else:
		var r := safe_rect
		loop = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y),
			r.end, Vector2(r.position.x, r.end.y), r.position])
	_add_debug_outline(loop)
	# Each cover block, so collision can be checked against the painted boulder.
	var obstacles := get_node_or_null("Obstacles")
	if obstacles:
		for c in obstacles.get_children():
			if not (c is CollisionShape2D):
				continue
			var o: Vector2 = c.position
			if c.shape is RectangleShape2D:
				var hs: Vector2 = (c.shape as RectangleShape2D).size * 0.5
				_add_debug_outline(PackedVector2Array([
					o + Vector2(-hs.x, -hs.y), o + Vector2(hs.x, -hs.y),
					o + Vector2(hs.x, hs.y), o + Vector2(-hs.x, hs.y),
					o + Vector2(-hs.x, -hs.y)]))
			elif c.shape is ConvexPolygonShape2D:
				var pts: PackedVector2Array = (c.shape as ConvexPolygonShape2D).points
				if pts.size() >= 2:
					var loop2 := PackedVector2Array()
					for v in pts:
						loop2.append(o + v)
					loop2.append(o + pts[0])
					_add_debug_outline(loop2)

func _add_debug_outline(loop: PackedVector2Array) -> void:
	var line := Line2D.new()
	line.points = loop
	line.width = 3.0
	line.default_color = Color(1.0, 0.2, 0.2, 0.9)
	line.z_index = 100
	add_child(line)

# Crossed the island boundary: start the off-screen tumble. Kill credit is
# captured NOW (respawn later clears last_damaged_by) and settled in
# on_ringout_complete once the fall finishes, so the KO lands with the drop.
func _ringout(victim: Node) -> void:
	if victim.is_falling:
		return
	var killer: Node = victim.last_damaged_by if "last_damaged_by" in victim else null
	if killer == null and active_players.size() == 2:
		killer = active_players[1] if victim == active_players[0] else active_players[0]
	victim.ringout_killer = killer
	play_sfx("ko", 0.0)
	shake(7.0, 0.18)
	# Crossed the upper half → launched into the sky (recoverable). Else drop.
	var center := _safe_center()
	var go_up: bool = victim.global_position.y < center.y
	victim.begin_ringout(go_up, center.y)

func on_ringout_complete(victim: Node) -> void:
	var killer: Node = victim.ringout_killer
	victim.ringout_killer = null
	if victim.has_method("respawn"):
		victim.respawn()
	if killer != null and killer != victim and killer in active_players:
		award_ko(killer, victim)

# The dino mashed its way back onto the field — no KO, no respawn, keeps its HP.
func on_ringout_recovered(victim: Node) -> void:
	victim.ringout_killer = null

func handle_environmental_kill(victim: Node) -> void:
	var killer: Node = victim.last_damaged_by if "last_damaged_by" in victim else null
	if killer == null and active_players.size() == 2:
		killer = active_players[1] if victim == active_players[0] else active_players[0]
	# Get them off the hazard immediately either way.
	if victim.has_method("respawn"):
		victim.respawn()
	# Attributed ring-out ends the round (credits the killer). An unattributed
	# FFA self-ring-out is neutral — just the respawn above, round continues.
	if killer != null and killer != victim and killer in active_players:
		award_ko(killer, victim)

func report_ko(victim: Node, killer: Node) -> void:
	award_ko(killer, victim)

# A KO ends the current round (in FFA: first KO of the round wins it). The
# killer takes the round + DP; first to kos_to_win rounds wins the match.
func award_ko(killer: Node, victim: Node) -> void:
	if match_over or not round_active:
		return
	if killer == null or killer == victim or not (killer in active_players):
		return
	round_active = false
	var killer_pid: String = killer.player_id
	dp[killer_pid] = dp.get(killer_pid, 0) + 100
	round_wins[killer_pid] = round_wins.get(killer_pid, 0) + 1
	update_score_display()
	if round_wins[killer_pid] >= kos_to_win:
		end_match(killer, _dino_name(killer_pid))
	else:
		_end_round(killer_pid)

func _dino_name(pid: String) -> String:
	var dino_id: String = MatchConfig.dino_choices.get(pid, "trex")
	return MatchConfig.DINOS[dino_id].display_name

func add_dp(pid: String, points: int) -> void:
	if pid in dp:
		dp[pid] = dp[pid] + points

# Round-over interstitial → reset everyone → next round.
func _end_round(winner_pid: String) -> void:
	hud_win.text = "%s TAKES ROUND %d" % [_dino_name(winner_pid), current_round]
	hud_win.add_theme_color_override("font_color", MatchConfig.PLAYER_COLORS.get(winner_pid, Color.WHITE))
	for p in active_players:
		p.set_physics_process(false)
		p.set_process_input(false)
	await get_tree().create_timer(1.6, true, false, true).timeout
	if match_over:
		return
	current_round += 1
	_clear_world_weapons()
	for p in active_players:
		p.set_physics_process(true)
		p.set_process_input(true)
		if p.has_method("respawn"):
			p.respawn()
	hud_win.text = "ROUND %d" % current_round
	hud_win.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	round_active = true
	await get_tree().create_timer(0.8, true, false, true).timeout
	if not match_over:
		hud_win.text = ""

# Wipe any thrown/dropped weapons so each round starts on a clean platform.
func _clear_world_weapons() -> void:
	for item in get_tree().get_nodes_in_group("weapon_items"):
		if is_instance_valid(item):
			item.queue_free()

func _grade(points: int) -> String:
	if points >= 480: return "A+"
	if points >= 380: return "A"
	if points >= 290: return "B"
	if points >= 200: return "C"
	if points >= 120: return "D"
	return "F"

func update_score_display() -> void:
	for p in active_players:
		var pid: String = p.player_id
		var dino_id: String = MatchConfig.dino_choices.get(pid, "trex")
		var display_name: String = MatchConfig.DINOS[dino_id].display_name
		var label := get_node_or_null("HUD/%sScore" % pid.to_upper())
		if label:
			label.text = "%s  %d / %d" % [display_name, round_wins.get(pid, 0), kos_to_win]

func end_match(winner: CharacterBody2D, label: String) -> void:
	match_over = true
	round_active = false
	hud_win.text = "%s WINS" % label
	var win_color: Color = MatchConfig.PLAYER_COLORS.get(winner.player_id, Color.WHITE)
	hud_win.add_theme_color_override("font_color", win_color)
	# DinoPoints grade card: per-player DP + letter grade, then the restart hint.
	var lines: Array[String] = []
	for p in active_players:
		var pid: String = p.player_id
		var pts: int = dp.get(pid, 0)
		lines.append("%s   %d DP   %s" % [_dino_name(pid), pts, _grade(pts)])
	lines.append("")
	lines.append("press START for character select")
	hud_hint.text = "\n".join(lines)
	for p in active_players:
		p.set_process_input(false)
		p.set_physics_process(false)
	play_sfx("win", 0.0)

# --- Audio ---

func play_sfx(sound_name: String, pitch_var: float = 0.05) -> void:
	if not sound_name in sfx:
		return
	var player: AudioStreamPlayer = sfx[sound_name]
	if player.stream == null:
		return
	player.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	player.play()

# --- Camera juice (called from dinos) ---

func shake(intensity: float, duration: float) -> void:
	shake_amount = max(shake_amount, intensity)
	shake_remaining = max(shake_remaining, duration)

# Overlap-safe freeze-frame. Concurrent calls (e.g. a killing blow fires both
# on_hit_landed and on_ko_landed) extend to the latest end and keep the
# strongest slow; a single watcher restores time_scale exactly once at the end.
func hit_pause(duration: float, scale: float = 0.2) -> void:
	if duration <= 0.0:
		return
	_pause_until_ms = max(_pause_until_ms, Time.get_ticks_msec() + int(duration * 1000.0))
	var base: float = Engine.time_scale if _pause_active else 1.0
	Engine.time_scale = min(base, scale)
	if _pause_active:
		return
	_pause_active = true
	while Time.get_ticks_msec() < _pause_until_ms:
		# ignore_time_scale timer so the freeze lasts in real time, not game time.
		await get_tree().create_timer(0.01, true, false, true).timeout
	Engine.time_scale = 1.0
	_pause_active = false

func on_hit_landed(damage: int) -> void:
	var intensity: float = min(24.0, float(damage) * 0.45)
	var duration: float = 0.12 + float(damage) * 0.004
	var pause_dur: float = float(damage) * 0.002
	shake(intensity, duration)
	hit_pause(pause_dur, 0.25)

# Blocked hit: a firm thunk you feel, but no freeze — blocking shouldn't
# interrupt the flow the way landing a clean hit does.
func on_hit_blocked(damage: int) -> void:
	shake(min(8.0, float(damage) * 0.25), 0.09)

# Guard break: the big "you're cracked open" beat. Crunchy shake + short freeze.
func on_guard_break() -> void:
	shake(18.0, 0.32)
	hit_pause(0.10, 0.2)

func on_ko_landed() -> void:
	shake(28.0, 0.5)
	hit_pause(0.18, 0.12)
	play_sfx("ko", 0.05)
