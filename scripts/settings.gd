extends Node2D

# SETTINGS — audio volumes. Gamepad-only: UP/DOWN pick a row, LEFT/RIGHT turn
# the knob, B returns to title. MUSIC adjusts audibly under the menu theme; SFX
# blips at each step so both can be set by ear. Steps persist in MetaSave and
# apply live through the Audio autoload (see Audio.set_volume_step).

const TITLE_SCENE := "res://scenes/title.tscn"
const ACCENT := Color(1.0, 0.85, 0.30)
const DIM := Color(0.74, 0.74, 0.82)
const BAR_OFF := Color(0.22, 0.21, 0.30)

const UP := ["p1_up", "p2_up", "p3_up", "p4_up"]
const DOWN := ["p1_down", "p2_down", "p3_down", "p4_down"]
const LEFT := ["p1_left", "p2_left", "p3_left", "p4_left"]
const RIGHT := ["p1_right", "p2_right", "p3_right", "p4_right"]
const BACK := ["p1_heavy", "p2_heavy", "p3_heavy", "p4_heavy"]

const ROW_Y := [300.0, 400.0]
const SEG_W := 34.0
const SEG_H := 26.0
const SEG_GAP := 8.0
const BAR_X := 560.0

# rows[i] = {name, label: Label, arrows: [Label, Label], segs: [ColorRect], value: Label}
var rows: Array = []
var selected: int = 0
var nav_prev: int = 0
var adj_prev: int = 0

func _ready() -> void:
	Audio.play_music("menu")
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.10)
	bg.size = Vector2(1280, 720)
	add_child(bg)
	_label("SETTINGS", 0, 56, 1280, 56, ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 40)
	_label("SET THE MIX BY EAR - IT SAVES AS YOU GO", 0, 124, 1280, 34, DIM, HORIZONTAL_ALIGNMENT_CENTER, 22)
	for i in range(Audio.VOLUME_BUSES.size()):
		_build_row(i, Audio.VOLUME_BUSES[i], ROW_Y[i])
	_label("UP / DOWN  SELECT      LEFT / RIGHT  ADJUST      B  BACK",
		0, 662, 1280, 34, DIM, HORIZONTAL_ALIGNMENT_CENTER, 24)
	_refresh()

func _build_row(_i: int, bus: String, y: float) -> void:
	var row: Dictionary = {"name": bus}
	row["label"] = _label("%s VOLUME" % bus.to_upper(), 220, y, 300, 40, DIM, HORIZONTAL_ALIGNMENT_LEFT, 30)
	row["arrows"] = [
		_label("◀", BAR_X - 44, y, 36, 40, DIM, HORIZONTAL_ALIGNMENT_CENTER, 30),
		_label("▶", BAR_X + Audio.VOL_STEPS * (SEG_W + SEG_GAP), y, 36, 40, DIM, HORIZONTAL_ALIGNMENT_CENTER, 30),
	]
	var segs: Array = []
	for s in range(Audio.VOL_STEPS):
		var seg := ColorRect.new()
		seg.position = Vector2(BAR_X + s * (SEG_W + SEG_GAP), y + (40.0 - SEG_H) / 2.0)
		seg.size = Vector2(SEG_W, SEG_H)
		add_child(seg)
		segs.append(seg)
	row["segs"] = segs
	row["value"] = _label("", BAR_X + Audio.VOL_STEPS * (SEG_W + SEG_GAP) + 44, y, 80, 40, DIM, HORIZONTAL_ALIGNMENT_LEFT, 30)
	rows.append(row)

func _label(text: String, x: float, y: float, w: float, h: float, col: Color, align: int, fs: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(x, y)
	l.size = Vector2(w, h)
	l.horizontal_alignment = align
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", fs)
	add_child(l)
	return l

func _refresh() -> void:
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var on: bool = i == selected
		var step: int = Audio.get_volume_step(row["name"])
		row["label"].add_theme_color_override("font_color", ACCENT if on else DIM)
		for a in row["arrows"]:
			a.add_theme_color_override("font_color", ACCENT if on else DIM)
			a.visible = on
		for s in range(row["segs"].size()):
			row["segs"][s].color = (ACCENT if on else DIM) if s < step else BAR_OFF
		row["value"].text = "MUTE" if step == 0 else str(step)
		row["value"].add_theme_color_override("font_color", ACCENT if on else DIM)

func _process(_delta: float) -> void:
	for a in BACK:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			Audio.ui("back")
			get_tree().change_scene_to_file(TITLE_SCENE)
			return
	# Edge-triggered nav, same idiom as the title: fires on held-direction change.
	var dir: int = 1 if _held(DOWN) else (-1 if _held(UP) else 0)
	if dir != nav_prev:
		nav_prev = dir
		if dir != 0:
			Audio.ui("move")
			selected = (selected + dir + rows.size()) % rows.size()
			_refresh()
	var adj: int = 1 if _held(RIGHT) else (-1 if _held(LEFT) else 0)
	if adj != adj_prev:
		adj_prev = adj
		if adj != 0:
			_adjust(adj)

func _adjust(dir: int) -> void:
	var bus: String = rows[selected]["name"]
	var step: int = clampi(Audio.get_volume_step(bus) + dir, 0, Audio.VOL_STEPS)
	if step == Audio.get_volume_step(bus):
		Audio.ui("back")   # bumped the end of the range
		return
	Audio.set_volume_step(bus, step)
	# Audition the change: SFX blips at its new level; MUSIC is already audible.
	if bus == "SFX":
		Audio.ui("confirm")
	else:
		Audio.ui("move")
	_refresh()

func _held(actions: Array) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false
