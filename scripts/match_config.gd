extends Node

const ROSTER_ORDER := ["trex", "raptor", "trike", "pterry", "bronto", "anky"]

const PLAYER_COLORS := {
	"p1": Color(1.00, 0.88, 0.30, 1.0),
	"p2": Color(0.30, 0.80, 1.00, 1.0),
	"p3": Color(0.95, 0.45, 0.85, 1.0),
	"p4": Color(0.45, 0.95, 0.45, 1.0),
}

const PLAYER_IDS := ["p1", "p2", "p3", "p4"]
const ACTION_NAMES := ["up", "down", "left", "right", "attack", "heavy", "special", "swap", "block", "dodge", "pickup", "throw", "confirm"]

const PLAYER_TINTS := {
	"p1": Color(1.30, 1.20, 0.50),
	"p2": Color(0.50, 1.10, 1.30),
	"p3": Color(1.30, 0.60, 1.20),
	"p4": Color(0.60, 1.20, 0.60),
}

# Weapons modify light + heavy attacks (not the signature special). Y swaps the
# active weapon. "fists" = the dino's natural attack. Melee only for now — Bow
# needs the projectile path (TODO). Each dino has a 2-weapon loadout (DINOS.weapons).
const WEAPONS := {
	"fists":     {"display_name": "FISTS",     "dmg": 1.0,  "kb": 1.0,  "range": 0,   "windup": 1.0, "recovery": 1.0},
	"sword":     {"display_name": "SWORD",      "dmg": 1.2,  "kb": 1.1,  "range": 16,  "windup": 1.0, "recovery": 1.0},
	"dagger":    {"display_name": "DAGGER",     "dmg": 0.7,  "kb": 0.7,  "range": -4,  "windup": 0.6, "recovery": 0.6},
	"axe":       {"display_name": "AXE",        "dmg": 1.45, "kb": 1.25, "range": 12,  "windup": 1.25, "recovery": 1.2},
	"mace":      {"display_name": "SPIKED MACE", "dmg": 1.4, "kb": 1.5,  "range": 10,  "windup": 1.3, "recovery": 1.3},
	"hammer":    {"display_name": "WAR HAMMER", "dmg": 1.9,  "kb": 1.7,  "range": 10,  "windup": 1.6, "recovery": 1.5},
	"nunchucks": {"display_name": "NUNCHUCKS",  "dmg": 0.85, "kb": 0.6,  "range": 4,   "windup": 0.5, "recovery": 0.7},
}

const DINOS := {
	"trex": {
		"display_name": "T-REX",
		"weapons": ["fists", "hammer"],
		"dino_color": Color(0.4, 0.85, 0.55, 1.0),
		"sprite_role": "trex",
		"sprite_scale": 3.6,
		"sprite_offset_y": -20.0,
		"hit_sfx_name": "hit_chomp",
		"max_speed": 240.0,
		"ground_accel": 1500.0,
		"ground_friction": 2200.0,
		"ice_accel": 300.0,
		"ice_friction": 90.0,
		"max_hp": 150,
		"attack_damage": 25,
		"attack_knockback": 460.0,
		"attack_windup": 0.22,
		"attack_active": 0.14,
		"attack_recovery": 0.40,
		"attack_hitbox_size": Vector2(80, 72),
		"attack_hitbox_offset": 60.0,
		"heavy_damage": 45,
		"heavy_knockback": 700.0,
		"heavy_windup": 0.40,
		"heavy_active": 0.20,
		"heavy_recovery": 0.60,
		"heavy_hitbox_size": Vector2(110, 90),
		"heavy_hitbox_offset": 70.0,
		"heavy_self_dash": 0.0,
		"max_block": 120.0,
		"block_regen": 25.0,
		"dodge_duration": 0.22,
		"dodge_cooldown": 0.7,
		"dodge_distance": 110.0,
		"dodge_block_cost": 40.0,
		"special_type": "chomp",
		"special_damage": 28,
		"special_knockback": 300.0,
		"special_windup": 0.22,
		"special_active": 0.12,
		"special_recovery": 0.45,
		"special_hitbox_size": Vector2(72, 64),
		"special_hitbox_offset": 58.0,
		"special_self_dash": 700.0,
		"special_cooldown": 5.0,
		"special_lifesteal": 0.5,
	},
	"trike": {
		"display_name": "TRIKE",
		"weapons": ["fists", "mace"],
		"dino_color": Color(0.95, 0.85, 0.30, 1.0),
		"sprite_role": "trike",
		"sprite_scale": 1.6,
		"sprite_offset_y": -20.0,
		"hit_sfx_name": "hit_chomp",
		"max_speed": 300.0,
		"ground_accel": 2500.0,
		"ground_friction": 3500.0,
		"ice_accel": 500.0,
		"ice_friction": 150.0,
		"max_hp": 130,
		"attack_damage": 18,
		"attack_knockback": 350.0,
		"attack_windup": 0.16,
		"attack_active": 0.12,
		"attack_recovery": 0.32,
		"attack_hitbox_size": Vector2(70, 60),
		"attack_hitbox_offset": 50.0,
		"heavy_damage": 34,
		"heavy_knockback": 560.0,
		"heavy_windup": 0.30,
		"heavy_active": 0.16,
		"heavy_recovery": 0.52,
		"heavy_hitbox_size": Vector2(88, 72),
		"heavy_hitbox_offset": 56.0,
		"heavy_self_dash": 0.0,
		"max_block": 95.0,
		"block_regen": 28.0,
		"dodge_duration": 0.20,
		"dodge_cooldown": 0.6,
		"dodge_distance": 150.0,
		"dodge_block_cost": 32.0,
		"special_type": "headbutt",
		"special_damage": 30,
		"special_knockback": 650.0,
		"special_windup": 0.30,
		"special_active": 0.16,
		"special_recovery": 0.55,
		"special_hitbox_size": Vector2(90, 80),
		"special_hitbox_offset": 60.0,
		"special_self_dash": 1400.0,
		"special_cooldown": 5.0,
	},
	"pterry": {
		"display_name": "PTERRY",
		"weapons": ["fists", "sword"],
		"dino_color": Color(0.85, 0.45, 0.30, 1.0),
		"sprite_role": "pterry",
		"sprite_scale": 2.7,
		"sprite_offset_y": -20.0,
		"hit_sfx_name": "hit_chomp",
		"max_speed": 280.0,
		"ground_accel": 2000.0,
		"ground_friction": 3000.0,
		"ice_accel": 400.0,
		"ice_friction": 120.0,
		"max_hp": 140,
		"attack_damage": 16,
		"attack_knockback": 380.0,
		"attack_windup": 0.14,
		"attack_active": 0.10,
		"attack_recovery": 0.28,
		"attack_hitbox_size": Vector2(70, 50),
		"attack_hitbox_offset": 48.0,
		"heavy_damage": 40,
		"heavy_knockback": 750.0,
		"heavy_windup": 0.25,
		"heavy_active": 0.18,
		"heavy_recovery": 0.55,
		"heavy_hitbox_size": Vector2(80, 60),
		"heavy_hitbox_offset": 55.0,
		"heavy_self_dash": 1400.0,
		"max_block": 100.0,
		"block_regen": 25.0,
		"dodge_duration": 0.20,
		"dodge_cooldown": 0.6,
		"dodge_distance": 120.0,
		"dodge_block_cost": 35.0,
		"special_type": "screech",
		"special_damage": 8,
		"special_knockback": 250.0,
		"special_windup": 0.20,
		"special_active": 0.06,
		"special_recovery": 0.50,
		"special_radius": 220.0,
		"special_slow_duration": 1.5,
		"special_cooldown": 6.0,
	},
	"raptor": {
		"display_name": "RAPTOR",
		"weapons": ["fists", "dagger"],
		"dino_color": Color(0.95, 0.45, 0.45, 1.0),
		"sprite_role": "raptor",
		"sprite_scale": 2.5,
		"sprite_offset_y": -20.0,
		"hit_sfx_name": "hit_claw",
		"max_speed": 440.0,
		"ground_accel": 5000.0,
		"ground_friction": 5000.0,
		"ice_accel": 1100.0,
		"ice_friction": 380.0,
		"max_hp": 100,
		"attack_damage": 12,
		"attack_knockback": 200.0,
		"attack_windup": 0.06,
		"attack_active": 0.08,
		"attack_recovery": 0.18,
		"attack_hitbox_size": Vector2(56, 48),
		"attack_hitbox_offset": 44.0,
		"heavy_damage": 22,
		"heavy_knockback": 440.0,
		"heavy_windup": 0.14,
		"heavy_active": 0.10,
		"heavy_recovery": 0.30,
		"heavy_hitbox_size": Vector2(72, 60),
		"heavy_hitbox_offset": 50.0,
		"heavy_self_dash": 1100.0,
		"max_block": 70.0,
		"block_regen": 35.0,
		"dodge_duration": 0.18,
		"dodge_cooldown": 0.5,
		"dodge_distance": 200.0,
		"dodge_block_cost": 25.0,
		"special_type": "dash_claw",
		"special_damage": 20,
		"special_knockback": 350.0,
		"special_windup": 0.10,
		"special_active": 0.10,
		"special_recovery": 0.30,
		"special_hitbox_size": Vector2(64, 52),
		"special_hitbox_offset": 48.0,
		"special_self_dash": 950.0,
		"special_cooldown": 3.5,
	},
	"bronto": {
		"display_name": "BRONTO",
		"weapons": ["fists", "hammer"],
		"dino_color": Color(0.45, 0.55, 0.85, 1.0),
		"sprite_role": "bronto",
		"sprite_scale": 3.2,
		"sprite_offset_y": -16.0,
		"hit_sfx_name": "hit_chomp",
		"max_speed": 250.0,
		"ground_accel": 1700.0,
		"ground_friction": 2500.0,
		"ice_accel": 340.0,
		"ice_friction": 110.0,
		"max_hp": 165,
		"attack_damage": 20,
		"attack_knockback": 360.0,
		"attack_windup": 0.18,
		"attack_active": 0.12,
		"attack_recovery": 0.34,
		"attack_hitbox_size": Vector2(82, 56),
		"attack_hitbox_offset": 58.0,
		"heavy_damage": 36,
		"heavy_knockback": 600.0,
		"heavy_windup": 0.34,
		"heavy_active": 0.18,
		"heavy_recovery": 0.55,
		"heavy_hitbox_size": Vector2(96, 72),
		"heavy_hitbox_offset": 60.0,
		"heavy_self_dash": 0.0,
		"max_block": 110.0,
		"block_regen": 24.0,
		"dodge_duration": 0.22,
		"dodge_cooldown": 0.75,
		"dodge_distance": 120.0,
		"dodge_block_cost": 38.0,
		"special_type": "neck_whip",
		"special_damage": 28,
		"special_knockback": 520.0,
		"special_windup": 0.30,
		"special_active": 0.16,
		"special_recovery": 0.52,
		"special_hitbox_size": Vector2(120, 64),
		"special_hitbox_offset": 72.0,
		"special_cooldown": 5.0,
	},
	"anky": {
		"display_name": "ANKY",
		"weapons": ["fists", "axe"],
		"dino_color": Color(0.55, 0.5, 0.4, 1.0),
		"sprite_role": "anky",
		"sprite_scale": 2.6,
		"sprite_offset_y": -16.0,
		"hit_sfx_name": "hit_chomp",
		"max_speed": 260.0,
		"ground_accel": 2000.0,
		"ground_friction": 3000.0,
		"ice_accel": 400.0,
		"ice_friction": 120.0,
		"max_hp": 155,
		"attack_damage": 18,
		"attack_knockback": 320.0,
		"attack_windup": 0.17,
		"attack_active": 0.12,
		"attack_recovery": 0.32,
		"attack_hitbox_size": Vector2(74, 60),
		"attack_hitbox_offset": 50.0,
		"heavy_damage": 34,
		"heavy_knockback": 560.0,
		"heavy_windup": 0.32,
		"heavy_active": 0.16,
		"heavy_recovery": 0.52,
		"heavy_hitbox_size": Vector2(88, 74),
		"heavy_hitbox_offset": 54.0,
		"heavy_self_dash": 0.0,
		"max_block": 120.0,
		"block_regen": 26.0,
		"dodge_duration": 0.20,
		"dodge_cooldown": 0.7,
		"dodge_distance": 120.0,
		"dodge_block_cost": 36.0,
		"special_type": "tail_smash",
		"special_damage": 26,
		"special_knockback": 640.0,
		"special_windup": 0.26,
		"special_active": 0.16,
		"special_recovery": 0.50,
		"special_hitbox_size": Vector2(100, 80),
		"special_hitbox_offset": 44.0,
		"special_cooldown": 4.5,
	},
}

# Iciest Age removed from the roster 2026-05-22: the Frozen Floes redesign was
# flat-vector and clashed with the pixel-art islands. arena_floes.tscn + the
# floe/drown code stay in the repo (unreferenced) in case it's reskinned later.
const ISLAND_ORDER := ["laughing_lava", "beauty_beach", "sunny_springs", "white_water_falls", "purple_fields"]

const ISLAND_NAMES := {
	"laughing_lava": "LAUGHING LAVA",
	"beauty_beach": "BEAUTY BEACH",
	"sunny_springs": "SUNNY SPRINGS",
	"white_water_falls": "WHITE WATER FALLS",
	"purple_fields": "PURPLE FIELDS",
}

const ISLAND_SCENES := {
	"laughing_lava": "res://scenes/arena_lava.tscn",
	"beauty_beach": "res://scenes/arena_beach.tscn",
	"sunny_springs": "res://scenes/arena_springs.tscn",
	"white_water_falls": "res://scenes/arena_falls.tscn",
	"purple_fields": "res://scenes/arena_purple.tscn",
}

var dino_choices: Dictionary = {"p1": "trex", "p2": "raptor", "p3": "trike", "p4": "pterry"}
var island: String = "laughing_lava"
var player_count: int = 2
## Which slots are CPU-controlled this match. Set on the select screen.
var cpu_players: Dictionary = {"p1": false, "p2": false, "p3": false, "p4": false}
## pid -> chosen weapon id; the in-match loadout becomes ["fists", choice].
## Absent (e.g. CPU slots) -> the dino's default loadout from DINOS.weapons.
var weapon_choices: Dictionary = {}

func _ready() -> void:
	_setup_input_actions()

func _setup_input_actions() -> void:
	var p1_keys := {
		"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D,
		"attack": KEY_F, "heavy": KEY_H, "special": KEY_B, "swap": KEY_V, "block": KEY_T, "dodge": KEY_G,
		"pickup": KEY_Q, "throw": KEY_E,
		"confirm": KEY_F,
	}
	var p2_keys := {
		"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT,
		"attack": KEY_PERIOD, "heavy": KEY_M, "special": KEY_L, "swap": KEY_SEMICOLON, "block": KEY_COMMA, "dodge": KEY_SLASH,
		"pickup": KEY_O, "throw": KEY_P,
		"confirm": KEY_PERIOD,
	}
	_register_player_actions("p1", 0, p1_keys)
	_register_player_actions("p2", 1, p2_keys)
	_register_player_actions("p3", 2, {})
	_register_player_actions("p4", 3, {})
	_register_restart_action()
	_register_pause_action()

func _register_pause_action() -> void:
	if InputMap.has_action("pause"):
		InputMap.action_erase_events("pause")
	else:
		InputMap.add_action("pause")
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_ESCAPE
	InputMap.action_add_event("pause", key_event)
	for device in [0, 1, 2, 3]:
		var btn := InputEventJoypadButton.new()
		btn.device = device
		btn.button_index = JOY_BUTTON_START
		InputMap.action_add_event("pause", btn)

func _register_restart_action() -> void:
	if InputMap.has_action("restart"):
		InputMap.action_erase_events("restart")
	else:
		InputMap.add_action("restart")
	for keycode in [KEY_R, KEY_ENTER]:
		var key_event := InputEventKey.new()
		key_event.keycode = keycode
		InputMap.action_add_event("restart", key_event)
	for device in [0, 1]:
		var btn := InputEventJoypadButton.new()
		btn.device = device
		btn.button_index = JOY_BUTTON_START
		InputMap.action_add_event("restart", btn)

func _register_player_actions(prefix: String, device: int, keys: Dictionary) -> void:
	var joy_dpad := {
		"up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN,
		"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT,
	}
	var joy_axes := {
		"up":    [JOY_AXIS_LEFT_Y, -1.0],
		"down":  [JOY_AXIS_LEFT_Y,  1.0],
		"left":  [JOY_AXIS_LEFT_X, -1.0],
		"right": [JOY_AXIS_LEFT_X,  1.0],
	}
	var joy_buttons := {
		"attack":  JOY_BUTTON_X,
		"heavy":   JOY_BUTTON_B,
		"special": JOY_BUTTON_LEFT_SHOULDER,
		"swap":    JOY_BUTTON_Y,
		"block":   JOY_BUTTON_RIGHT_SHOULDER,
		"dodge":   JOY_BUTTON_A,
		"confirm": JOY_BUTTON_A,
	}
	# Analog triggers (LT/RT) rest at 0 and climb to 1 when squeezed, so they're
	# bound as positive-axis motions rather than buttons.
	var joy_triggers := {
		"pickup": JOY_AXIS_TRIGGER_LEFT,
		"throw":  JOY_AXIS_TRIGGER_RIGHT,
	}
	for action_name in ACTION_NAMES:
		var full := "%s_%s" % [prefix, action_name]
		if InputMap.has_action(full):
			InputMap.action_erase_events(full)
		else:
			InputMap.add_action(full, 0.3)
		InputMap.action_set_deadzone(full, 0.3)
		if action_name in keys:
			var key_event := InputEventKey.new()
			key_event.keycode = keys[action_name]
			InputMap.action_add_event(full, key_event)
		if action_name in joy_dpad:
			var btn := InputEventJoypadButton.new()
			btn.device = device
			btn.button_index = joy_dpad[action_name]
			InputMap.action_add_event(full, btn)
		if action_name in joy_axes:
			var motion := InputEventJoypadMotion.new()
			motion.device = device
			motion.axis = joy_axes[action_name][0]
			motion.axis_value = joy_axes[action_name][1]
			InputMap.action_add_event(full, motion)
		if action_name in joy_buttons:
			var btn := InputEventJoypadButton.new()
			btn.device = device
			btn.button_index = joy_buttons[action_name]
			InputMap.action_add_event(full, btn)
		if action_name in joy_triggers:
			var trigger := InputEventJoypadMotion.new()
			trigger.device = device
			trigger.axis = joy_triggers[action_name]
			trigger.axis_value = 1.0
			InputMap.action_add_event(full, trigger)

# Held-weapon silhouettes (point along +X). The dino rotates these to its facing
# while held; weapon_item.gd reuses them for the thrown/dropped weapon so a sword
# on the ground reads as the same sword you were carrying. Empty poly = fists.
func weapon_shape(id: String) -> Dictionary:
	match id:
		"sword":
			return {"poly": PackedVector2Array([Vector2(-3, -2), Vector2(-3, 2), Vector2(28, 2.5), Vector2(38, 0), Vector2(28, -2.5)]), "color": Color(0.85, 0.88, 0.95)}
		"dagger":
			return {"poly": PackedVector2Array([Vector2(-3, -2), Vector2(-3, 2), Vector2(15, 2), Vector2(22, 0), Vector2(15, -2)]), "color": Color(0.8, 0.82, 0.88)}
		"axe":
			return {"poly": PackedVector2Array([Vector2(0, -2), Vector2(20, -2), Vector2(20, -13), Vector2(34, -5), Vector2(34, 5), Vector2(20, 13), Vector2(20, 2), Vector2(0, 2)]), "color": Color(0.72, 0.74, 0.8)}
		"mace":
			return {"poly": PackedVector2Array([Vector2(0, -2), Vector2(20, -2), Vector2(20, -9), Vector2(35, -9), Vector2(35, 9), Vector2(20, 9), Vector2(20, 2), Vector2(0, 2)]), "color": Color(0.5, 0.5, 0.56)}
		"hammer":
			return {"poly": PackedVector2Array([Vector2(0, -3), Vector2(22, -3), Vector2(22, -14), Vector2(42, -14), Vector2(42, 14), Vector2(22, 14), Vector2(22, 3), Vector2(0, 3)]), "color": Color(0.55, 0.55, 0.6)}
		"nunchucks":
			return {"poly": PackedVector2Array([Vector2(0, -2.5), Vector2(26, -2.5), Vector2(26, 2.5), Vector2(0, 2.5)]), "color": Color(0.45, 0.32, 0.2)}
		_:
			return {"poly": PackedVector2Array(), "color": Color.WHITE}  # fists: no held item
