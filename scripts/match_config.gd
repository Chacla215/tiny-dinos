extends Node

const ROSTER_ORDER := ["trex", "raptor", "trike", "pterry", "bronto", "anky", "ralph"]

# ---- Cosmetic skins (shared across every dino) -------------------------------
# A skin is a live recolor of the fighter via assets/shaders/skin_recolor.gdshader
# (no per-skin art needed in-match). DEFAULT (index 0) is the un-recolored fighter.
# `swatch` is the carousel fallback colour; hue/sat/val drive the shader. The
# painterly creator portrait uses assets/concept/<dino>/<dino>_<name>.png when it
# exists, else the recoloured base hero. Persisted per dino in MetaSave.
const SKIN_SHADER := preload("res://assets/shaders/skin_recolor.gdshader")
const SKINS := [
	{"name": "DEFAULT", "rarity": "COMMON", "swatch": Color("9aa3b4"), "recolor": false},
	{"name": "CRYSTAL", "rarity": "RARE",   "swatch": Color("8fd6e8"), "hue": 0.50, "sat": 0.88, "val": 1.14},
	{"name": "VOLCANO", "rarity": "RARE",   "swatch": Color("e0622a"), "hue": 0.015, "sat": 1.35, "val": 0.66},
	{"name": "FROZEN",  "rarity": "RARE",   "swatch": Color("bcd8ec"), "hue": 0.55, "sat": 0.45, "val": 1.15},
	{"name": "SPRING",  "rarity": "RARE",   "swatch": Color("a9d98c"), "hue": 0.27, "sat": 0.85, "val": 1.06},
	{"name": "VOID",    "rarity": "EPIC",   "swatch": Color("8a5cc8"), "hue": 0.75, "sat": 0.85, "val": 0.90},
	{"name": "GOLDEN",  "rarity": "EPIC",   "swatch": Color("e6c860"), "hue": 0.12, "sat": 1.00, "val": 1.12},
]

# A ShaderMaterial configured for skin `idx`, or null for DEFAULT / out-of-range
# (so callers can do `node.material = MatchConfig.skin_material(idx)` uniformly).
func skin_material(idx: int) -> ShaderMaterial:
	if idx <= 0 or idx >= SKINS.size():
		return null
	var s: Dictionary = SKINS[idx]
	if not s.get("recolor", true):
		return null
	var m := ShaderMaterial.new()
	m.shader = SKIN_SHADER
	m.set_shader_parameter("target_hue", float(s.get("hue", 0.0)))
	m.set_shader_parameter("sat_mul", float(s.get("sat", 1.0)))
	m.set_shader_parameter("val_mul", float(s.get("val", 1.0)))
	m.set_shader_parameter("strength", 1.0)
	return m

const PLAYER_COLORS := {
	"p1": Color(1.00, 0.88, 0.30, 1.0),
	"p2": Color(0.30, 0.80, 1.00, 1.0),
	"p3": Color(0.95, 0.45, 0.85, 1.0),
	"p4": Color(0.45, 0.95, 0.45, 1.0),
}

const PLAYER_IDS := ["p1", "p2", "p3", "p4"]
const ACTION_NAMES := ["up", "down", "left", "right", "attack", "heavy", "special", "swap", "block", "dodge", "pickup", "throw", "confirm", "emote"]

# Quick taunt emotes. Tapping Select in a match pops the next one over your dino.
# `text` is the art-free bubble shown today; a painterly pose can swap in later.
const EMOTES := [
	{"name": "WAVE",     "text": "HI!"},
	{"name": "EXCITED",  "text": "YEAH!"},
	{"name": "CONFUSED", "text": "HUH?"},
	{"name": "LOVE",     "text": "<3"},
	{"name": "ROAR",     "text": "ROAR!"},
	{"name": "SLEEPY",   "text": "ZZZ"},
	{"name": "DIZZY",    "text": "@_@"},
	{"name": "PROUD",    "text": "TA-DA!"},
]

const PLAYER_TINTS := {
	"p1": Color(1.30, 1.20, 0.50),
	"p2": Color(0.50, 1.10, 1.30),
	"p3": Color(1.30, 0.60, 1.20),
	"p4": Color(0.60, 1.20, 0.60),
}

# Weapons modify light + heavy attacks (not the signature special). RB swaps the
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
		"sprite_scale": 0.70,
		"sprite_offset_y": -39.0,
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
		"sprite_scale": 0.64,
		"sprite_offset_y": -35.0,
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
		"sprite_scale": 0.55,
		"sprite_offset_y": -29.0,
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
		"sprite_scale": 0.52,
		"sprite_offset_y": -27.0,
		"hit_sfx_name": "hit_claw",
		"max_speed": 440.0,
		"ground_accel": 5000.0,
		"ground_friction": 5000.0,
		"ice_accel": 1100.0,
		"ice_friction": 380.0,
		"max_hp": 100,
		"attack_damage": 15,
		"attack_knockback": 200.0,
		"attack_windup": 0.06,
		"attack_active": 0.08,
		"attack_recovery": 0.18,
		"attack_hitbox_size": Vector2(56, 48),
		"attack_hitbox_offset": 44.0,
		"heavy_damage": 26,
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
		"special_damage": 25,
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
		"sprite_scale": 0.72,
		"sprite_offset_y": -40.0,
		"hit_sfx_name": "hit_chomp",
		"max_speed": 250.0,
		"ground_accel": 1700.0,
		"ground_friction": 2500.0,
		"ice_accel": 340.0,
		"ice_friction": 110.0,
		"max_hp": 158,
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
		"sprite_scale": 0.63,
		"sprite_offset_y": -34.0,
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
	# Ralph the mascot — a scrappy medium bruiser whose niche is the AoE signature
	# "Tiny Meteor Stomp" (reuses the radial screech shockwave). Stats track the
	# character-screen flavor: HP 120, ATK 28 ((19+37)/2), DEF 20 (block 120/6).
	"ralph": {
		"display_name": "RALPH",
		"weapons": ["fists", "hammer"],
		"dino_color": Color(0.5, 0.82, 0.52, 1.0),
		"sprite_role": "ralph",
		"sprite_scale": 0.6,
		"sprite_offset_y": -32.0,
		"hit_sfx_name": "hit_chomp",
		"max_speed": 250.0,
		"ground_accel": 2200.0,
		"ground_friction": 3200.0,
		"ice_accel": 450.0,
		"ice_friction": 130.0,
		"max_hp": 120,
		"attack_damage": 19,
		"attack_knockback": 380.0,
		"attack_windup": 0.18,
		"attack_active": 0.12,
		"attack_recovery": 0.34,
		"attack_hitbox_size": Vector2(72, 62),
		"attack_hitbox_offset": 52.0,
		"heavy_damage": 37,
		"heavy_knockback": 600.0,
		"heavy_windup": 0.32,
		"heavy_active": 0.17,
		"heavy_recovery": 0.55,
		"heavy_hitbox_size": Vector2(92, 76),
		"heavy_hitbox_offset": 58.0,
		"heavy_self_dash": 0.0,
		"max_block": 120.0,
		"block_regen": 26.0,
		"dodge_duration": 0.20,
		"dodge_cooldown": 0.65,
		"dodge_distance": 130.0,
		"dodge_block_cost": 34.0,
		"special_type": "stomp",
		"special_damage": 16,
		"special_knockback": 520.0,
		"special_windup": 0.30,
		"special_active": 0.10,
		"special_recovery": 0.55,
		"special_radius": 210.0,
		"special_slow_duration": 1.0,
		"special_cooldown": 8.0,
	},
}

# Iciest Age (Frozen Floes) re-added to the roster 2026-05-24. It was cut on
# 2026-05-22 only because its flat-vector art clashed with the pixel-art islands;
# with every island moving to the new pixel-art look that conflict is gone. Its
# unique mechanic (drown_off_floes) lives in arena_floes.tscn. The lush pixel-art
# background is still pending -- the procedural floe art is a placeholder for now.
const ISLAND_ORDER := ["laughing_lava", "beauty_beach", "sunny_springs", "white_water_falls", "purple_fields", "iciest_age"]

const ISLAND_NAMES := {
	"laughing_lava": "LAUGHING LAVA",
	"beauty_beach": "BEAUTY BEACH",
	"sunny_springs": "SUNNY SPRINGS",
	"white_water_falls": "WHITE WATER FALLS",
	"purple_fields": "PURPLE FIELDS",
	"iciest_age": "ICIEST AGE",
}

const ISLAND_SCENES := {
	"laughing_lava": "res://scenes/arena_lava.tscn",
	"beauty_beach": "res://scenes/arena_beach.tscn",
	"sunny_springs": "res://scenes/arena_springs.tscn",
	"white_water_falls": "res://scenes/arena_falls.tscn",
	"purple_fields": "res://scenes/arena_purple.tscn",
	"iciest_age": "res://scenes/arena_floes.tscn",
}

# --- Game modes ---
# The match flow main.gd runs. ROUNDS is the classic best-of (a KO wins a round,
# first to kos_to_win rounds). STOCK = each fighter has STOCK_LIVES; a KO costs a
# life; last dino standing wins. KOTH = stand in the hill to bank time; first to
# KOTH_TARGET seconds wins (KOs just respawn). EGGS = grab loose eggs off the
# field; first to EGG_TARGET wins (KOs just respawn). All four reuse the one
# arena + the procedural hill/egg props, so every island plays every mode.
# Curated set of 6 (2026-06-10): 2 fight formats + zone control + 2 party +
# survival, each mechanically distinct. EGG GRAB (redundant with KOTH) and THE
# BEAST (high-maintenance, swingy) were retired from the menu; their main.gd
# logic stays dormant/unreachable (game_mode can never select them) so it can be
# revived without re-deriving it.
const MODE_ORDER := ["rounds", "stock", "koth", "sumo", "bombtag", "flood"]
const MODE_NAMES := {
	"rounds": "BEST OF ROUNDS",
	"stock": "LAST DINO STANDING",
	"koth": "KING OF THE HILL",
	"eggs": "EGG GRAB",
	"sumo": "SUMO",
	"bombtag": "BOMB TAG",
	"beast": "THE BEAST",
	"flood": "RISING TIDE",
}
# Concrete win conditions (with the actual targets) so the select screen reads
# as rules, not vibes. {n} tokens are filled from the tuning consts in _blurb().
const MODE_BLURBS := {
	"rounds": "FIRST TO {rounds} ROUNDS  -  A KO TAKES THE ROUND",
	"stock": "{lives} LIVES EACH  -  LAST DINO STANDING",
	"koth": "HOLD THE HILL  -  FIRST TO {koth}s  -  KOs RESPAWN",
	"eggs": "GRAB EGGS  -  FIRST TO {eggs}  -  KOs RESPAWN",
	"sumo": "NO HP  -  SHOVE THEM OFF  -  FIRST TO {sumo} RING-OUTS",
	"bombtag": "PASS THE BOMB OR BOOM  -  SURVIVE TO WIN",
	"beast": "BE THE CROWNED BEAST  -  FIRST TO {beast}s",
	"flood": "THE TIDE RISES  -  LAST DINO ON DRY LAND WINS",
}
var game_mode: String = "rounds"
const STOCK_LIVES := 3        # lives each fighter starts with in LAST DINO STANDING
const KOTH_TARGET := 20.0     # seconds of hill control needed to win KING OF THE HILL
const EGG_TARGET := 6         # eggs to collect to win EGG GRAB
const SUMO_TARGET := 5        # ring-outs to win SUMO (HP off; only knockback scores)
const BOMB_FUSE := 6.0        # BOMB TAG: seconds before the bomb detonates on its holder
const BOMB_PASS_LOCK := 0.5   # grace after catching the bomb before it can pass again
const BEAST_TARGET := 25.0    # THE BEAST: seconds spent crowned needed to win
const FLOOD_DURATION := 28.0  # RISING TIDE: seconds for the safe zone to fully close in
const FLOOD_MIN := 0.15       # smallest the safe zone shrinks to (a final-showdown platform)
const ROUNDS_TO_WIN := 3      # BEST OF ROUNDS: round wins needed (standard versus default)

# Win-condition blurb for `mode` with its real targets filled in (see MODE_BLURBS).
func mode_blurb(mode: String) -> String:
	return String(MODE_BLURBS.get(mode, "")).format({
		"rounds": ROUNDS_TO_WIN,
		"lives": STOCK_LIVES,
		"koth": int(KOTH_TARGET),
		"eggs": EGG_TARGET,
		"sumo": SUMO_TARGET,
		"beast": int(BEAST_TARGET),
	})

var dino_choices: Dictionary = {"p1": "trex", "p2": "raptor", "p3": "trike", "p4": "pterry"}
var island: String = "laughing_lava"
var player_count: int = 2
## Which slots are CPU-controlled this match. Set on the select screen.
var cpu_players: Dictionary = {"p1": false, "p2": false, "p3": false, "p4": false}
## pid -> chosen weapon id; the in-match loadout becomes ["fists", choice].
## Absent (e.g. CPU slots) -> the dino's default loadout from DINOS.weapons.
var weapon_choices: Dictionary = {}

# --- Teams ---
# When enabled, scoring/win conditions aggregate by side and friendly fire is off.
# `teams` maps pid -> "a"/"b"; the select screen sets it from a split preset (2v2,
# 1v2, 1v3). Disabled = every fighter is its own side (free-for-all, the default).
var teams_enabled: bool = false
var teams: Dictionary = {"p1": "a", "p2": "b", "p3": "a", "p4": "b"}
const TEAM_NAMES := {"a": "RED", "b": "BLUE"}
const TEAM_COLORS := {"a": Color(0.95, 0.4, 0.4), "b": Color(0.4, 0.65, 1.0)}

# The "side" a fighter scores for: its team when teams are on, else itself.
func side_of(pid: String) -> String:
	return teams.get(pid, pid) if teams_enabled else pid

func same_side(a: String, b: String) -> bool:
	return teams_enabled and teams.get(a, a) == teams.get(b, b)
## Difficulty applied to every CPU this match (chosen on the select screen).
## Maps to a knob preset in dino_ai.gd via apply_difficulty().
const CPU_DIFFICULTY_ORDER := ["easy", "normal", "hard"]
const CPU_DIFFICULTY_NAMES := {"easy": "EASY", "normal": "NORMAL", "hard": "HARD"}
var cpu_difficulty: String = "normal"

# --- Arcade ladder (solo spine) ---
# A single-player gauntlet: P1 fights a rising sequence of CPU foes, each on its
# own island, ending on a HARD final boss. The commercial hook — something a lone
# player can pick up, stream, and demo. main.gd drives the between-rung flow;
# this just holds the ladder and reconfigures the match for each rung.
var arcade_setup: bool = false       # title -> select handoff: configure a solo ladder
var arcade: bool = false
var arcade_rung: int = 0
var arcade_ladder: Array = []        # [{foes: [dino,...], difficulty, island}]
var arcade_player_dino: String = "trex"
var arcade_player_weapon: String = "hammer"
var arcade_duo: bool = false         # co-op: P1 + a CPU ally climb as a 2-fighter team
var arcade_ally_dino: String = "raptor"
const ARCADE_DIFFS := ["easy", "easy", "normal", "normal", "hard"]

func start_arcade(player_dino: String, player_weapon: String, start_island: String = "", duo: bool = false) -> void:
	arcade = true
	arcade_duo = duo
	teams_enabled = duo
	arcade_rung = 0
	arcade_player_dino = player_dino
	arcade_player_weapon = player_weapon
	if duo:
		# A partner different from the player, fixed for the whole run.
		var pool: Array = ROSTER_ORDER.filter(func(d): return d != player_dino)
		pool.shuffle()
		arcade_ally_dino = pool[0] if not pool.is_empty() else player_dino
	arcade_ladder = _build_ladder(player_dino, start_island)
	_apply_arcade_rung()

# The ladder is every OTHER dino, difficulty ramping easy->hard, each on a
# different island for variety. The last rung is always the toughest on HARD.
# start_island rotates the island sequence so rung 1 opens on the chosen island.
# In duo each rung fields TWO foes (you + ally vs two), drawn from the pool.
func _build_ladder(player_dino: String, start_island: String = "") -> Array:
	var foes: Array = []
	for d in ROSTER_ORDER:
		if d != player_dino and (not arcade_duo or d != arcade_ally_dino):
			foes.append(d)
	var offset: int = max(0, ISLAND_ORDER.find(start_island))
	var ladder: Array = []
	var n: int = foes.size()
	for i in range(n):
		var rung_foes: Array = [foes[i]]
		if arcade_duo:
			rung_foes.append(foes[(i + 1) % n])  # a second foe so it's a 2-v-2
		ladder.append({
			"foes": rung_foes,
			"difficulty": ARCADE_DIFFS[min(i, ARCADE_DIFFS.size() - 1)],
			"island": ISLAND_ORDER[(offset + i) % ISLAND_ORDER.size()],
		})
	if not ladder.is_empty():
		ladder[ladder.size() - 1]["difficulty"] = "hard"  # final boss
	return ladder

func _apply_arcade_rung() -> void:
	var rung: Dictionary = arcade_ladder[arcade_rung]
	var foes: Array = rung["foes"]
	weapon_choices = {"p1": arcade_player_weapon}
	cpu_difficulty = rung["difficulty"]
	island = rung["island"]
	game_mode = "rounds"
	dino_choices["p1"] = arcade_player_dino
	if arcade_duo:
		player_count = 4
		teams_enabled = true
		teams = {"p1": "a", "p3": "a", "p2": "b", "p4": "b"}
		cpu_players = {"p1": false, "p3": true, "p2": true, "p4": true}
		dino_choices["p3"] = arcade_ally_dino
		dino_choices["p2"] = foes[0]
		dino_choices["p4"] = foes[1] if foes.size() > 1 else foes[0]
	else:
		player_count = 2
		teams_enabled = false
		cpu_players = {"p1": false, "p2": true, "p3": false, "p4": false}
		dino_choices["p2"] = foes[0]

# Advance to the next rung. Returns false when the ladder is cleared (champion).
func arcade_advance() -> bool:
	arcade_rung += 1
	if arcade_rung >= arcade_ladder.size():
		return false
	_apply_arcade_rung()
	return true

func arcade_scene() -> String:
	return ISLAND_SCENES.get(island, "res://scenes/main.tscn")

func arcade_is_final() -> bool:
	return arcade_rung >= arcade_ladder.size() - 1

# --- Roguelike gauntlet (solo spine v2) ---
# An endless, escalating run: win a wave, draft one of three upgrades that stack
# for the rest of the run, fight a tougher foe, repeat until you lose (permadeath).
# Upgrades are pure data (stat -> ["mul"|"add", value]); dino.gd applies them on
# spawn to the player only. Enemies scale via gauntlet_enemy_*_mult per wave.
var gauntlet_setup: bool = false     # title -> select handoff
var gauntlet: bool = false
var gauntlet_wave: int = 0           # 0-indexed; displayed as wave+1
var gauntlet_upgrades: Array = []    # upgrade ids picked this run (may repeat)
var gauntlet_player_dino: String = "trex"
var gauntlet_player_weapon: String = "hammer"
var gauntlet_player_hp: int = -1     # HP carried into the next wave; -1 = spawn at full
var gauntlet_start_island: String = ""  # solo-setup pick for wave 1; "" = random
# Persistent meta perks snapshotted from MetaSave at run start (see meta_save.gd).
var gauntlet_meta_hp_bonus: int = 0  # HARDENED: flat starting max-HP bonus
var gauntlet_extra_draft: bool = false  # EXTRA DRAFT: offer 4 upgrade cards, not 3

const UPGRADES := {
	"sharp_claws":  {"name": "SHARP CLAWS",  "desc": "+25% ATTACK DAMAGE",      "mods": {"attack_damage": ["mul", 1.25], "heavy_damage": ["mul", 1.25], "special_damage": ["mul", 1.25]}},
	"thick_hide":   {"name": "THICK HIDE",   "desc": "+35 MAX HP",              "mods": {"max_hp": ["add", 35]}},
	"adrenaline":   {"name": "ADRENALINE",   "desc": "+15% MOVE SPEED",         "mods": {"max_speed": ["mul", 1.15]}},
	"heavy_hitter": {"name": "HEAVY HITTER", "desc": "+30% KNOCKBACK",          "mods": {"attack_knockback": ["mul", 1.3], "heavy_knockback": ["mul", 1.3], "special_knockback": ["mul", 1.3]}},
	"quick_inst":   {"name": "QUICK INSTINCT","desc": "-30% SPECIAL COOLDOWN",  "mods": {"special_cooldown": ["mul", 0.7]}},
	"iron_guard":   {"name": "IRON GUARD",   "desc": "+40 MAX BLOCK",           "mods": {"max_block": ["add", 40]}},
	"nimble":       {"name": "NIMBLE",       "desc": "-25% DODGE COOLDOWN/COST","mods": {"dodge_cooldown": ["mul", 0.75], "dodge_block_cost": ["mul", 0.75]}},
	"light_feet":   {"name": "LIGHT FEET",   "desc": "+30% DODGE DISTANCE",     "mods": {"dodge_distance": ["mul", 1.3]}},
	"fast_hands":   {"name": "FAST HANDS",   "desc": "-20% ATTACK WINDUP",      "mods": {"attack_windup": ["mul", 0.8], "heavy_windup": ["mul", 0.8]}},
	"berserker":    {"name": "BERSERKER",    "desc": "+35% DMG, -15% MAX HP",   "mods": {"attack_damage": ["mul", 1.35], "heavy_damage": ["mul", 1.35], "special_damage": ["mul", 1.35], "max_hp": ["mul", 0.85]}},
	"tough_skin":   {"name": "TOUGH SKIN",   "desc": "+60% BLOCK REGEN",        "mods": {"block_regen": ["mul", 1.6]}},
	"bulwark":      {"name": "BULWARK",      "desc": "+25 HP, +20 BLOCK",       "mods": {"max_hp": ["add", 25], "max_block": ["add", 20]}},
	# Mechanic upgrades — these change how combat plays, not just a stat. "effect"
	# keys map to run_* flags dino.gd reads in try_hit / take_damage (player only).
	"vampire":      {"name": "VAMPIRE",      "desc": "HEAL 18% OF MELEE DAMAGE DEALT",      "effect": {"lifesteal": 0.18}},
	"spiked_hide":  {"name": "SPIKED HIDE",  "desc": "REFLECT 30% OF DAMAGE TAKEN",         "effect": {"thorns": 0.30}},
	"executioner":  {"name": "EXECUTIONER",  "desc": "+60% DAMAGE TO FOES BELOW 35% HP",    "effect": {"execute": 0.60}},
	# Heal upgrades — meaningful only because HP now carries between waves.
	# "heal_now" restores a fraction of max HP the instant it's drafted; "wave_heal"
	# adds to the breather healed at the start of every future wave (stacks).
	"field_medic":  {"name": "FIELD MEDIC",  "desc": "HEAL 50% OF MAX HP NOW",              "heal_now": 0.5},
	"second_wind":  {"name": "SECOND WIND",  "desc": "+20% MAX HP HEALED EACH WAVE",        "wave_heal": 0.2},
}

# HP carried from the won wave; healed by this fraction of max HP each new wave so
# attrition stings without dooming a low-HP survivor. SECOND WIND adds on top.
const GAUNTLET_WAVE_HEAL := 0.20

func start_gauntlet(player_dino: String, player_weapon: String, start_island: String = "") -> void:
	gauntlet = true
	teams_enabled = false  # solo run is always 1-v-1
	gauntlet_wave = 0
	gauntlet_upgrades = []
	gauntlet_player_dino = player_dino
	gauntlet_player_weapon = player_weapon
	gauntlet_player_hp = -1
	gauntlet_start_island = start_island
	# Snapshot the cross-run meta perks unlocked so far.
	gauntlet_meta_hp_bonus = MetaSave.hp_bonus()
	gauntlet_extra_draft = MetaSave.has_unlock("extra_draft")
	if MetaSave.has_unlock("veteran_start"):
		var pool: Array = UPGRADES.keys()
		pool.shuffle()
		gauntlet_upgrades.append(pool[0])  # VETERAN START: begin with one upgrade
	_apply_gauntlet_wave()

# Each wave: a random foe (mirror matches allowed) on a random island, difficulty
# ramping easy -> normal -> hard then holding at hard while enemies keep scaling.
func _apply_gauntlet_wave() -> void:
	player_count = 2
	cpu_players = {"p1": false, "p2": true, "p3": false, "p4": false}
	dino_choices["p1"] = gauntlet_player_dino
	dino_choices["p2"] = ROSTER_ORDER[randi() % ROSTER_ORDER.size()]
	weapon_choices = {"p1": gauntlet_player_weapon}
	if gauntlet_wave < 2:
		cpu_difficulty = "easy"
	elif gauntlet_wave < 5:
		cpu_difficulty = "normal"
	else:
		cpu_difficulty = "hard"
	# Wave 1 uses the island chosen in solo setup (if any); the rest stay random.
	if gauntlet_wave == 0 and gauntlet_start_island != "":
		island = gauntlet_start_island
	else:
		island = ISLAND_ORDER[randi() % ISLAND_ORDER.size()]
	game_mode = "rounds"

func gauntlet_next_wave() -> void:
	gauntlet_wave += 1
	_apply_gauntlet_wave()

func gauntlet_add_upgrade(id: String) -> void:
	if not UPGRADES.has(id):
		return
	gauntlet_upgrades.append(id)
	# FIELD MEDIC and friends heal the carried HP the moment they're taken.
	var heal_now: float = UPGRADES[id].get("heal_now", 0.0)
	if heal_now > 0.0 and gauntlet_player_hp >= 0:
		var mx: int = gauntlet_player_max_hp()
		gauntlet_player_hp = min(mx, gauntlet_player_hp + int(round(mx * heal_now)))

# Player's max HP after every drafted max_hp mod — used for heal math + the draft
# HP readout, mirroring how dino.gd applies the same mods on spawn.
func gauntlet_player_max_hp() -> int:
	var hp: float = float(DINOS.get(gauntlet_player_dino, {}).get("max_hp", 100))
	for uid in gauntlet_upgrades:
		var mods: Dictionary = UPGRADES.get(uid, {}).get("mods", {})
		if mods.has("max_hp"):
			var op: Array = mods["max_hp"]
			hp = (hp * op[1]) if op[0] == "mul" else (hp + op[1])
	return int(round(hp)) + gauntlet_meta_hp_bonus

# Fraction of max HP healed at the start of a wave: baseline breather + SECOND WIND.
func gauntlet_wave_heal_frac() -> float:
	var frac: float = GAUNTLET_WAVE_HEAL
	for uid in gauntlet_upgrades:
		frac += UPGRADES.get(uid, {}).get("wave_heal", 0.0)
	return frac

# Distinct random upgrade ids to offer in the between-wave draft — 3 normally,
# 4 once the EXTRA DRAFT meta perk is unlocked.
func gauntlet_draft_options() -> Array:
	var pool: Array = UPGRADES.keys()
	pool.shuffle()
	return pool.slice(0, 4 if gauntlet_extra_draft else 3)

func gauntlet_scene() -> String:
	return ISLAND_SCENES.get(island, "res://scenes/main.tscn")

# Early waves are best-of-2 (a buffer while you're under-powered); from wave 4 on
# they tighten to a single decisive KO so the late run stays tense.
func gauntlet_kos_to_win() -> int:
	return 2 if gauntlet_wave < 3 else 1

# Endless enemy scaling so late waves stay threatening past the HARD difficulty cap.
func gauntlet_enemy_hp_mult() -> float:
	return 1.0 + 0.08 * float(gauntlet_wave)

func gauntlet_enemy_dmg_mult() -> float:
	return 1.0 + 0.04 * float(gauntlet_wave)

func _ready() -> void:
	_setup_input_actions()

func _setup_input_actions() -> void:
	# Gamepad-only: all four players drive the game from controllers. There are no
	# keyboard bindings — _register_player_actions wires pad buttons/axes only.
	_register_player_actions("p1", 0)
	_register_player_actions("p2", 1)
	_register_player_actions("p3", 2)
	_register_player_actions("p4", 3)
	_register_restart_action()
	_register_pause_action()

func _register_pause_action() -> void:
	if InputMap.has_action("pause"):
		InputMap.action_erase_events("pause")
	else:
		InputMap.add_action("pause")
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
	for device in [0, 1, 2, 3]:
		var btn := InputEventJoypadButton.new()
		btn.device = device
		btn.button_index = JOY_BUTTON_START
		InputMap.action_add_event("restart", btn)

func _register_player_actions(prefix: String, device: int) -> void:
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
		"swap":    JOY_BUTTON_RIGHT_SHOULDER,
		"block":   JOY_BUTTON_Y,
		"dodge":   JOY_BUTTON_A,
		"confirm": JOY_BUTTON_A,
		"emote":   JOY_BUTTON_BACK,
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
