extends Control
## Ralph character creator / profile screen. Matches the target mockup at
## assets/concept/ralph_creator_target.png. Built programmatically + data-driven
## so AI-generated skin/emote PNGs slot in as they land. Gamepad-only:
##   Left/Right = cycle skins,  B (heavy) = back to title.
## Art tiers: hero/skins/emotes are tier-1 AI art (placeholders until generated);
## the in-match sprite is tier-2 (gen_ralph.py). See scripts/tools/ralph_art_prompts.md.

const TITLE_SCENE := "res://scenes/title.tscn"
const HERO_PATH := "res://assets/concept/ralph/ralph_hero.png"

# ---- palette (dark slate + gold, from the target) ----
const BG := Color("12151f")
const PANEL := Color("212838")
const PANEL_IN := Color("171b27")
const BORDER := Color("3c4660")
const GOLD := Color("e6c878")
const GOLD_DK := Color("8a6f32")
const TEXT := Color("dce2ec")
const TEXT_DIM := Color("8b95a8")
const GREEN := Color("7fd06a")

# ---- profile data (curated for the card; can later link to MatchConfig.DINOS) ----
const STATS := [
	["HP", "120", Color("e0564f")],
	["ATK", "28", Color("e89a3c")],
	["DEF", "20", Color("5aa0e0")],
	["SPD", "18", Color("d2a878")],
	["CRT", "10%", Color("e6c878")],
]
const BIO := "A tiny dino with a big heart and an even bigger attitude. Ralph may be small, but his courage is larger than life."
const MOVE_NAME := "TINY METEOR STOMP"
const MOVE_DESC := "Ralph leaps high into the air, spinning into a ball and crashes down, causing a shockwave that deals damage in all directions."
const CUSTOM := ["HEAD", "SPIKES", "OUTFIT", "NECK", "TAIL", "COLOR"]
# Each skin: real art if "img" set (hero + algorithmic recolors), else a tinted
# placeholder swatch (Crystal/Volcano/Void still need AI for their new detail).
const RALPH_DIR := "res://assets/concept/ralph/"
const SKINS := [
	{"name": "EXPLORER", "tint": Color("8cc47a"), "img": RALPH_DIR + "ralph_hero.png", "rarity": "COMMON"},
	{"name": "CRYSTAL", "tint": Color("8fd6e8"), "img": "", "rarity": "RARE"},
	{"name": "VOLCANO", "tint": Color("4a4650"), "img": "", "rarity": "RARE"},
	{"name": "FROZEN", "tint": Color("bcd8ec"), "img": RALPH_DIR + "ralph_frozen.png", "rarity": "RARE"},
	{"name": "SPRING", "tint": Color("a9d98c"), "img": RALPH_DIR + "ralph_spring.png", "rarity": "RARE"},
	{"name": "VOID", "tint": Color("6a4a98"), "img": RALPH_DIR + "ralph_void.png", "rarity": "EPIC"},
	{"name": "GOLDEN", "tint": Color("e6c860"), "img": RALPH_DIR + "ralph_golden.png", "rarity": "EPIC"},
]
const EMOTES := ["WAVE", "EXCITED", "CONFUSED", "LOVE", "ROAR", "SLEEPY", "DIZZY", "PROUD"]

var skin_idx := 0
var rarity_label: Label
var skin_slots: Array = []
var portrait: TextureRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg(self, 0, 0, 1280, 720, BG)
	_build_portrait()
	_build_stats()
	_build_bio()
	_build_move()
	_build_customization()
	_build_skins()
	_build_emotes()
	_refresh_skin()
	# optional offscreen screenshot for previews: godot <scene> -- --shot
	if "--shot" in OS.get_cmdline_user_args():
		await _shoot()


# ============================================================ build helpers ===
func _sb(bg: Color, border := BORDER, bw := 3, radius := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	return s


func _bg(parent: Node, x: float, y: float, w: float, h: float, c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	parent.add_child(r)
	return r


func _panel(x: float, y: float, w: float, h: float, title := "") -> Panel:
	var p := Panel.new()
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.add_theme_stylebox_override("panel", _sb(PANEL))
	add_child(p)
	if title != "":
		var tab := Panel.new()
		tab.add_theme_stylebox_override("panel", _sb(PANEL_IN, GOLD_DK, 2, 7))
		tab.position = Vector2(14, -16)
		var w_est: float = 22 + title.length() * 13
		tab.size = Vector2(w_est, 30)
		p.add_child(tab)
		var lbl := _text(tab, title, 0, 0, 20, GOLD)
		lbl.size = tab.size
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return p


func _text(parent: Node, s: String, x: float, y: float, size: int, c := TEXT) -> Label:
	var l := Label.new()
	l.text = s
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	parent.add_child(l)
	return l


# ===================================================================== panels ==
func _build_portrait() -> void:
	var p := _panel(16, 16, 540, 540)
	# stage backdrop behind the hero (placeholder for the painted diorama)
	var stage := _bg(p, 12, 12, 516, 516, PANEL_IN)
	stage.color = Color("2a3a52")
	portrait = TextureRect.new()
	if ResourceLoader.exists(HERO_PATH):
		portrait.texture = load(HERO_PATH)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(12, 12)
	portrait.size = Vector2(516, 516)
	p.add_child(portrait)
	# banner
	var ban := Panel.new()
	ban.add_theme_stylebox_override("panel", _sb(Color("1a1f2c"), GOLD, 3, 12))
	ban.position = Vector2(70, 8)
	ban.size = Vector2(400, 92)
	p.add_child(ban)
	var name_l := _text(ban, "RALPH", 0, 6, 52, GOLD)
	name_l.size = Vector2(400, 56); name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := _text(ban, "• TINY DINO •", 0, 60, 20, TEXT_DIM)
	sub.size = Vector2(400, 24); sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# rarity badge
	var badge := Panel.new()
	badge.add_theme_stylebox_override("panel", _sb(PANEL_IN, GOLD_DK, 2, 8))
	badge.position = Vector2(20, 110); badge.size = Vector2(96, 70)
	p.add_child(badge)
	var star := _text(badge, "★", 0, 2, 30, GOLD)
	star.size = Vector2(96, 34); star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rl := _text(badge, "RARITY", 0, 36, 13, TEXT_DIM)
	rl.size = Vector2(96, 16); rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label = _text(badge, "COMMON", 0, 50, 14, TEXT)
	rarity_label.size = Vector2(96, 18); rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# cycle arrows
	var la := _text(p, "◀", 8, 250, 40, GOLD); la.size = Vector2(40, 40)
	var ra := _text(p, "▶", 492, 250, 40, GOLD); ra.size = Vector2(40, 40)
	# EXP / level bar
	var bar := Panel.new()
	bar.add_theme_stylebox_override("panel", _sb(PANEL_IN, GOLD_DK, 2, 8))
	bar.position = Vector2(20, 488); bar.size = Vector2(500, 40)
	p.add_child(bar)
	_text(bar, "LV. 1", 12, 6, 22, GOLD)
	var track := _bg(bar, 96, 11, 320, 18, Color("0e1118")); track.color = Color("0e1118")
	_bg(track, 0, 0, 4, 18, GOLD)  # 0% fill stub
	var exp := _text(bar, "0 / 100", 96, 8, 16, TEXT_DIM)
	exp.size = Vector2(320, 18); exp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text(bar, "EXP", 432, 8, 18, TEXT_DIM)


func _build_stats() -> void:
	var p := _panel(572, 16, 300, 212, "STATS")
	var y := 44.0
	for row in STATS:
		var dot := _bg(p, 22, y + 6, 16, 16, row[2]); dot.color = row[2]
		_text(p, row[0], 50, y, 24, TEXT)
		var v := _text(p, row[1], 0, y, 24, GOLD)
		v.size = Vector2(258, 28); v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		y += 32


func _build_bio() -> void:
	var p := _panel(888, 16, 376, 212)
	var b := _text(p, BIO, 20, 16, 18, TEXT)
	b.size = Vector2(336, 110); b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text(p, "PERSONALITY:", 20, 134, 18, GREEN)
	_text(p, "BRAVE • CURIOUS • LOYAL", 20, 158, 18, TEXT)


func _build_move() -> void:
	var p := _panel(572, 252, 692, 150, "SIGNATURE MOVE")
	# icon box (placeholder = hero thumbnail; real Stomp art swaps in later)
	var icon := Panel.new()
	icon.add_theme_stylebox_override("panel", _sb(Color("16314a"), GOLD_DK, 2, 8))
	icon.position = Vector2(20, 28); icon.size = Vector2(120, 104)
	p.add_child(icon)
	if ResourceLoader.exists(HERO_PATH):
		var t := TextureRect.new()
		t.texture = load(HERO_PATH)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.position = Vector2(6, 6); t.size = Vector2(108, 92)
		icon.add_child(t)
	_text(p, MOVE_NAME, 160, 26, 26, GOLD)
	var d := _text(p, MOVE_DESC, 160, 58, 16, TEXT)
	d.size = Vector2(510, 60); d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text(p, "TYPE: PHYSICAL", 160, 118, 16, TEXT_DIM)
	_text(p, "COOLDOWN: 12s", 420, 118, 16, TEXT_DIM)


func _build_customization() -> void:
	var p := _panel(572, 414, 692, 142, "CUSTOMIZATION")
	var slot_w := 104.0
	for i in CUSTOM.size():
		var x := 20.0 + i * (slot_w + 8)
		var box := Panel.new()
		box.add_theme_stylebox_override("panel", _sb(PANEL_IN, BORDER, 2, 8))
		box.position = Vector2(x, 34); box.size = Vector2(slot_w, 72)
		p.add_child(box)
		_bg(box, slot_w / 2 - 18, 14, 36, 36, Color("39435c"))
		var l := _text(p, CUSTOM[i], x, 110, 16, TEXT_DIM)
		l.size = Vector2(slot_w, 20); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_skins() -> void:
	var p := _panel(16, 568, 720, 138, "SKINS")
	var slot_w := 92.0
	for i in SKINS.size():
		var skin: Dictionary = SKINS[i]
		var x := 16.0 + i * (slot_w + 8)
		var box := Panel.new()
		box.add_theme_stylebox_override("panel", _sb(PANEL_IN, BORDER, 2, 8))
		box.position = Vector2(x, 30); box.size = Vector2(slot_w, 76)
		p.add_child(box)
		var img: String = skin.get("img", "")
		if img != "" and ResourceLoader.exists(img):
			var t := TextureRect.new()
			t.texture = load(img)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			t.position = Vector2(4, 4); t.size = Vector2(slot_w - 8, 68)
			box.add_child(t)
		else:
			_bg(box, slot_w / 2 - 22, 14, 44, 44, skin["tint"])
		var l := _text(p, skin["name"], x, 108, 13, TEXT_DIM)
		l.size = Vector2(slot_w, 18); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skin_slots.append(box)


func _build_emotes() -> void:
	var p := _panel(748, 568, 516, 138, "EMOTES")
	var sw := 116.0
	for i in EMOTES.size():
		var col := i % 4
		var rowi := i / 4
		var x := 16.0 + col * (sw + 6)
		var y := 26.0 + rowi * 54
		var box := Panel.new()
		box.add_theme_stylebox_override("panel", _sb(PANEL_IN, BORDER, 2, 6))
		box.position = Vector2(x, y); box.size = Vector2(sw, 48)
		p.add_child(box)
		var l := _text(box, EMOTES[i], 0, 0, 15, TEXT_DIM)
		l.size = Vector2(sw, 48)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


# ================================================================ interaction ==
func _refresh_skin() -> void:
	for i in skin_slots.size():
		var on := i == skin_idx
		skin_slots[i].add_theme_stylebox_override(
			"panel", _sb(PANEL_IN, GOLD if on else BORDER, 4 if on else 2, 8))
	var skin: Dictionary = SKINS[skin_idx]
	rarity_label.text = skin.get("rarity", "COMMON")
	var img: String = skin.get("img", "")
	if img != "" and ResourceLoader.exists(img):
		portrait.texture = load(img)
	elif ResourceLoader.exists(HERO_PATH):
		portrait.texture = load(HERO_PATH)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("p1_right"):
		skin_idx = (skin_idx + 1) % SKINS.size()
		_refresh_skin()
	elif Input.is_action_just_pressed("p1_left"):
		skin_idx = (skin_idx - 1 + SKINS.size()) % SKINS.size()
		_refresh_skin()
	elif Input.is_action_just_pressed("p1_heavy"):
		get_tree().change_scene_to_file(TITLE_SCENE)


func _shoot() -> void:
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			skin_idx = clampi(int(a), 0, SKINS.size() - 1)
			_refresh_skin()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/ralph/creator_shot.png")
	get_tree().quit()
