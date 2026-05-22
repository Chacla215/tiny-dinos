extends Node

const ROSTER_ORDER := ["trex", "raptor", "trike", "pterry"]

const PLAYER_COLORS := {
	"p1": Color(1.00, 0.88, 0.30, 1.0),
	"p2": Color(0.30, 0.80, 1.00, 1.0),
	"p3": Color(0.95, 0.45, 0.85, 1.0),
	"p4": Color(0.45, 0.95, 0.45, 1.0),
}

const PLAYER_IDS := ["p1", "p2", "p3", "p4"]
const ACTION_NAMES := ["up", "down", "left", "right", "attack", "heavy", "block", "dodge", "confirm"]

const PLAYER_TINTS := {
	"p1": Color(1.30, 1.20, 0.50),
	"p2": Color(0.50, 1.10, 1.30),
	"p3": Color(1.30, 0.60, 1.20),
	"p4": Color(0.60, 1.20, 0.60),
}

const DINOS := {
	"trex": {
		"display_name": "T-REX",
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
		"attack_knockback": 520.0,
		"attack_windup": 0.22,
		"attack_active": 0.14,
		"attack_recovery": 0.40,
		"attack_hitbox_size": Vector2(80, 72),
		"attack_hitbox_offset": 60.0,
		"heavy_damage": 45,
		"heavy_knockback": 850.0,
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
	},
	"trike": {
		"display_name": "TRIKE",
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
		"heavy_attack_type": "projectile",
		"heavy_damage": 22,
		"heavy_knockback": 380.0,
		"heavy_windup": 0.35,
		"heavy_active": 0.05,
		"heavy_recovery": 0.55,
		"heavy_hitbox_size": Vector2(1, 1),
		"heavy_hitbox_offset": 0.0,
		"heavy_self_dash": 0.0,
		"projectile_speed": 700.0,
		"projectile_lifetime": 1.8,
		"projectile_color": Color(0.95, 0.85, 0.4, 1.0),
		"max_block": 95.0,
		"block_regen": 28.0,
		"dodge_duration": 0.20,
		"dodge_cooldown": 0.6,
		"dodge_distance": 150.0,
		"dodge_block_cost": 32.0,
	},
	"pterry": {
		"display_name": "PTERRY",
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
	},
	"raptor": {
		"display_name": "RAPTOR",
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
	},
}

const ISLAND_ORDER := ["iciest_age", "laughing_lava", "beauty_beach", "sunny_springs", "white_water_falls", "purple_fields"]

const ISLAND_NAMES := {
	"iciest_age": "ICIEST AGE",
	"laughing_lava": "LAUGHING LAVA",
	"beauty_beach": "BEAUTY BEACH",
	"sunny_springs": "SUNNY SPRINGS",
	"white_water_falls": "WHITE WATER FALLS",
	"purple_fields": "PURPLE FIELDS",
}

const ISLAND_SCENES := {
	"iciest_age": "res://scenes/main.tscn",
	"laughing_lava": "res://scenes/arena_lava.tscn",
	"beauty_beach": "res://scenes/arena_beach.tscn",
	"sunny_springs": "res://scenes/arena_springs.tscn",
	"white_water_falls": "res://scenes/arena_falls.tscn",
	"purple_fields": "res://scenes/arena_purple.tscn",
}

var dino_choices: Dictionary = {"p1": "trex", "p2": "raptor", "p3": "trike", "p4": "pterry"}
var island: String = "iciest_age"
var player_count: int = 2

func _ready() -> void:
	_setup_input_actions()

func _setup_input_actions() -> void:
	var p1_keys := {
		"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D,
		"attack": KEY_F, "heavy": KEY_V, "block": KEY_G, "dodge": KEY_SPACE,
		"confirm": KEY_F,
	}
	var p2_keys := {
		"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT,
		"attack": KEY_PERIOD, "heavy": KEY_M, "block": KEY_COMMA, "dodge": KEY_SLASH,
		"confirm": KEY_PERIOD,
	}
	_register_player_actions("p1", 0, p1_keys)
	_register_player_actions("p2", 1, p2_keys)
	_register_player_actions("p3", 2, {})
	_register_player_actions("p4", 3, {})
	_register_restart_action()

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
		"block":   JOY_BUTTON_RIGHT_SHOULDER,
		"dodge":   JOY_BUTTON_A,
		"confirm": JOY_BUTTON_A,
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
