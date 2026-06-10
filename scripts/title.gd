extends Node2D

# Front door: pick a mode, then drop into character select. The two hero dinos
# are rendered from the SAME pixel art the match uses (dino.gd's ANIM_LAYOUTS),
# so the title reads as "this is the game you'll play" — same rule as the picker.
const DinoScript := preload("res://scripts/dino.gd")
const SELECT_SCENE := "res://scenes/select.tscn"
const CREATOR_SCENE := "res://scenes/ralph_creator.tscn"
const BACKDROP_PATH := "res://assets/tilesets/beauty_beach_bg.png"

# Two crowd-pleasers flanking the logo, facing center (echoes the versus screen).
const LEFT_DINO := "trex"
const RIGHT_DINO := "raptor"
const DINO_TARGET_H := 220.0          # both sprites normalized to this height

const ACCENT := Color(1.0, 0.88, 0.30, 1.0)   # P1 yellow = the "selected" color
const DIM_TEXT := Color(0.72, 0.72, 0.78, 1.0)

# Gamepad-only: any of the four controllers can drive the front end.
const UP := ["p1_up", "p2_up", "p3_up", "p4_up"]
const DOWN := ["p1_down", "p2_down", "p3_down", "p4_down"]
const CONFIRM := ["p1_confirm", "p2_confirm", "p3_confirm", "p4_confirm"]
# Back = B button (heavy) on any pad — matches the on-screen "B  Back" hint.
const BACK := ["p1_heavy", "p2_heavy", "p3_heavy", "p4_heavy"]

@onready var logo: Node2D = $Logo
@onready var tiny: Sprite2D = $Logo/Tiny       # animated independently in the intro
@onready var dinos: Sprite2D = $Logo/Dinos
@onready var backdrop: Sprite2D = $Backdrop
@onready var prompt: Label = $Prompt
@onready var howto_panel: Node2D = $HowToPanel
@onready var left_graphic: AnimatedSprite2D = $LeftDino/Graphic
@onready var right_graphic: AnimatedSprite2D = $RightDino/Graphic
@onready var cam: Camera2D = $ShakeCam
@onready var dust: CPUParticles2D = $Dust

const SHAKE_DUR := 0.42           # screen-shake length, seconds
const SHAKE_MAG := 22.0           # peak shake offset, px

var menu_items: Array = []   # [{label: Label, base: String, action: String}]
var selected: int = 0
var howto_open: bool = false
var t: float = 0.0
var logo_base_y: float = 0.0
var nav_prev_dir: int = 0
var intro_done: bool = false      # gates the idle bob until the slam finishes
var tiny_rest: Vector2            # logo-local resting spots, captured from the scene
var dinos_rest: Vector2
var shake_left: float = 0.0       # seconds of screen-shake remaining

func _ready() -> void:
	# Defensive: returning here from a hit-paused match can leave time_scale low.
	Engine.time_scale = 1.0
	logo_base_y = logo.position.y
	_setup_backdrop()
	_setup_dino(left_graphic, LEFT_DINO, true)
	_setup_dino(right_graphic, RIGHT_DINO, false)
	# ARCADE + GAUNTLET are added in code (clones of the PLAY label) so the .tscn
	# isn't restructured; the items are re-stacked (spacing shrinks to fit) below.
	var arcade_label: Label = $Menu/PlayItem.duplicate()
	arcade_label.name = "ArcadeItem"
	$Menu.add_child(arcade_label)
	var gauntlet_label: Label = $Menu/PlayItem.duplicate()
	gauntlet_label.name = "GauntletItem"
	$Menu.add_child(gauntlet_label)
	# Once you've made progress, the GAUNTLET line shows your best wave so far.
	var gauntlet_base: String = "GAUNTLET"
	if MetaSave.best_wave > 0:
		gauntlet_base = "GAUNTLET  (BEST: WAVE %d)" % MetaSave.best_wave
	menu_items = [
		{"label": $Menu/PlayItem, "base": "VERSUS", "action": "play"},
		{"label": arcade_label, "base": "ARCADE", "action": "arcade"},
		{"label": gauntlet_label, "base": gauntlet_base, "action": "gauntlet"},
		{"label": $Menu/CharacterItem, "base": "CHARACTER", "action": "creator"},
		{"label": $Menu/HowToItem, "base": "HOW TO PLAY", "action": "howto"},
		{"label": $Menu/QuitItem, "base": "QUIT", "action": "quit"},
	]
	var top0: float = $Menu/PlayItem.offset_top
	var h0: float = $Menu/PlayItem.offset_bottom - $Menu/PlayItem.offset_top
	# Shrink the row spacing so the (now six) items still clear the bottom edge.
	var spacing: float = min(48.0, (704.0 - top0) / float(menu_items.size()))
	for i in range(menu_items.size()):
		var ml: Label = menu_items[i]["label"]
		ml.offset_top = top0 + i * spacing
		ml.offset_bottom = ml.offset_top + h0
	# Scale the selected item from its own center, not its top-left corner.
	for item in menu_items:
		var l: Label = item.label
		l.pivot_offset = Vector2(640.0, (l.offset_bottom - l.offset_top) / 2.0)
	howto_panel.visible = false
	_refresh_menu()
	prompt.text = "UP / DOWN  SELECT      A  CONFIRM"

	# TINY drops in and slams onto DINOS every time the title screen opens.
	tiny_rest = tiny.position
	dinos_rest = dinos.position
	_play_intro()

func _process(delta: float) -> void:
	t += delta
	# Idle life: logo bobs, dinos bob out of phase, backdrop sways, prompt pulses.
	# Hold the logo bob until the slam-in intro has settled.
	if intro_done:
		logo.position.y = logo_base_y + sin(t * 1.6) * 6.0
	left_graphic.position.y = sin(t * 2.2) * 7.0
	right_graphic.position.y = sin(t * 2.2 + PI) * 7.0
	backdrop.position.x = 640.0 + sin(t * 0.3) * 18.0
	prompt.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 3.0))

	# Decaying screen-shake, kicked by the slam impact.
	if shake_left > 0.0:
		shake_left -= delta
		var k: float = clampf(shake_left / SHAKE_DUR, 0.0, 1.0)
		var mag: float = SHAKE_MAG * k * k        # ease the shake out
		cam.offset = Vector2(randf_range(-mag, mag), randf_range(-mag, mag))
	else:
		cam.offset = Vector2.ZERO

	if howto_open:
		if _just(BACK) or _just(CONFIRM):
			_close_howto()
		return

	_handle_nav(delta)
	if _just(CONFIRM):
		_activate(menu_items[selected]["action"])

	# Gentle pulse on whichever item is highlighted.
	for i in range(menu_items.size()):
		var l: Label = menu_items[i]["label"]
		l.scale = Vector2.ONE * (1.06 + 0.03 * sin(t * 5.0)) if i == selected else Vector2.ONE

# Single press = single move, no auto-repeat. Fires only on the edge where the
# held direction changes, so holding does nothing and the analog stick crossing
# its deadzone twice can't double-trigger.
func _handle_nav(_delta: float) -> void:
	var dir: int = 1 if _held(DOWN) else (-1 if _held(UP) else 0)
	if dir == nav_prev_dir:
		return
	nav_prev_dir = dir
	if dir != 0:
		selected = (selected + dir + menu_items.size()) % menu_items.size()
		_refresh_menu()

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

func _refresh_menu() -> void:
	for i in range(menu_items.size()):
		var l: Label = menu_items[i]["label"]
		if i == selected:
			l.text = ">   %s   <" % menu_items[i]["base"]
			l.add_theme_color_override("font_color", ACCENT)
		else:
			l.text = menu_items[i]["base"]
			l.add_theme_color_override("font_color", DIM_TEXT)

func _activate(action: String) -> void:
	match action:
		"play":
			MatchConfig.arcade_setup = false
			get_tree().change_scene_to_file(SELECT_SCENE)
		"arcade":
			MatchConfig.arcade_setup = true
			get_tree().change_scene_to_file(SELECT_SCENE)
		"gauntlet":
			MatchConfig.gauntlet_setup = true
			get_tree().change_scene_to_file(SELECT_SCENE)
		"creator":
			get_tree().change_scene_to_file(CREATOR_SCENE)
		"howto":
			_open_howto()
		"quit":
			get_tree().quit()

func _open_howto() -> void:
	howto_open = true
	howto_panel.visible = true

func _close_howto() -> void:
	howto_open = false
	howto_panel.visible = false

# Intro: TINY drops from above and slams onto DINOS, which squashes flat and
# springs back, launching TINY into a few decaying bounces before it settles
# into the idle float. Pure Tween — one sequential chain with parallel beats.
func _play_intro() -> void:
	tiny.position = Vector2(tiny_rest.x, -240.0)   # start well above the screen
	tiny.scale = Vector2.ONE
	dinos.scale = Vector2.ONE
	var tw := create_tween()
	# 1) The fall — accelerate hard into the impact.
	tw.tween_property(tiny, "position:y", tiny_rest.y, 0.40) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	# Impact beat — kick the screen-shake and dust the instant TINY lands.
	tw.tween_callback(_on_impact)
	# 2) Collapse — DINOS flattens like a tennis ball + dips; TINY drives down into it.
	tw.tween_property(dinos, "scale", Vector2(1.36, 0.46), 0.09) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(dinos, "position:y", dinos_rest.y + 12.0, 0.09)
	tw.parallel().tween_property(tiny, "scale", Vector2(1.10, 0.90), 0.09)
	tw.parallel().tween_property(tiny, "position:y", tiny_rest.y + 70.0, 0.09) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 3) Spring back — DINOS rebounds tall and launches TINY high.
	tw.tween_property(dinos, "scale", Vector2(0.84, 1.20), 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(dinos, "position:y", dinos_rest.y, 0.15)
	tw.parallel().tween_property(tiny, "scale", Vector2.ONE, 0.12)
	tw.parallel().tween_property(tiny, "position:y", tiny_rest.y - 95.0, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 4) Settle — DINOS wobbles elastically back to round; TINY bounces to rest.
	tw.tween_property(dinos, "scale", Vector2.ONE, 0.34) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(tiny, "position:y", tiny_rest.y, 0.60) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func() -> void: intro_done = true)

# Fired by the tween exactly when TINY lands: shake the screen and puff dust.
func _on_impact() -> void:
	shake_left = SHAKE_DUR
	dust.restart()

func _setup_backdrop() -> void:
	if not ResourceLoader.exists(BACKDROP_PATH):
		return
	var tex: Texture2D = load(BACKDROP_PATH)
	backdrop.texture = tex
	# Zoom in (and the scene node sits high, y=205) so the arena art's baked
	# "BEAUTY BEACH" heading band is cropped off the top, behind the logo.
	var cover: float = max(1280.0 / tex.get_width(), 720.0 / tex.get_height()) * 1.5
	backdrop.scale = Vector2(cover, cover)

# Build a looping idle from dino.gd's ANIM_LAYOUTS, scaled to a uniform height
# and flipped to face screen center. Mirrors select.gd's _set_graphic.
func _setup_dino(graphic: AnimatedSprite2D, dino_id: String, on_left: bool) -> void:
	var dino: Dictionary = MatchConfig.DINOS.get(dino_id, {})
	var role: String = dino.get("sprite_role", "")
	var sf := DinoScript.build_sprite_frames(role, PackedStringArray(["idle"]))
	if sf == null:
		return
	var layout: Dictionary = DinoScript.ANIM_LAYOUTS[role]
	graphic.sprite_frames = sf
	graphic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # fighters are painterly now
	var s: float = DINO_TARGET_H / float(layout["idle"].rects[0].size.y)
	graphic.scale = Vector2(s, s)
	# Left-side dino looks right, right-side looks left — they square off.
	var faces_left_art: bool = layout.get("faces_left", false)
	graphic.flip_h = faces_left_art if on_left else not faces_left_art
	graphic.play("idle")
