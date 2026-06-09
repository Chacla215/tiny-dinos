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

## Special-ready pip: a small square at the inboard end of each corner's block
## bar that fills as the signature special recharges and glows gold when it's
## ready. Built in code so all 6 arenas inherit it from the shared script. The
## anchors track the HUD bar layout (left corners grow right from x=24, right
## corners grow left from x=1256). Dinos with special_type "none" get no pip.
const PIP_SIZE := 18.0
const PIP_POS := {
	"p1": Vector2(292.0, 87.0),
	"p2": Vector2(970.0, 87.0),
	"p3": Vector2(292.0, 665.0),
	"p4": Vector2(970.0, 665.0),
}
const PIP_BG := Color(0.1, 0.1, 0.1, 0.75)
const PIP_CHARGING := Color(0.85, 0.72, 0.35, 1.0)  # muted gold while recharging
const PIP_READY := Color(1.0, 0.85, 0.3, 1.0)      # bright gold when ready

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

# --- Game-mode state (see MatchConfig.game_mode) ---
var game_mode: String = "rounds"
var stocks: Dictionary = {}          # STOCK: pid -> lives left
var mode_score: Dictionary = {}      # KOTH (seconds) / EGGS (count): pid -> score
var hill_center: Vector2 = Vector2.ZERO
var hill_visual: Node2D = null
var hill_ring: Line2D = null
const HILL_RADIUS := 130.0
var eliminated: Dictionary = {}      # STOCK: pid -> true once out of lives
var arcade_end: String = ""          # ARCADE end-state: "advance" / "champion" / "gameover"
var gauntlet_drafting: bool = false  # GAUNTLET: the between-wave upgrade pick is open
var draft_options: Array = []
var draft_index: int = 0
var draft_nodes: Array = []   # every node in the draft overlay (for cleanup)
var draft_cards: Array = []   # just the selectable cards (for highlight)
const DRAFT_CARD_W := 320.0
const DRAFT_CARD_H := 210.0
const DRAFT_GAP := 34.0
var eggs: Array = []                 # EGGS: live egg nodes on the field
var egg_spawn_timer: float = 0.0
const EGG_SPAWN_INTERVAL := 2.2
const EGG_MAX_ON_FIELD := 3
const EGG_PICKUP_RADIUS := 46.0

var shake_amount: float = 0.0
var shake_remaining: float = 0.0

var _pause_until_ms: int = 0
var _pause_active: bool = false

var lava_area: Area2D = null
var lava_tick_timers: Dictionary = {}
var drown_timers: Dictionary = {}  # pid -> seconds spent off all floes

var special_pips: Dictionary = {}  # pid -> {"fill": Polygon2D}

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
	game_mode = MatchConfig.game_mode if MatchConfig and "game_mode" in MatchConfig else "rounds"
	if MatchConfig and "arcade" in MatchConfig and MatchConfig.arcade:
		kos_to_win = 2  # snappier rungs for the solo ladder
	if MatchConfig and "gauntlet" in MatchConfig and MatchConfig.gauntlet:
		kos_to_win = MatchConfig.gauntlet_kos_to_win()  # best-of-2 early, single-KO later
	_setup_active_players()
	_apply_match_colors()
	_style_hud()
	_build_special_pips()
	_setup_game_mode()
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

# A square special-ready pip by each active corner's block bar. The fill
# Polygon2D is scaled vertically by cooldown progress in _update_hud_bars; a
# dark backing square sits behind it. Dinos without a special get no pip.
func _build_special_pips() -> void:
	for p in active_players:
		if not ("special_type" in p) or p.special_type == "none":
			continue
		var pid: String = p.player_id
		var pos: Vector2 = PIP_POS.get(pid, Vector2.ZERO)
		var quad := PackedVector2Array([
			Vector2(0, 0), Vector2(PIP_SIZE, 0),
			Vector2(PIP_SIZE, PIP_SIZE), Vector2(0, PIP_SIZE)])
		var back := Polygon2D.new()
		back.polygon = quad
		back.color = PIP_BG
		back.position = pos
		back.z_index = 1
		$HUD.add_child(back)
		var fill := Polygon2D.new()
		# Upward quad anchored at the pip's bottom edge, so scaling y fills it
		# bottom-up as the special recharges.
		fill.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(PIP_SIZE, 0),
			Vector2(PIP_SIZE, -PIP_SIZE), Vector2(0, -PIP_SIZE)])
		fill.color = PIP_CHARGING
		fill.position = pos + Vector2(0, PIP_SIZE)
		fill.scale = Vector2(1, 0)
		fill.z_index = 2
		$HUD.add_child(fill)
		special_pips[pid] = {"fill": fill}

# --- Game modes ---
# All four modes run on the same arena. STOCK/KOTH/EGGS keep play continuous (no
# round resets); only ROUNDS uses the interstitial flow. The hill and the eggs are
# built procedurally here so every island plays every mode without editing scenes.

func _setup_game_mode() -> void:
	for p in active_players:
		stocks[p.player_id] = MatchConfig.STOCK_LIVES
		mode_score[p.player_id] = 0.0
	match game_mode:
		"koth":
			hill_center = _safe_center()
			_build_hill()
		"eggs":
			egg_spawn_timer = 0.5

func _circle_points(rx: float, ry: float, segs: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segs):
		var a: float = TAU * float(i) / float(segs)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts

# The arena background is at z 0 but earlier in the tree, so a runtime node at a
# lower z hides BEHIND it. Insert just before Player1 instead: same z 0, but tree
# order draws it over the background and under the fighters.
func _insert_under_players(node: Node) -> void:
	var first := get_node_or_null("Player1")
	if first:
		move_child(node, first.get_index())

func _build_hill() -> void:
	hill_visual = Node2D.new()
	hill_visual.position = hill_center
	add_child(hill_visual)
	_insert_under_players(hill_visual)
	var pts := _circle_points(HILL_RADIUS, HILL_RADIUS, 48)
	var disc := Polygon2D.new()
	disc.polygon = pts
	disc.color = Color(1.0, 0.92, 0.4, 0.2)
	hill_visual.add_child(disc)
	var loop := pts
	loop.append(pts[0])
	hill_ring = Line2D.new()
	hill_ring.points = loop
	hill_ring.width = 7.0
	hill_ring.default_color = Color(0.95, 0.9, 0.7, 0.85)  # bright neutral when empty/contested
	hill_visual.add_child(hill_ring)

# KOTH: the lone fighter inside the hill banks time; contested or empty scores
# nobody. The ring glows the holder's colour so the state reads at a glance.
func _update_koth(delta: float) -> void:
	var holders: Array = []
	for p in active_players:
		if eliminated.get(p.player_id, false):
			continue
		if p.global_position.distance_to(hill_center) <= HILL_RADIUS:
			holders.append(p)
	var ring_color := Color(0.95, 0.9, 0.7, 0.85)  # bright neutral: empty or contested
	if holders.size() == 1:
		var p: Node = holders[0]
		var pid: String = p.player_id
		mode_score[pid] = mode_score.get(pid, 0.0) + delta
		ring_color = MatchConfig.PLAYER_COLORS.get(pid, Color.WHITE)
		if mode_score[pid] >= MatchConfig.KOTH_TARGET:
			dp[pid] = dp.get(pid, 0) + 200
			end_match(p, _dino_name(pid))
			return
	if hill_ring:
		hill_ring.default_color = ring_color

# EGGS: loose eggs trickle onto the field; walk over one to bag it. First to the
# target wins. KOs just respawn (no score), so it's a frantic grab, not a brawl.
func _update_eggs(delta: float) -> void:
	egg_spawn_timer -= delta
	if egg_spawn_timer <= 0.0 and eggs.size() < EGG_MAX_ON_FIELD:
		_spawn_egg()
		egg_spawn_timer = EGG_SPAWN_INTERVAL
	for i in range(eggs.size() - 1, -1, -1):
		var egg: Node2D = eggs[i]
		if not is_instance_valid(egg):
			eggs.remove_at(i)
			continue
		for p in active_players:
			if eliminated.get(p.player_id, false):
				continue
			if p.global_position.distance_to(egg.position) <= EGG_PICKUP_RADIUS:
				_collect_egg(p, egg, i)
				break

func _spawn_egg() -> void:
	var egg := Node2D.new()
	egg.position = _random_safe_point()
	var shadow := Polygon2D.new()
	shadow.polygon = _circle_points(15.0, 6.0, 18)
	shadow.position = Vector2(0, 13)
	shadow.color = Color(0, 0, 0, 0.22)
	egg.add_child(shadow)
	var shell := Polygon2D.new()
	shell.polygon = _circle_points(13.0, 17.0, 22)
	shell.color = Color(0.98, 0.96, 0.88)
	egg.add_child(shell)
	var spot := Polygon2D.new()
	spot.polygon = _circle_points(4.0, 5.0, 14)
	spot.position = Vector2(-4, -3)
	spot.color = Color(0.85, 0.8, 0.6, 0.7)
	egg.add_child(spot)
	add_child(egg)
	_insert_under_players(egg)
	eggs.append(egg)

func _collect_egg(p: Node, egg: Node2D, i: int) -> void:
	var pid: String = p.player_id
	mode_score[pid] = mode_score.get(pid, 0.0) + 1.0
	dp[pid] = dp.get(pid, 0) + 60
	play_sfx("dodge", 0.12)  # light pickup blip (reuses an existing sound)
	if is_instance_valid(egg):
		egg.queue_free()
	eggs.remove_at(i)
	update_score_display()
	if mode_score[pid] >= float(MatchConfig.EGG_TARGET):
		end_match(p, _dino_name(pid))

func _random_safe_point() -> Vector2:
	for _attempt in range(28):
		var pt: Vector2
		if safe_polygon.size() >= 3:
			var bb := _polygon_bounds(safe_polygon)
			pt = Vector2(randf_range(bb.position.x, bb.end.x), randf_range(bb.position.y, bb.end.y))
			if not Geometry2D.is_point_in_polygon(pt, safe_polygon):
				continue
		else:
			var r := safe_rect.grow(-60.0)
			pt = Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))
		return pt
	return _safe_center()

func _polygon_bounds(poly: PackedVector2Array) -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for pt in poly:
		r = r.expand(pt)
	return r

# STOCK: a KO costs the victim a life; out of lives = eliminated. Last dino in wins.
func _award_ko_stock(killer: Node, victim: Node) -> void:
	dp[killer.player_id] = dp.get(killer.player_id, 0) + 100
	var vp: String = victim.player_id
	if eliminated.get(vp, false):
		return
	stocks[vp] = max(0, stocks.get(vp, 0) - 1)
	update_score_display()
	if stocks[vp] <= 0:
		_eliminate(victim)
		var alive: Array = _alive_players()
		if alive.size() <= 1:
			var winner: Node = alive[0] if alive.size() == 1 else killer
			end_match(winner, _dino_name(winner.player_id))

func _eliminate(p: Node) -> void:
	eliminated[p.player_id] = true
	p.visible = false
	p.velocity = Vector2.ZERO
	p.set_physics_process(false)
	p.set_process_input(false)

func _alive_players() -> Array:
	var arr: Array = []
	for p in active_players:
		if not eliminated.get(p.player_id, false):
			arr.append(p)
	return arr

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
	if match_over:
		if gauntlet_drafting:
			_draft_input()
		elif Input.is_action_just_pressed("restart"):
			if MatchConfig and "gauntlet" in MatchConfig and MatchConfig.gauntlet:
				MatchConfig.gauntlet = false  # run over -> back to the title
				get_tree().change_scene_to_file("res://scenes/title.tscn")
			elif MatchConfig and "arcade" in MatchConfig and MatchConfig.arcade:
				_arcade_continue()
			else:
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
			label.text = "%s  %s%s" % [_dino_name(p.player_id), _score_text(p), wsuffix]
		_update_special_pip(p)

# The per-mode scoreboard fragment shown after the dino name: round wins, lives
# left, hill seconds, or eggs bagged.
func _score_text(p: Node) -> String:
	var pid: String = p.player_id
	match game_mode:
		"stock":
			return "LIVES %d" % stocks.get(pid, 0)
		"koth":
			return "%ds / %ds" % [int(mode_score.get(pid, 0.0)), int(MatchConfig.KOTH_TARGET)]
		"eggs":
			return "EGGS %d / %d" % [int(mode_score.get(pid, 0.0)), MatchConfig.EGG_TARGET]
		_:
			return "%d / %d" % [round_wins.get(pid, 0), kos_to_win]

# Fill the special pip by recharge progress; glow bright gold + full once it's
# ready to fire (cooldown elapsed). A null/zero cooldown reads as always ready.
func _update_special_pip(p: Node) -> void:
	var pip: Dictionary = special_pips.get(p.player_id, {})
	if pip.is_empty():
		return
	var fill: Polygon2D = pip["fill"]
	var cd: float = p.special_cooldown if "special_cooldown" in p else 0.0
	var t: float = p.special_cooldown_timer if "special_cooldown_timer" in p else 0.0
	var progress: float = 1.0 if cd <= 0.0 else clamp(1.0 - t / cd, 0.0, 1.0)
	var ready: bool = t <= 0.0
	fill.scale.y = progress
	fill.color = PIP_READY if ready else PIP_CHARGING

func _physics_process(delta: float) -> void:
	if match_over or not round_active:
		return
	_separate_players()
	for p in active_players:
		if eliminated.get(p.player_id, false):
			continue  # out of the match (stock mode)
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
	if game_mode == "koth":
		_update_koth(delta)
	elif game_mode == "eggs":
		_update_eggs(delta)

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
	if match_over:
		return
	if killer == null or killer == victim or not (killer in active_players):
		return
	match game_mode:
		"stock":
			_award_ko_stock(killer, victim)
		"koth", "eggs":
			dp[killer.player_id] = dp.get(killer.player_id, 0) + 40  # KO bounty; no round
		_:
			_award_ko_rounds(killer)

func _award_ko_rounds(killer: Node) -> void:
	if not round_active:
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
			label.text = "%s  %s" % [display_name, _score_text(p)]

func end_match(winner: CharacterBody2D, label: String) -> void:
	if MatchConfig and "gauntlet" in MatchConfig and MatchConfig.gauntlet:
		_end_match_gauntlet(winner)
		return
	if MatchConfig and "arcade" in MatchConfig and MatchConfig.arcade:
		_end_match_arcade(winner)
		return
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

# Arcade ladder end-of-rung: win -> advance or crown champion; loss -> game over.
# START then routes through _arcade_continue.
func _end_match_arcade(winner: Node) -> void:
	match_over = true
	round_active = false
	for p in active_players:
		p.set_process_input(false)
		p.set_physics_process(false)
	var player_won: bool = winner != null and winner.player_id == "p1"
	var stage: int = MatchConfig.arcade_rung + 1
	var total: int = MatchConfig.arcade_ladder.size()
	if not player_won:
		arcade_end = "gameover"
		hud_win.text = "DEFEATED"
		hud_win.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		hud_hint.text = "REACHED STAGE %d / %d\n\npress START for the title" % [stage, total]
		play_sfx("ko", 0.0)
	elif MatchConfig.arcade_is_final():
		arcade_end = "champion"
		hud_win.text = "CHAMPION!"
		hud_win.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		hud_hint.text = "YOU CLEARED THE GAUNTLET\n\npress START for the title"
		play_sfx("win", 0.0)
	else:
		arcade_end = "advance"
		var next_dino: String = MatchConfig.arcade_ladder[MatchConfig.arcade_rung + 1]["dino"]
		var next_name: String = MatchConfig.DINOS[next_dino].display_name
		hud_win.text = "STAGE %d CLEARED" % stage
		hud_win.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
		hud_hint.text = "NEXT:  %s   (STAGE %d / %d)\n\npress START to continue" % [next_name, stage + 1, total]
		play_sfx("win", 0.0)

func _arcade_continue() -> void:
	if arcade_end == "advance":
		MatchConfig.arcade_advance()
		get_tree().change_scene_to_file(MatchConfig.arcade_scene())
	else:  # champion or gameover -> end the run, back to the title
		MatchConfig.arcade = false
		get_tree().change_scene_to_file("res://scenes/title.tscn")

# --- Gauntlet (roguelike) wave flow + upgrade draft ---

func _end_match_gauntlet(winner: Node) -> void:
	match_over = true
	round_active = false
	for p in active_players:
		p.set_process_input(false)
		p.set_physics_process(false)
	var player_won: bool = winner != null and winner.player_id == "p1"
	var wave: int = MatchConfig.gauntlet_wave + 1
	if not player_won:
		hud_win.text = "RUN OVER"
		hud_win.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		var newly: Array = MetaSave.record_run(wave)
		var msg: String = "REACHED WAVE %d   -   %d UPGRADES\nBEST WAVE %d" % [wave, MatchConfig.gauntlet_upgrades.size(), MetaSave.best_wave]
		for u in newly:
			msg += "\nNEW UNLOCK!   %s  -  %s" % [u["name"], u["blurb"]]
		msg += "\n\npress START for the title"
		hud_hint.text = msg
		play_sfx("ko", 0.0)
		return
	# Carry the survivor's HP into the next wave (the winner is always p1 here).
	MatchConfig.gauntlet_player_hp = max(1, winner.hp)
	# The draft draws its own header/prompt above and below the cards; clear the
	# centered scene labels so they don't bleed through the card row.
	hud_win.text = ""
	hud_hint.text = ""
	play_sfx("win", 0.0)
	_open_draft()

func _open_draft() -> void:
	draft_options = MatchConfig.gauntlet_draft_options()
	draft_index = 0
	gauntlet_drafting = true
	_build_draft_cards()

func _build_draft_cards() -> void:
	_clear_draft_cards()
	var n: int = draft_options.size()
	# Shrink cards to fit when EXTRA DRAFT offers 4 (3 keeps the full width).
	var card_w: float = min(DRAFT_CARD_W, (1200.0 - DRAFT_GAP * float(n - 1)) / float(n))
	var total: float = card_w * float(n) + DRAFT_GAP * float(n - 1)
	var x0: float = (1280.0 - total) / 2.0
	var y: float = 268.0
	# Header above the cards + prompt below — drawn in the HUD layer, tracked so
	# they're freed with the cards.
	var header := Label.new()
	header.position = Vector2(0, 214)
	header.size = Vector2(1280, 46)
	header.text = "WAVE %d CLEARED  -  CHOOSE AN UPGRADE" % (MatchConfig.gauntlet_wave + 1)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 34)
	header.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
	header.z_index = 50
	$HUD.add_child(header)
	draft_nodes.append(header)
	var prompt := Label.new()
	prompt.position = Vector2(0, 510)
	prompt.size = Vector2(1280, 40)
	prompt.text = "HP  %d / %d      LEFT / RIGHT  CHOOSE      A  TAKE IT" % [MatchConfig.gauntlet_player_hp, MatchConfig.gauntlet_player_max_hp()]
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	prompt.z_index = 50
	$HUD.add_child(prompt)
	draft_nodes.append(prompt)
	for i in range(draft_options.size()):
		var up: Dictionary = MatchConfig.UPGRADES.get(draft_options[i], {})
		var card := ColorRect.new()
		card.position = Vector2(x0 + i * (card_w + DRAFT_GAP), y)
		card.size = Vector2(card_w, DRAFT_CARD_H)
		card.pivot_offset = card.size * 0.5  # scale the highlighted card from its center
		card.z_index = 50
		var name_l := Label.new()
		name_l.position = Vector2(0, 40)
		name_l.size = Vector2(card_w, 48)
		name_l.text = up.get("name", "")
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.add_theme_font_size_override("font_size", 30)
		name_l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		card.add_child(name_l)
		var desc_l := Label.new()
		desc_l.position = Vector2(16, 116)
		desc_l.size = Vector2(card_w - 32, 80)
		desc_l.text = up.get("desc", "")
		desc_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_l.add_theme_font_size_override("font_size", 22)
		desc_l.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96))
		card.add_child(desc_l)
		$HUD.add_child(card)
		draft_nodes.append(card)
		draft_cards.append(card)
	_refresh_draft()

func _refresh_draft() -> void:
	for i in range(draft_cards.size()):
		var card: ColorRect = draft_cards[i]
		if i == draft_index:
			card.color = Color(0.20, 0.30, 0.46, 0.97)
			card.scale = Vector2(1.06, 1.06)
		else:
			card.color = Color(0.10, 0.12, 0.18, 0.92)
			card.scale = Vector2.ONE

func _draft_input() -> void:
	if Input.is_action_just_pressed("p1_left"):
		draft_index = (draft_index - 1 + draft_options.size()) % draft_options.size()
		_refresh_draft()
	elif Input.is_action_just_pressed("p1_right"):
		draft_index = (draft_index + 1) % draft_options.size()
		_refresh_draft()
	elif Input.is_action_just_pressed("p1_confirm"):
		MatchConfig.gauntlet_add_upgrade(draft_options[draft_index])
		gauntlet_drafting = false
		_clear_draft_cards()
		MatchConfig.gauntlet_next_wave()
		get_tree().change_scene_to_file(MatchConfig.gauntlet_scene())

func _clear_draft_cards() -> void:
	for n in draft_nodes:
		if is_instance_valid(n):
			n.queue_free()
	draft_nodes.clear()
	draft_cards.clear()

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
