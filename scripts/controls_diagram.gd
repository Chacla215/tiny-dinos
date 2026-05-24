@tool
extends Node2D

# Native controller diagram for the How-to-Play screen.
#
# Everything here is drawn in screen space (1280x720) so it can sit directly
# inside the title's full-screen HowToPanel with no transform. It is a static
# drawing: _draw runs once and is cached until queue_redraw().
#
# The pad graphic is the real Xbox controller photo (TEX_PATH). The callout
# anchors below are the photo's actual button positions (measured from the
# image), mapped from the controller's bounding box into TEX_TARGET. If the
# texture is ever missing we fall back to the hand-drawn pad (_draw_body).
#
# CONTROLS SHOWN = WHAT THE BUILD ACTUALLY DOES TODAY. The bindings come from
# match_config.gd's _register_player_actions():
#     X  -> attack      B -> heavy        Y -> swap weapon   A -> dodge
#     LB -> special     RB -> block       L-Stick / D-Pad -> move
#     Menu(Start) -> pause
# LT, RT and the right stick are intentionally not called out — nothing is
# bound to them yet, so the screen never promises a button that does nothing.

const TEX_PATH := "res://assets/ui/xbox_controller.png"

# Where the photo is drawn on screen, and which slice of the 750x750 source to
# draw (its controller bounding box, so the surrounding whitespace is cropped).
const TEX_TARGET := Rect2(451.0, 210.0, 377.0, 260.0)
const TEX_SRC := Rect2(42.75, 150.75, 663.0, 457.5)

# Page 2: the Magic Keyboard photo. KBD_SRC is its bounding box in the 750x750
# source; KBD_TARGET is where it lands on screen. KB* are the bbox fractions
# used to map measured key positions (full-image fractions) into KBD_TARGET.
const KBD_TEX_PATH := "res://assets/ui/magic_keyboard.png"
const KBD_TARGET := Rect2(320.0, 150.0, 640.0, 175.0)
const KBD_SRC := Rect2(62.25, 288.75, 624.75, 171.0)
const KBX0 := 0.083
const KBY0 := 0.385
const KBW := 0.833
const KBH := 0.228

const C := Vector2(640.0, 352.0)   # controller center (hand-drawn fallback only)

# --- palette ---------------------------------------------------------------
const TEXT    := Color(0.95, 0.95, 0.98)
const ACCENT  := Color(1.00, 0.88, 0.30)        # P1 yellow, matches the title
const SUBTLE  := Color(0.60, 0.63, 0.72)
const LINE    := Color(0.78, 0.82, 0.92, 0.85)  # callout connectors
const OUTLINE := Color(0.00, 0.00, 0.00, 0.92)
const SHADOW  := Color(0.00, 0.00, 0.00, 0.28)
const BODY    := Color(0.91, 0.92, 0.95)        # white-ish Xbox shell
const BODY_DK := Color(0.74, 0.76, 0.82)
const WELL    := Color(0.22, 0.23, 0.28)        # stick wells / d-pad
const STICK   := Color(0.12, 0.12, 0.16)
const BTN_A   := Color(0.30, 0.72, 0.34)        # green
const BTN_B   := Color(0.86, 0.26, 0.24)        # red
const BTN_X   := Color(0.24, 0.49, 0.86)        # blue
const BTN_Y   := Color(0.93, 0.78, 0.16)        # yellow

const KBD_P1 := Color(1.00, 0.82, 0.25)         # player-1 key highlight (yellow)
const KBD_P2 := Color(0.40, 0.80, 0.98)         # player-2 key highlight (cyan)

# --- alignment ---
const A_LEFT := 0
const A_CENTER := 1
const A_RIGHT := 2

# Page flip (controller <-> keyboard): any pad's left/right or the arrow keys.
const NAV_LEFT := ["ui_left", "p1_left", "p2_left", "p3_left", "p4_left"]
const NAV_RIGHT := ["ui_right", "p1_right", "p2_right", "p3_right", "p4_right"]

var font: Font
var controller_tex: Texture2D
var kbd_tex: Texture2D
var page: int = 0   # 0 = controller, 1 = keyboard

# Generic callout anchors (screen space) — set for the photo, or derived from
# the hand-drawn pad in fallback. Callouts only ever read these four.
var a_ls: Vector2      # left stick
var a_lb: Vector2      # left bumper / shoulder
var a_rb: Vector2      # right bumper / shoulder
var a_face: Vector2    # right edge of the face-button cluster

# Hand-drawn fallback pad geometry (only used when the photo is missing).
var ls: Vector2
var dpad: Vector2
var rs: Vector2
var fb: Vector2
var by: Vector2
var bx: Vector2
var bb: Vector2
var ba: Vector2
var view_btn: Vector2
var menu_btn: Vector2
var guide_btn: Vector2
var lb_rect: Rect2
var rb_rect: Rect2
var lt_rect: Rect2
var rt_rect: Rect2

func _ready() -> void:
	_ensure_setup()
	queue_redraw()

# Idempotent. Called from _ready AND from _draw so the diagram is safe in the
# editor (@tool), where _draw can fire before _ready or after a script reload.
func _ensure_setup() -> void:
	if font == null:
		font = ThemeDB.fallback_font
	if controller_tex == null and ResourceLoader.exists(TEX_PATH):
		controller_tex = load(TEX_PATH)
	if kbd_tex == null and ResourceLoader.exists(KBD_TEX_PATH):
		kbd_tex = load(KBD_TEX_PATH)
	if controller_tex != null:
		_setup_photo_anchors()
	else:
		_setup_drawn_anchors()

# Flip between the controller and keyboard pages with Left/Right.
func _process(_dt: float) -> void:
	if Engine.is_editor_hint() or not is_visible_in_tree():
		return
	if _just(NAV_RIGHT) and page < 1:
		page = 1
		queue_redraw()
	elif _just(NAV_LEFT) and page > 0:
		page = 0
		queue_redraw()

func _just(actions: Array) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			return true
	return false

# Map a point given as a fraction of the controller's BOUNDING BOX (not the full
# image) into screen space within TEX_TARGET. Fractions measured from the photo.
func _photo(u: float, v: float) -> Vector2:
	return TEX_TARGET.position + Vector2(u, v) * TEX_TARGET.size

func _setup_photo_anchors() -> void:
	a_ls = _photo(0.249, 0.280)     # left stick
	a_lb = _photo(0.274, 0.0)       # left shoulder top
	a_rb = _photo(0.682, 0.0)       # right shoulder top
	a_face = _photo(0.86, 0.290)    # just right of the B button

func _setup_drawn_anchors() -> void:
	ls = C + Vector2(-92.0, -28.0)
	dpad = C + Vector2(-52.0, 48.0)
	rs = C + Vector2(40.0, 48.0)
	fb = C + Vector2(96.0, -28.0)
	by = fb + Vector2(0.0, -27.0)
	bx = fb + Vector2(-27.0, 0.0)
	bb = fb + Vector2(27.0, 0.0)
	ba = fb + Vector2(0.0, 27.0)
	view_btn = C + Vector2(-30.0, -44.0)
	menu_btn = C + Vector2(30.0, -44.0)
	guide_btn = C + Vector2(0.0, -74.0)
	lb_rect = Rect2(C.x - 188.0, C.y - 112.0, 84.0, 22.0)
	rb_rect = Rect2(C.x + 104.0, C.y - 112.0, 84.0, 22.0)
	lt_rect = Rect2(C.x - 184.0, C.y - 138.0, 74.0, 20.0)
	rt_rect = Rect2(C.x + 110.0, C.y - 138.0, 74.0, 20.0)
	# Feed the generic anchors so callouts work in fallback too.
	a_ls = ls
	a_lb = Vector2(lb_rect.get_center().x, lb_rect.position.y)
	a_rb = Vector2(rb_rect.get_center().x, rb_rect.position.y)
	a_face = Vector2(bb.x + 16.0, fb.y)

func _draw() -> void:
	_ensure_setup()
	_label(Vector2(640.0, 88.0), "HOW TO PLAY", 40, ACCENT, A_CENTER)
	if page == 0:
		_draw_controller_page()
	else:
		_draw_keyboard_page()
	_draw_page_footer()

# --- controller silhouette -------------------------------------------------
func _draw_body() -> void:
	# Soft drop shadow first (same colour everywhere, so the overlapping parts
	# merge into one blob with no internal seams), then the shell on top.
	var off := Vector2(0.0, 7.0)
	_grips(off, SHADOW)
	_grips(Vector2.ZERO, BODY)

func _grips(off: Vector2, col: Color) -> void:
	draw_circle(C + Vector2(-150.0, 44.0) + off, 70.0, col)
	draw_circle(C + Vector2(150.0, 44.0) + off, 70.0, col)
	_fill_rrect(Rect2(C.x - 150.0 + off.x, C.y - 72.0 + off.y, 300.0, 132.0), 44.0, col)
	_fill_rrect(Rect2(C.x - 148.0 + off.x, C.y - 96.0 + off.y, 296.0, 60.0), 26.0, col)

# --- sticks, d-pad, buttons, bumpers, triggers -----------------------------
func _draw_inputs() -> void:
	# Triggers (LT / RT) — bare, drawn faint so they read as "present but unused".
	_fill_rrect(lt_rect, 9.0, Color(BODY_DK.r, BODY_DK.g, BODY_DK.b, 0.45))
	_fill_rrect(rt_rect, 9.0, Color(BODY_DK.r, BODY_DK.g, BODY_DK.b, 0.45))
	_centered(lt_rect.get_center(), "LT", 14, SUBTLE)
	_centered(rt_rect.get_center(), "RT", 14, SUBTLE)

	# Bumpers (LB / RB) — bound.
	_fill_rrect(lb_rect, 9.0, BODY_DK)
	_fill_rrect(rb_rect, 9.0, BODY_DK)
	_centered(lb_rect.get_center(), "LB", 14, Color(0.16, 0.16, 0.2))
	_centered(rb_rect.get_center(), "RB", 14, Color(0.16, 0.16, 0.2))

	# Left stick (bound: move) and right stick (bare).
	_stick(ls, false)
	_stick(rs, true)

	# D-pad (bound: move).
	_fill_rrect(Rect2(dpad.x - 9.0, dpad.y - 24.0, 18.0, 48.0), 4.0, WELL)
	_fill_rrect(Rect2(dpad.x - 24.0, dpad.y - 9.0, 48.0, 18.0), 4.0, WELL)

	# Center cluster: View, Menu (= pause), Xbox guide.
	draw_circle(guide_btn, 13.0, BODY_DK)
	draw_circle(view_btn, 7.0, WELL)
	draw_circle(menu_btn, 8.0, WELL)
	draw_arc(menu_btn, 11.0, 0.0, TAU, 24, ACCENT, 2.0, true)  # ring the pause btn

	# Face buttons (Xbox diamond: Y top, X left, B right, A bottom).
	_face(by, "Y", BTN_Y)
	_face(bx, "X", BTN_X)
	_face(bb, "B", BTN_B)
	_face(ba, "A", BTN_A)

func _stick(center: Vector2, faint: bool) -> void:
	var well_col := WELL
	var top_col := STICK
	if faint:
		well_col = Color(WELL.r, WELL.g, WELL.b, 0.5)
		top_col = Color(STICK.r, STICK.g, STICK.b, 0.5)
	draw_circle(center, 25.0, well_col)
	draw_circle(center, 17.0, top_col)

func _face(center: Vector2, glyph: String, col: Color) -> void:
	draw_circle(center, 15.0, col)
	_centered(center + Vector2(0.0, 0.5), glyph, 16, Color.WHITE)

# --- callout connectors + their labels -------------------------------------
func _draw_callouts() -> void:
	# LB -> Special (label top-left, line down to the left shoulder).
	_elbow_v(a_lb, 186.0, 305.0)
	_pair(Vector2(305.0, 150.0), "LB", "SPECIAL", ACCENT, A_CENTER)

	# RB -> Block (label top-right, line down to the right shoulder).
	_elbow_v(a_rb, 186.0, 975.0)
	_pair(Vector2(975.0, 150.0), "RB", "BLOCK", ACCENT, A_CENTER)

	# Left stick / d-pad -> Move (label to the left, line into the stick).
	draw_circle(a_ls, 3.0, LINE)
	draw_polyline(PackedVector2Array([a_ls, Vector2(405.0, a_ls.y)]), LINE, 2.0, true)
	_label(Vector2(395.0, a_ls.y - 21.0), "MOVE", 22, TEXT, A_RIGHT)
	_label(Vector2(395.0, a_ls.y + 7.0), "L-Stick / D-Pad", 15, SUBTLE, A_RIGHT)

	# Face cluster -> a braced 4-line list on the right.
	var brace_x := 850.0
	var rows := [
		{"y": 250.0, "glyph": "Y", "col": BTN_Y, "action": "SWAP WEAPON"},
		{"y": 280.0, "glyph": "X", "col": BTN_X, "action": "ATTACK"},
		{"y": 310.0, "glyph": "B", "col": BTN_B, "action": "HEAVY"},
		{"y": 340.0, "glyph": "A", "col": BTN_A, "action": "DODGE"},
	]
	draw_circle(a_face, 3.0, LINE)
	draw_polyline(PackedVector2Array([a_face, Vector2(brace_x, 0.5 * (rows[1]["y"] + rows[2]["y"]))]), LINE, 2.0, true)
	draw_polyline(PackedVector2Array([
		Vector2(brace_x, rows[0]["y"]), Vector2(brace_x, rows[3]["y"])
	]), LINE, 2.0, true)
	for row in rows:
		var ry: float = row["y"]
		draw_polyline(PackedVector2Array([Vector2(brace_x, ry), Vector2(brace_x + 12.0, ry)]), LINE, 2.0, true)
		_pair(Vector2(brace_x + 22.0, ry - 10.0), row["glyph"], row["action"], row["col"], A_LEFT, 19)

# Vertical-then-horizontal connector from a button up to a horizontal rail at
# rail_y, ending under label_x (with a marker dot at the button).
func _elbow_v(from: Vector2, rail_y: float, label_x: float) -> void:
	draw_circle(from, 3.0, LINE)
	draw_polyline(PackedVector2Array([
		from, Vector2(from.x, rail_y), Vector2(label_x, rail_y)
	]), LINE, 2.0, true)

# --- the static text below the pad -----------------------------------------
func _draw_controller_page() -> void:
	if controller_tex != null:
		draw_texture_rect_region(controller_tex, TEX_TARGET, TEX_SRC)
	else:
		_draw_body()
		_draw_inputs()
	_draw_callouts()
	_label(Vector2(640.0, 500.0), "Pause  •  Menu button", 18, TEXT, A_CENTER)
	_label(Vector2(640.0, 528.0),
		"L-Trigger • R-Trigger • Right Stick  —  not bound yet", 15, SUBTLE, A_CENTER)

# --- page 2: keyboard ------------------------------------------------------
# Map a key's full-image fraction (measured from the photo) into screen space
# within KBD_TARGET, via the keyboard's bounding box.
func _kbd(fx: float, fy: float) -> Vector2:
	return KBD_TARGET.position + Vector2((fx - KBX0) / KBW, (fy - KBY0) / KBH) * KBD_TARGET.size

func _key_hl(center: Vector2, col: Color) -> void:
	var r := Rect2(center - Vector2(13.0, 12.0), Vector2(26.0, 24.0))
	draw_colored_polygon(_rrect_points(r, 5.0), Color(col.r, col.g, col.b, 0.34))
	var pts := _rrect_points(r, 5.0)
	pts.append(pts[0])
	draw_polyline(pts, Color(col.r, col.g, col.b, 0.95), 2.0, true)

func _draw_keyboard_page() -> void:
	if kbd_tex != null:
		draw_texture_rect_region(kbd_tex, KBD_TARGET, KBD_SRC)

	# Highlight every used key. Positions are full-image fractions measured from
	# the photo (keycap centres detected via PIL), so they land on the keys.
	# P1 = W A S D F G H T V B ; P2 = arrows + . M L ; , /
	var p1_keys := [[0.2, 0.482], [0.173, 0.52], [0.209, 0.52], [0.247, 0.52],
		[0.285, 0.52], [0.323, 0.52], [0.36, 0.52], [0.313, 0.482], [0.304, 0.555], [0.341, 0.555]]
	var p2_keys := [[0.697, 0.553], [0.66, 0.596], [0.697, 0.596], [0.735, 0.596],
		[0.493, 0.555], [0.417, 0.555], [0.473, 0.52], [0.512, 0.52], [0.455, 0.555], [0.531, 0.555]]
	for k in p1_keys:
		_key_hl(_kbd(k[0], k[1]), KBD_P1)
	for k in p2_keys:
		_key_hl(_kbd(k[0], k[1]), KBD_P2)
	_key_hl(_kbd(0.10, 0.399), Color(0.62, 0.64, 0.76))   # Esc = pause (shared)

	# --- legend below the keyboard --------------------------------------
	# Movement grouped on its own; everything else grouped beneath it. Key
	# letters are coloured by player (P1 yellow / P2 cyan); the MOVE row names
	# the players so the colours read everywhere.
	_segments(640.0, 354.0, [["MOVE        ", TEXT], ["P1  WASD", KBD_P1],
		["          ", TEXT], ["P2  Arrows", KBD_P2]], A_CENTER, 22)

	var cells := [
		[400.0, 412.0, "ATTACK", "F", "."], [640.0, 412.0, "HEAVY", "H", "M"], [880.0, 412.0, "SPECIAL", "B", "L"],
		[400.0, 448.0, "BLOCK", "T", ","], [640.0, 448.0, "DODGE", "G", "/"], [880.0, 448.0, "SWAP", "V", ";"],
	]
	for c in cells:
		_segments(c[0], c[1], [[c[2] + "  ", TEXT], [c[3], KBD_P1], [" / ", SUBTLE], [c[4], KBD_P2]], A_CENTER, 20)
	_segments(640.0, 486.0, [["PAUSE   ", TEXT], ["Esc", Color(0.85, 0.86, 0.92)]], A_CENTER, 20)

# Draw a run of coloured text segments ([text, color], ...) as one aligned line.
func _segments(x: float, y: float, parts: Array, align: int, size: int) -> void:
	var total := 0.0
	for p in parts:
		total += font.get_string_size(p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var sx := x
	if align == A_CENTER:
		sx -= total * 0.5
	elif align == A_RIGHT:
		sx -= total
	for p in parts:
		_label(Vector2(sx, y), p[0], size, p[1], A_LEFT)
		sx += font.get_string_size(p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

# --- shared footer (page nav + back) ---------------------------------------
func _draw_page_footer() -> void:
	var other := "Keyboard" if page == 0 else "Controller"
	_label(Vector2(640.0, 600.0), "◄ ►  %s        B / Esc  Back" % other, 16, SUBTLE, A_CENTER)
	for i in range(2):
		var c: Color = ACCENT if i == page else Color(0.45, 0.47, 0.55)
		draw_circle(Vector2(630.0 + i * 20.0, 626.0), 4.0, c)

# --- drawing helpers -------------------------------------------------------

# Rounded-rect polygon, sampled clockwise from the top-left corner.
func _rrect_points(r: Rect2, rad: float, seg: int = 5) -> PackedVector2Array:
	rad = min(rad, min(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(r.position.x + rad, r.position.y + rad), PI, PI * 1.5],
		[Vector2(r.end.x - rad, r.position.y + rad), PI * 1.5, TAU],
		[Vector2(r.end.x - rad, r.end.y - rad), 0.0, PI * 0.5],
		[Vector2(r.position.x + rad, r.end.y - rad), PI * 0.5, PI],
	]
	for c in corners:
		var center: Vector2 = c[0]
		var a0: float = c[1]
		var a1: float = c[2]
		for i in range(seg + 1):
			var a: float = lerp(a0, a1, float(i) / float(seg))
			pts.append(center + Vector2(cos(a), sin(a)) * rad)
	return pts

func _fill_rrect(r: Rect2, rad: float, col: Color) -> void:
	draw_colored_polygon(_rrect_points(r, rad), col)

# Text with a cheap multi-direction outline so it reads on any background,
# matching the outlined Labels used elsewhere in the UI. `pos` is the top-left
# (or top-center / top-right per align) of the text box.
func _label(pos: Vector2, text: String, size: int, col: Color, align: int) -> void:
	var dim := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var x := pos.x
	if align == A_CENTER:
		x -= dim.x * 0.5
	elif align == A_RIGHT:
		x -= dim.x
	var baseline := Vector2(x, pos.y + font.get_ascent(size))
	var t := 2.0 if size >= 24 else 1.0
	for d in [Vector2(-t, 0), Vector2(t, 0), Vector2(0, -t), Vector2(0, t),
			Vector2(-t, -t), Vector2(t, -t), Vector2(-t, t), Vector2(t, t)]:
		draw_string(font, baseline + d, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, OUTLINE)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

# Single label centered on a point (used for glyphs on buttons/bumpers).
func _centered(center: Vector2, text: String, size: int, col: Color) -> void:
	var dim := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	_label(center - dim * 0.5, text, size, col, A_LEFT)

# A button-code chip (coloured) followed by its action (white), drawn as one
# unit. align controls how the combined block is placed at `pos`.
func _pair(pos: Vector2, code: String, action: String, code_col: Color, align: int, size: int = 20) -> void:
	var code_full := code + "   "
	var w_code := font.get_string_size(code_full, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var w_action := font.get_string_size(action, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var total := w_code + w_action
	var x := pos.x
	if align == A_CENTER:
		x -= total * 0.5
	elif align == A_RIGHT:
		x -= total
	_label(Vector2(x, pos.y), code_full, size, code_col, A_LEFT)
	_label(Vector2(x + w_code, pos.y), action, size, TEXT, A_LEFT)
