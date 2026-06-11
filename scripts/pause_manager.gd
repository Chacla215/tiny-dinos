extends Node
## Global pause. Autoload with process_mode ALWAYS so it keeps running while the
## rest of the tree is paused. The "pause" action (controller Start) opens an
## overlay menu mid-match: RESUME -> HOW TO PLAY -> EXIT (back to the picker).
## HOW TO PLAY reuses the title screen's controller-map (controls_diagram.gd), so
## the in-match reference reads identically to the front end.

const SELECT_SCENE := "res://scenes/select.tscn"
const ControlsDiagram := preload("res://scripts/controls_diagram.gd")

# Gamepad-only front end: any of the four pads can drive the pause menu, matching
# title.gd. Back = B (heavy); Confirm = A; Start toggles/backs out.
const UP := ["p1_up", "p2_up", "p3_up", "p4_up"]
const DOWN := ["p1_down", "p2_down", "p3_down", "p4_down"]
const CONFIRM := ["p1_confirm", "p2_confirm", "p3_confirm", "p4_confirm"]
const BACK := ["p1_heavy", "p2_heavy", "p3_heavy", "p4_heavy"]

const ACCENT := Color(1.0, 0.88, 0.30, 1.0)     # P1 yellow = the "selected" color
const DIM_TEXT := Color(0.72, 0.72, 0.78, 1.0)

# Menu rows, top to bottom — HOW TO PLAY sits between RESUME and EXIT as asked.
const ITEMS := [
	{"base": "RESUME", "action": "resume"},
	{"base": "HOW TO PLAY", "action": "howto"},
	{"base": "EXIT", "action": "exit"},
]

var _layer: CanvasLayer
var _menu_root: Control          # dim + title + items + hint
var _howto_root: Control         # darker dim + panel + controls diagram
var _item_labels: Array = []     # parallel to ITEMS

var _paused: bool = false
var _howto_open: bool = false
var _selected: int = 0
var _nav_prev_dir: int = 0
var _t: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 128
	add_child(_layer)
	_build_menu()
	_build_howto()
	_menu_root.visible = false
	_howto_root.visible = false

func _process(delta: float) -> void:
	_t += delta
	if not _paused:
		if Input.is_action_just_pressed("pause"):
			_open_pause()
		return

	# How-to-Play sub-screen: B / A / Start all back out to the pause menu.
	if _howto_open:
		if _just(BACK) or _just(CONFIRM) or Input.is_action_just_pressed("pause"):
			_close_howto()
		return

	# Pause menu: Start resumes; otherwise navigate + confirm.
	if Input.is_action_just_pressed("pause"):
		_resume()
		return
	_handle_nav()
	if _just(CONFIRM):
		_activate(ITEMS[_selected]["action"])
	_pulse()

# --- state transitions ------------------------------------------------------

func _open_pause() -> void:
	# Only pausable inside a live match (the Main node has match_over), and not
	# once it's over (Start is the restart button on the win screen).
	var scene := get_tree().current_scene
	if scene == null or not ("match_over" in scene) or scene.match_over:
		return
	_paused = true
	_howto_open = false
	_selected = 0
	_nav_prev_dir = 0
	get_tree().paused = true
	_refresh_menu()
	_menu_root.visible = true
	_howto_root.visible = false

func _resume() -> void:
	_paused = false
	_howto_open = false
	get_tree().paused = false
	_menu_root.visible = false
	_howto_root.visible = false

func _exit_to_select() -> void:
	# Drop the pause before swapping scenes so the picker doesn't load paused, and
	# clear time_scale in case a hit-pause was mid-flight when the player paused.
	_paused = false
	_howto_open = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	_menu_root.visible = false
	_howto_root.visible = false
	get_tree().change_scene_to_file(SELECT_SCENE)

func _open_howto() -> void:
	_howto_open = true
	_menu_root.visible = false
	_howto_root.visible = true

func _close_howto() -> void:
	_howto_open = false
	_howto_root.visible = false
	_menu_root.visible = true

func _activate(action: String) -> void:
	Audio.ui("confirm")
	match action:
		"resume":
			_resume()
		"howto":
			_open_howto()
		"exit":
			_exit_to_select()

# --- navigation -------------------------------------------------------------

# Single press = single move, no auto-repeat. Fires only on the edge where the
# held direction changes (mirrors title.gd), so holding does nothing and the
# stick crossing its deadzone can't double-trigger.
func _handle_nav() -> void:
	var dir: int = 1 if _held(DOWN) else (-1 if _held(UP) else 0)
	if dir == _nav_prev_dir:
		return
	_nav_prev_dir = dir
	if dir != 0:
		Audio.ui("move")
		_selected = (_selected + dir + ITEMS.size()) % ITEMS.size()
		_refresh_menu()

func _refresh_menu() -> void:
	for i in range(_item_labels.size()):
		var l: Label = _item_labels[i]
		if i == _selected:
			l.text = ">   %s   <" % ITEMS[i]["base"]
			l.add_theme_color_override("font_color", ACCENT)
		else:
			l.text = ITEMS[i]["base"]
			l.add_theme_color_override("font_color", DIM_TEXT)

func _pulse() -> void:
	for i in range(_item_labels.size()):
		var l: Label = _item_labels[i]
		l.scale = Vector2.ONE * (1.06 + 0.03 * sin(_t * 5.0)) if i == _selected else Vector2.ONE

func _just(actions: Array) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			return true
	return false

func _held(actions: Array) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false

# --- overlay construction ---------------------------------------------------

func _build_menu() -> void:
	_menu_root = Control.new()
	_menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_menu_root)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.08, 0.7)  # matches the end-screen backdrop
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_root.add_child(dim)

	_make_label(_menu_root, "PAUSED", 150.0, 64)

	_item_labels.clear()
	var y := 320.0
	for item in ITEMS:
		_item_labels.append(_make_label(_menu_root, item["base"], y, 40))
		y += 80.0

	var hint := _make_label(_menu_root, "UP / DOWN  SELECT      A  CONFIRM      START  RESUME", 624.0, 18)
	hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1))

func _build_howto() -> void:
	_howto_root = Control.new()
	_howto_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_howto_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_howto_root)

	# Same backing as the title's HowToPanel: a heavy dim, then a framed panel,
	# then the controller diagram drawn on top in screen space.
	var hdim := ColorRect.new()
	hdim.color = Color(0.04, 0.04, 0.07, 0.85)
	hdim.set_anchors_preset(Control.PRESET_FULL_RECT)
	hdim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_howto_root.add_child(hdim)

	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.13, 0.2, 0.98)
	panel.position = Vector2(200.0, 80.0)
	panel.size = Vector2(880.0, 560.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_howto_root.add_child(panel)

	var diagram := ControlsDiagram.new()
	diagram.position = Vector2.ZERO
	_howto_root.add_child(diagram)

# Full-width label centered horizontally at a fixed y, inheriting the game's
# Jersey 25 theme font. Pivot is set to the screen center so the selection pulse
# scales from the middle, not the top-left corner.
func _make_label(parent: Node, text: String, y: float, size: int) -> Label:
	var box_h := float(size) + 24.0
	var l := Label.new()
	l.text = text
	l.position = Vector2(0.0, y)
	l.size = Vector2(1280.0, box_h)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	l.pivot_offset = Vector2(640.0, box_h / 2.0)
	parent.add_child(l)
	return l
