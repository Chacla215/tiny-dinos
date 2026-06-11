extends Node2D

const START_DELAY := 0.8
# Weapons are not picked here — everyone starts unarmed and fights over the
# drops that fall onto the island mid-round (see main.gd weapon drops).

# The picker shows the SAME art the match uses, so pick == play. Dinos render
# from dino.gd's ANIM_LAYOUTS; islands use each arena's actual gameplay
# background (NOT the hand-drawn concept cards). Frozen Floes is drawn
# procedurally, so it gets a generated preview that matches its layout.
const DinoScript := preload("res://scripts/dino.gd")
const TITLE_SCENE := "res://scenes/title.tscn"
# Bottom-of-screen control hint. The game is gamepad-only, so this is constant.
const HINT_PAD := "A CONFIRM   B BACK   LB ADD OPPONENT   RB DIFFICULTY   Y MODE   X TEAMS   P1 PICKS EACH CPU"
const ISLAND_PREVIEW := {
	"laughing_lava":     "res://assets/tilesets/laughing_lava_bg.png",
	"beauty_beach":      "res://assets/tilesets/beauty_beach_bg.png",
	"sunny_springs":     "res://assets/tilesets/sunny_springs_bg.png",
	"white_water_falls": "res://assets/tilesets/white_water_falls_bg.png",
	"purple_fields":     "res://assets/tilesets/purple_fields_bg.png",
	"iciest_age":        "res://assets/tilesets/iciest_floes_bg.png",
}
const PANEL_Y := 430.0          # baseline for the player cards row
const GRAPHIC_TARGET_H := 170.0 # all dino sprites scaled to this height (consistent size)
const ISLAND_BG_WIDTH := 680.0  # centerpiece island preview width

@onready var countdown_label: Label = $Countdown
@onready var panels := {
	"p1": $P1Panel,
	"p2": $P2Panel,
	"p3": $P3Panel,
	"p4": $P4Panel,
}
@onready var island_label: Label = $IslandLabel
@onready var hint_label: Label = $Hint
@onready var island_bg: Sprite2D = $IslandBg
# Built in code (so the .tscn isn't restructured): shows the CPU difficulty just
# under the island line, only while at least one slot is a CPU.
var difficulty_label: Label
# Built in code too: the match's game mode, on its own line under the island.
var mode_label: Label
var mode_idx: int = 0
# Teams line (also built in code): the chosen split, P1 cycles it with X.
var teams_label: Label
var team_preset_idx: int = 0
# Solo setup (arcade ladder OR roguelike gauntlet): P1 picks only their own
# fighter; the p2 slot is the CPU opponent, not host-configurable.
var arcade: bool = false
var gauntlet: bool = false
var solo_duo: bool = false   # arcade co-op: P1 + a CPU partner

func _solo() -> bool:
	return arcade or gauntlet

var indexes: Dictionary = {"p1": 0, "p2": 1, "p3": 2, "p4": 3}
# Per-slot skin (color) pick, seeded from the dino's creator-equipped skin
# whenever the dino changes. Committed to MatchConfig.skin_choices at launch.
var skin_sel: Dictionary = {"p1": 0, "p2": 0, "p3": 0, "p4": 0}
var stages: Dictionary = {"p1": "dino", "p2": "dino", "p3": "dino", "p4": "dino"}
var island_idx: int = 0
var ready_states: Dictionary = {"p1": false, "p2": false, "p3": false, "p4": false}
var cpu_states: Dictionary = {"p1": false, "p2": false, "p3": false, "p4": false}
var active_players: Array = []
var start_timer: float = 0.0
# Everyone is locked in AND the host has pressed the Ready/START button: the
# match is counting down. Until then we hold on the Ready gate (see _process).
var launch_armed: bool = false

func _ready() -> void:
	Audio.play_music("menu")
	var controller_count: int = Input.get_connected_joypads().size()
	var initial_count: int = clamp(controller_count, 2, 4)
	if controller_count < 2:
		initial_count = 2
	for pid in MatchConfig.PLAYER_IDS:
		indexes[pid] = clamp(indexes[pid], 0, MatchConfig.ROSTER_ORDER.size() - 1)
		skin_sel[pid] = MetaSave.get_skin(MatchConfig.ROSTER_ORDER[indexes[pid]])
		_apply_player_color_to_panel(pid)
	# Each opponent is HUMAN only if its own controller is plugged in, else CPU.
	_refresh_cpu_assignment()
	_apply_active_count(initial_count)
	countdown_label.text = ""
	_update_hint()
	# Plugging/unplugging a pad re-decides which slots are human and which prompts show.
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	island_idx = MatchConfig.ISLAND_ORDER.find(MatchConfig.island)
	if island_idx < 0:
		island_idx = 0
	_update_island()
	_build_difficulty_label()
	_update_difficulty_label()
	mode_idx = MatchConfig.MODE_ORDER.find(MatchConfig.game_mode)
	if mode_idx < 0:
		mode_idx = 0
	_build_mode_label()
	_update_mode_label()
	MatchConfig.teams_enabled = false  # versus defaults to FFA until P1 picks a split
	team_preset_idx = 0
	_build_teams_label()
	_update_teams_label()
	arcade = MatchConfig.arcade_setup
	gauntlet = MatchConfig.gauntlet_setup
	if _solo():
		_enter_solo_setup()

# Solo setup: lock to P1 + a fixed CPU opponent slot the host doesn't configure.
# Hide the versus-only selectors. The banner/hint differ per solo mode.
func _enter_solo_setup() -> void:
	_apply_active_count(2)
	cpu_states["p2"] = true
	ready_states["p2"] = true   # the opponent is always ready; the host can't edit it
	stages["p2"] = "ready"
	island_label.text = "ROGUELIKE GAUNTLET  -  SURVIVE + UPGRADE" if gauntlet else "ARCADE LADDER  -  CLIMB THE GAUNTLET"
	# Arcade can be played co-op (you + a CPU partner); the gauntlet stays solo.
	hint_label.text = "A CONFIRM   B BACK   P1 PICK FIGHTER  -  UP/DOWN ISLAND" + ("   X PARTNER" if arcade else "")
	_update_solo_duo_label()
	_update_solo_island_label()  # repurposes the (otherwise-hidden) mode label
	_set_island_bg(MatchConfig.ISLAND_ORDER[island_idx])
	_refresh_displays()
	_refresh_start()

# Arcade co-op toggle, shown on the (otherwise-hidden-in-solo) difficulty line.
func _update_solo_duo_label() -> void:
	if not difficulty_label:
		return
	if not arcade:
		difficulty_label.visible = false
		return
	difficulty_label.visible = true
	difficulty_label.text = "PARTNER (CO-OP):  %s    (P1 X)" % ("ON" if solo_duo else "OFF")

# Solo setup borrows the mode label to show the chosen starting island; the
# gauntlet randomizes islands after wave 1, the arcade ladder opens here.
func _update_solo_island_label() -> void:
	if not mode_label:
		return
	mode_label.visible = true
	var island_name: String = MatchConfig.ISLAND_NAMES[MatchConfig.ISLAND_ORDER[island_idx]]
	mode_label.text = "START ISLAND:  %s   (P1 UP / DOWN)" % island_name

func _cycle_solo_island(step: int) -> void:
	Audio.ui("move")
	var n: int = MatchConfig.ISLAND_ORDER.size()
	island_idx = (island_idx + step + n) % n
	_set_island_bg(MatchConfig.ISLAND_ORDER[island_idx])
	_update_solo_island_label()

# Activate the first n player slots (2-4); the rest are hidden. Rebuilds the row.
func _apply_active_count(n: int) -> void:
	MatchConfig.player_count = clamp(n, 2, 4)
	active_players.clear()
	for pid in MatchConfig.PLAYER_IDS:
		var is_active: bool = int(pid.substr(1)) <= MatchConfig.player_count
		panels[pid].visible = is_active
		if is_active:
			active_players.append(pid)
	# Position cards first so _set_graphic can face each dino toward center.
	_layout_panels()
	for pid in active_players:
		_update_display(pid)
	_refresh_start()
	_update_difficulty_label()
	# THE BEAST needs 3-4 fighters; if the count dropped below that, fall back to
	# ROUNDS so the menu never sits on an unplayable mode.
	if not _mode_available(MatchConfig.game_mode):
		MatchConfig.game_mode = "rounds"
		mode_idx = MatchConfig.MODE_ORDER.find("rounds")
		_update_mode_label()
	# Fewer/more fighters changes which splits are valid — reset to OFF.
	team_preset_idx = 0
	_apply_team_preset()
	_update_teams_label()

# Host adds a computer opponent (cycles 2 -> 3 -> 4 -> 2 players). Newly added
# opponent slots default to CPU, so a solo player can fight 1-v-2 or 1-v-3.
func _cycle_opponent_count() -> void:
	Audio.ui("move")
	var prev: int = MatchConfig.player_count
	var n: int = prev + 1 if prev < 4 else 2
	_apply_active_count(n)
	for pid in active_players:
		if int(pid.substr(1)) > prev and pid != "p1":
			cpu_states[pid] = not _controller_present(int(pid.substr(1)) - 1)
			ready_states[pid] = false
			stages[pid] = "dino"
	_update_difficulty_label()
	_refresh_displays()
	_refresh_start()

func _process(delta: float) -> void:
	# Solo: P1 picks the starting island any time before the launch countdown
	# arms (UP/DOWN is unused by the fighter picker, so there's no conflict).
	if _solo() and not launch_armed:
		if Input.is_action_just_pressed("p1_up"):
			_cycle_solo_island(-1)
		elif Input.is_action_just_pressed("p1_down"):
			_cycle_solo_island(1)
		# Arcade only: X toggles the co-op partner.
		if arcade and Input.is_action_just_pressed("p1_attack"):
			Audio.ui("move")
			solo_duo = not solo_duo
			_update_solo_duo_label()
	if _all_ready():
		_process_launch(delta)
		return
	launch_armed = false
	countdown_label.text = ""
	# Versus-only match settings (island / extra opponents / difficulty / mode). The
	# solo modes fix all of these, so the host only picks a fighter.
	if not _solo():
		if Input.is_action_just_pressed("p1_up"):
			island_idx = (island_idx - 1 + MatchConfig.ISLAND_ORDER.size()) % MatchConfig.ISLAND_ORDER.size()
			_update_island()
		elif Input.is_action_just_pressed("p1_down"):
			island_idx = (island_idx + 1) % MatchConfig.ISLAND_ORDER.size()
			_update_island()
		# Host adds/cycles computer opponents (1-v-2, 1-v-3, ...).
		if Input.is_action_just_pressed("p1_special"):
			_cycle_opponent_count()
		# Host cycles the CPU difficulty (only matters when a CPU is in the match).
		if Input.is_action_just_pressed("p1_swap") and _any_cpu():
			_cycle_difficulty()
		# Host cycles the game mode (rounds / stock / king of the hill / egg grab).
		if Input.is_action_just_pressed("p1_block"):
			_cycle_mode()
		# Host cycles the team split (OFF / 2v2 / 1v3 / 1v2, depending on count + mode).
		if Input.is_action_just_pressed("p1_attack"):
			_cycle_teams()
	# P1 (the host) configures their own fighter first, then every CPU's dino
	# AND color, all on the LEFT stick. Human opponents pick on their own pads.
	var target: String = _host_focus()
	if target == "":
		# All host slots locked; let BACK still un-ready the most recent pick.
		var q: Array = _host_queue()
		if not q.is_empty():
			target = q[q.size() - 1]
	if target != "":
		_drive_slot(target, "p1", target != "p1")
	for pid in active_players:
		if pid != "p1" and not cpu_states[pid]:
			_drive_slot(pid, pid, false)

# Every fighter has locked a dino + color. Hold on a Ready/START gate so the
# host can eyeball the whole line-up -- nobody drops into the match until the
# Ready button (confirm) is pressed. Back reopens a pick so it can be changed.
func _process_launch(delta: float) -> void:
	if launch_armed:
		start_timer -= delta
		countdown_label.text = "STARTING..."
		if start_timer <= 0.0:
			_start_match()
		return
	var on_pad: bool = not Input.get_connected_joypads().is_empty()
	var keys: Array = ["A", "B"] if on_pad else ["F", "H"]
	countdown_label.text = "EVERYONE READY?    %s  START      %s  BACK" % keys
	if Input.is_action_just_pressed("p1_confirm"):
		Audio.ui("confirm")
		launch_armed = true
		start_timer = START_DELAY
		return
	# Host (B) reopens the last fighter it locked; a human (their B) reopens theirs.
	if Input.is_action_just_pressed("p1_heavy"):
		_reopen_last_host_pick()
		return
	for pid in active_players:
		if pid != "p1" and not cpu_states[pid] and Input.is_action_just_pressed("%s_heavy" % pid):
			Audio.ui("back")
			stages[pid] = "skin"
			_set_ready(pid, false)
			return

# Step the last host-controlled fighter (P1, or the last CPU) back to its color
# pick so the host can change it; this drops us out of the Ready gate.
func _reopen_last_host_pick() -> void:
	var q: Array = _host_queue()
	if q.is_empty():
		return
	Audio.ui("back")
	var pid: String = q[q.size() - 1]
	stages[pid] = "skin"
	_set_ready(pid, false)

# The slots P1 configures, in order: P1's own fighter, then each CPU opponent.
# Human opponents are absent here -- they drive their own slots with their pads.
func _host_queue() -> Array:
	if _solo():
		return ["p1"]  # the CPU opponent slot isn't host-configurable
	var arr: Array = ["p1"]
	for pid in active_players:
		if pid != "p1" and cpu_states[pid]:
			arr.append(pid)
	return arr

# The slot P1 is editing right now: first one in the queue not yet locked in.
func _host_focus() -> String:
	for pid in _host_queue():
		if not ready_states[pid]:
			return pid
	return ""

func _all_ready() -> bool:
	for pid in active_players:
		if not ready_states[pid]:
			return false
	return true

# Run one slot's dino -> color -> ready picker from the `src` controller's
# inputs. `host_edit` is true when P1 is configuring a CPU: BACK on its dino
# stage steps focus back to the previous fighter in the queue.
func _drive_slot(pid: String, src: String, host_edit: bool) -> void:
	var left := Input.is_action_just_pressed("%s_left" % src)
	var right := Input.is_action_just_pressed("%s_right" % src)
	var confirm := Input.is_action_just_pressed("%s_confirm" % src)
	# Back is B (heavy) -- matches the title screen's back button. (RB now flips
	# an opponent human/CPU, so B is free here.)
	var back := Input.is_action_just_pressed("%s_heavy" % src)
	if left or right:
		Audio.ui("move")
	if confirm:
		Audio.ui("confirm")
	elif back:
		Audio.ui("back")

	match stages[pid]:
		"dino":
			if left: _cycle_dino(pid, -1)
			elif right: _cycle_dino(pid, 1)
			if confirm:
				stages[pid] = "skin"
				_refresh_displays()
			elif back:
				if host_edit:
					_host_back_to_prev(pid)
				elif pid == "p1":
					# Host is at the very first pick with nothing left to undo,
					# so backing out leaves the select screen for the title.
					_return_to_title()
		"skin":
			if left: _cycle_skin(pid, -1)
			elif right: _cycle_skin(pid, 1)
			if confirm:
				stages[pid] = "ready"
				_set_ready(pid, true)
			elif back:
				stages[pid] = "dino"
				_refresh_displays()
		"ready":
			if back:
				stages[pid] = "skin"
				_set_ready(pid, false)

# P1 pressed BACK while picking a CPU's dino: re-open the previous fighter in
# the queue (un-ready it) so P1 can change that pick before continuing.
func _host_back_to_prev(pid: String) -> void:
	var q: Array = _host_queue()
	var i: int = q.find(pid)
	if i <= 0:
		return
	var prev: String = q[i - 1]
	stages[prev] = "skin"
	_set_ready(prev, false)

func _cycle_dino(pid: String, step: int) -> void:
	var n: int = MatchConfig.ROSTER_ORDER.size()
	indexes[pid] = (indexes[pid] + step + n) % n
	# New dino: re-seed the color pick from its creator-equipped skin.
	skin_sel[pid] = MetaSave.get_skin(MatchConfig.ROSTER_ORDER[indexes[pid]])
	_update_display(pid)

func _cycle_skin(pid: String, step: int) -> void:
	var n: int = MatchConfig.SKINS.size()
	skin_sel[pid] = (skin_sel[pid] + step + n) % n
	_update_display(pid)

func _set_ready(pid: String, ready_state: bool) -> void:
	ready_states[pid] = ready_state
	_refresh_start()
	_refresh_displays()

func _refresh_displays() -> void:
	for pid in active_players:
		_update_display(pid)

func _refresh_start() -> void:
	# Reaching "all ready" no longer starts the match on its own -- the Ready/START
	# gate in _process does. Any change before launch disarms a pending start.
	if not _all_ready():
		launch_armed = false

func _update_display(pid: String) -> void:
	var idx: int = indexes[pid]
	var dino_id: String = MatchConfig.ROSTER_ORDER[idx]
	var dino: Dictionary = MatchConfig.DINOS[dino_id]
	var panel: Node2D = panels[pid]
	var name_label: Label = panel.get_node("Name")
	var status_label: Label = panel.get_node("Status")
	var header_label: Label = panel.get_node("Header")
	var graphic: AnimatedSprite2D = panel.get_node("Graphic")

	if _solo() and pid == "p2":
		var accent := Color(1.0, 0.6, 0.2, 1)
		header_label.text = "GAUNTLET" if gauntlet else "ARCADE"
		header_label.add_theme_color_override("font_color", accent)
		name_label.text = "ENDLESS" if gauntlet else "GAUNTLET"
		name_label.add_theme_color_override("font_color", accent)
		status_label.text = "SURVIVE + UPGRADE!" if gauntlet else "5 RIVALS  -  CLIMB!"
		status_label.add_theme_color_override("font_color", accent)
		panel.modulate = Color(1, 1, 1, 1)
		_set_graphic(graphic, dino_id)  # a mystery silhouette
		return

	name_label.text = dino.display_name
	name_label.add_theme_color_override("font_color", dino.dino_color)
	_set_graphic(graphic, dino_id)
	# Live color preview: the same recolor shader the match uses (pick == play).
	graphic.material = MatchConfig.skin_material(skin_sel[pid])

	var is_cpu: bool = cpu_states[pid]
	header_label.text = "PLAYER %s  (CPU)" % pid.substr(1) if is_cpu else "PLAYER %s" % pid.substr(1)
	# In team mode, tag + color the header by side so the split reads at a glance.
	if MatchConfig.teams_enabled:
		var side: String = MatchConfig.side_of(pid)
		header_label.text += "  -  %s" % MatchConfig.TEAM_NAMES.get(side, "")
		header_label.add_theme_color_override("font_color", MatchConfig.TEAM_COLORS.get(side, Color.WHITE))
	else:
		header_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	# A CPU the host hasn't reached yet waits in line, dimmed; the slot P1 (or a
	# human) is actively editing is at full brightness.
	var waiting: bool = is_cpu and not ready_states[pid] and _host_focus() != pid
	panel.modulate = Color(1, 1, 1, 0.4) if waiting else Color(1, 1, 1, 1)
	if waiting:
		status_label.text = "CPU   .   UP NEXT"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1))
		return

	var prefix: String = "CPU   " if is_cpu else ""
	match stages[pid]:
		"dino":
			status_label.text = "%sPICK DINO" % prefix
			status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
		"skin":
			var skin: Dictionary = MatchConfig.SKINS[skin_sel[pid]]
			status_label.text = "%sCOLOR:  %s" % [prefix, skin["name"]]
			status_label.add_theme_color_override("font_color", skin["swatch"])
		"ready":
			status_label.text = "%sREADY" % prefix
			status_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5, 1))

func _apply_player_color_to_panel(pid: String) -> void:
	var color: Color = MatchConfig.PLAYER_COLORS.get(pid, Color.WHITE)
	var panel: Node2D = panels[pid]
	var header: Label = panel.get_node("Header")
	header.add_theme_color_override("font_color", color)

func _update_island() -> void:
	MatchConfig.island = MatchConfig.ISLAND_ORDER[island_idx]
	island_label.text = "ISLAND:  %s    (P1 UP / DOWN)" % MatchConfig.ISLAND_NAMES[MatchConfig.island]
	_set_island_bg(MatchConfig.island)

# --- CPU difficulty ---

# True when any active slot is a computer opponent (difficulty is meaningless in
# an all-human lobby, so the selector hides itself then).
func _any_cpu() -> bool:
	for pid in active_players:
		if cpu_states.get(pid, false):
			return true
	return false

func _cycle_difficulty() -> void:
	Audio.ui("move")
	var order: Array = MatchConfig.CPU_DIFFICULTY_ORDER
	var i: int = order.find(MatchConfig.cpu_difficulty)
	MatchConfig.cpu_difficulty = order[(i + 1) % order.size()]
	_update_difficulty_label()

func _build_difficulty_label() -> void:
	difficulty_label = Label.new()
	difficulty_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	difficulty_label.offset_top = 88.0
	difficulty_label.offset_bottom = 112.0
	difficulty_label.offset_left = 0.0
	difficulty_label.offset_right = 1280.0
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_font_size_override("font_size", 18)
	difficulty_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1))
	add_child(difficulty_label)

func _update_difficulty_label() -> void:
	if difficulty_label == null:
		return
	if _solo():
		difficulty_label.visible = false
		return
	if not _any_cpu():
		difficulty_label.visible = false
		return
	difficulty_label.visible = true
	var dname: String = MatchConfig.CPU_DIFFICULTY_NAMES.get(MatchConfig.cpu_difficulty, "NORMAL")
	difficulty_label.text = "CPU DIFFICULTY:  %s    (P1 RB)" % dname

# --- Game mode ---

# THE BEAST is a 1-vs-all crowd mode — only offered with 3-4 fighters.
func _mode_available(mode: String) -> bool:
	if mode == "beast":
		return MatchConfig.player_count >= MatchConfig.BEAST_MIN_PLAYERS
	return true

func _cycle_mode() -> void:
	Audio.ui("move")
	var order: Array = MatchConfig.MODE_ORDER
	# Advance to the next AVAILABLE mode (skips THE BEAST at <3 players).
	for _i in order.size():
		mode_idx = (mode_idx + 1) % order.size()
		if _mode_available(order[mode_idx]):
			break
	MatchConfig.game_mode = order[mode_idx]
	_update_mode_label()
	# Switching to/from an FFA-only mode changes whether teams are offered.
	team_preset_idx = 0
	_apply_team_preset()
	_update_teams_label()
	_refresh_displays()

func _build_mode_label() -> void:
	mode_label = Label.new()
	mode_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	mode_label.offset_top = 110.0
	mode_label.offset_bottom = 158.0
	mode_label.offset_left = 0.0
	mode_label.offset_right = 1280.0
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.add_theme_font_size_override("font_size", 20)
	mode_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.6, 1))
	add_child(mode_label)

func _update_mode_label() -> void:
	if mode_label == null:
		return
	if _solo():
		mode_label.visible = false
		return
	var mname: String = MatchConfig.MODE_NAMES.get(MatchConfig.game_mode, "BEST OF ROUNDS")
	var blurb: String = MatchConfig.mode_blurb(MatchConfig.game_mode)
	mode_label.text = "MODE:  %s    (P1 Y)\n%s" % [mname, blurb]

# --- Teams ---
# Bomb Tag (one bomb) and The Beast (one crown) are inherently free-for-all, so
# teams are offered only for the other modes — and only with 3+ fighters.
const TEAM_MODES := ["rounds", "koth", "eggs", "sumo", "flood"]

func _mode_allows_teams() -> bool:
	return MatchConfig.game_mode in TEAM_MODES

# Index 0 is always OFF (free-for-all). The rest are split presets for the current
# fighter count: 2v2 / 1v3 at four players, 1v2 at three.
func _team_presets() -> Array:
	var presets: Array = [{"name": "OFF", "teams": {}}]
	if _mode_allows_teams():
		if MatchConfig.player_count == 3:
			presets.append({"name": "1 v 2", "teams": {"p1": "a", "p2": "b", "p3": "b"}})
		elif MatchConfig.player_count == 4:
			presets.append({"name": "2 v 2", "teams": {"p1": "a", "p2": "b", "p3": "a", "p4": "b"}})
			presets.append({"name": "1 v 3", "teams": {"p1": "a", "p2": "b", "p3": "b", "p4": "b"}})
	return presets

func _cycle_teams() -> void:
	Audio.ui("move")
	var presets: Array = _team_presets()
	if presets.size() <= 1:
		return  # no split available for this count/mode
	team_preset_idx = (team_preset_idx + 1) % presets.size()
	_apply_team_preset()
	_update_teams_label()
	_refresh_displays()  # recolor cards by team

# Push the chosen split into MatchConfig (live, so the cards/markers preview it).
func _apply_team_preset() -> void:
	var presets: Array = _team_presets()
	team_preset_idx = clamp(team_preset_idx, 0, presets.size() - 1)
	var preset: Dictionary = presets[team_preset_idx]
	if preset["teams"].is_empty():
		MatchConfig.teams_enabled = false
	else:
		MatchConfig.teams_enabled = true
		MatchConfig.teams = preset["teams"].duplicate()

func _build_teams_label() -> void:
	teams_label = Label.new()
	teams_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	teams_label.offset_top = 162.0
	teams_label.offset_bottom = 186.0
	teams_label.offset_left = 0.0
	teams_label.offset_right = 1280.0
	teams_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teams_label.add_theme_font_size_override("font_size", 18)
	teams_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.95, 1))
	add_child(teams_label)

func _update_teams_label() -> void:
	if teams_label == null:
		return
	# No split possible (solo, <3 fighters, or an FFA-only mode) → hide the line.
	if _solo() or _team_presets().size() <= 1:
		teams_label.visible = false
		return
	teams_label.visible = true
	var presets: Array = _team_presets()
	team_preset_idx = clamp(team_preset_idx, 0, presets.size() - 1)
	teams_label.text = "TEAMS:  %s    (P1 X)" % presets[team_preset_idx]["name"]

# --- Concept-art helpers ---

# Spread the active player cards evenly across the screen in a single row.
func _layout_panels() -> void:
	var n: int = active_players.size()
	for i in range(n):
		var pid: String = active_players[i]
		panels[pid].position = Vector2(1280.0 * (i + 0.5) / n, PANEL_Y)

# Show the dino's in-game sprite (idle anim) so the picker matches the match.
# Built from the same ANIM_LAYOUTS the dino uses, scaled to a consistent height.
func _set_graphic(graphic: AnimatedSprite2D, dino_id: String) -> void:
	var dino: Dictionary = MatchConfig.DINOS.get(dino_id, {})
	var role: String = dino.get("sprite_role", "")
	var sf := DinoScript.build_sprite_frames(role, PackedStringArray(["idle"]))
	if sf == null:
		graphic.sprite_frames = null
		return
	var layout: Dictionary = DinoScript.ANIM_LAYOUTS[role]
	graphic.sprite_frames = sf
	graphic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # fighters are painterly now
	var src_h: float = layout["idle"].rects[0].size.y
	var s: float = GRAPHIC_TARGET_H / src_h
	graphic.scale = Vector2(s, s)
	# Face toward screen center: left-side dinos look right, right-side look left.
	var faces_left_art: bool = layout.get("faces_left", false)
	var on_left: bool = graphic.get_parent().position.x < 640.0
	graphic.flip_h = faces_left_art if on_left else not faces_left_art
	graphic.play("idle")

# Dimmed island concept art behind the cards, so players preview the arena.
func _set_island_bg(island_id: String) -> void:
	var path: String = ISLAND_PREVIEW.get(island_id, "")
	if path == "" or not ResourceLoader.exists(path):
		island_bg.texture = null
		return
	var tex: Texture2D = load(path)
	island_bg.texture = tex
	island_bg.scale = Vector2(ISLAND_BG_WIDTH / tex.get_width(), ISLAND_BG_WIDTH / tex.get_width())

# A controller is "present" for a slot when that slot's device id is plugged in
# (p1->0, p2->1, ...). Drives both HUMAN/CPU assignment and which hint shows.
func _controller_present(device: int) -> bool:
	return device in Input.get_connected_joypads()

# Opponents (p2..p4) are HUMAN only when their own controller is connected,
# otherwise CPU; P1 (host) is always human. A slot whose role flips is reset so
# its new driver (P1 or that human) picks from scratch.
func _refresh_cpu_assignment() -> void:
	if _solo():
		return  # the opponent stays CPU no matter what's plugged in
	for pid in MatchConfig.PLAYER_IDS:
		var should_cpu: bool = pid != "p1" and not _controller_present(int(pid.substr(1)) - 1)
		if cpu_states[pid] != should_cpu:
			cpu_states[pid] = should_cpu
			ready_states[pid] = false
			stages[pid] = "dino"

# A pad was plugged in or removed: re-decide human/CPU slots and refresh prompts.
func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh_cpu_assignment()
	_refresh_displays()
	_refresh_start()
	_update_hint()
	_update_difficulty_label()

# Gamepad-only, so the hint never changes (except the trimmed arcade hint).
func _update_hint() -> void:
	if _solo():
		hint_label.text = "A CONFIRM    B BACK    P1 PICK FIGHTER  -  UP/DOWN ISLAND"
		return
	hint_label.text = HINT_PAD

func _return_to_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)

func _start_match() -> void:
	# Color picks: configured slots override; everyone else (inactive slots,
	# solo CPU rungs) falls back to their creator-equipped MetaSave skin via -1.
	for pid in MatchConfig.PLAYER_IDS:
		var picked: bool = pid in active_players and not (_solo() and pid != "p1")
		MatchConfig.skin_choices[pid] = skin_sel[pid] if picked else -1
	if _solo():
		var pd: String = MatchConfig.ROSTER_ORDER[indexes["p1"]]
		var pi: String = MatchConfig.ISLAND_ORDER[island_idx]
		if gauntlet:
			MatchConfig.gauntlet_setup = false
			MatchConfig.start_gauntlet(pd, pi)
			get_tree().change_scene_to_file(MatchConfig.gauntlet_scene())
		else:
			MatchConfig.arcade_setup = false
			MatchConfig.start_arcade(pd, pi, solo_duo)
			get_tree().change_scene_to_file(MatchConfig.arcade_scene())
		return
	for pid in MatchConfig.PLAYER_IDS:
		MatchConfig.cpu_players[pid] = cpu_states.get(pid, false)
	for pid in active_players:
		MatchConfig.dino_choices[pid] = MatchConfig.ROSTER_ORDER[indexes[pid]]
	var scene_path: String = MatchConfig.ISLAND_SCENES.get(MatchConfig.island, "res://scenes/main.tscn")
	get_tree().change_scene_to_file(scene_path)
