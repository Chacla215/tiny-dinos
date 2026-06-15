extends Node2D

# SHOP — spend season coins. Two kinds of stock: coin-priced EPIC skins (a one-time
# unlock, then equippable on any dino via the creator) and CONTINUE TOKENS (a
# consumable that revives a lost season at the failed matchday). Cosmetic + soft
# safety only — nothing here changes combat stats. Gamepad-only: UP/DOWN move,
# A buys the highlighted item (if affordable / not already owned), B returns to title.

const TITLE_SCENE := "res://scenes/title.tscn"
const ACCENT := Color(1.0, 0.85, 0.30)
const DIM := Color(0.74, 0.74, 0.82)
const OK_COLOR := Color(0.45, 0.95, 0.55)
const NO_COLOR := Color(0.95, 0.45, 0.45)
const CONTINUE_TOKEN_COST := 80

const UP := ["p1_up", "p2_up", "p3_up", "p4_up"]
const DOWN := ["p1_down", "p2_down", "p3_down", "p4_down"]
const CONFIRM := ["p1_confirm", "p2_confirm", "p3_confirm", "p4_confirm"]
const BACK := ["p1_heavy", "p2_heavy", "p3_heavy", "p4_heavy"]

var items: Array = []          # [{kind, idx?, name, cost}]
var rows: Array = []           # the Label per item
var selected: int = 0
var nav_prev: int = 0
var coin_label: Label
var msg_label: Label

func _ready() -> void:
	Audio.play_music("menu")
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.10)
	bg.size = Vector2(1280, 720)
	add_child(bg)
	_label("SHOP", 0, 56, 1280, 56, ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 40)
	coin_label = _label("", 0, 124, 1280, 38, Color(1.0, 0.8, 0.32), HORIZONTAL_ALIGNMENT_CENTER, 28)

	# Stock: every coin-priced skin, then the continue token.
	for i in range(MatchConfig.SKINS.size()):
		var s: Dictionary = MatchConfig.SKINS[i]
		if int(s.get("cost", 0)) > 0:
			items.append({"kind": "skin", "idx": i, "name": "%s SKIN" % s["name"], "cost": int(s["cost"])})
	items.append({"kind": "token", "name": "CONTINUE TOKEN", "cost": CONTINUE_TOKEN_COST})

	var y: float = 230.0
	for it in items:
		rows.append(_label("", 300, y, 680, 44, DIM, HORIZONTAL_ALIGNMENT_LEFT, 30))
		y += 60.0

	msg_label = _label("", 0, 600, 1280, 36, DIM, HORIZONTAL_ALIGNMENT_CENTER, 24)
	_label("UP / DOWN  SELECT      A  BUY      B  BACK", 0, 662, 1280, 34, DIM, HORIZONTAL_ALIGNMENT_CENTER, 24)
	_refresh()

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

func _owned(it: Dictionary) -> bool:
	return it["kind"] == "skin" and MetaSave.owns_skin(it["idx"])

func _refresh() -> void:
	coin_label.text = "COINS:  %d" % MetaSave.coins
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var cur: String = ">  " if i == selected else "   "
		var status: String
		if _owned(it):
			status = "OWNED"
		elif it["kind"] == "token":
			status = "x%d   -   %d COINS" % [MetaSave.continue_tokens, it["cost"]]
		else:
			status = "%d COINS" % it["cost"]
		rows[i].text = "%s%-22s %s" % [cur, it["name"], status]
		var col: Color = DIM
		if i == selected:
			col = ACCENT
		if _owned(it):
			col = OK_COLOR
		rows[i].add_theme_color_override("font_color", col)

func _process(_delta: float) -> void:
	for a in BACK:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			Audio.ui("back")
			get_tree().change_scene_to_file(TITLE_SCENE)
			return
	var dir: int = 1 if _held(DOWN) else (-1 if _held(UP) else 0)
	if dir != nav_prev:
		nav_prev = dir
		if dir != 0:
			Audio.ui("move")
			selected = (selected + dir + items.size()) % items.size()
			msg_label.text = ""
			_refresh()
	for a in CONFIRM:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			_buy()
			return

func _buy() -> void:
	var it: Dictionary = items[selected]
	if _owned(it):
		_say("ALREADY OWNED", NO_COLOR)
		return
	if MetaSave.coins < it["cost"]:
		Audio.ui("back")
		_say("NOT ENOUGH COINS", NO_COLOR)
		return
	MetaSave.spend_coins(it["cost"])
	if it["kind"] == "skin":
		MetaSave.buy_skin(it["idx"])
		_say("UNLOCKED %s  -  EQUIP IT IN CHARACTER" % it["name"], OK_COLOR)
	else:
		MetaSave.add_continue_token(1)
		_say("BOUGHT A CONTINUE TOKEN", OK_COLOR)
	Audio.ui("confirm")
	_refresh()

func _say(text: String, col: Color) -> void:
	msg_label.text = text
	msg_label.add_theme_color_override("font_color", col)

func _held(actions: Array) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false
