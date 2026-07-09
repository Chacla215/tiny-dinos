extends Node2D
# CAREER — PICK YOUR DINO. The one-time choice that starts a journey: the dino you
# pick here is the ONE you raise the whole way. Only reached when no career exists
# (a started career resumes straight to the DEN from the title). Gamepad-only.
const DinoScript := preload("res://scripts/dino.gd")
const Creator := preload("res://scripts/ralph_creator.gd")  # reuse its rich PROFILES

const ACCENT := Color(1.0, 0.88, 0.30)
const DIM := Color(0.72, 0.72, 0.78)

const LEFT := ["p1_left", "p2_left", "p3_left", "p4_left"]
const RIGHT := ["p1_right", "p2_right", "p3_right", "p4_right"]
const CONFIRM := ["p1_confirm", "p2_confirm", "p3_confirm", "p4_confirm"]
const BACK := ["p1_heavy", "p2_heavy", "p3_heavy", "p4_heavy"]

var _idx := 0
var _bob := 0.0
var _portrait: Control = null
var _dyn: Dictionary = {}

func _pressed(list: Array) -> bool:
	for a in list:
		if Input.is_action_just_pressed(a):
			return true
	return false

func _ready() -> void:
	if Audio: Audio.play_music("menu")
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.10, 0.14)
	bg.size = Vector2(1280, 720)
	add_child(bg)
	_label("CHOOSE YOUR DINO", Vector2(0, 40), 44, Color.WHITE, 1280, true)
	_label("THE ONE YOU'LL RAISE THE WHOLE JOURNEY", Vector2(0, 96), 24, DIM, 1280, true)
	_dyn["name"] = _label("", Vector2(650, 176), 52, ACCENT, 560)
	_dyn["sub"] = _label("", Vector2(650, 238), 26, Color(1.0, 0.8, 0.55), 560)
	_dyn["passive"] = _label("", Vector2(650, 286), 22, Color(0.6, 0.9, 1.0), 560)
	_dyn["bio"] = _label("", Vector2(650, 336), 22, Color(0.85, 0.88, 0.95), 560)
	_dyn["persona"] = _label("", Vector2(650, 470), 22, DIM, 560)
	_label("<  LB / RB  >   CHOOSE      A  BEGIN      B  BACK", Vector2(0, 664), 22, DIM, 1280, true)
	_refresh()

func _label(text: String, pos: Vector2, size: int, col: Color, w: float, center := false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(w, size + 40)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	return l

func _dino() -> String:
	return MatchConfig.ROSTER_ORDER[_idx]

func _refresh() -> void:
	var id: String = _dino()
	var prof: Dictionary = Creator.PROFILES.get(id, {})
	if _portrait:
		_portrait.queue_free()
	_portrait = _make_portrait(id, Rect2(70, 150, 520, 440))
	_dyn["name"].text = prof.get("display_name", id.to_upper())
	_dyn["sub"].text = prof.get("subtitle", "")
	_dyn["passive"].text = prof.get("passive", "")
	_dyn["bio"].text = prof.get("bio", "")
	_dyn["persona"].text = prof.get("personality", "")

func _make_portrait(dino_id: String, rect: Rect2) -> Control:
	var hero := "res://assets/concept/%s/%s_hero.png" % [dino_id, dino_id]
	var t := TextureRect.new()
	if ResourceLoader.exists(hero):
		t.texture = load(hero)
	else:
		var role: String = MatchConfig.DINOS.get(dino_id, {}).get("sprite_role", dino_id)
		var at := DinoScript.first_frame(role)
		if at: t.texture = at
		t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = rect.position
	t.size = rect.size
	add_child(t)
	return t

func _process(delta: float) -> void:
	_bob += delta * 2.2
	if _portrait:
		_portrait.position.y = 150.0 + sin(_bob) * 8.0
	# LB/RB (swap) or D-pad left/right to browse the roster.
	var swap_l: bool = Input.is_action_just_pressed("p1_swap")  # RB steps forward
	if _pressed(RIGHT) or swap_l:
		_idx = (_idx + 1) % MatchConfig.ROSTER_ORDER.size()
		if Audio: Audio.ui("move")
		_refresh()
	elif _pressed(LEFT) or Input.is_action_just_pressed("p1_special"):  # LB steps back
		_idx = (_idx - 1 + MatchConfig.ROSTER_ORDER.size()) % MatchConfig.ROSTER_ORDER.size()
		if Audio: Audio.ui("move")
		_refresh()
	elif _pressed(CONFIRM):
		var id: String = _dino()
		var nm: String = Creator.PROFILES.get(id, {}).get("display_name", id.to_upper())
		MetaSave.career_begin(id, nm)
		if Audio: Audio.ui("confirm")
		get_tree().change_scene_to_file("res://scenes/career_home.tscn")
	elif _pressed(BACK):
		if Audio: Audio.ui("back")
		get_tree().change_scene_to_file("res://scenes/title.tscn")
