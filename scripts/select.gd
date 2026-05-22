extends Node2D

const START_DELAY := 0.8
# Weapons you can pick (fists is always the other half of the loadout).
const WEAPON_PICKS := ["sword", "dagger", "axe", "mace", "hammer", "nunchucks"]

@onready var countdown_label: Label = $Countdown
@onready var panels := {
	"p1": $P1Panel,
	"p2": $P2Panel,
	"p3": $P3Panel,
	"p4": $P4Panel,
}
@onready var island_label: Label = $IslandLabel
@onready var hint_label: Label = $Hint

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
	var player_count: int = clamp(controller_count, 2, 4)
	if controller_count < 2:
		player_count = 2
	MatchConfig.player_count = player_count
	var solo: bool = controller_count < 2
	for pid in MatchConfig.PLAYER_IDS:
		var slot_num: int = int(pid.substr(1))
		var is_active: bool = slot_num <= player_count
		panels[pid].visible = is_active
		if is_active:
			active_players.append(pid)
			cpu_states[pid] = solo and pid != "p1"
			indexes[pid] = clamp(indexes[pid], 0, MatchConfig.ROSTER_ORDER.size() - 1)
			_apply_player_color_to_panel(pid)
			_update_display(pid)
	countdown_label.text = ""
	hint_label.text = "<- ->  choose      A / F / .  confirm (dino > weapon > ready)      RB / G / ,  back      heavy  toggle CPU"
	island_idx = MatchConfig.ISLAND_ORDER.find(MatchConfig.island)
	if island_idx < 0:
		island_idx = 0
	_update_island()

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
	for pid in active_players:
		_handle_player_input(pid)

func _all_ready() -> bool:
	for pid in active_players:
		if not cpu_states[pid] and not ready_states[pid]:
			return false
	return true

func _handle_player_input(pid: String) -> void:
	# Opponent slots can be flipped HUMAN <-> CPU. P1 stays the human host.
	if pid != "p1" and Input.is_action_just_pressed("%s_heavy" % pid):
		cpu_states[pid] = not cpu_states[pid]
		ready_states[pid] = false
		stages[pid] = "dino"
		_update_display(pid)
		_refresh_start()

	if cpu_states[pid]:
		# Bot: pick its dino (still left/right), default loadout, auto-ready.
		if Input.is_action_just_pressed("%s_left" % pid):
			_cycle_dino(pid, -1)
		elif Input.is_action_just_pressed("%s_right" % pid):
			_cycle_dino(pid, 1)
		return

	var left := Input.is_action_just_pressed("%s_left" % pid)
	var right := Input.is_action_just_pressed("%s_right" % pid)
	var confirm := Input.is_action_just_pressed("%s_confirm" % pid)
	var back := Input.is_action_just_pressed("%s_block" % pid)

	match stages[pid]:
		"dino":
			if left: _cycle_dino(pid, -1)
			elif right: _cycle_dino(pid, 1)
			if confirm:
				stages[pid] = "weapon"
				_update_display(pid)
		"weapon":
			if left: _cycle_weapon(pid, -1)
			elif right: _cycle_weapon(pid, 1)
			if confirm:
				stages[pid] = "ready"
				_set_ready(pid, true)
			elif back:
				stages[pid] = "dino"
				_update_display(pid)
		"ready":
			if back:
				stages[pid] = "weapon"
				_set_ready(pid, false)

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
	var preview: Polygon2D = panel.get_node("Preview")

	name_label.text = dino.display_name
	name_label.add_theme_color_override("font_color", dino.dino_color)
	preview.color = dino.dino_color

	if cpu_states[pid]:
		status_label.text = "CPU  <  >"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1))
		return
	match stages[pid]:
		"dino":
			status_label.text = "<  PICK DINO  >"
			status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
		"weapon":
			status_label.text = "<  %s  >" % _weapon_label(pid)
			status_label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0, 1))
		"ready":
			status_label.text = "READY  -  %s" % _weapon_label(pid)
			status_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5, 1))

func _apply_player_color_to_panel(pid: String) -> void:
	var color: Color = MatchConfig.PLAYER_COLORS.get(pid, Color.WHITE)
	var panel: Node2D = panels[pid]
	var header: Label = panel.get_node("Header")
	header.add_theme_color_override("font_color", color)

func _update_island() -> void:
	MatchConfig.island = MatchConfig.ISLAND_ORDER[island_idx]
	island_label.text = "Island:  %s    (P1 up / down)" % MatchConfig.ISLAND_NAMES[MatchConfig.island]

func _start_match() -> void:
	MatchConfig.weapon_choices = {}
	for pid in MatchConfig.PLAYER_IDS:
		MatchConfig.cpu_players[pid] = cpu_states.get(pid, false)
	for pid in active_players:
		MatchConfig.dino_choices[pid] = MatchConfig.ROSTER_ORDER[indexes[pid]]
		# Humans get their picked weapon; CPUs keep the dino's default loadout.
		if not cpu_states[pid]:
			MatchConfig.weapon_choices[pid] = WEAPON_PICKS[weapon_idx[pid]]
	var scene_path: String = MatchConfig.ISLAND_SCENES.get(MatchConfig.island, "res://scenes/main.tscn")
	get_tree().change_scene_to_file(scene_path)
