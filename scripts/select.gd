extends Node2D

const START_DELAY := 0.8

@onready var countdown_label: Label = $Countdown
@onready var panels := {
	"p1": $P1Panel,
	"p2": $P2Panel,
	"p3": $P3Panel,
	"p4": $P4Panel,
}
@onready var island_label: Label = $IslandLabel

var indexes: Dictionary = {"p1": 0, "p2": 1, "p3": 2, "p4": 3}
var island_idx: int = 0
var ready_states: Dictionary = {"p1": false, "p2": false, "p3": false, "p4": false}
var active_players: Array = []
var start_timer: float = 0.0

func _ready() -> void:
	var controller_count: int = Input.get_connected_joypads().size()
	var player_count: int = clamp(controller_count, 2, 4)
	if controller_count < 2:
		player_count = 2
	MatchConfig.player_count = player_count
	for pid in MatchConfig.PLAYER_IDS:
		var slot_num: int = int(pid.substr(1))
		var is_active: bool = slot_num <= player_count
		panels[pid].visible = is_active
		if is_active:
			active_players.append(pid)
			indexes[pid] = clamp(indexes[pid], 0, MatchConfig.ROSTER_ORDER.size() - 1)
			_apply_player_color_to_panel(pid)
			_update_display(pid)
	countdown_label.text = ""
	island_idx = MatchConfig.ISLAND_ORDER.find(MatchConfig.island)
	if island_idx < 0:
		island_idx = 0
	_update_island()

func _process(delta: float) -> void:
	var all_ready: bool = true
	for pid in active_players:
		if not ready_states[pid]:
			all_ready = false
			break
	if all_ready:
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

func _handle_player_input(pid: String) -> void:
	if not ready_states[pid]:
		var idx: int = indexes[pid]
		if Input.is_action_just_pressed("%s_left" % pid):
			idx = (idx - 1 + MatchConfig.ROSTER_ORDER.size()) % MatchConfig.ROSTER_ORDER.size()
			_set_idx(pid, idx)
		elif Input.is_action_just_pressed("%s_right" % pid):
			idx = (idx + 1) % MatchConfig.ROSTER_ORDER.size()
			_set_idx(pid, idx)
		if Input.is_action_just_pressed("%s_confirm" % pid):
			_set_ready(pid, true)
	else:
		if Input.is_action_just_pressed("%s_block" % pid):
			_set_ready(pid, false)

func _set_idx(pid: String, idx: int) -> void:
	indexes[pid] = idx
	_update_display(pid)

func _set_ready(pid: String, ready_state: bool) -> void:
	ready_states[pid] = ready_state
	var all_ready: bool = true
	for active_pid in active_players:
		if not ready_states[active_pid]:
			all_ready = false
			break
	if all_ready:
		start_timer = START_DELAY
	_update_display(pid)

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
	if ready_states[pid]:
		status_label.text = "READY"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5, 1))
	else:
		status_label.text = "<  A  >"
		status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))

func _apply_player_color_to_panel(pid: String) -> void:
	var color: Color = MatchConfig.PLAYER_COLORS.get(pid, Color.WHITE)
	var panel: Node2D = panels[pid]
	var header: Label = panel.get_node("Header")
	header.add_theme_color_override("font_color", color)

func _update_island() -> void:
	MatchConfig.island = MatchConfig.ISLAND_ORDER[island_idx]
	island_label.text = "Island:  %s    (P1 up / down)" % MatchConfig.ISLAND_NAMES[MatchConfig.island]

func _start_match() -> void:
	for pid in active_players:
		MatchConfig.dino_choices[pid] = MatchConfig.ROSTER_ORDER[indexes[pid]]
	var scene_path: String = MatchConfig.ISLAND_SCENES.get(MatchConfig.island, "res://scenes/main.tscn")
	get_tree().change_scene_to_file(scene_path)
