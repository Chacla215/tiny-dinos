@tool
extends Node2D

# Native controller diagram for the How-to-Play screen.
#
# One page only: the real Xbox controller photo, centered, with callout lines
# radiating out to labels down the left and right edges — a "controller map".
# The keyboard/computer page was removed; the build is played on gamepads.
#
# Everything is drawn in screen space (1280x720) so it sits directly inside the
# title's full-screen HowToPanel with no transform. It is a static drawing:
# _draw runs once and is cached until queue_redraw(). Open/close (B / ESC) is
# owned by title.gd, so this node has no _process.
#
# The pad graphic is the real Xbox controller photo (TEX_PATH). Callout anchors
# are the photo's actual button positions, measured from the image as fractions
# of the controller's bounding box and mapped into TEX_TARGET. If the texture is
# ever missing we fall back to the hand-drawn pad (_draw_body / _draw_inputs).
#
# CONTROLS SHOWN = WHAT THE BUILD ACTUALLY DOES TODAY. The bindings come from
# match_config.gd's _register_player_actions():
#     LT -> pick up weapon   RT -> throw weapon
#     LB -> special attack   RB -> swap weapon
#     X  -> light attack   B -> heavy attack   Y -> block   A -> dodge
#     L-Stick / D-Pad -> move    Menu(Start) -> pause
# Only the right stick is left unbound; it simply gets no callout, so the screen
# never promises a button that does nothing.

const TEX_PATH := "res://assets/ui/xbox_controller.png"

# Game-wide UI font (Jersey 25) so this screen's text matches every other menu;
# falls back to the engine font only if the resource is somehow missing.
const FONT_PATH := "res://assets/fonts/Jersey25.ttf"

# Where the photo is drawn on screen, and which slice of the 750x750 source to
# draw (its controller bounding box, so the surrounding whitespace is cropped).
const TEX_TARGET := Rect2(451.0, 210.0, 377.0, 260.0)
const TEX_SRC := Rect2(42.75, 150.75, 663.0, 457.5)

const C := Vector2(640.0, 352.0)   # controller center (hand-drawn fallback only)

# --- palette ---------------------------------------------------------------
const TEXT    := Color(0.95, 0.95, 0.98)
const ACCENT  := Color(1.00, 0.88, 0.30)        # P1 yellow, matches the title
const SUBTLE  := Color(0.60, 0.63, 0.72)
const LINE    := Color(0.36, 0.82, 0.42, 0.90)  # callout connectors (green)
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
const SYS     := Color(0.85, 0.86, 0.92)        # neutral system buttons (Menu)

# --- alignment ---
const A_LEFT := 0
const A_CENTER := 1
const A_RIGHT := 2

var font: Font
var controller_tex: Texture2D

# Callout anchors (screen space) — one per labelled control. Set from the photo,
# or derived from the hand-drawn pad in fallback. _draw_callouts only reads these.
var a_lt: Vector2      # left trigger
var a_lb: Vector2      # left bumper
var a_rt: Vector2      # right trigger
var a_rb: Vector2      # right bumper
var a_ls: Vector2      # left stick
var a_dpad: Vector2    # d-pad
var a_y: Vector2       # Y face button
var a_b: Vector2       # B face button
var a_x: Vector2       # X face button
var a_a: Vector2       # A face button
var a_menu: Vector2    # Menu (Start) button
var a_rs: Vector2      # right stick (unbound; no callout, kept for completeness)

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
		if ResourceLoader.exists(FONT_PATH):
			font = load(FONT_PATH)
		else:
			font = ThemeDB.fallback_font
	if controller_tex == null and ResourceLoader.exists(TEX_PATH):
		controller_tex = load(TEX_PATH)
	if controller_tex != null:
		_setup_photo_anchors()
	else:
		_setup_drawn_anchors()

# Map a point given as a fraction of the controller's BOUNDING BOX (not the full
# image) into screen space within TEX_TARGET. Fractions measured from the photo.
func _photo(u: float, v: float) -> Vector2:
	return TEX_TARGET.position + Vector2(u, v) * TEX_TARGET.size

func _setup_photo_anchors() -> void:
	# Triggers aren't visible top-down, so they're anchored just outboard of the
	# bumpers at the top edge (where they physically sit).
	a_lt = _photo(0.205, 0.00)
	a_lb = _photo(0.274, 0.03)
	a_rt = _photo(0.755, 0.00)
	a_rb = _photo(0.682, 0.03)
	a_ls = _photo(0.249, 0.280)
	a_dpad = _photo(0.373, 0.519)
	a_y = _photo(0.750, 0.183)
	a_b = _photo(0.821, 0.286)
	a_x = _photo(0.687, 0.274)
	a_a = _photo(0.753, 0.376)
	a_menu = _photo(0.577, 0.265)
	a_rs = _photo(0.611, 0.501)

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
	a_lt = lt_rect.get_center()
	a_lb = lb_rect.get_center()
	a_rt = rt_rect.get_center()
	a_rb = rb_rect.get_center()
	a_ls = ls
	a_dpad = dpad
	a_rs = rs
	a_y = by
	a_b = bb
	a_x = bx
	a_a = ba
	a_menu = menu_btn

func _draw() -> void:
	_ensure_setup()
	_label(Vector2(640.0, 88.0), "HOW TO PLAY", 40, ACCENT, A_CENTER)
	if controller_tex != null:
		draw_texture_rect_region(controller_tex, TEX_TARGET, TEX_SRC)
	else:
		_draw_body()
		_draw_inputs()
	_draw_callouts()
	_label(Vector2(640.0, 600.0), "B    Back", 16, SUBTLE, A_CENTER)

# --- callouts: lines radiating to labels down both edges --------------------
func _draw_callouts() -> void:
	var rx := 400.0   # left-column labels are right-aligned to here
	var lx := 880.0   # right-column labels are left-aligned to here

	# Left column: triggers + bumpers.
	_callout_l(a_lt, rx, 222.0, "LT", "PICK UP", ACCENT)
	_callout_l(a_lb, rx, 264.0, "LB", "SPECIAL ATTACK", ACCENT)

	# MOVE — the left stick and the d-pad both do it, so one label fans two
	# connectors out to both.
	var move_y := 345.0
	var move_lead := Vector2(rx + 18.0, move_y)
	draw_circle(a_ls, 3.0, LINE)
	draw_circle(a_dpad, 3.0, LINE)
	draw_polyline(PackedVector2Array([a_ls, move_lead]), LINE, 2.0, true)
	draw_polyline(PackedVector2Array([a_dpad, move_lead]), LINE, 2.0, true)
	draw_polyline(PackedVector2Array([move_lead, Vector2(rx + 6.0, move_y)]), LINE, 2.0, true)
	_label(Vector2(rx, move_y - 22.0), "MOVE", 22, TEXT, A_RIGHT)
	_label(Vector2(rx, move_y + 4.0), "L-Stick / D-Pad", 15, SUBTLE, A_RIGHT)

	# Right column: triggers + bumpers, then the four face buttons ordered by
	# their height on the pad so the connector lines stay roughly parallel.
	_callout_r(a_rt, lx, 222.0, "RT", "THROW", ACCENT)
	_callout_r(a_rb, lx, 264.0, "RB", "SWAP WEAPON", ACCENT)
	_callout_r(a_y, lx, 306.0, "Y", "BLOCK", BTN_Y)
	_callout_r(a_x, lx, 348.0, "X", "LIGHT ATTACK", BTN_X)
	_callout_r(a_b, lx, 390.0, "B", "HEAVY ATTACK", BTN_B)
	_callout_r(a_a, lx, 432.0, "A", "DODGE", BTN_A)

	# Pause — Menu button, dropped to a centered label just below the pad.
	draw_circle(a_menu, 3.0, LINE)
	draw_polyline(PackedVector2Array([a_menu, Vector2(640.0, 484.0)]), LINE, 2.0, true)
	_label(Vector2(640.0, 487.0), "MENU / PAUSE", 19, SYS, A_CENTER)

# Left-edge callout: dot at the button, a line out to the gutter, then a label
# right-aligned with its right edge at rx and centered vertically on ly.
func _callout_l(anchor: Vector2, rx: float, ly: float, code: String, action: String, col: Color) -> void:
	draw_circle(anchor, 3.0, LINE)
	draw_polyline(PackedVector2Array([anchor, Vector2(rx + 18.0, ly), Vector2(rx + 6.0, ly)]), LINE, 2.0, true)
	_pair(Vector2(rx, ly - 10.0), code, action, col, A_RIGHT, 19)

# Right-edge callout: mirror of _callout_l, label left-aligned from lx.
func _callout_r(anchor: Vector2, lx: float, ly: float, code: String, action: String, col: Color) -> void:
	draw_circle(anchor, 3.0, LINE)
	draw_polyline(PackedVector2Array([anchor, Vector2(lx - 18.0, ly), Vector2(lx - 6.0, ly)]), LINE, 2.0, true)
	_pair(Vector2(lx, ly - 10.0), code, action, col, A_LEFT, 19)

# --- hand-drawn fallback pad (only when the photo is missing) ---------------
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

func _draw_inputs() -> void:
	# Triggers (LT / RT) and bumpers (LB / RB) — all bound, drawn solid.
	for r in [lt_rect, rt_rect, lb_rect, rb_rect]:
		_fill_rrect(r, 9.0, BODY_DK)
	_centered(lt_rect.get_center(), "LT", 14, Color(0.16, 0.16, 0.2))
	_centered(rt_rect.get_center(), "RT", 14, Color(0.16, 0.16, 0.2))
	_centered(lb_rect.get_center(), "LB", 14, Color(0.16, 0.16, 0.2))
	_centered(rb_rect.get_center(), "RB", 14, Color(0.16, 0.16, 0.2))

	# Left stick (move) and right stick (bare).
	_stick(ls, false)
	_stick(rs, true)

	# D-pad (move).
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
