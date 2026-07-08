extends Node2D
# CAREER HOME / DEN — the between-fights care hub. Your bonded dino rests here;
# you FEED / REST / TRAIN it, then head to the next stop on the journey. This is
# the heart of the "bond" — caring for one dino you carry the whole way.
# Gamepad-only, ALL CAPS, same input rules as the other screens.
const DinoScript := preload("res://scripts/dino.gd")

const ARENA_MATCH := "res://scenes/main.tscn"  # career_scene() overrides per island
const ACCENT := Color(1.0, 0.88, 0.30)         # selected = P1 yellow
const DIM := Color(0.72, 0.72, 0.78)
const GOOD := Color(0.45, 0.92, 0.5)
const BAD := Color(1.0, 0.42, 0.42)

const UP := ["p1_up", "p2_up", "p3_up", "p4_up"]
const DOWN := ["p1_down", "p2_down", "p3_down", "p4_down"]
const CONFIRM := ["p1_confirm", "p2_confirm", "p3_confirm", "p4_confirm"]
const BACK := ["p1_heavy", "p2_heavy", "p3_heavy", "p4_heavy"]

var _state := "main"                       # "main" | "train"
var _sel := 0
var _main_items := ["feed", "rest", "train", "go"]
var _train_items := ["power", "speed", "toughness", "guard", "back"]
var _menu_labels: Array = []               # current selectable Label nodes
var _dyn: Dictionary = {}                  # named labels refreshed after an action
var _bob: float = 0.0
var _portrait: Control = null
var _flash: float = 0.0                    # brief den-tint after a denied action

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
	# The island you're about to fight on, dimmed — ties HOME to the journey.
	var stop: Dictionary = MatchConfig.career_current_stop()
	var bgp := "res://assets/tilesets/%s_bg.png" % _island_bg(stop.get("island", ""))
	if ResourceLoader.exists(bgp):
		var isl := TextureRect.new()
		isl.texture = load(bgp)
		isl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		isl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		isl.size = Vector2(1280, 720)
		isl.modulate = Color(0.32, 0.34, 0.4)
		add_child(isl)
	_build()

func _island_bg(island: String) -> String:
	# arena bg filenames don't all match the island id (see restyle memory).
	match island:
		"beauty_beach": return "beauty_beach"
		"iciest_age": return "iciest_floes"
		_: return island

func _title_label(text: String, pos: Vector2, size: int, col: Color, w := 560.0, center := false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(w, size + 10)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	return l

func _build() -> void:
	# --- Left: the bonded dino portrait (bobs gently for life) ---
	_portrait = _make_portrait(MetaSave.career_dino, Rect2(70, 150, 500, 420))
	var nm: String = MetaSave.career_name if MetaSave.career_name != "" else _dino_display(MatchConfig.career_dino)
	_title_label("%s" % nm.to_upper(), Vector2(70, 74), 52, Color.WHITE, 500, true)
	_dyn["lv"] = _title_label("", Vector2(70, 590), 30, ACCENT, 500, true)
	_dyn["mood"] = _title_label("", Vector2(70, 626), 28, DIM, 500, true)

	# --- Right: status + next fight + the care menu ---
	_title_label("THE DEN", Vector2(650, 60), 34, DIM, 560)
	_dyn["stats"] = _title_label("", Vector2(650, 112), 24, Color(0.85, 0.88, 0.95), 600)
	_dyn["wallet"] = _title_label("", Vector2(650, 150), 24, Color(0.85, 0.88, 0.95), 600)
	_dyn["hp"] = _title_label("", Vector2(650, 184), 24, Color(0.85, 0.88, 0.95), 600)
	# next-fight card
	var card := ColorRect.new()
	card.color = Color(0, 0, 0, 0.42)
	card.position = Vector2(650, 232)
	card.size = Vector2(560, 96)
	add_child(card)
	_dyn["next"] = _title_label("", Vector2(668, 244), 24, Color(1.0, 0.8, 0.55), 540)
	_dyn["scars"] = _title_label("", Vector2(668, 300), 18, DIM, 540)

	# menu items live at fixed rows; the selected one is tinted each frame.
	_rebuild_menu()
	_title_label("A  CONFIRM      B  BACK", Vector2(650, 664), 22, DIM, 560)
	_refresh()

func _rebuild_menu() -> void:
	for l in _menu_labels:
		if is_instance_valid(l):
			l.queue_free()
	_menu_labels = []
	var items: Array = _main_items if _state == "main" else _train_items
	var y := 356.0
	for i in items.size():
		var l := Label.new()
		l.position = Vector2(668, y)
		l.size = Vector2(560, 40)
		l.add_theme_font_size_override("font_size", 32)
		add_child(l)
		_menu_labels.append(l)
		y += 46.0
	_sel = clampi(_sel, 0, items.size() - 1)

func _menu_text(item: String) -> String:
	match item:
		"feed": return "FEED   (%d COINS)" % MetaSave.CAREER_FEED_COST
		"rest": return "REST"
		"train": return "TRAIN  >"
		"go":
			var s: Dictionary = MatchConfig.career_current_stop()
			return "GO  ->  %s" % ("BOSS FIGHT" if s.get("boss") else ("RIVAL FIGHT" if s.get("rival") else "STOP %d" % (MetaSave.career_stop + 1)))
		"back": return "<  BACK"
		_:  # a train stat row
			var pips: int = MetaSave.career_pip_count(item)
			var cost: int = MetaSave.career_pip_cost(item)
			return "%-10s %s   (%d XP)" % [item.to_upper(), _pips(pips), cost]

func _pips(n: int) -> String:
	var s := ""
	for i in range(mini(n, 8)):
		s += "*"
	return s if s != "" else "-"

func _refresh() -> void:
	_dyn["lv"].text = "LEVEL %d   -   %d XP" % [MetaSave.career_level(), MetaSave.career_xp]
	_dyn["mood"].text = "MOOD  %s  %d" % [_mood_face(), MetaSave.career_mood]
	_dyn["mood"].add_theme_color_override("font_color", GOOD if MetaSave.career_mood >= 50 else BAD)
	_dyn["stats"].text = "POW %s  SPD %s  TUF %s  GRD %s" % [
		_pips(MetaSave.career_pip_count("power")), _pips(MetaSave.career_pip_count("speed")),
		_pips(MetaSave.career_pip_count("toughness")), _pips(MetaSave.career_pip_count("guard"))]
	_dyn["wallet"].text = "COINS  %d" % MetaSave.coins
	var hp: int = MetaSave.career_hp_carry
	_dyn["hp"].text = "CONDITION  " + ("FRESH" if hp < 0 else "HURT (%d HP)" % hp)
	_dyn["hp"].add_theme_color_override("font_color", GOOD if hp < 0 else BAD)
	var s: Dictionary = MatchConfig.career_current_stop()
	var tag: String = "  [BOSS]" if s.get("boss") else ("  [RIVAL]" if s.get("rival") else "")
	_dyn["next"].text = "NEXT  -  STOP %d%s\nvs %s   %s @ %s   [%s]" % [
		MetaSave.career_stop + 1, tag, _dino_display(s.get("foe", "")).to_upper(),
		MatchConfig.MODE_NAMES.get(s.get("mode", "rounds"), "ROUNDS"),
		MatchConfig.ISLAND_NAMES.get(s.get("island", ""), "?"), s.get("difficulty", "").to_upper()]
	_dyn["scars"].text = "RECORD  %d W - %d L%s" % [MetaSave.career_wins, MetaSave.career_losses,
		("     SCARS: %d" % MetaSave.career_scars.size()) if MetaSave.career_scars.size() > 0 else ""]
	var items: Array = _main_items if _state == "main" else _train_items
	for i in items.size():
		_menu_labels[i].text = _menu_text(items[i])

func _mood_face() -> String:
	var m: int = MetaSave.career_mood
	if m >= 80: return ":D"
	if m >= 50: return ":)"
	if m >= 25: return ":|"
	return ":("

func _dino_display(id: String) -> String:
	return str(MatchConfig.DINOS.get(id, {}).get("name", id)).capitalize()

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
	# gentle idle bob
	_bob += delta * 2.2
	if _portrait:
		_portrait.position.y = 150.0 + sin(_bob) * 8.0
	if _flash > 0.0:
		_flash -= delta
	# selected-row highlight
	var items: Array = _main_items if _state == "main" else _train_items
	for i in _menu_labels.size():
		var on: bool = i == _sel
		var col: Color = ACCENT if on else DIM
		if on and _flash > 0.0:
			col = BAD
		_menu_labels[i].add_theme_color_override("font_color", col)
		_menu_labels[i].text = ("> " if on else "  ") + _menu_text(items[i])

	if _pressed(UP):
		_sel = (_sel - 1 + items.size()) % items.size()
		if Audio: Audio.ui("move")
	elif _pressed(DOWN):
		_sel = (_sel + 1) % items.size()
		if Audio: Audio.ui("move")
	elif _pressed(CONFIRM):
		_activate(items[_sel])
	elif _pressed(BACK):
		if _state == "train":
			_state = "main"; _sel = 2; _rebuild_menu(); _refresh()
			if Audio: Audio.ui("back")
		else:
			if Audio: Audio.ui("back")
			get_tree().change_scene_to_file("res://scenes/title.tscn")

func _activate(item: String) -> void:
	match item:
		"feed":
			if MetaSave.career_feed():
				_ok()
			else:
				_deny()
		"rest":
			MetaSave.career_rest(); _ok()
		"train":
			_state = "train"; _sel = 0; _rebuild_menu(); _refresh()
			if Audio: Audio.ui("confirm")
		"go":
			if Audio: Audio.ui("confirm")
			MatchConfig.career_start_match()
			get_tree().change_scene_to_file(MatchConfig.career_scene())
		"back":
			_state = "main"; _sel = 2; _rebuild_menu(); _refresh()
			if Audio: Audio.ui("back")
		_:  # a train stat
			if MetaSave.career_train(item):
				_ok()
			else:
				_deny()

func _ok() -> void:
	if Audio: Audio.ui("confirm")
	_refresh()

func _deny() -> void:
	_flash = 0.35
	if Audio: Audio.ui("back")
