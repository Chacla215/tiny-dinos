extends Node

const ROSTER_ORDER := ["ralph", "raptor", "trike", "pterry", "bronto", "anky"]

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
	# EPIC skins are bought in the SHOP with coins (MetaSave.owns_skin). Cosmetic only.
	{"name": "VOID",    "rarity": "EPIC",   "swatch": Color("8a5cc8"), "hue": 0.75, "sat": 0.85, "val": 0.90, "cost": 120},
	{"name": "GOLDEN",  "rarity": "EPIC",   "swatch": Color("e6c860"), "hue": 0.12, "sat": 1.00, "val": 1.12, "cost": 200},
	# Earned by winning a SEASON (MetaSave.champion_skin_unlocked). Gated via skin_unlocked().
	{"name": "CHAMPION", "rarity": "LEGENDARY", "swatch": Color("ffd84a"), "hue": 0.13, "sat": 1.15, "val": 1.28, "unlock": "champion"},
]

# Whether skin `idx` is available to equip. Free skins are always open; CHAMPION needs
# a season win; coin-priced ("cost") skins need a SHOP purchase. Cosmetic-only gate.
func skin_unlocked(idx: int) -> bool:
	if idx < 0 or idx >= SKINS.size():
		return false
	var s: Dictionary = SKINS[idx]
	var req: String = s.get("unlock", "")
	if req == "champion":
		return MetaSave.champion_skin_unlocked()
	if s.get("cost", 0) > 0:
		return MetaSave.owns_skin(idx)
	return true

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
	"p5": Color(1.00, 0.55, 0.30, 1.0),   # orange (3v3)
	"p6": Color(0.65, 0.55, 1.00, 1.0),   # violet (3v3)
}

const PLAYER_IDS := ["p1", "p2", "p3", "p4", "p5", "p6"]
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
	"p5": Color(1.30, 0.85, 0.55),
	"p6": Color(0.90, 0.80, 1.30),
}

# Weapons modify light + heavy attacks (not the signature special). RB swaps the
# active weapon. "fists" = the dino's natural attack. A weapon flagged
# "projectile" is RANGED: dino.gd fires a shot in the facing direction (reusing
# the spike-projectile path) instead of swinging — its standout trait is reach,
# paid for with modest damage. "range" still nudges the (unused) melee offset but
# the shot itself flies via the dino's projectile_speed/lifetime exports.
# Everyone starts armed with their SIGNATURE weapon (DINOS.weapons' non-fists
# entry; see signature_weapon / main._grant_signature_weapons). Throw it away
# and you're on fists until the next round hands it back — or grab one of the
# drops that keep raining mid-round (picked up with LT) to go off-brand.
const WEAPONS := {
	"fists":     {"display_name": "FISTS",     "dmg": 1.0,  "kb": 1.0,  "range": 0,   "windup": 1.0, "recovery": 1.0},
	"sword":     {"display_name": "SWORD",      "dmg": 1.2,  "kb": 1.1,  "range": 16,  "windup": 1.0, "recovery": 1.0},
	"dagger":    {"display_name": "DAGGER",     "dmg": 0.7,  "kb": 0.7,  "range": -4,  "windup": 0.6, "recovery": 0.6},
	"axe":       {"display_name": "AXE",        "dmg": 1.45, "kb": 1.25, "range": 12,  "windup": 1.25, "recovery": 1.2},
	"mace":      {"display_name": "SPIKED MACE", "dmg": 1.4, "kb": 1.5,  "range": 10,  "windup": 1.3, "recovery": 1.3},
	"hammer":    {"display_name": "WAR HAMMER", "dmg": 1.9,  "kb": 1.7,  "range": 10,  "windup": 1.6, "recovery": 1.5},
	"nunchucks": {"display_name": "NUNCHUCKS",  "dmg": 0.85, "kb": 0.6,  "range": 4,   "windup": 0.5, "recovery": 0.7},
	"bow":       {"display_name": "BOW",        "dmg": 0.8,  "kb": 0.8,  "range": 0,   "windup": 1.1, "recovery": 1.0, "projectile": true},
}

const DINOS := {
	"trike": {
		"display_name": "GUS",
		"weapons": ["fists", "mace"],
		"dino_color": Color(0.95, 0.85, 0.30, 1.0),
		"sprite_role": "trike",
		"sprite_scale": 0.64,
		"sprite_offset_y": -35.0,
		"grip_offset": Vector2(30.0, -14.0),   # mouth, low & forward (quadruped)
		"hit_sfx_name": "hit_chomp",
		"max_speed": 300.0,
		"ground_accel": 2500.0,
		"ground_friction": 3500.0,
		"ice_accel": 500.0,
		"ice_friction": 150.0,
		"max_hp": 138,
		"attack_damage": 21,
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
		"max_block": 105.0,
		"block_regen": 28.0,
		"dodge_duration": 0.20,
		"dodge_cooldown": 0.6,
		"dodge_distance": 150.0,
		"dodge_block_cost": 32.0,
		"signature": "charger",   # super-armor through his heavy — plows through trades
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
		"display_name": "JESSIE",
		"weapons": ["fists", "bow"],
		"dino_color": Color(0.85, 0.45, 0.30, 1.0),
		"sprite_role": "pterry",
		"sprite_scale": 0.55,
		"sprite_offset_y": -29.0,
		"grip_offset": Vector2(22.0, -18.0),   # near wing-claw hand, mid-height
		"hit_sfx_name": "hit_chomp",
		"max_speed": 280.0,
		"ground_accel": 2000.0,
		"ground_friction": 3000.0,
		"ice_accel": 400.0,
		"ice_friction": 120.0,
		"max_hp": 140,
		"attack_damage": 19,
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
		"signature": "flighty",   # landing a hit refunds her dodge — endless hit-and-run
		"special_type": "screech",
		"special_damage": 14,
		"special_knockback": 250.0,
		"special_windup": 0.20,
		"special_active": 0.06,
		"special_recovery": 0.50,
		"special_radius": 220.0,
		"special_slow_duration": 2.2,
		"special_cooldown": 4.5,
	},
	"raptor": {
		"display_name": "MAX",
		"weapons": ["fists", "dagger"],
		"dino_color": Color(0.95, 0.45, 0.45, 1.0),
		"sprite_role": "raptor",
		"sprite_scale": 0.52,
		"sprite_offset_y": -27.0,
		"grip_offset": Vector2(20.0, -20.0),   # hands, mid-height (biped)
		"hit_sfx_name": "hit_claw",
		"max_speed": 440.0,
		"ground_accel": 5000.0,
		"ground_friction": 5000.0,
		"ice_accel": 1100.0,
		"ice_friction": 380.0,
		"max_hp": 130,
		"attack_damage": 22,
		"attack_knockback": 200.0,
		"attack_windup": 0.06,
		"attack_active": 0.08,
		"attack_recovery": 0.18,
		"attack_hitbox_size": Vector2(56, 48),
		"attack_hitbox_offset": 44.0,
		"heavy_damage": 34,
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
		"dodge_block_cost": 22.0,
		"signature": "dash_cancel",   # can cancel attack recovery into a dodge
		"special_type": "dash_claw",
		"special_damage": 30,
		"special_knockback": 350.0,
		"special_windup": 0.10,
		"special_active": 0.10,
		"special_recovery": 0.30,
		"special_hitbox_size": Vector2(64, 52),
		"special_hitbox_offset": 48.0,
		"special_self_dash": 950.0,
		"special_cooldown": 2.8,
	},
	"bronto": {
		"display_name": "STEVE",
		"weapons": ["fists", "hammer"],
		"dino_color": Color(0.45, 0.55, 0.85, 1.0),
		"sprite_role": "bronto",
		"sprite_scale": 0.72,
		"sprite_offset_y": -40.0,
		"grip_offset": Vector2(26.0, -78.0),   # mouth, HIGH at the top of the long neck
		"hit_sfx_name": "hit_chomp",
		"max_speed": 250.0,
		"ground_accel": 1700.0,
		"ground_friction": 2500.0,
		"ice_accel": 340.0,
		"ice_friction": 110.0,
		"max_hp": 150,
		"attack_damage": 20,
		"attack_knockback": 360.0,
		"attack_windup": 0.18,
		"attack_active": 0.12,
		"attack_recovery": 0.34,
		"attack_hitbox_size": Vector2(82, 56),
		"attack_hitbox_offset": 58.0,
		"heavy_damage": 32,
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
		"signature": "bulwark",   # jabs can't stagger the titan — only real blows
		"special_type": "neck_whip",
		"special_damage": 22,
		"special_knockback": 520.0,
		"special_windup": 0.30,
		"special_active": 0.16,
		"special_recovery": 0.52,
		"special_hitbox_size": Vector2(120, 64),
		"special_hitbox_offset": 72.0,
		"special_cooldown": 5.5,
	},
	"anky": {
		"display_name": "FRANK",
		"weapons": ["fists", "axe"],
		"dino_color": Color(0.55, 0.5, 0.4, 1.0),
		"sprite_role": "anky",
		"sprite_scale": 0.63,
		"sprite_offset_y": -34.0,
		"grip_offset": Vector2(32.0, -10.0),   # mouth, low & forward (wide quadruped)
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
		"signature": "spikeback",   # reflects a share of BLOCKED damage at the attacker
		"special_type": "tail_smash",
		"special_damage": 18,
		"special_knockback": 520.0,
		"special_windup": 0.26,
		"special_active": 0.16,
		"special_recovery": 0.50,
		"special_radius": 140.0,
		"special_cooldown": 6.0,
	},
	# Ralph the mascot — a scrappy medium bruiser whose niche is the AoE signature
	# "Tiny Meteor Stomp" (reuses the radial screech shockwave). Stats track the
	# character-screen flavor: HP 120, ATK 28 ((19+37)/2), DEF 20 (block 120/6).
	# Ralph absorbed the old T-Rex slot (2026-06-10): Ralph's design WAS the
	# T-Rex concept, so he now carries the heavyweight-king kit (chomp lifesteal
	# lunge) with his own art. The standalone trex entry is gone.
	"ralph": {
		"display_name": "RALPH",
		"weapons": ["fists", "hammer"],
		"dino_color": Color(0.5, 0.82, 0.52, 1.0),
		"sprite_role": "ralph",
		"sprite_scale": 0.6,
		"sprite_offset_y": -32.0,
		"grip_offset": Vector2(18.0, -14.0),   # tiny T-rex arms, low hand height
		"hit_sfx_name": "hit_chomp",
		"max_speed": 240.0,
		"ground_accel": 1500.0,
		"ground_friction": 2200.0,
		"ice_accel": 300.0,
		"ice_friction": 90.0,
		"max_hp": 135,
		"attack_damage": 21,
		"attack_knockback": 460.0,
		"attack_windup": 0.22,
		"attack_active": 0.14,
		"attack_recovery": 0.40,
		"attack_hitbox_size": Vector2(80, 72),
		"attack_hitbox_offset": 60.0,
		"heavy_damage": 34,
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
		"signature": "combo_king",   # light chains speed up his next light — rushdown
		"special_type": "chomp",
		"special_damage": 24,
		"special_knockback": 300.0,
		"special_windup": 0.22,
		"special_active": 0.12,
		"special_recovery": 0.45,
		"special_hitbox_size": Vector2(72, 64),
		"special_hitbox_offset": 58.0,
		"special_self_dash": 700.0,
		"special_cooldown": 6.0,
		"special_lifesteal": 0.20,
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
# Curated set (2026-06-10): every mode is a DISTINCT verb so none feel like
# another — duels (rounds), hold-the-zone (koth), scramble-for-eggs (eggs),
# shove-off (sumo), bomb-pass (bombtag), hunt-the-beast (beast), outlast-the-tide
# (flood). LAST DINO STANDING was retired (its HP-KO loop felt the same as BEST
# OF ROUNDS; its dormant main.gd logic stays revivable). THE BEAST is gated to
# 3-4 players by the select screen (it collapses in 1v1) — see select._mode_available.
const MODE_ORDER := ["rounds", "koth", "eggs", "sumo", "bombtag", "beast", "flood"]
const BEAST_MIN_PLAYERS := 3  # THE BEAST is a 1-vs-all crowd mode; hidden in 1v1
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
	"sumo": "STAY IN THE RING  -  FORCE THEM OUT  -  FIRST TO {sumo} POINTS",
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

var dino_choices: Dictionary = {"p1": "ralph", "p2": "raptor", "p3": "trike", "p4": "pterry", "p5": "bronto", "p6": "anky"}
var island: String = "laughing_lava"
var player_count: int = 2
## Which slots are CPU-controlled this match. Set on the select screen.
var cpu_players: Dictionary = {"p1": false, "p2": false, "p3": false, "p4": false, "p5": false, "p6": false}
## pid -> SKINS index picked on the select screen for this match.
## -1 = no pick: the dino spawns with its creator-equipped MetaSave skin.
var skin_choices: Dictionary = {"p1": -1, "p2": -1, "p3": -1, "p4": -1, "p5": -1, "p6": -1}

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
const CPU_DIFFICULTY_ORDER := ["easy", "normal", "hard", "brutal"]
const CPU_DIFFICULTY_NAMES := {"easy": "EASY", "normal": "NORMAL", "hard": "HARD", "brutal": "BRUTAL"}
var cpu_difficulty: String = "normal"

# --- FLOPPY MODE (Gang-Beasts-style physics movement) ---
# The DEFAULT couch experience (the game's identity: party chaos beats a precise
# ladder we can't sustain without online). Fighters move with momentum/inertia
# (skate + overshoot, can't reverse on a dime), hard hits knock them off their
# feet, and LT grabs / RT throws a foe. The host can flip it OFF on the select
# screen (Select button) for the precise/balance-tuned model.
var floppy_mode: bool = true

# --- SEASON MODE (couch campaign) ---
# You build a team (1 or 2 fighters: humans + CPUs), pick team size, and climb a
# fixed run of MATCHDAYS — each a DIFFERENT game mode on a different island, foes
# escalating to a BRUTAL final. Your side (A) = your fighters; foe side (B) = CPUs.
# Win all matchdays => SEASON CHAMPION (records to MetaSave, unlocks CHAMPION skin).
# main.gd drives the between-matchday flow; this holds the schedule + reconfigures.
var season_setup: bool = false       # title -> select handoff: configure a season
var season: bool = false
var season_matchday: int = 0
var season_schedule: Array = []      # [{foes:[dino,...], mode, difficulty, island}]
var season_size: int = 2             # fighters PER SIDE (1 = 1v1, 2 = 2v2; engine caps at 4)
var season_team: Array = []          # your side: [{dino: String, human: bool}], len == season_size
var season_perks: Array = []         # TEAM PERK ids drafted between matchdays (stack, your side only)
var season_division: int = 0         # 0 ROOKIE / 1 PRO / 2 LEGEND — set by start_season (Phase 3)
# SQUAD + FATIGUE (Phase 3): your squad is the fielded fighters plus one reserve.
# Fielded fighters tire each matchday; benched ones recover. Fatigue is a mild capped
# stat dip applied at spawn (dino.gd), so resting your ace before the finale matters.
var season_squad: Array = []         # [{dino, fatigue}], len == season_size + 1
var season_field: Array = []         # indices into season_squad fielded this matchday (len season_size)
var season_field_fatigue: Dictionary = {}  # fielded pid -> that fighter's fatigue (dino.gd reads at spawn)
var season_humans: int = 1           # how many present pads on your side; they pilot field slots 0..n-1
const SEASON_BENCH := 1              # reserves beyond the fielded count
const FATIGUE_MAX := 4               # fatigue caps here
const FATIGUE_SPEED_PEN := 0.06      # -6% move speed per fatigue point (floored)
const FATIGUE_DMG_PEN := 0.05        # -5% damage per fatigue point (floored)
func season_fatigue_speed_mult(f: int) -> float:
	return maxf(0.70, 1.0 - FATIGUE_SPEED_PEN * f)
func season_fatigue_dmg_mult(f: int) -> float:
	return maxf(0.70, 1.0 - FATIGUE_DMG_PEN * f)
# Coin rewards (Phase 3 economy). Each matchday win pays out; the championship adds
# a bonus. Both scale with the division so climbing pays better.
const MATCHDAY_COIN := 15
const CHAMPION_COIN := 60
func season_matchday_reward() -> int:
	return MATCHDAY_COIN + season_division * 10
func season_champion_reward() -> int:
	return CHAMPION_COIN + season_division * 40
# Matchdays cycle the TEAM-COMPATIBLE modes (Beast + Bomb Tag are FFA, excluded), so
# a season tours the game. Difficulty ramps to a BRUTAL finale.
const SEASON_MODES := ["rounds", "koth", "eggs", "sumo", "flood"]
const SEASON_DIFFS := ["easy", "normal", "normal", "hard", "brutal"]
# Named rival teams, one per matchday, fought on their HOME island in escalating
# order — the last is the BRUTAL boss. dinos are sliced to the team size: [0] for
# 1v1, [0..1] for 2v2, [0..2] for 3v3.
const RIVAL_TEAMS := [
	{"name": "BEACH BRAWLERS", "island": "beauty_beach",      "dinos": ["ralph", "raptor", "trike"]},
	{"name": "TIDE RIDERS",    "island": "white_water_falls", "dinos": ["pterry", "raptor", "bronto"]},
	{"name": "SPRING STAMPEDE", "island": "sunny_springs",    "dinos": ["bronto", "trike", "ralph"]},
	{"name": "FROST FANGS",    "island": "iciest_age",        "dinos": ["anky", "pterry", "raptor"]},
	{"name": "MAGMA TYRANTS",  "island": "laughing_lava",     "dinos": ["trike", "anky", "bronto"]},
]

# DIVISIONS (Phase 3): a campaign is played at a division (0 ROOKIE / 1 PRO / 2
# LEGEND). The division raises the whole season's difficulty floor and the coin
# payouts; you keep promotions (MetaSave.best_division) and may replay any unlocked
# division. The difficulty ladder each matchday's base difficulty is shifted along.
const DIFF_LADDER := ["easy", "normal", "hard", "brutal"]
func _bump_difficulty(diff: String, steps: int) -> String:
	var i: int = DIFF_LADDER.find(diff)
	if i < 0:
		i = 1
	return DIFF_LADDER[clampi(i + steps, 0, DIFF_LADDER.size() - 1)]

func start_season(team: Array, size: int, division: int = 0, reserve: String = "") -> void:
	season = true
	season_size = clampi(size, 1, 3)   # 1v1 / 2v2 / 3v3 (engine fields up to 6)
	season_team = team
	season_matchday = 0
	season_perks = []
	season_division = clampi(division, 0, MetaSave.unlocked_division())
	# Pads follow field SLOTS, not dinos: slot 0 is always you, slot 1 a 2nd pad if it
	# joined. So rotating the CPU reserve into a slot never drops a present human.
	season_humans = 0
	for t in team:
		if bool(t.get("human", false)):
			season_humans += 1
	season_humans = maxi(1, season_humans)
	season_squad = _build_squad(team, reserve)
	season_field = []
	for i in range(season_size):
		season_field.append(i)   # your starters are fielded for matchday 1
	teams_enabled = season_size == 2
	season_schedule = _build_season()
	_apply_season_matchday()

# Your squad: the starters (with their human flags) + one reserve. The reserve is a
# chosen dino, else auto-picked as the first roster dino not already a starter. The
# reserve is CPU-piloted when fielded (you only ever hold one pad as p1 / field[0]).
func _build_squad(team: Array, reserve: String) -> Array:
	var sq: Array = []
	for t in team:
		sq.append({"dino": t["dino"], "fatigue": 0})
	var rdino: String = reserve
	if rdino == "":
		var used: Array = []
		for t in team:
			used.append(t["dino"])
		for d in ROSTER_ORDER:
			if not (d in used):
				rdino = d
				break
		if rdino == "":
			rdino = ROSTER_ORDER[0]
	sq.append({"dino": rdino, "fatigue": 0})
	return sq

# One matchday per RIVAL TEAM: a named foe team on its home island, a cycling mode,
# and a ramping difficulty (shifted up by the division) — fixed escalating fixtures.
# foes = the rival's dinos sliced to the team size.
func _build_season() -> Array:
	var sched: Array = []
	for i in range(SEASON_MODES.size()):
		var rival: Dictionary = RIVAL_TEAMS[i % RIVAL_TEAMS.size()]
		var rd: Array = rival["dinos"]
		var foes: Array = []
		for j in range(season_size):
			foes.append(rd[j] if j < rd.size() else rd[rd.size() - 1])
		var base_diff: String = SEASON_DIFFS[min(i, SEASON_DIFFS.size() - 1)]
		sched.append({
			"foes": foes,
			"mode": SEASON_MODES[i],
			"difficulty": _bump_difficulty(base_diff, season_division),
			"island": rival["island"],
			"rival": rival["name"],
		})
	return sched

# Seat your team on side A (P1 + optional P2), foes on side B; apply the matchday's
# mode/island/difficulty. Win is side-based (main.gd same_side), so co-op + solo
# both resolve through the team rules.
func _apply_season_matchday() -> void:
	var md: Dictionary = season_schedule[season_matchday]
	var foes: Array = md["foes"]
	cpu_difficulty = md["difficulty"]
	island = md["island"]
	game_mode = md["mode"]
	# The fighters fielded this matchday, drawn from the squad via season_field.
	var fielded: Array = []
	for idx in season_field:
		fielded.append(season_squad[idx])
	# Seat your side (A: p1..pN) and the foes (B: the next N), for any size 1/2/3.
	# Pads fill the low your-side slots (season_humans); the rest of your side + all
	# foes are CPU. Teams are off only in 1v1 (FFA). Works for 2 / 4 / 6 fighters.
	season_field_fatigue = {}
	player_count = season_size * 2
	teams_enabled = season_size >= 2
	for i in range(season_size):
		var your_pid: String = "p%d" % (i + 1)
		var foe_pid: String = "p%d" % (season_size + i + 1)
		teams[your_pid] = "a"
		teams[foe_pid] = "b"
		cpu_players[your_pid] = i >= season_humans
		cpu_players[foe_pid] = true
		dino_choices[your_pid] = fielded[i]["dino"]
		dino_choices[foe_pid] = foes[i] if i < foes.size() else foes[foes.size() - 1]
		season_field_fatigue[your_pid] = int(fielded[i]["fatigue"])

# Advance to the next matchday. Returns false when the season is cleared (champion).
# By default ages the squad first (the fighters that just played tire, the bench
# recovers); the rotation flow ages separately, then advances with age=false.
func season_advance(age: bool = true) -> bool:
	if age:
		_age_squad()
	season_matchday += 1
	if season_matchday >= season_schedule.size():
		return false
	_apply_season_matchday()
	return true

# Public hook so the rotation screen can tire the lineup that just played BEFORE you
# pick who rests next matchday (so the shown fatigue is current).
func season_age_squad() -> void:
	_age_squad()

# Fielded fighters gain a fatigue point (capped); benched fighters shed one (floored).
func _age_squad() -> void:
	for i in range(season_squad.size()):
		var fat: int = int(season_squad[i]["fatigue"])
		if i in season_field:
			season_squad[i]["fatigue"] = mini(FATIGUE_MAX, fat + 1)
		else:
			season_squad[i]["fatigue"] = maxi(0, fat - 1)

# Set the fielded lineup (indices into season_squad). Used by the between-matchday
# rotation screen; ignores invalid sizes so a bad call can't desync seating.
func season_set_field(indices: Array) -> void:
	if indices.size() == season_size:
		season_field = indices.duplicate()

func season_scene() -> String:
	return ISLAND_SCENES.get(island, "res://scenes/main.tscn")

# True on the final matchday (the BRUTAL finale) — for the "CHAMPIONSHIP" banner.
func season_is_final() -> bool:
	return not season_schedule.is_empty() and season_matchday >= season_schedule.size() - 1

# Team perks drafted between matchdays apply to your WHOLE side (dino.gd
# _apply_run_upgrades). Reuse the gauntlet UPGRADES, minus the heal perks (they rely
# on between-wave HP carry, which season doesn't have).
func season_draft_options() -> Array:
	var pool: Array = []
	for id in UPGRADES:
		var up: Dictionary = UPGRADES[id]
		if up.has("heal_now") or up.has("wave_heal"):
			continue
		pool.append(id)
	pool.shuffle()
	return pool.slice(0, 3)

func season_add_perk(id: String) -> void:
	if UPGRADES.has(id):
		season_perks.append(id)

# --- Roguelike gauntlet (solo spine v2) ---
# An endless, escalating run: win a wave, draft one of three upgrades that stack
# for the rest of the run, fight a tougher foe, repeat until you lose (permadeath).
# Upgrades are pure data (stat -> ["mul"|"add", value]); dino.gd applies them on
# spawn to the player only. Enemies scale via gauntlet_enemy_*_mult per wave.
var gauntlet_setup: bool = false     # title -> select handoff
var gauntlet: bool = false
var gauntlet_wave: int = 0           # 0-indexed; displayed as wave+1
var gauntlet_upgrades: Array = []    # upgrade ids picked this run (may repeat)
var gauntlet_player_dino: String = "ralph"
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

func start_gauntlet(player_dino: String, start_island: String = "") -> void:
	gauntlet = true
	teams_enabled = false  # solo run is always 1-v-1
	gauntlet_wave = 0
	gauntlet_upgrades = []
	gauntlet_player_dino = player_dino
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

# Floppy difficulty lever: late foes absorb more knockback so they can't be trivially
# thrown/shoved off the edge. Without this the gauntlet curve was FLAT on ring-out
# arenas under floppy (a wave-16 foe lost 7:1) while it scaled fine on confined ones.
func gauntlet_enemy_kb_resist() -> float:
	return clampf(0.04 * float(gauntlet_wave), 0.0, 0.6)

# --- CAREER MODE: raise ONE bonded dino across a long, authored journey. The run
# state PERSISTS (MetaSave), unlike the throwaway gauntlet. `career` is the runtime
# flag a career match sets so dino.gd applies the player's grown stats at spawn.
# The journey is rebuilt DETERMINISTICALLY from the chosen dino (no RNG) so it's
# identical every time you resume. See CAREER_MODE_PLAN.md. ---
var career: bool = false

const CAREER_STOP_COUNT := 21          # long grind; the final stop is the BOSS
const CAREER_RIVAL_STOPS := [5, 11, 16]  # the recurring rival ambushes here...
# ...and the boss (last stop) IS the rival — the showdown you've been building to.
# A couple of mid-run stops swap in a mode for variety; the rest are straight fights.
const CAREER_MODE_STOPS := {8: "koth", 14: "sumo"}

# Stable per-career seed from the bonded dino id (char sum) — keeps the journey
# reproducible across sessions without storing the whole schedule.
func _career_seed() -> int:
	var s: int = 0
	for i in MetaSave.career_dino.length():
		s += MetaSave.career_dino.unicode_at(i)
	return s

# The rival = a fixed foe (first roster dino that isn't yours) — a recurring nemesis.
func career_rival() -> String:
	for d in ROSTER_ORDER:
		if d != MetaSave.career_dino:
			return d
	return "raptor"

func career_is_boss(stop: int) -> bool:
	return stop >= CAREER_STOP_COUNT - 1

func career_is_rival(stop: int) -> bool:
	return career_is_boss(stop) or stop in CAREER_RIVAL_STOPS

func _career_difficulty(stop: int) -> String:
	if career_is_boss(stop):
		return "brutal"
	var band: String = "easy" if stop < 4 else ("normal" if stop < 10 else "hard")
	if career_is_rival(stop):  # the rival always fights a notch above the locals
		band = "normal" if band == "easy" else "hard"
	return band

# The full journey, rebuilt deterministically. Each stop: island / mode / foe /
# difficulty / rival / boss.
func career_stops() -> Array:
	var seed: int = _career_seed()
	var pool: Array = []
	for d in ROSTER_ORDER:
		if d != MetaSave.career_dino:
			pool.append(d)
	var out: Array = []
	for i in range(CAREER_STOP_COUNT):
		var foe: String = career_rival() if career_is_rival(i) else pool[(i * 3 + seed) % pool.size()]
		out.append({
			"island": ISLAND_ORDER[(i + seed) % ISLAND_ORDER.size()],
			"mode": CAREER_MODE_STOPS.get(i, "rounds"),
			"foe": foe,
			"difficulty": _career_difficulty(i),
			"rival": career_is_rival(i),
			"boss": career_is_boss(i),
		})
	return out

func career_current_stop() -> Dictionary:
	var stops: Array = career_stops()
	return stops[clampi(MetaSave.career_stop, 0, stops.size() - 1)]

# Growth the bonded dino applies at spawn (dino.gd reads this for p1). Pips are
# permanent; mood gives a small same-fight buff/penalty. Format mirrors UPGRADES mods.
func career_stat_bonus() -> Dictionary:
	var pw: int = MetaSave.career_pip_count("power")
	var sp: int = MetaSave.career_pip_count("speed")
	var to: int = MetaSave.career_pip_count("toughness")
	var gu: int = MetaSave.career_pip_count("guard")
	var dmg_mul: float = pow(1.0 + MetaSave.CAREER_PIP_POWER, pw)
	var spd_mul: float = pow(1.0 + MetaSave.CAREER_PIP_SPEED, sp)
	var mood_mul: float = 1.05 if MetaSave.career_mood >= 70 else (0.95 if MetaSave.career_mood <= 30 else 1.0)
	dmg_mul *= mood_mul
	spd_mul *= mood_mul
	return {
		"attack_damage": ["mul", dmg_mul],
		"heavy_damage": ["mul", dmg_mul],
		"special_damage": ["mul", dmg_mul],
		"max_speed": ["mul", spd_mul],
		"max_hp": ["add", MetaSave.CAREER_PIP_TOUGH * to],
		"max_block": ["add", MetaSave.CAREER_PIP_GUARD * gu],
	}

# HP the bonded dino spawns with this fight (-1 = full). REST restores it to full.
func career_player_hp() -> int:
	return MetaSave.career_hp_carry

# Configure a versus match for the current journey stop (you = p1, foe = p2 CPU).
func career_start_match() -> void:
	career = true
	gauntlet = false
	season = false
	var stop: Dictionary = career_current_stop()
	teams_enabled = false
	player_count = 2
	cpu_players = {"p1": false, "p2": true, "p3": false, "p4": false, "p5": false, "p6": false}
	dino_choices["p1"] = MetaSave.career_dino
	dino_choices["p2"] = stop["foe"]
	cpu_difficulty = stop["difficulty"]
	island = stop["island"]
	game_mode = stop["mode"]

# Boss is best-of-3; the rest best-of-2 (a forgiving buffer, per the design).
func career_kos_to_win() -> int:
	return 3 if career_is_boss(MetaSave.career_stop) else 2

func career_scene() -> String:
	return ISLAND_SCENES.get(island, "res://scenes/main.tscn")

# --- CAREER story beats. Light, characterful flavor keyed to the journey. %s =
# your dino's name, %r = the rival's name. Milestone stops (rival encounters + the
# boss) get authored lines; ordinary stops draw from pools (indexed by stop, so a
# run reads varied but is reproducible). ---
const CAREER_INTRO := {
	0: "SIX ISLANDS. ONE CROWN. TIME TO EARN IT, %s.",
	5: "%r BLOCKS THE ROAD.  \"SO YOU'RE THE ROOKIE EVERYONE'S ON ABOUT?\"",
	11: "%r WAITS AGAIN.  \"...HUH. MAYBE YOU ARE THE REAL DEAL.\"",
	16: "%r, ONE MORE TIME.  \"THIS ENDS BEFORE THE FINALE. IT HAS TO.\"",
	20: "THE LAST ISLAND. ONLY %r STANDS BETWEEN %s AND THE CROWN.",
}
const CAREER_INTRO_POOL := [
	"A NEW ISLAND. A NEW CHALLENGER SIZING YOU UP.",
	"THE LOCALS SAY NOBODY BEATS THEIR CHAMPION HERE.",
	"WORD OF %s IS SPREADING ACROSS THE ISLANDS.",
	"REST UP. THIS ONE WON'T GO EASY.",
	"ANOTHER RUNG ON THE CLIMB. KEEP GOING, %s.",
]
const CAREER_WIN_POOL := [
	"ANOTHER ONE DOWN. THE CROWD LOVES %s.",
	"CLEAN WORK. ON TO THE NEXT ISLAND.",
	"THEY WON'T FORGET THAT ONE.",
	"%s TAKES IT. THE LEGEND GROWS.",
]
const CAREER_LOSS_POOL := [
	"A ROUGH ONE. SHAKE IT OFF, %s.",
	"NOT TODAY. BACK TO THE DEN TO REGROUP.",
	"DOWN, NOT OUT. TRAIN UP AND RUN IT BACK.",
]

func _career_fmt(s: String) -> String:
	var me: String = MetaSave.career_name if MetaSave.career_name != "" else career_rival()
	var riv: String = str(DINOS.get(career_rival(), {}).get("name", career_rival())).to_upper()
	return s.replace("%s", me.to_upper()).replace("%r", riv)

# Story line for a stop. phase = "intro" (DEN, upcoming) | "win" | "loss".
func career_story(stop: int, phase: String) -> String:
	if phase == "intro":
		if CAREER_INTRO.has(stop):
			return _career_fmt(CAREER_INTRO[stop])
		return _career_fmt(CAREER_INTRO_POOL[stop % CAREER_INTRO_POOL.size()])
	if phase == "win":
		if career_is_boss(stop):
			return _career_fmt("THE ISLANDS HAVE A NEW CHAMPION:  %s!")
		if career_is_rival(stop):
			return _career_fmt("%r REELS BACK, STUNNED.  \"...HOW?\"")
		return _career_fmt(CAREER_WIN_POOL[stop % CAREER_WIN_POOL.size()])
	# loss
	if career_is_rival(stop):
		return _career_fmt("%r SMIRKS.  \"COME BACK WHEN YOU'RE READY.\"")
	return _career_fmt(CAREER_LOSS_POOL[stop % CAREER_LOSS_POOL.size()])

# XP / coin reward for clearing the current stop (rival + boss pay more).
func career_win_reward() -> Dictionary:
	var stop: int = MetaSave.career_stop
	var xp: int = 60 + stop * 6
	var coins_r: int = 12 + stop
	if career_is_boss(stop):
		xp *= 3; coins_r *= 3
	elif career_is_rival(stop):
		xp = int(xp * 1.6); coins_r = int(coins_r * 1.6)
	return {"xp": xp, "coins": coins_r}

func _ready() -> void:
	_setup_input_actions()

func _setup_input_actions() -> void:
	# Gamepad-only: all four players drive the game from controllers. There are no
	# keyboard bindings — _register_player_actions wires pad buttons/axes only.
	_register_player_actions("p1", 0)
	_register_player_actions("p2", 1)
	_register_player_actions("p3", 2)
	_register_player_actions("p4", 3)
	_register_player_actions("p5", 4)   # 3v3: 5th/6th pads (or CPU-driven)
	_register_player_actions("p6", 5)
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
# The dino's signature weapon: the first non-fists entry of DINOS.weapons.
# Everyone spawns holding theirs (main._grant_signature_weapons).
func signature_weapon(dino_id: String) -> String:
	var arr: Array = DINOS.get(dino_id, {}).get("weapons", [])
	for w in arr:
		if w != "fists":
			return w
	return ""

# Baked painterly weapon sprite (blade toward +X, see bake_weapon_sprites.py),
# or null for fists/unknown ids — callers fall back to weapon_shape polygons.
func weapon_texture(id: String) -> Texture2D:
	var path := "res://assets/sprites/weapons/%s.png" % id
	if not ResourceLoader.exists(path):
		return null
	return load(path)

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
		"bow":
			# A thin C-shaped bow limb facing +X (drawn arm side toward the dino).
			return {"poly": PackedVector2Array([Vector2(2, -18), Vector2(10, -12), Vector2(13, 0), Vector2(10, 12), Vector2(2, 18), Vector2(5, 16), Vector2(9, 4), Vector2(9, -4), Vector2(5, -16)]), "color": Color(0.55, 0.38, 0.22)}
		_:
			return {"poly": PackedVector2Array(), "color": Color.WHITE}  # fists: no held item
