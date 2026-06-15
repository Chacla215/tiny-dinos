extends Node2D

# TROPHY CABINET — a read-only persistence display: lifetime season titles (by
# division), the highest division reached, gauntlet best wave, matchdays won, and
# the current coin balance. All values come from MetaSave; this screen never writes.
# Gamepad-only: A or B returns to the title. Built entirely in code (no .tscn churn),
# mirroring the in-match draft/overlay pattern.

const TITLE_SCENE := "res://scenes/title.tscn"
const ACCENT := Color(1.0, 0.85, 0.30)
const GOLD := Color(1.0, 0.80, 0.32)
const DIM := Color(0.74, 0.74, 0.82)
const BACK := ["p1_heavy", "p2_heavy", "p3_heavy", "p4_heavy"]
const CONFIRM := ["p1_confirm", "p2_confirm", "p3_confirm", "p4_confirm"]

func _ready() -> void:
	Audio.play_music("menu")
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.10)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	_label("TROPHY CABINET", 0, 64, 1280, 56, ACCENT, HORIZONTAL_ALIGNMENT_CENTER)

	var rows: Array = [
		["SEASON TITLES", "%d" % MetaSave.seasons_won],
		["HIGHEST DIVISION", MetaSave.division_name(MetaSave.best_division)],
		["MATCHDAYS WON", "%d" % MetaSave.matchdays_won],
		["BEST GAUNTLET WAVE", "%d" % MetaSave.best_wave],
		["COINS", "%d" % MetaSave.coins],
	]
	var y: float = 190.0
	for r in rows:
		_label(r[0], 300, y, 420, 40, DIM, HORIZONTAL_ALIGNMENT_LEFT)
		_label(r[1], 560, y, 420, 40, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		y += 52.0

	# Per-division championship breakdown — the heart of the cabinet.
	y += 24.0
	_label("- CHAMPIONSHIPS BY DIVISION -", 0, y, 1280, 36, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	y += 48.0
	for d in range(MetaSave.DIVISION_NAMES.size()):
		var n: int = MetaSave.season_titles_by_division[d] if d < MetaSave.season_titles_by_division.size() else 0
		var trophies: String = "*".repeat(mini(n, 12)) if n > 0 else "-"
		var locked: bool = d > MetaSave.unlocked_division()
		var col: Color = DIM if locked else GOLD
		_label(MetaSave.division_name(d), 360, y, 280, 38, col, HORIZONTAL_ALIGNMENT_LEFT)
		_label("%d   %s" % [n, trophies], 560, y, 360, 38, col, HORIZONTAL_ALIGNMENT_RIGHT)
		y += 46.0

	_label("B  BACK", 0, 660, 1280, 36, DIM, HORIZONTAL_ALIGNMENT_CENTER)

func _label(text: String, x: float, y: float, w: float, h: float, col: Color, align: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(x, y)
	l.size = Vector2(w, h)
	l.horizontal_alignment = align
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", 30 if h <= 42 else 40)
	add_child(l)
	return l

func _process(_delta: float) -> void:
	for a in BACK + CONFIRM:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			Audio.ui("back")
			get_tree().change_scene_to_file(TITLE_SCENE)
			return
