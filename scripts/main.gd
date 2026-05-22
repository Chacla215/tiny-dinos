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

@onready var ice_patches: Node2D = $IcePatches
@onready var camera: Camera2D = $Camera2D
@onready var hud_win: Label = $HUD/WinMessage
@onready var hud_hint: Label = $HUD/RestartHint

@onready var all_players: Array[CharacterBody2D] = [
	$Player1, $Player2, $Player3, $Player4,
]

var active_players: Array[CharacterBody2D] = []
var scores: Dictionary = {}
var match_over: bool = false

var shake_amount: float = 0.0
var shake_remaining: float = 0.0

var lava_area: Area2D = null
var lava_tick_timers: Dictionary = {}

var sfx: Dictionary = {}

func _ready() -> void:
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
	hud_win.text = ""
	hud_hint.text = ""
	_setup_active_players()
	_apply_match_colors()
	update_score_display()
	_load_sfx()

func _setup_active_players() -> void:
	var count: int = MatchConfig.player_count
	for i in range(all_players.size()):
		var p: CharacterBody2D = all_players[i]
		if i < count:
			active_players.append(p)
			scores[p.player_id] = 0
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

func _physics_process(delta: float) -> void:
	if match_over:
		return
	for p in active_players:
		p.current_push = global_current
		if ledge_kill_enabled and not safe_rect.has_point(p.global_position):
			handle_environmental_kill(p)
		if clamp_to_bounds:
			p.global_position = p.global_position.clamp(play_bounds.position, play_bounds.end)
	if lava_area:
		_process_lava(delta)

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

func _on_water_entered(body: Node) -> void:
	if match_over:
		return
	if body in active_players:
		handle_environmental_kill(body)

func handle_environmental_kill(victim: Node) -> void:
	var killer: Node = victim.last_damaged_by if "last_damaged_by" in victim else null
	if killer == null and active_players.size() == 2:
		killer = active_players[1] if victim == active_players[0] else active_players[0]
	award_ko(killer, victim)
	if victim.has_method("respawn"):
		victim.respawn()

func report_ko(victim: Node, killer: Node) -> void:
	if match_over:
		return
	award_ko(killer, victim)

func award_ko(killer: Node, victim: Node) -> void:
	if match_over:
		return
	if killer == null or killer == victim:
		return
	if not (killer in active_players):
		return
	var killer_pid: String = killer.player_id
	scores[killer_pid] = scores.get(killer_pid, 0) + 1
	update_score_display()
	if scores[killer_pid] >= kos_to_win:
		var dino_id: String = MatchConfig.dino_choices.get(killer_pid, "trex")
		var display_name: String = MatchConfig.DINOS[dino_id].display_name
		end_match(killer, display_name)

func update_score_display() -> void:
	for p in active_players:
		var pid: String = p.player_id
		var dino_id: String = MatchConfig.dino_choices.get(pid, "trex")
		var display_name: String = MatchConfig.DINOS[dino_id].display_name
		var label := get_node_or_null("HUD/%sScore" % pid.to_upper())
		if label:
			label.text = "%s  %d / %d" % [display_name, scores.get(pid, 0), kos_to_win]

func end_match(winner: CharacterBody2D, label: String) -> void:
	match_over = true
	hud_win.text = "%s WINS" % label
	var win_color: Color = MatchConfig.PLAYER_COLORS.get(winner.player_id, Color.WHITE)
	hud_win.add_theme_color_override("font_color", win_color)
	hud_hint.text = "press R / ENTER / START for character select"
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

func hit_pause(duration: float, scale: float = 0.2) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func on_hit_landed(damage: int) -> void:
	var intensity: float = float(damage) * 0.45
	var duration: float = 0.12 + float(damage) * 0.004
	var pause_dur: float = float(damage) * 0.002
	shake(intensity, duration)
	hit_pause(pause_dur, 0.25)

func on_ko_landed() -> void:
	shake(28.0, 0.5)
	hit_pause(0.18, 0.12)
	play_sfx("ko", 0.05)
