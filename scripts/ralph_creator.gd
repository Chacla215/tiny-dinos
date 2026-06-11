extends Control
## Character screen: roster grid (entry) → per-dino profile.
## Built programmatically + data-driven so AI-generated hero/skin PNGs slot in
## as they land. Gamepad-only:
##   GRID:   D-pad navigates,  A opens profile,  B → title
##   PROFILE: ◀▶ cycles skins,  A equips,  B → grid
## The grid features the 6 playable dinos (Ralph included). Flavor copy is
## hand-curated in PROFILES; stats and cooldowns derive from MatchConfig.DINOS
## so balance numbers stay the single source of truth. Portraits use the hero
## art at assets/concept/<dino>/<dino>_hero.png, falling back to the in-match
## pixel sprite. Prompts: scripts/tools/dino_art_prompts.md.
## File kept as ralph_creator.{gd,tscn} for minimum churn (was Ralph-only).

const DinoScript := preload("res://scripts/dino.gd")
const TITLE_SCENE := "res://scenes/title.tscn"
const RALPH_DIR := "res://assets/concept/ralph/"
const RALPH_HERO := RALPH_DIR + "ralph_hero.png"

# ---- palette (dark slate + gold, from the creator-screen target) ----
const BG := Color("12151f")
const PANEL := Color("212838")
const PANEL_IN := Color("171b27")
const BORDER := Color("3c4660")
const GOLD := Color("e6c878")
const GOLD_DK := Color("8a6f32")
const TEXT := Color("dce2ec")
const TEXT_DIM := Color("8b95a8")
const GREEN := Color("7fd06a")

# Grid: Ralph first as featured mascot, then the rest of the roster. Two rows.
const GRID_ROWS := [
	["ralph", "raptor", "trike"],
	["pterry", "bronto", "anky"],
]

# Skins are shared across every dino (see MatchConfig.SKINS). The carousel
# previews each by recolouring the dino's own portrait, so no per-skin art is
# required — but a painterly override at assets/concept/<dino>/<dino>_<name>.png
# is used for the big portrait when it exists (Ralph ships frozen/spring/void/
# golden). The equipped skin is persisted per dino in MetaSave.
# Painterly per-skin portrait override path, or "" if none exists. idx 0 = the
# dino's base hero; other skins look for <dino>_<skinname>.png.
func _skin_img(dino_id: String, idx: int) -> String:
	if idx == 0:
		return PROFILES.get(dino_id, {}).get("hero", "")
	var key: String = String(MatchConfig.SKINS[idx]["name"]).to_lower()
	var path := "res://assets/concept/%s/%s_%s.png" % [dino_id, dino_id, key]
	return path if ResourceLoader.exists(path) else ""

# Hand-curated copy. Stats and cooldowns are DERIVED from MatchConfig (see
# _stats_for / _cooldown_text) — only flavor text lives here so the in-game
# numbers stay the single source of truth. Each dino's hero path is checked
# for existence; missing → fall back to the in-match pixel sprite.
const PROFILES := {
	"ralph": {
		"display_name": "RALPH",
		"subtitle": "THE TINY KING",
		"rarity": "COMMON",
		"bio": "A tiny dino with a big heart and an even bigger attitude. Ralph may be small, but his courage is larger than life.",
		"personality": "BRAVE • CURIOUS • LOYAL",
		"move_name": "CHOMP",
		"move_desc": "Ralph lunges with jaws wide. Each bite heals him for part of the damage dealt — the more the tiny king feasts, the longer he reigns.",
		"move_type": "PHYSICAL",
		"hero": RALPH_HERO,
		"has_creator": true,
	},
	"raptor": {
		"display_name": "MAX",
		"subtitle": "THE SPEEDSTER",
		"rarity": "RARE",
		"bio": "Quick as a sneeze and twice as messy. Max the raptor strikes before you've finished the thought of dodging.",
		"personality": "SWIFT • CLEVER • MISCHIEVOUS",
		"move_name": "DASH CLAW",
		"move_desc": "Max rockets forward with sickle claws raised. A clean hit renews the hunt — the cooldown almost fully refunds.",
		"move_type": "PHYSICAL",
		"hero": "res://assets/concept/raptor/raptor_hero.png",
		"has_creator": false,
	},
	"trike": {
		"display_name": "GUS",
		"subtitle": "THE BULWARK",
		"rarity": "RARE",
		"bio": "Three horns and zero patience for picking a way around. Gus the trike's frill is for show. The headbutt is not.",
		"personality": "STUBBORN • LOYAL • GROUNDED",
		"move_name": "HEADBUTT CHARGE",
		"move_desc": "Gus lowers his horns and barrels forward, knocking enemies clear off the island. Nothing shoves Gus off course mid-charge.",
		"move_type": "PHYSICAL",
		"hero": "res://assets/concept/trike/trike_hero.png",
		"has_creator": false,
	},
	"pterry": {
		"display_name": "JESSIE",
		"subtitle": "THE SKY ACE",
		"rarity": "RARE",
		"bio": "Jessie the pterodactyl, self-proclaimed sky ace. Every landing is on purpose, every wing-bandage is a story.",
		"personality": "COCKY • BREEZY • AERIAL",
		"move_name": "SCREECH",
		"move_desc": "A piercing wail that slows every enemy caught in range. Jessie's favorite icebreaker.",
		"move_type": "SONIC",
		"hero": "res://assets/concept/pterry/pterry_hero.png",
		"has_creator": false,
	},
	"bronto": {
		"display_name": "STEVE",
		"subtitle": "THE GENTLE GIANT",
		"rarity": "RARE",
		"bio": "The slowest bronto to anger and the sweetest to share. Steve keeps a flower in his mouth and a cloud in his step.",
		"personality": "DREAMY • KIND • PATIENT",
		"move_name": "NECK WHIP",
		"move_desc": "Steve sweeps his long neck in a wide arc, scooping every enemy along the way. Raised guards crumble — blocking the whip drains far more.",
		"move_type": "PHYSICAL",
		"hero": "res://assets/concept/bronto/bronto_hero.png",
		"has_creator": false,
	},
	"anky": {
		"display_name": "FRANK",
		"subtitle": "THE VETERAN",
		"rarity": "RARE",
		"bio": "An old anky survivor with a plant in his armor and a grudge for breakfast. Get behind Frank before he turns around.",
		"personality": "GRUMPY • LOYAL • DEPENDABLE",
		"move_name": "TAIL SMASH",
		"move_desc": "Frank brings his club tail crashing down, sending a shockwave through the ground in every direction. There is no safe side.",
		"move_type": "PHYSICAL",
		"hero": "res://assets/concept/anky/anky_hero.png",
		"has_creator": false,
	},
}

# ---- runtime state ----
var grid_root: Control
var profile_root: Control
var grid_cards: Array = []        # [{id, node, row, col, sel_panel}]
var grid_row: int = 0
var grid_col: int = 0
var grid_nav_prev: Vector2i = Vector2i.ZERO
var in_profile: bool = false
var current_dino: String = "ralph"
var skin_idx: int = 0

# Profile-only refs that need refreshing on dino swap / skin cycle.
var portrait: TextureRect
var rarity_label: Label
var skin_slots: Array = []
var skin_status_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg(self, 0, 0, 1280, 720, BG)
	_build_grid_view()
	_build_profile_view()
	_show_grid()
	if "--shot" in OS.get_cmdline_user_args():
		await _shoot()


# ============================================================== shared helpers ==
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


func _panel(parent: Node, x: float, y: float, w: float, h: float, title := "") -> Panel:
	var p := Panel.new()
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.add_theme_stylebox_override("panel", _sb(PANEL))
	parent.add_child(p)
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


## Render the dino's portrait into `parent` at `rect`. Uses the AI hero PNG if
## it exists, else falls back to the first idle frame of the in-match sprite
## (atlas region from dino.gd ANIM_LAYOUTS) drawn with nearest-neighbor so the
## pixels stay crisp at the upscale.
func _add_portrait(parent: Control, dino_id: String, rect: Rect2, fallback_scale := 4.0) -> TextureRect:
	var profile: Dictionary = PROFILES.get(dino_id, {})
	var hero: String = profile.get("hero", "")
	if hero != "" and ResourceLoader.exists(hero):
		var t := TextureRect.new()
		t.texture = load(hero)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.position = rect.position
		t.size = rect.size
		parent.add_child(t)
		return t
	# Fallback: in-match pixel sprite, upscaled.
	var dino: Dictionary = MatchConfig.DINOS.get(dino_id, {})
	var role: String = dino.get("sprite_role", dino_id)
	var at := DinoScript.first_frame(role)
	if at == null:
		return null
	var faces_left: bool = DinoScript.ANIM_LAYOUTS[role].get("faces_left", false)
	var t := TextureRect.new()
	t.texture = at
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # fighters are painterly now
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Sized so the sprite reads as a hero portrait, not a sticker — fits the
	# panel but flips so face-left sheets still look toward the camera.
	t.position = rect.position
	t.size = rect.size
	t.flip_h = faces_left
	parent.add_child(t)
	return t


## Stats for the SIGNATURE panel. Every dino (Ralph included) derives
## HP/ATK/DEF/SPD/SPC from MatchConfig so balance numbers stay the single
## source of truth.
func _stats_for(dino_id: String) -> Array:
	var d: Dictionary = MatchConfig.DINOS.get(dino_id, {})
	if d.is_empty():
		return []
	var hp: int = int(d.get("max_hp", 100))
	var atk: int = int(round((float(d.get("attack_damage", 0)) + float(d.get("heavy_damage", 0))) / 2.0))
	var def_v: int = int(round(float(d.get("max_block", 60)) / 6.0))
	var spd: int = int(round(float(d.get("max_speed", 240)) / 12.0))
	var spc: int = int(d.get("special_damage", 0))
	return [
		["HP", str(hp), Color("e0564f")],
		["ATK", str(atk), Color("e89a3c")],
		["DEF", str(def_v), Color("5aa0e0")],
		["SPD", str(spd), Color("d2a878")],
		["SPC", str(spc), Color("e6c878")],
	]

# Signature-move cooldown straight from MatchConfig, e.g. "6s" / "4.5s".
func _cooldown_text(dino_id: String) -> String:
	var cd: float = float(MatchConfig.DINOS.get(dino_id, {}).get("special_cooldown", 0.0))
	if cd <= 0.0:
		return "—"
	var s := "%.1f" % cd
	if s.ends_with(".0"):
		s = s.substr(0, s.length() - 2)
	return s + "s"

# Largest value seen for each stat across the whole cast, so the profile bars
# are relative — the fastest dino's SPD bar is full, and a glass cannon's HP
# bar reads short. Cached after the first build.
var _stat_max_cache: Array = []
func _stat_maxes() -> Array:
	if not _stat_max_cache.is_empty():
		return _stat_max_cache
	var maxes := [1, 1, 1, 1, 1]
	for id in MatchConfig.ROSTER_ORDER:
		var rows: Array = _stats_for(id)
		for i in range(min(rows.size(), maxes.size())):
			maxes[i] = max(maxes[i], int(rows[i][1]))
	_stat_max_cache = maxes
	return maxes


# ================================================================== grid view ==
func _build_grid_view() -> void:
	grid_root = Control.new()
	grid_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(grid_root)

	var title := _text(grid_root, "CHARACTERS", 0, 28, 56, GOLD)
	title.size = Vector2(1280, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := _text(grid_root, "PICK A DINO TO VIEW THEIR PROFILE", 0, 96, 20, TEXT_DIM)
	subtitle.size = Vector2(1280, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var card_w := 224.0
	var card_h := 240.0
	var col_gap := 24.0
	var row_gap := 28.0
	var rows_total: float = GRID_ROWS.size() * card_h + (GRID_ROWS.size() - 1) * row_gap
	var rows_y: float = 152.0 + maxf(0.0, (520.0 - rows_total) / 2.0)
	for row in GRID_ROWS.size():
		var ids: Array = GRID_ROWS[row]
		var row_w: float = ids.size() * card_w + (ids.size() - 1) * col_gap
		var row_x: float = (1280.0 - row_w) / 2.0
		var y: float = rows_y + row * (card_h + row_gap)
		for col in ids.size():
			var x: float = row_x + col * (card_w + col_gap)
			var card := _build_card(ids[col], x, y, card_w, card_h)
			grid_cards.append({"id": ids[col], "node": card, "row": row, "col": col})

	var hint := _text(grid_root, "D-PAD  MOVE     A  CONFIRM     B  BACK", 0, 686, 18, TEXT_DIM)
	hint.size = Vector2(1280, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_refresh_grid_selection()


func _build_card(dino_id: String, x: float, y: float, w: float, h: float) -> Panel:
	var profile: Dictionary = PROFILES.get(dino_id, {})
	var p := Panel.new()
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.add_theme_stylebox_override("panel", _sb(PANEL, BORDER, 3, 12))
	grid_root.add_child(p)
	# Portrait area (top 70%).
	var pad := 12.0
	var portrait_h := h * 0.72
	var stage := _bg(p, pad, pad, w - pad * 2, portrait_h - pad, Color("2a3a52"))
	stage.color = Color("2a3a52")
	_add_portrait(p, dino_id, Rect2(pad, pad, w - pad * 2, portrait_h - pad))
	# Name strip (bottom).
	var name_y := portrait_h + 4
	var name_l := _text(p, profile.get("display_name", dino_id.to_upper()), 0, name_y, 24, GOLD)
	name_l.size = Vector2(w, 32)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var role := _text(p, profile.get("subtitle", ""), 0, name_y + 30, 14, TEXT_DIM)
	role.size = Vector2(w, 18)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return p


func _refresh_grid_selection() -> void:
	for entry in grid_cards:
		var on: bool = entry["row"] == grid_row and entry["col"] == grid_col
		var card: Panel = entry["node"]
		card.add_theme_stylebox_override("panel",
			_sb(PANEL, GOLD if on else BORDER, 5 if on else 3, 12))
		card.scale = Vector2.ONE * (1.05 if on else 1.0)
		card.pivot_offset = card.size / 2.0


func _clamp_grid_col() -> void:
	var row_len: int = GRID_ROWS[grid_row].size()
	grid_col = clampi(grid_col, 0, row_len - 1)


func _handle_grid_nav() -> void:
	var dx: int = 0
	var dy: int = 0
	if Input.is_action_just_pressed("p1_right"):
		dx = 1
	elif Input.is_action_just_pressed("p1_left"):
		dx = -1
	elif Input.is_action_just_pressed("p1_down"):
		dy = 1
	elif Input.is_action_just_pressed("p1_up"):
		dy = -1
	if dx != 0:
		var row_len: int = GRID_ROWS[grid_row].size()
		grid_col = (grid_col + dx + row_len) % row_len
		_refresh_grid_selection()
	elif dy != 0:
		grid_row = (grid_row + dy + GRID_ROWS.size()) % GRID_ROWS.size()
		_clamp_grid_col()
		_refresh_grid_selection()
	if Input.is_action_just_pressed("p1_confirm"):
		current_dino = GRID_ROWS[grid_row][grid_col]
		_show_profile(current_dino)
	elif Input.is_action_just_pressed("p1_heavy"):
		get_tree().change_scene_to_file(TITLE_SCENE)


# =============================================================== profile view ==
func _build_profile_view() -> void:
	profile_root = Control.new()
	profile_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(profile_root)
	# Each builder writes its widgets into profile_root via _panel(profile_root,
	# …). The big panels rebuild themselves on dino swap via _refresh_profile.
	_build_portrait_panel()
	_build_stats_panel()
	_build_bio_panel()
	_build_move_panel()
	_build_customization_panel()
	_build_skins_panel()
	_build_emotes_panel()


# Each builder below assumes a single instance and stashes the nodes it needs
# to refresh on dino swap on `self`. To swap dinos we wipe the dynamic content
# (name banner, portrait, stats text, bio text, move text, skins row) and
# re-populate from PROFILES + _stats_for.

var portrait_panel: Panel
var name_label: Label
var subtitle_label: Label
var stats_container: Panel
var bio_label: Label
var personality_label: Label
var move_panel: Panel
var move_name_label: Label
var move_desc_label: Label
var move_type_label: Label
var move_cooldown_label: Label
var move_icon_holder: Panel
var skins_panel: Panel
var customization_panel: Panel
var emotes_panel: Panel


func _build_portrait_panel() -> void:
	portrait_panel = _panel(profile_root, 16, 16, 540, 540)
	var stage := _bg(portrait_panel, 12, 12, 516, 516, PANEL_IN)
	stage.color = Color("2a3a52")
	# Portrait placeholder; replaced on _refresh_profile.
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(12, 12)
	portrait.size = Vector2(516, 516)
	portrait_panel.add_child(portrait)
	# Banner.
	var ban := Panel.new()
	ban.add_theme_stylebox_override("panel", _sb(Color("1a1f2c"), GOLD, 3, 12))
	ban.position = Vector2(70, 8)
	ban.size = Vector2(400, 92)
	portrait_panel.add_child(ban)
	name_label = _text(ban, "RALPH", 0, 6, 52, GOLD)
	name_label.size = Vector2(400, 56)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label = _text(ban, "• TINY DINO •", 0, 60, 20, TEXT_DIM)
	subtitle_label.size = Vector2(400, 24)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Rarity badge.
	var badge := Panel.new()
	badge.add_theme_stylebox_override("panel", _sb(PANEL_IN, GOLD_DK, 2, 8))
	badge.position = Vector2(20, 110)
	badge.size = Vector2(96, 70)
	portrait_panel.add_child(badge)
	var star := _text(badge, "★", 0, 2, 30, GOLD)
	star.size = Vector2(96, 34)
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rl := _text(badge, "RARITY", 0, 36, 13, TEXT_DIM)
	rl.size = Vector2(96, 16)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label = _text(badge, "COMMON", 0, 50, 14, TEXT)
	rarity_label.size = Vector2(96, 18)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Cycle arrows (only meaningful when the dino has skins).
	_text(portrait_panel, "◀", 8, 250, 40, GOLD).size = Vector2(40, 40)
	_text(portrait_panel, "▶", 492, 250, 40, GOLD).size = Vector2(40, 40)
	# EXP / level bar.
	var bar := Panel.new()
	bar.add_theme_stylebox_override("panel", _sb(PANEL_IN, GOLD_DK, 2, 8))
	bar.position = Vector2(20, 488)
	bar.size = Vector2(500, 40)
	portrait_panel.add_child(bar)
	_text(bar, "LV. 1", 12, 6, 22, GOLD)
	var track := _bg(bar, 96, 11, 320, 18, Color("0e1118"))
	track.color = Color("0e1118")
	_bg(track, 0, 0, 4, 18, GOLD)
	var exp_l := _text(bar, "0 / 100", 96, 8, 16, TEXT_DIM)
	exp_l.size = Vector2(320, 18)
	exp_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text(bar, "EXP", 432, 8, 18, TEXT_DIM)


func _build_stats_panel() -> void:
	stats_container = _panel(profile_root, 572, 16, 300, 212, "STATS")


func _build_bio_panel() -> void:
	var p := _panel(profile_root, 888, 16, 376, 212)
	bio_label = _text(p, "", 20, 16, 18, TEXT)
	bio_label.size = Vector2(336, 110)
	bio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text(p, "PERSONALITY:", 20, 134, 18, GREEN)
	personality_label = _text(p, "", 20, 158, 18, TEXT)


func _build_move_panel() -> void:
	move_panel = _panel(profile_root, 572, 252, 692, 150, "SIGNATURE MOVE")
	move_icon_holder = Panel.new()
	move_icon_holder.add_theme_stylebox_override("panel", _sb(Color("16314a"), GOLD_DK, 2, 8))
	move_icon_holder.position = Vector2(20, 28)
	move_icon_holder.size = Vector2(120, 104)
	move_panel.add_child(move_icon_holder)
	move_name_label = _text(move_panel, "", 160, 26, 26, GOLD)
	move_desc_label = _text(move_panel, "", 160, 58, 16, TEXT)
	move_desc_label.size = Vector2(510, 60)
	move_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	move_type_label = _text(move_panel, "TYPE: PHYSICAL", 160, 118, 16, TEXT_DIM)
	move_cooldown_label = _text(move_panel, "COOLDOWN: —", 420, 118, 16, TEXT_DIM)


func _build_customization_panel() -> void:
	customization_panel = _panel(profile_root, 572, 414, 692, 142, "CUSTOMIZATION")


func _build_skins_panel() -> void:
	skins_panel = _panel(profile_root, 16, 568, 720, 138, "SKINS")


func _build_emotes_panel() -> void:
	emotes_panel = _panel(profile_root, 748, 568, 516, 138, "EMOTES")


# Clear every dynamic child a builder spawned that we don't want to reuse for
# the new dino. Static labels stay (we just overwrite their text); dynamic
# rows of slot/swatch panels (stats / skins / customization / emotes) get
# wiped + rebuilt from data.
func _clear_children(parent: Node) -> void:
	for c in parent.get_children():
		c.queue_free()


func _refresh_profile(dino_id: String) -> void:
	var profile: Dictionary = PROFILES.get(dino_id, {})
	if profile.is_empty():
		return
	# Banner + portrait.
	name_label.text = profile.get("display_name", dino_id.to_upper())
	subtitle_label.text = "• %s •" % profile.get("subtitle", "")
	_refresh_portrait_for_dino(dino_id)
	# Stats: rebuild rows.
	_clear_children(stats_container)
	# The title tab is recreated by _panel — re-add it here.
	_decorate_panel_title(stats_container, "STATS")
	var rows: Array = _stats_for(dino_id)
	var maxes: Array = _stat_maxes()
	var y: float = 44.0
	for i in range(rows.size()):
		var row: Array = rows[i]
		var dot := _bg(stats_container, 22, y + 7, 14, 14, row[2])
		dot.color = row[2]
		_text(stats_container, row[0], 44, y, 24, TEXT)
		# Bar: a dark track with a fill scaled to this stat vs. the cast max.
		const BAR_X := 100.0
		const BAR_W := 130.0
		_bg(stats_container, BAR_X, y + 7, BAR_W, 14, Color("0e1118"))
		var denom: float = float(maxes[i]) if i < maxes.size() and maxes[i] > 0 else 1.0
		var frac: float = clamp(float(int(row[1])) / denom, 0.06, 1.0)
		_bg(stats_container, BAR_X, y + 7, BAR_W * frac, 14, row[2])
		var v := _text(stats_container, row[1], 0, y, 24, GOLD)
		v.size = Vector2(282, 28)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		y += 32
	# Bio + personality.
	bio_label.text = profile.get("bio", "")
	personality_label.text = profile.get("personality", "")
	# Move card.
	move_name_label.text = profile.get("move_name", "")
	move_desc_label.text = profile.get("move_desc", "")
	move_type_label.text = "TYPE: %s" % profile.get("move_type", "PHYSICAL")
	move_cooldown_label.text = "COOLDOWN: %s" % _cooldown_text(dino_id)
	_clear_children(move_icon_holder)
	_add_portrait(move_icon_holder, dino_id, Rect2(6, 6, 108, 92))
	# Skins (every dino) + weapons; emotes are still a teaser.
	skin_idx = MetaSave.get_skin(dino_id)
	skin_slots.clear()
	_clear_children(skins_panel)
	_decorate_panel_title(skins_panel, "SKINS")
	_clear_children(customization_panel)
	_decorate_panel_title(customization_panel, "WEAPONS")
	_populate_weapons(customization_panel, dino_id)
	_clear_children(emotes_panel)
	_decorate_panel_title(emotes_panel, "EMOTES")
	_populate_emotes()
	_populate_skins(dino_id)
	# Portrait + rarity badge reflect the equipped/previewed skin.
	_refresh_skin_selection()


# A one-line "playstyle" tag derived from whichever core stat (HP/ATK/DEF/SPD)
# stands out most for this dino — tracks balance automatically.
func _playstyle_tag(dino_id: String) -> String:
	var rows: Array = _stats_for(dino_id)
	var maxes: Array = _stat_maxes()
	var labels := ["FRONTLINE BRUISER", "HEAVY HITTER", "STONE WALL", "HIT-AND-RUN"]
	var best_i := 0
	var best_frac := -1.0
	for i in range(min(4, rows.size())):
		var denom: float = float(maxes[i]) if maxes[i] > 0 else 1.0
		var frac: float = float(int(rows[i][1])) / denom
		if frac > best_frac:
			best_frac = frac
			best_i = i
	return labels[best_i]

# A short, player-facing descriptor of how a weapon plays vs. the dino's fists.
func _weapon_desc(wid: String) -> String:
	var w: Dictionary = MatchConfig.WEAPONS.get(wid, {})
	var dmg: float = w.get("dmg", 1.0)
	var rng = w.get("range", 0)
	var wind: float = w.get("windup", 1.0)
	var dmg_s: String = "DMG BASE" if abs(dmg - 1.0) < 0.01 else "DMG %+d%%" % int(round((dmg - 1.0) * 100.0))
	var rng_s: String = "REACH —" if int(rng) == 0 else "REACH %+d" % int(rng)
	var spd_s: String = "FAST" if wind < 0.85 else ("SLOW" if wind > 1.15 else "STEADY")
	return "%s    %s    %s" % [dmg_s, rng_s, spd_s]

# Fill the (repurposed) customization panel with the dino's two-weapon loadout and
# its playstyle tag, all derived from MatchConfig so it tracks the live balance.
func _populate_weapons(panel: Panel, dino_id: String) -> void:
	var dino: Dictionary = MatchConfig.DINOS.get(dino_id, {})
	var loadout: Array = dino.get("weapons", ["fists"])
	_text(panel, "PLAYSTYLE:  %s" % _playstyle_tag(dino_id), 20, 10, 18, GREEN)
	var cols := [24.0, 360.0]
	for i in range(min(loadout.size(), 2)):
		var wid: String = loadout[i]
		var x: float = cols[i]
		var disp: String = MatchConfig.WEAPONS.get(wid, {}).get("display_name", wid.to_upper())
		_text(panel, disp, x, 48, 24, GOLD)
		_text(panel, _weapon_desc(wid), x, 82, 16, TEXT_DIM)


# The panel title tab is a child of the panel created by _panel(). Clearing the
# panel children kills it, so re-attach it here whenever we wipe + repopulate.
func _decorate_panel_title(panel: Panel, title: String) -> void:
	if title == "":
		return
	var tab := Panel.new()
	tab.add_theme_stylebox_override("panel", _sb(PANEL_IN, GOLD_DK, 2, 7))
	tab.position = Vector2(14, -16)
	var w_est: float = 22 + title.length() * 13
	tab.size = Vector2(w_est, 30)
	panel.add_child(tab)
	var lbl := _text(tab, title, 0, 0, 20, GOLD)
	lbl.size = tab.size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _refresh_portrait_for_dino(dino_id: String) -> void:
	# Big portrait reflects the previewed skin (skin_idx). Painterly skin/base art
	# fills the stage when it exists; otherwise the base hero (or, last resort, the
	# in-match sprite) is recoloured live by the skin shader.
	var art: String = _skin_img(dino_id, skin_idx)
	var base_hero: String = PROFILES.get(dino_id, {}).get("hero", "")
	if art != "" and ResourceLoader.exists(art):
		portrait.texture = load(art)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		portrait.material = null
		portrait.flip_h = false
		portrait.position = Vector2(12, 12)
		portrait.size = Vector2(516, 516)
		return
	if base_hero != "" and ResourceLoader.exists(base_hero):
		portrait.texture = load(base_hero)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		portrait.material = MatchConfig.skin_material(skin_idx)
		portrait.flip_h = false
		portrait.position = Vector2(12, 12)
		portrait.size = Vector2(516, 516)
		return
	# Last resort: the in-match pixel sprite, recoloured, kept sprite-sized.
	var dino: Dictionary = MatchConfig.DINOS.get(dino_id, {})
	var role: String = dino.get("sprite_role", dino_id)
	var at := DinoScript.first_frame(role)
	if at == null:
		portrait.texture = null
		return
	portrait.texture = at
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # fighters are painterly now
	portrait.material = MatchConfig.skin_material(skin_idx)
	portrait.flip_h = DinoScript.ANIM_LAYOUTS[role].get("faces_left", false)
	var src: Vector2 = at.region.size
	var target_h: float = 320.0
	var box_w: float = target_h * src.x / src.y
	portrait.position = Vector2(12.0 + (516.0 - box_w) / 2.0, 12.0 + (516.0 - target_h) / 2.0)
	portrait.size = Vector2(box_w, target_h)


# Skin carousel for ANY dino: each slot previews the skin by recolouring the
# dino's own portrait. Works with zero per-skin art; painterly overrides slot in
# automatically where they exist.
func _populate_skins(dino_id: String) -> void:
	var slot_w := 92.0
	for i in MatchConfig.SKINS.size():
		var skin: Dictionary = MatchConfig.SKINS[i]
		var x: float = 16.0 + i * (slot_w + 8)
		var box := Panel.new()
		box.add_theme_stylebox_override("panel", _sb(PANEL_IN, BORDER, 2, 8))
		box.position = Vector2(x, 24)
		box.size = Vector2(slot_w, 66)
		skins_panel.add_child(box)
		_fill_skin_thumb(box, dino_id, i, slot_w)
		var l := _text(skins_panel, skin["name"], x, 92, 12, TEXT_DIM)
		l.size = Vector2(slot_w, 16)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skin_slots.append(box)
	skin_status_label = _text(skins_panel, "", 16, 110, 15, GREEN)
	skin_status_label.size = Vector2(688, 20)
	skin_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


# Fill one carousel slot with a recoloured thumbnail of the dino (skin `i`).
func _fill_skin_thumb(box: Panel, dino_id: String, i: int, slot_w: float) -> void:
	var art: String = _skin_img(dino_id, i)
	var src_img: String = art if (art != "" and ResourceLoader.exists(art)) else PROFILES.get(dino_id, {}).get("hero", "")
	if src_img == "" or not ResourceLoader.exists(src_img):
		_bg(box, slot_w / 2 - 20, 12, 40, 40, MatchConfig.SKINS[i].get("swatch", BORDER))
		return
	var tr := TextureRect.new()
	tr.texture = load(src_img)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.position = Vector2(4, 4)
	tr.size = Vector2(slot_w - 8, 58)
	# Only recolour when this slot is showing the base hero (no bespoke skin art).
	if art == "":
		tr.material = MatchConfig.skin_material(i)
	box.add_child(tr)


func _populate_panel_placeholder(panel: Panel, msg: String) -> void:
	var l := _text(panel, msg, 0, 0, 20, TEXT_DIM)
	l.size = panel.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


# Emote gallery: the same quick-taunt bubbles you can pop in a match with SELECT.
func _populate_emotes() -> void:
	var cw := 122.0
	var ch := 50.0
	for i in MatchConfig.EMOTES.size():
		var em: Dictionary = MatchConfig.EMOTES[i]
		var x: float = 14.0 + (i % 4) * cw
		var y: float = 18.0 + (i / 4) * (ch + 10)
		var bubble := Panel.new()
		bubble.add_theme_stylebox_override("panel", _sb(Color("f5f1e6"), GOLD, 2, 9))
		bubble.position = Vector2(x, y)
		bubble.size = Vector2(cw - 16, ch - 18)
		emotes_panel.add_child(bubble)
		var t := _text(bubble, em["text"], 0, 0, 18, Color("2a2118"))
		t.size = bubble.size
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var nm := _text(emotes_panel, em["name"], x, y + ch - 18, 11, TEXT_DIM)
		nm.size = Vector2(cw - 16, 14)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


# Cursor (gold) = previewed skin; green = currently equipped. Updates rarity,
# the status line, and the big portrait.
func _refresh_skin_selection() -> void:
	var equipped: int = MetaSave.get_skin(current_dino)
	for i in skin_slots.size():
		var border: Color = BORDER
		var bw: int = 2
		if i == skin_idx:
			border = GOLD
			bw = 4
		elif i == equipped:
			border = GREEN
			bw = 3
		skin_slots[i].add_theme_stylebox_override("panel", _sb(PANEL_IN, border, bw, 8))
	rarity_label.text = MatchConfig.SKINS[skin_idx].get("rarity", "COMMON")
	if skin_status_label != null:
		if skin_idx == equipped:
			skin_status_label.text = "EQUIPPED:  %s" % MatchConfig.SKINS[equipped]["name"]
		else:
			skin_status_label.text = "A  EQUIP %s      (EQUIPPED: %s)" % [
				MatchConfig.SKINS[skin_idx]["name"], MatchConfig.SKINS[equipped]["name"]]
	_refresh_portrait_for_dino(current_dino)


# ================================================================ view toggles ==
func _show_grid() -> void:
	in_profile = false
	grid_root.visible = true
	profile_root.visible = false


func _show_profile(dino_id: String) -> void:
	in_profile = true
	current_dino = dino_id
	skin_idx = 0
	_refresh_profile(dino_id)
	grid_root.visible = false
	profile_root.visible = true


# =================================================================== process ==
func _process(_delta: float) -> void:
	if in_profile:
		_handle_profile_input()
	else:
		_handle_grid_nav()


func _handle_profile_input() -> void:
	if Input.is_action_just_pressed("p1_heavy"):
		_show_grid()
		return
	# ◀▶ previews skins (every dino), A equips the previewed one (persisted).
	if skin_slots.is_empty():
		return
	var n: int = MatchConfig.SKINS.size()
	if Input.is_action_just_pressed("p1_right"):
		skin_idx = (skin_idx + 1) % n
		_refresh_skin_selection()
	elif Input.is_action_just_pressed("p1_left"):
		skin_idx = (skin_idx - 1 + n) % n
		_refresh_skin_selection()
	elif Input.is_action_just_pressed("p1_confirm"):
		MetaSave.set_skin(current_dino, skin_idx)
		_refresh_skin_selection()


# Offscreen screenshot for previews: godot <scene> -- --shot [view] [dino_id]
#   view = "grid" (default) or "profile"
#   dino_id = roster id when view = "profile" (default: ralph)
func _shoot() -> void:
	var args := OS.get_cmdline_user_args()
	var want_profile: bool = "profile" in args
	var want_dino: String = "ralph"
	for a in args:
		if a in PROFILES:
			want_dino = a
	if want_profile:
		_show_profile(want_dino)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var suffix := want_dino if want_profile else "grid"
	img.save_png("/tmp/ralph/creator_shot_%s.png" % suffix)
	get_tree().quit()
