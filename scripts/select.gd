extends Node2D

const START_DELAY := 0.8
# Weapons you can pick (fists is always the other half of the loadout).
const WEAPON_PICKS := ["sword", "dagger", "axe", "mace", "hammer", "nunchucks"]

# The picker shows the SAME art the match uses, so pick == play. Dinos render
# from dino.gd's ANIM_LAYOUTS; islands use each arena's actual gameplay
# background (NOT the hand-drawn concept cards). Frozen Floes is drawn
# procedurally, so it gets a generated preview that matches its layout.
const DinoScript := preload("res://scripts/dino.gd")
const ISLAND_PREVIEW := {
	"laughing_lava":     "res://assets/tilesets/example2.png",
	"beauty_beach":      "res://assets/tilesets/beauty_beach_bg.png",
	"sunny_springs":     "res://assets/tilesets/example4.png",
	"white_water_falls": "res://assets/tilesets/example3.png",
	"purple_fields":     "res://assets/tilesets/purple_fields_bg.png",
}
const PANEL_Y := 430.0          # baseline for the player cards row
const GRAPHIC_TARGET_H := 170.0 # all dino sprites scaled to this height (consistent size)
const ISLAND_BG_WIDTH := 680.0  # centerpiece island preview width

@onready var countdown_label: Label = $Countdown
@onready var panels := {
	"p1": $P1Panel,
	"p2": $P2Panel,
	"p3": $P3Panel,
	"p4": $P4Panel,
}
@onready var island_label: Label = $IslandLabel
@onready var hint_label: Label = $Hint
@onready var island_bg: Sprite2D = $IslandBg

var indexes: Dictionary = {"p1": 0, "p2": 1, "p3": 2, "p4": 3}
var weapon_idx: Dictionary = {"p1": 0, "p2": 0, "p3": 0, "p4": 0}
var stages: Dictionary = {"p1": "dino", "p2": "dino", "p3": "dino", "p4": "dino"}
var island_idx: int = 0
var ready_states: Dictionary = {"p1": false, "p2": false, "p3": false, "p4": false}
var cpu_states: Dictionary = {"p1": false, "p2": false, "p3": false, "p4": false}
var active_players: Array = []
var start_timer: float = 0.0

func _ready() -> void:
	var controller_count: int = Input.get_connected_joypads().size()
	var solo: bool = controller_count < 2
	var initial_count: int = clamp(controller_count, 2, 4)
	if controller_count < 2:
		initial_count = 2
	# Per-slot defaults: solo fills opponents with CPUs; multi-controller = humans.
	for pid in MatchConfig.PLAYER_IDS:
		cpu_states[pid] = solo and pid != "p1"
		indexes[pid] = clamp(indexes[pid], 0, MatchConfig.ROSTER_ORDER.size() - 1)
		_apply_player_color_to_panel(pid)
	_apply_active_count(initial_count)
	countdown_label.text = ""
	hint_label.text = "<- -> choose    A/F/. confirm    RB/G/, back    heavy human/CPU    LB/B add opponent    P1 picks each CPU's dino + weapon"
	island_idx = MatchConfig.ISLAND_ORDER.find(MatchConfig.island)
	if island_idx < 0:
		island_idx = 0
	_update_island()

# Activate the first n player slots (2-4); the rest are hidden. Rebuilds the row.
func _apply_active_count(n: int) -> void:
	MatchConfig.player_count = clamp(n, 2, 4)
	active_players.clear()
	for pid in MatchConfig.PLAYER_IDS:
		var is_active: bool = int(pid.substr(1)) <= MatchConfig.player_count
		panels[pid].visible = is_active
		if is_active:
			active_players.append(pid)
	# Position cards first so _set_graphic can face each dino toward center.
	_layout_panels()
	for pid in active_players:
		_update_display(pid)
	_refresh_start()

# Host adds a computer opponent (cycles 2 -> 3 -> 4 -> 2 players). Newly added
# opponent slots default to CPU, so a solo player can fight 1-v-2 or 1-v-3.
func _cycle_opponent_count() -> void:
	var prev: int = MatchConfig.player_count
	var n: int = prev + 1 if prev < 4 else 2
	_apply_active_count(n)
	for pid in active_players:
		if int(pid.substr(1)) > prev and pid != "p1":
			cpu_states[pid] = true
			ready_states[pid] = false
			stages[pid] = "dino"
	_refresh_displays()
	_refresh_start()

func _process(delta: float) -> void:
	if _all_ready():
		start_timer -= delta
		countdown_label.text = "STARTING..."
		if start_timer <= 0.0:
			_start_match()
		return
	countdown_label.text = ""
	if Input.is_action_just_pressed("p1_up"):
		island_idx = (island_idx - 1 + MatchConfig.ISLAND_ORDER.size()) % MatchConfig.ISLAND_ORDER.size()
		_update_island()
	elif Input.is_action_just_pressed("p1_down"):
		island_idx = (island_idx + 1) % MatchConfig.ISLAND_ORDER.size()
		_update_island()
	# Host adds/cycles computer opponents (1-v-2, 1-v-3, ...).
	if Input.is_action_just_pressed("p1_special"):
		_cycle_opponent_count()
	# Opponent slots can be flipped HUMAN <-> CPU before they're locked in.
	for pid in active_players:
		if pid != "p1" and Input.is_action_just_pressed("%s_heavy" % pid):
			cpu_states[pid] = not cpu_states[pid]
			ready_states[pid] = false
			stages[pid] = "dino"
			_refresh_displays()
			_refresh_start()
	# P1 (the host) configures their own fighter first, then every CPU's dino
	# AND weapon, all on the LEFT stick. Human opponents pick on their own pads.
	var target: String = _host_focus()
	if target == "":
		# All host slots locked; let BACK still un-ready the most recent pick.
		var q: Array = _host_queue()
		if not q.is_empty():
			target = q[q.size() - 1]
	if target != "":
		_drive_slot(target, "p1", target != "p1")
	for pid in active_players:
		if pid != "p1" and not cpu_states[pid]:
			_drive_slot(pid, pid, false)

# The slots P1 configures, in order: P1's own fighter, then each CPU opponent.
# Human opponents are absent here -- they drive their own slots with their pads.
func _host_queue() -> Array:
	var arr: Array = ["p1"]
	for pid in active_players:
		if pid != "p1" and cpu_states[pid]:
			arr.append(pid)
	return arr

# The slot P1 is editing right now: first one in the queue not yet locked in.
func _host_focus() -> String:
	for pid in _host_queue():
		if not ready_states[pid]:
			return pid
	return ""

func _all_ready() -> bool:
	for pid in active_players:
		if not ready_states[pid]:
			return false
	return true

# Run one slot's dino -> weapon -> ready picker from the `src` controller's
# inputs. `host_edit` is true when P1 is configuring a CPU: BACK on its dino
# stage steps focus back to the previous fighter in the queue.
func _drive_slot(pid: String, src: String, host_edit: bool) -> void:
	var left := Input.is_action_just_pressed("%s_left" % src)
	var right := Input.is_action_just_pressed("%s_right" % src)
	var confirm := Input.is_action_just_pressed("%s_confirm" % src)
	var back := Input.is_action_just_pressed("%s_block" % src)

	match stages[pid]:
		"dino":
			if left: _cycle_dino(pid, -1)
			elif right: _cycle_dino(pid, 1)
			if confirm:
				stages[pid] = "weapon"
				_refresh_displays()
			elif back and host_edit:
				_host_back_to_prev(pid)
		"weapon":
			if left: _cycle_weapon(pid, -1)
			elif right: _cycle_weapon(pid, 1)
			if confirm:
				stages[pid] = "ready"
				_set_ready(pid, true)
			elif back:
				stages[pid] = "dino"
				_refresh_displays()
		"ready":
			if back:
				stages[pid] = "weapon"
				_set_ready(pid, false)

# P1 pressed BACK while picking a CPU's dino: re-open the previous fighter in
# the queue (un-ready it) so P1 can change that pick before continuing.
func _host_back_to_prev(pid: String) -> void:
	var q: Array = _host_queue()
	var i: int = q.find(pid)
	if i <= 0:
		return
	var prev: String = q[i - 1]
	stages[prev] = "weapon"
	_set_ready(prev, false)

func _cycle_dino(pid: String, step: int) -> void:
	var n: int = MatchConfig.ROSTER_ORDER.size()
	indexes[pid] = (indexes[pid] + step + n) % n
	_update_display(pid)

func _cycle_weapon(pid: String, step: int) -> void:
	var n: int = WEAPON_PICKS.size()
	weapon_idx[pid] = (weapon_idx[pid] + step + n) % n
	_update_display(pid)

func _set_ready(pid: String, ready_state: bool) -> void:
	ready_states[pid] = ready_state
	_refresh_start()
	_refresh_displays()

func _refresh_displays() -> void:
	for pid in active_players:
		_update_display(pid)

func _refresh_start() -> void:
	if _all_ready():
		start_timer = START_DELAY

func _weapon_label(pid: String) -> String:
	var wid: String = WEAPON_PICKS[weapon_idx[pid]]
	return MatchConfig.WEAPONS.get(wid, {}).get("display_name", wid.to_upper())

func _update_display(pid: String) -> void:
	var idx: int = indexes[pid]
	var dino_id: String = MatchConfig.ROSTER_ORDER[idx]
	var dino: Dictionary = MatchConfig.DINOS[dino_id]
	var panel: Node2D = panels[pid]
	var name_label: Label = panel.get_node("Name")
	var status_label: Label = panel.get_node("Status")
	var header_label: Label = panel.get_node("Header")
	var graphic: AnimatedSprite2D = panel.get_node("Graphic")

	name_label.text = dino.display_name
	name_label.add_theme_color_override("font_color", dino.dino_color)
	_set_graphic(graphic, dino_id)

	var is_cpu: bool = cpu_states[pid]
	header_label.text = "PLAYER %s  (CPU)" % pid.substr(1) if is_cpu else "PLAYER %s" % pid.substr(1)

	# A CPU the host hasn't reached yet waits in line, dimmed; the slot P1 (or a
	# human) is actively editing is at full brightness.
	var waiting: bool = is_cpu and not ready_states[pid] and _host_focus() != pid
	panel.modulate = Color(1, 1, 1, 0.4) if waiting else Color(1, 1, 1, 1)
	if waiting:
		status_label.text = "CPU   .   up next"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1))
		return

	var prefix: String = "CPU   " if is_cpu else ""
	match stages[pid]:
		"dino":
			status_label.text = "%s<  PICK DINO  >" % prefix
			status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
		"weapon":
			status_label.text = "%s<  %s  >" % [prefix, _weapon_label(pid)]
			status_label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0, 1))
		"ready":
			status_label.text = "%sREADY  -  %s" % [prefix, _weapon_label(pid)]
			status_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5, 1))

func _apply_player_color_to_panel(pid: String) -> void:
	var color: Color = MatchConfig.PLAYER_COLORS.get(pid, Color.WHITE)
	var panel: Node2D = panels[pid]
	var header: Label = panel.get_node("Header")
	header.add_theme_color_override("font_color", color)

func _update_island() -> void:
	MatchConfig.island = MatchConfig.ISLAND_ORDER[island_idx]
	island_label.text = "Island:  %s    (P1 up / down)" % MatchConfig.ISLAND_NAMES[MatchConfig.island]
	_set_island_bg(MatchConfig.island)

# --- Concept-art helpers ---

# Spread the active player cards evenly across the screen in a single row.
func _layout_panels() -> void:
	var n: int = active_players.size()
	for i in range(n):
		var pid: String = active_players[i]
		panels[pid].position = Vector2(1280.0 * (i + 0.5) / n, PANEL_Y)

# Show the dino's in-game sprite (idle anim) so the picker matches the match.
# Built from the same ANIM_LAYOUTS the dino uses, scaled to a consistent height.
func _set_graphic(graphic: AnimatedSprite2D, dino_id: String) -> void:
	var dino: Dictionary = MatchConfig.DINOS.get(dino_id, {})
	var role: String = dino.get("sprite_role", "")
	var layouts: Dictionary = DinoScript.ANIM_LAYOUTS
	if not layouts.has(role):
		graphic.sprite_frames = null
		return
	var layout: Dictionary = layouts[role]
	var sheet_path: String = layout.get("sheet", "")
	if not ResourceLoader.exists(sheet_path):
		graphic.sprite_frames = null
		return
	var sheet: Texture2D = load(sheet_path)
	var idle: Dictionary = layout.get("idle", {})
	var rects: Array = idle.get("rects", [])
	if rects.is_empty():
		graphic.sprite_frames = null
		return
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("idle")
	sf.set_animation_loop("idle", true)
	sf.set_animation_speed("idle", idle.get("speed", 4.0))
	for r in rects:
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = r
		sf.add_frame("idle", at)
	graphic.sprite_frames = sf
	var s: float = GRAPHIC_TARGET_H / rects[0].size.y
	graphic.scale = Vector2(s, s)
	# Face toward screen center: left-side dinos look right, right-side look left.
	var faces_left_art: bool = layout.get("faces_left", false)
	var on_left: bool = graphic.get_parent().position.x < 640.0
	graphic.flip_h = faces_left_art if on_left else not faces_left_art
	graphic.play("idle")

# Dimmed island concept art behind the cards, so players preview the arena.
func _set_island_bg(island_id: String) -> void:
	var path: String = ISLAND_PREVIEW.get(island_id, "")
	if path == "" or not ResourceLoader.exists(path):
		island_bg.texture = null
		return
	var tex: Texture2D = load(path)
	island_bg.texture = tex
	island_bg.scale = Vector2(ISLAND_BG_WIDTH / tex.get_width(), ISLAND_BG_WIDTH / tex.get_width())

func _start_match() -> void:
	MatchConfig.weapon_choices = {}
	for pid in MatchConfig.PLAYER_IDS:
		MatchConfig.cpu_players[pid] = cpu_states.get(pid, false)
	for pid in active_players:
		MatchConfig.dino_choices[pid] = MatchConfig.ROSTER_ORDER[indexes[pid]]
		# Every fighter -- human or CPU -- now carries a weapon the host picked.
		MatchConfig.weapon_choices[pid] = WEAPON_PICKS[weapon_idx[pid]]
	var scene_path: String = MatchConfig.ISLAND_SCENES.get(MatchConfig.island, "res://scenes/main.tscn")
	get_tree().change_scene_to_file(scene_path)
