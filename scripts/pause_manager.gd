extends Node
## Global pause. Autoload with process_mode ALWAYS so it keeps running while the
## rest of the tree is paused. Toggles get_tree().paused on the "pause" action
## (controller Start), but only inside an active match.

var _layer: CanvasLayer
var _dim: ColorRect
var _label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 128
	add_child(_layer)

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	_layer.add_child(_dim)

	_label = Label.new()
	_label.text = "PAUSED\n\npress START to resume"
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 60)
	_label.add_theme_constant_override("outline_size", 10)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_label.visible = false
	_layer.add_child(_label)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_toggle()

func _toggle() -> void:
	var scene := get_tree().current_scene
	# Only pausable inside a match (the Main node has match_over), and not once
	# the match is over (Start is the restart button on the win screen).
	if scene == null or not ("match_over" in scene) or scene.match_over:
		return
	var now_paused := not get_tree().paused
	get_tree().paused = now_paused
	_dim.visible = now_paused
	_label.visible = now_paused
