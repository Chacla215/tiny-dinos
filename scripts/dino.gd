extends CharacterBody2D

enum Surface { GROUND, ICE }
enum AttackPhase { IDLE, WINDUP, ACTIVE, RECOVERY }
enum DefenseState { NORMAL, BLOCKING, DODGING, GUARD_BROKEN }

const SHEET_PLAYER := "res://assets/sprites/playersprites_revision.png"
const SHEET_REF := "res://assets/sprites/rynosaurlandcharacters.png"
const SHEET_ENEMY := "res://assets/sprites/enemysprites_revision.png"
# 3D-baked fighter sheets (Meshy model -> Blender toon bake, see scripts/tools/
# blender_render_dino.py). Each carries "motion": true so the game plays these
# frames via AnimatedSprite2D instead of the procedural rig. Old box-sliced
# sheets (*_fighter.png) remain on disk as history.
# Ralph is the painterly-chibi prototype: real Seedance motion clips
# (assets/concept/ralph/motion/{idle,walk,attack}.mp4) sliced + cut out + packed
# by scripts/tools/gen_dino_motion.py, so in-match Ralph matches the TRAILER look
# (smooth/LINEAR, no dither). The other 5 are still the older 3D toon bakes until
# the same motion pipeline rolls out to them.
const SHEET_RALPH := "res://assets/sprites/ralph_motion.png"
const SHEET_RAPTOR := "res://assets/sprites/raptor_fighter_3d.png"
const SHEET_TRIKE := "res://assets/sprites/trike_fighter_3d.png"
const SHEET_PTERRY := "res://assets/sprites/pterry_fighter_3d.png"
const SHEET_BRONTO := "res://assets/sprites/bronto_fighter_3d.png"
const SHEET_ANKY := "res://assets/sprites/anky_fighter_3d.png"

const ANIM_LAYOUTS := {
	# Every fighter below is a 3D-baked sheet (Meshy model -> Blender toon bake,
	# scripts/tools/blender_render_dino.py + pack_dino_sheet.py). "motion": true =>
	# wants_rig=false, so the AnimatedSprite2D plays these idle/walk/attack frames
	# (squash-and-stretch animation baked in) instead of the procedural limb rig.
	"raptor": {
		"sheet": SHEET_RAPTOR,
		"motion": true,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(0, 0, 130, 168), Rect2(130, 0, 130, 168)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(260, 0, 130, 168), Rect2(390, 0, 130, 168), Rect2(520, 0, 130, 168), Rect2(650, 0, 130, 168)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(780, 0, 130, 168), Rect2(910, 0, 130, 168), Rect2(1040, 0, 130, 168)]},
	},
	"ralph": {
		# Painterly motion sheet (135x153 cells, one row per anim) from
		# gen_dino_motion.py — trailer-matched. idle 4 / walk 8 / attack 5.
		"sheet": SHEET_RALPH,
		"motion": true,
		"idle":   {"loop": true,  "speed": 6.0,  "rects": [Rect2(0, 0, 135, 153), Rect2(135, 0, 135, 153), Rect2(270, 0, 135, 153), Rect2(405, 0, 135, 153)]},
		"walk":   {"loop": true,  "speed": 12.0, "rects": [Rect2(0, 153, 135, 153), Rect2(135, 153, 135, 153), Rect2(270, 153, 135, 153), Rect2(405, 153, 135, 153), Rect2(540, 153, 135, 153), Rect2(675, 153, 135, 153), Rect2(810, 153, 135, 153), Rect2(945, 153, 135, 153)]},
		"attack": {"loop": false, "speed": 14.0, "rects": [Rect2(0, 306, 135, 153), Rect2(135, 306, 135, 153), Rect2(270, 306, 135, 153), Rect2(405, 306, 135, 153), Rect2(540, 306, 135, 153)]},
	},
	"trike": {
		"sheet": SHEET_TRIKE,
		"motion": true,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(0, 0, 169, 168), Rect2(169, 0, 169, 168)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(338, 0, 169, 168), Rect2(507, 0, 169, 168), Rect2(676, 0, 169, 168), Rect2(845, 0, 169, 168)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(1014, 0, 169, 168), Rect2(1183, 0, 169, 168), Rect2(1352, 0, 169, 168)]},
	},
	"pterry": {
		"sheet": SHEET_PTERRY,
		"motion": true,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(0, 0, 155, 168), Rect2(155, 0, 155, 168)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(310, 0, 155, 168), Rect2(465, 0, 155, 168), Rect2(620, 0, 155, 168), Rect2(775, 0, 155, 168)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(930, 0, 155, 168), Rect2(1085, 0, 155, 168), Rect2(1240, 0, 155, 168)]},
	},
	"bronto": {
		"sheet": SHEET_BRONTO,
		"motion": true,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(0, 0, 143, 168), Rect2(143, 0, 143, 168)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(286, 0, 143, 168), Rect2(429, 0, 143, 168), Rect2(572, 0, 143, 168), Rect2(715, 0, 143, 168)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(858, 0, 143, 168), Rect2(1001, 0, 143, 168), Rect2(1144, 0, 143, 168)]},
	},
	"anky": {
		"sheet": SHEET_ANKY,
		"motion": true,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(0, 0, 191, 168), Rect2(191, 0, 191, 168)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(382, 0, 191, 168), Rect2(573, 0, 191, 168), Rect2(764, 0, 191, 168), Rect2(955, 0, 191, 168)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(1146, 0, 191, 168), Rect2(1337, 0, 191, 168), Rect2(1528, 0, 191, 168)]},
	},
}

@export var max_speed: float = 320.0
@export var ground_accel: float = 3000.0
@export var ground_friction: float = 3000.0
@export var ice_accel: float = 600.0
@export var ice_friction: float = 200.0

# FLOPPY MODE locomotion (MatchConfig.floppy_mode): low accel = sluggish to get
# going, very low friction = you keep gliding and overshoot, so you carry
# momentum and can't reverse instantly. The Gang-Beasts "loose control" core.
@export var floppy_accel: float = 1500.0       # ramp-up / reverse (~0.25s to reverse)
@export var floppy_friction: float = 620.0     # friction AT the reference speed (below)
@export var floppy_speed_mult: float = 1.10    # let momentum carry you a bit faster
# Extra friction applied ONLY when you release the stick. Tightens the post-release
# slide — the "ice-skating" symptom — without stiffening active drive/turn (those use
# accel, not friction), so floppy stays loose to control but plants where you aim.
@export var floppy_release_brake: float = 1.45
# Ice / lava-centre friction as a FRACTION of floppy-ground friction. Keeps those
# surfaces slippier than ground (still read distinct) without collapsing to the old
# flat ice_friction=200 floor, which made fast dinos slide ~half the arena (a 484-top
# dino: ~586px on ice vs ~125px on ground — the uniform-glide model breaking on ice).
@export var floppy_ice_factor: float = 0.55
# Floppy glide is v^2/(2*friction): with flat friction a 440-speed dino slid ~673px
# (half the arena — it rang itself out of a centre sprint) while a 240 tank slid
# ~135px (barely floppy). Scale friction with top speed so every dino coasts for the
# SAME time instead — loose but controllable, uniform across the roster.
# Hands-feel pass (Charlie playtest: "controls feel slippery"): tightened from
# accel 850 / fric 360 (~0.89s coast, ~234px glide) to 1500 / 620 (~0.52s coast,
# ~137px glide) + snappier reverse — still clearly floppy, far less sliding off.
const FLOPPY_REF_SPEED := 320.0

@export_group("Combat")
@export var max_hp: int = 100
# Fraction of incoming knockback absorbed (0 = none, 1 = immovable). Default 0 for
# everyone; the gauntlet scales it on foes per wave so late enemies resist being
# thrown/shoved off the edge — the difficulty lever that actually bites under floppy
# (HP scaling is moot when ring-outs ignore HP). See _apply_run_upgrades.
@export var knockback_resist: float = 0.0
@export var attack_damage: int = 15
@export var attack_knockback: float = 300.0
@export var attack_windup: float = 0.12
@export var attack_active: float = 0.10
@export var attack_recovery: float = 0.30
@export var attack_hitbox_size: Vector2 = Vector2(56, 56)
@export var attack_hitbox_offset: float = 52.0
@export var invuln_duration: float = 0.8
@export var hitstun_invuln: float = 0.15

@export_group("Heavy Attack")
@export var heavy_damage: int = 30
@export var heavy_knockback: float = 500.0
@export var heavy_windup: float = 0.30
@export var heavy_active: float = 0.16
@export var heavy_recovery: float = 0.55
@export var heavy_hitbox_size: Vector2 = Vector2(80, 80)
@export var heavy_hitbox_offset: float = 60.0
@export var heavy_self_dash: float = 0.0
@export var heavy_attack_type: String = "melee"
@export var projectile_speed: float = 700.0
@export var projectile_lifetime: float = 1.5
@export var projectile_color: Color = Color(0.95, 0.85, 0.4, 1.0)

@export_group("Special")
## Signature move on the special button. Type drives the few unique behaviors;
## everything else is a normal melee swing with these numbers.
## "none" | "chomp" (lifesteal) | "dash_claw" (cooldown refunds on hit)
## | "headbutt" (armored charge) | "screech"/"stomp" (radial AoE + slow)
## | "neck_whip" (guard crush) | "tail_smash" (radial shockwave)
@export var special_type: String = "none"
@export var special_damage: int = 25
@export var special_knockback: float = 350.0
@export var special_windup: float = 0.22
@export var special_active: float = 0.12
@export var special_recovery: float = 0.45
@export var special_hitbox_size: Vector2 = Vector2(80, 70)
@export var special_hitbox_offset: float = 58.0
@export var special_self_dash: float = 0.0
@export var special_cooldown: float = 4.0
@export var special_lifesteal: float = 0.0   ## chomp: heal this fraction of dmg dealt
@export var special_radius: float = 0.0       ## screech: AoE radius
@export var special_slow_duration: float = 0.0 ## screech: how long victims are slowed

# --- Gauntlet run-mechanic upgrades (player slot only; set in _apply_run_upgrades) ---
var run_lifesteal: float = 0.0   ## VAMPIRE: heal this fraction of melee damage dealt
var run_thorns: float = 0.0      ## SPIKED HIDE: reflect this fraction of damage taken
var run_execute: float = 0.0     ## EXECUTIONER: bonus damage multiplier vs low-HP foes
var _run_start_hp: int = -1      ## gauntlet HP carried into this wave; -1 = spawn at full

# SUMO / BOMB TAG: hits still shove (knockback applies) but never drain HP or KO —
# the only way out is over the edge (or, in bomb tag, the bomb). Set by main.gd.
var ringout_only: bool = false

# THE BEAST (juggernaut mode): the crowned fighter is bigger, hits harder, and
# carries a bonus HP pool. Toggled mid-match by main.gd via become_beast/clear_beast.
var beast_active: bool = false
var _base_max_hp: int = 0
const BEAST_HP_BONUS := 80
const BEAST_DMG_MULT := 1.4
const BEAST_KB_MULT := 1.45
const BEAST_SCALE := 1.3
const BEAST_TINT := Color(1.5, 1.2, 0.5)

@export_group("Weapons")
## 2-weapon loadout (ids into MatchConfig.WEAPONS). RB swaps the active one.
@export var weapons: Array = ["fists"]

@export_group("Defense")
@export var max_block: float = 100.0
@export var block_regen: float = 30.0
@export var block_move_factor: float = 0.3
@export var block_knockback_factor: float = 0.3
@export var guard_break_duration: float = 0.8
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.6
@export var dodge_distance: float = 160.0
@export var dodge_block_cost: float = 30.0

@export_group("Input")
@export var player_id: String = "p1"
## When true this dino is driven by dino_ai.gd instead of player input.
@export var is_cpu: bool = false
var ai: RefCounted = null

@export_group("Appearance")
@export var dino_color: Color = Color(0.4, 0.8, 0.6, 1.0)
@export var show_hitbox_debug: bool = false

@export_group("Audio")
@export var hit_sfx_name: String = "hit_claw"

@export_group("Sprite")
@export var sprite_role: String = "raptor"
@export var sprite_scale: float = 2.5
@export var sprite_offset_y: float = -10.0
## Where a held weapon / carried foe anchors on THIS dino's body, so the grab
## reads as anatomically true: x = distance forward along facing, y = vertical
## (negative = up). Hand-grabbers (Ralph/Max) sit near hand height; the wing-claw
## (Jessie) a touch higher; mouth-grabbers (Gus/Frank low, Steve high on his neck)
## anchor up at the snout. DINOS overrides this per dino; default = old hand anchor.
@export var grip_offset: Vector2 = Vector2(18.0, -6.0)
# Global visual-scale multiplier on every fighter (readability on the busy arenas).
const FIGHTER_SCALE_BOOST := 1.25
## True when the source sprite art faces left by default (e.g. bronto/Goober).
## Flips the flip_h logic so the dino visually faces its movement direction.
var sprite_faces_left: bool = false

@onready var polygon: Polygon2D = $Polygon2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# Runtime limb skeleton (built in code at spawn). When present it drives the
# in-match look (live idle/walk/hit motion) and the baked AnimatedSprite2D above
# is hidden; if its parts aren't on disk yet, `rig` stays null and we fall back
# to the baked sheet. Menus still use the sheet for static previews.
var rig: DinoRig = null
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hitbox_visual: Polygon2D = $Hitbox/Visual
@onready var player_marker: Polygon2D = $PlayerMarker

var current_surface: int = Surface.GROUND
var spawn_point: Vector2
var facing: Vector2 = Vector2.RIGHT
var hp: int
var attack_phase: int = AttackPhase.IDLE
var attack_timer: float = 0.0
var attack_phase_dur: float = 0.001   # full length of the current phase, for swing progress (0..1)
var invuln_timer: float = 0.0
var hit_targets_this_swing: Array = []

var defense_state: int = DefenseState.NORMAL
var block_durability: float
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_velocity: Vector2 = Vector2.ZERO
var guard_break_timer: float = 0.0
var last_damaged_by: Node = null
var hit_flash_timer: float = 0.0
var hit_flash_strength: float = 0.0   # 0 = soft (jab/blocked) … 1 = white-out (haymaker)
var hit_anim_timer: float = 0.0       # motion-sheet "hit" flinch clip (only when the sheet has one)
var afterimage_timer: float = 0.0
var ice_overlap_count: int = 0
var slow_overlap_count: int = 0
var floe_overlap_count: int = 0  # Frozen Floes: >0 means standing on safe ice
var current_push: Vector2 = Vector2.ZERO
var knockback_active: bool = false
var dash_active: bool = false   # a self-dash lunge is in flight (decays at a fixed rate)

# FLOPPY MODE stage 2: a big enough hit knocks you OFF YOUR FEET. While downed you
# lose control, slide with the blow, and the rig goes limp/tumbling until you
# scramble back up. Pure floppy-mode mechanic — gated on MatchConfig.floppy_mode.
var is_downed: bool = false
var down_timer: float = 0.0
var knockdown_immune_timer: float = 0.0  # after getting up, can't be re-floored a beat
const DOWN_DURATION := 0.85          # seconds floored before you scramble up
const DOWN_KB_THRESHOLD := 420.0     # knockback strength that takes your feet
const DOWN_GETUP_INVULN := 0.25
const DOWN_IMMUNE_AFTER := 0.9       # no re-knockdown window so you can't be juggled

# FLOPPY MODE stage 3: GRAB / carry / throw — the core Gang-Beasts verb. LT grabs
# a foe in front (else picks up a weapon as before); RT hurls a held foe (else
# throws a weapon). The held foe is dragged, goes limp, and mashes to break free.
var grabbing: Node = null            # the foe I'm currently holding (null = none)
var grabbed_by: Node = null          # who's holding me (null = free)
var grab_hold_timer: float = 0.0     # auto-release countdown while I hold someone
var grab_cooldown: float = 0.0       # brief lockout after a grab ends
var grab_escape: float = 0.0         # 0..1 struggle progress while I'm held
const GRAB_RANGE := 96.0             # how far in front a grab reaches
const GRAB_MAX_HOLD := 1.7           # seconds before a held foe slips free
const GRAB_HOLD_DIST := 62.0         # how far in front the held foe is carried
const GRAB_THROW_KB := 880.0         # launch power when you hurl them — a committed
									 # grab earns a decisive yeet (~245px slide vs ~185),
									 # so throw-off-the-edge is a real KO, not a soft toss
const GRAB_COOLDOWN := 0.55
const GRAB_ESCAPE_PER_MASH := 0.17   # struggle gained per button press (humans)
const GRAB_ESCAPE_CPU_RATE := 0.62   # struggle/sec a held CPU builds automatically
const GRAB_CARRY_SLOW := 0.72        # hauling a limp foe drags your own top speed down
const GRAB_CARRY_LAG := 0.32         # how fast the carried foe closes to the hold point
									 # (lower = it swings/trails behind you like dead weight)

# Ring-out: shoved off the island, the dino either tumbles off the BOTTOM (sides
# + low edge, a clean KO) or gets sucked UP and spirals into the sky off the TOP.
# The sky launch is escapable — mash to fight the pull back into the safe zone.
# main.gd starts it (begin_ringout) and is told when it ends/recovers.
var is_falling: bool = false
var fall_timer: float = 0.0
var fall_up: bool = false        # true = sky launch (recoverable), false = drop
var fall_center_y: float = 0.0   # arena center, for height-based shrink/fade
var spiral_angle: float = 0.0
var ringout_killer: Node = null

var current_attack_damage: int = 0
var current_attack_knockback: float = 0.0
var current_attack_active: float = 0.0
var current_attack_recovery: float = 0.0
var current_attack_hitbox_size: Vector2 = Vector2.ZERO
var current_attack_hitbox_offset: float = 0.0
var current_is_heavy: bool = false
var current_is_special: bool = false
var special_cooldown_timer: float = 0.0
var timed_slow_timer: float = 0.0  # screech-applied slow on this dino

var active_weapon: int = 0
var weapon_visual: Node2D = null     # held weapon (baked sprite, or polygon fallback), oriented to facing
var initial_weapons: Array = []      # loadout to restore on respawn
var wpn_dmg: float = 1.0
var wpn_kb: float = 1.0
var wpn_range: float = 0.0
var wpn_windup: float = 1.0
var wpn_recovery: float = 1.0
var wpn_projectile: bool = false  # ranged weapon (e.g. bow): fires a shot, no melee swing

# [experiment] Map power-up buffs: temporary multipliers applied at the movement
# + damage hooks, reverted when the timer runs out (or on respawn). 1.0 = no buff.
var powerup_speed_mult: float = 1.0
var powerup_dmg_mult: float = 1.0
var powerup_timer: float = 0.0
var powerup_aura: Node2D = null

# [experiment] Combo counter: consecutive hits landed without getting hit. Pops a
# "Nx HIT!" above the head at 2+; resets on a timeout or on taking a hit.
var combo_count: int = 0
var combo_timer: float = 0.0

const AFTERIMAGE_INTERVAL := 0.05
const SLOW_MOVE_FACTOR := 0.4
const SLOW_ACCEL_FACTOR := 0.6
## How fast knockback "launch" speed (the part above your normal max_speed)
## bleeds off, regardless of surface. Stops a hit from gliding you off an ice
## map while leaving normal ice-sliding untouched.
const KNOCKBACK_DECEL := 2000.0
## Self-dash lunges (dash_claw / headbutt charge) bleed their launch speed at this
## FIXED rate regardless of floppy_mode, so a lunge is a committed ~300px gap-closer
## in both models — not a launch that rides floppy's low friction off the edge.
const DASH_DECEL := 3000.0

## Ring-out fall tuning: how long the downward tumble lasts, downward accel, the
## initial downward pop, and tumble spin (radians/sec).
const FALL_DURATION := 0.75
const FALL_GRAVITY := 2800.0
const FALL_INITIAL_VY := 260.0
const FALL_SPIN := 9.0

## Sky launch (top-edge ring-out): a constant UPWARD pull sucks the dino into the
## sky; mashing kicks it back down. Escape past SKY_ESCAPE_Y (off the top) = KO;
## re-entering the safe zone = recovered. Spiral = swirl while rising.
const SKY_PULL := 720.0          # upward acceleration (px/s^2) — the suction
const SKY_INITIAL_VY := 200.0    # initial upward pop
const SKY_ESCAPE_Y := -200.0     # world Y past the top edge = fully rung out
const SKY_MAX_TIME := 3.0         # safety cap on the sky struggle (failsafe KO)
const SKY_SPIRAL_SPEED := 12.0   # swirl frequency (rad/s)
const SKY_SPIRAL_AMP := 150.0    # swirl sideways speed (px/s)
const MASH_BOOST := 235.0        # downward kick per button mash
const CPU_MASH_CHANCE := 0.11    # per-frame chance a CPU mashes to recover
const RECOVER_INVULN := 0.6      # i-frames after clawing back onto the field
## Buttons that count as a recovery mash.
const MASH_ACTIONS := ["attack", "heavy", "dodge", "special"]

## Throw (RT) / pickup (LT). A thrown weapon flies fast and lands harder than
## the same weapon swung — but whiff it off the platform and it's gone. Damage
## scales off this dino's weapon-modified light hit, so heavier loadouts throw
## for more (and have more to lose). PICKUP_RADIUS is how close you grab from.
const THROW_SPEED := 920.0
const THROW_DAMAGE_MULT := 1.6
const THROW_KB_MULT := 1.55
const PICKUP_RADIUS := 120.0

func _ready() -> void:
	_apply_config_preset()
	if MatchConfig and "cpu_players" in MatchConfig and MatchConfig.cpu_players.get(player_id, false):
		is_cpu = true
	if is_cpu:
		ai = preload("res://scripts/dino_ai.gd").new()
		if MatchConfig and "cpu_difficulty" in MatchConfig:
			ai.apply_difficulty(MatchConfig.cpu_difficulty)
		_equip_default_weapon()  # CPUs commit to their weapon (no human swap input)
	_apply_run_upgrades()  # gauntlet: player carries drafted upgrades; foes scale per wave
	spawn_point = global_position
	hp = max_hp
	if _run_start_hp >= 0:
		hp = _run_start_hp  # gauntlet: carried (and partly healed) HP for this wave
	block_durability = max_block
	if MatchConfig and MatchConfig.PLAYER_COLORS.has(player_id):
		var player_color: Color = MatchConfig.PLAYER_COLORS[player_id]
		polygon.color = player_color
		player_marker.color = player_color
	else:
		polygon.color = dino_color
	# Team mode: the floating marker shows the team color (body keeps its own hue so
	# teammates are still tellable apart).
	if MatchConfig and MatchConfig.teams_enabled:
		player_marker.color = MatchConfig.TEAM_COLORS.get(MatchConfig.side_of(player_id), player_marker.color)

	_setup_sprite()

# Gauntlet run modifiers, applied after the base preset and before HP/block init.
# The human player gets every upgrade they've drafted (stacking); CPU foes get the
# per-wave enemy scaling so the run keeps escalating past the HARD difficulty cap.
func _apply_run_upgrades() -> void:
	if not MatchConfig:
		return
	# SEASON: your whole side carries the drafted TEAM PERKS (stacking across
	# matchdays); the foe side gets nothing. same_side covers both 1v1 and 2v2.
	if "season" in MatchConfig and MatchConfig.season:
		if MatchConfig.same_side(player_id, "p1"):
			_apply_upgrade_list(MatchConfig.season_perks)
			# FATIGUE: a fielded fighter that played prior matchdays is a touch slower
			# and weaker (mild, capped). Resting it on the bench sheds the penalty.
			var f: int = int(MatchConfig.season_field_fatigue.get(player_id, 0))
			if f > 0:
				_scale_stat("max_speed", MatchConfig.season_fatigue_speed_mult(f))
				var dm: float = MatchConfig.season_fatigue_dmg_mult(f)
				_scale_stat("attack_damage", dm)
				_scale_stat("heavy_damage", dm)
				_scale_stat("special_damage", dm)
		return
	if not ("gauntlet" in MatchConfig) or not MatchConfig.gauntlet:
		return
	# The run belongs to the player slot (p1). Everyone else is a foe and scales per
	# wave. Keying on the slot (not is_cpu) keeps real play identical while letting
	# an AI-piloted p1 still carry its drafted upgrades (used by the demo runner).
	if player_id != "p1":
		_scale_stat("max_hp", MatchConfig.gauntlet_enemy_hp_mult())
		var dm: float = MatchConfig.gauntlet_enemy_dmg_mult()
		_scale_stat("attack_damage", dm)
		_scale_stat("heavy_damage", dm)
		_scale_stat("special_damage", dm)
		# Under floppy, HP scaling is moot — you just throw the foe off the edge. So
		# also make late foes harder to RING OUT (the only scaling lever that bites on
		# ring-out arenas; on confined arenas the HP/dmg scaling already worked).
		knockback_resist = MatchConfig.gauntlet_enemy_kb_resist()
		return
	_apply_upgrade_list(MatchConfig.gauntlet_upgrades)
	max_hp += MatchConfig.gauntlet_meta_hp_bonus  # HARDENED meta perk (0 if not unlocked)
	# HP carryover: wounds persist between waves (not between rounds — respawn()
	# still refills). A new wave heals back a breather; -1 means a fresh run = full.
	var carry: int = MatchConfig.gauntlet_player_hp
	if carry < 0:
		_run_start_hp = max_hp
	else:
		_run_start_hp = clampi(carry + int(round(float(max_hp) * MatchConfig.gauntlet_wave_heal_frac())), 1, max_hp)

# Apply a list of UPGRADES ids to self (stat mods + run_* effect flags). Shared by
# the gauntlet draft (player) and the season team-perk draft (your whole side).
func _apply_upgrade_list(ids: Array) -> void:
	for uid in ids:
		var up: Dictionary = MatchConfig.UPGRADES.get(uid, {})
		for stat in up.get("mods", {}):
			if not (stat in self):
				continue
			var op: Array = up["mods"][stat]
			var cur = get(stat)
			var nv = (cur * op[1]) if op[0] == "mul" else (cur + op[1])
			if typeof(cur) == TYPE_INT:
				nv = int(round(nv))
			set(stat, nv)
		var eff: Dictionary = up.get("effect", {})
		run_lifesteal += eff.get("lifesteal", 0.0)
		run_thorns += eff.get("thorns", 0.0)
		run_execute += eff.get("execute", 0.0)

func _scale_stat(stat: String, mult: float) -> void:
	if not (stat in self):
		return
	var cur = get(stat)
	if typeof(cur) == TYPE_INT:
		set(stat, int(round(cur * mult)))
	else:
		set(stat, cur * mult)

func _apply_config_preset() -> void:
	if not MatchConfig:
		return
	if not MatchConfig.dino_choices.has(player_id):
		return
	var dino_id: String = MatchConfig.dino_choices[player_id]
	if not MatchConfig.DINOS.has(dino_id):
		return
	var preset: Dictionary = MatchConfig.DINOS[dino_id]
	for key in preset:
		if key in self:
			set(key, preset[key])
	# READABILITY: fighters read too small on the busy painterly arenas (4-player
	# couch legibility is the priority). Bump the VISUAL scale a notch — look-only,
	# the Hitbox/CharacterBody2D use their own exports, so balance is untouched. Feet
	# stay planted via the project's footing convention (offset_y = 7.6 - 66*scale).
	sprite_scale *= FIGHTER_SCALE_BOOST
	sprite_offset_y = 7.6 - 66.0 * sprite_scale
	# Nobody spawns armed: weapons drop onto the island mid-round (main.gd) and
	# are fought over via LT pickup. Two slots so a fighter can carry a backup.
	# (DINOS.weapons remains as creator-screen "favorite weapons" flavor.)
	weapons = ["fists", "fists"]

	var shape := RectangleShape2D.new()
	shape.size = attack_hitbox_size
	hitbox_shape.shape = shape

	var hw := attack_hitbox_size.x * 0.5
	var hh := attack_hitbox_size.y * 0.5
	hitbox_visual.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	])
	hitbox_visual.color = Color(1.0, 0.95, 0.3, 0.45)
	hitbox_visual.visible = false
	hitbox_shape.disabled = true

	# Preset loadouts come straight from the const DINOS table (read-only), and
	# throw/pickup mutate the slots — so work on a private mutable copy.
	weapons = weapons.duplicate()
	initial_weapons = weapons.duplicate()  # restored each life after throws
	_refresh_weapon()

# --- Shared sprite-frame builders ---------------------------------------------
# The picker, title, and character screen all render dinos from the SAME
# ANIM_LAYOUTS the match uses (so pick == play). These statics are the single
# source of that build logic; callers add their own scale/flip/offset.

# A SpriteFrames for `role` from ANIM_LAYOUTS. `only` (animation names) limits
# which clips are built — empty = all (idle/walk/attack). null if the role or
# its sheet is unavailable.
static func build_sprite_frames(role: String, only: PackedStringArray = PackedStringArray()) -> SpriteFrames:
	if not ANIM_LAYOUTS.has(role):
		return null
	var layout: Dictionary = ANIM_LAYOUTS[role]
	var sheet_path: String = layout.get("sheet", SHEET_PLAYER)
	if not ResourceLoader.exists(sheet_path):
		return null
	var sheet: Texture2D = load(sheet_path)
	if sheet == null:
		return null
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim_name in layout:
		if anim_name == "sheet" or anim_name == "faces_left" or anim_name == "motion":
			continue
		if not only.is_empty() and not (anim_name in only):
			continue
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, layout[anim_name].loop)
		sf.set_animation_speed(anim_name, layout[anim_name].speed)
		for rect in layout[anim_name].rects:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = rect
			sf.add_frame(anim_name, atlas)
	return sf

# The first frame of `role`'s `anim` clip as a standalone AtlasTexture (used for
# static portraits). null if the role/sheet/clip is unavailable.
static func first_frame(role: String, anim: String = "idle") -> AtlasTexture:
	if not ANIM_LAYOUTS.has(role):
		return null
	var layout: Dictionary = ANIM_LAYOUTS[role]
	var sheet_path: String = layout.get("sheet", SHEET_PLAYER)
	if not ResourceLoader.exists(sheet_path):
		return null
	var rects: Array = layout.get(anim, {}).get("rects", [])
	if rects.is_empty():
		return null
	var at := AtlasTexture.new()
	at.atlas = load(sheet_path)
	at.region = rects[0]
	return at

func _setup_sprite() -> void:
	if not sprite_role in ANIM_LAYOUTS:
		sprite.visible = false
		return
	sprite_faces_left = ANIM_LAYOUTS[sprite_role].get("faces_left", false)
	var sf := build_sprite_frames(sprite_role)
	if sf == null:
		sprite.visible = false
		return
	sprite.sprite_frames = sf
	# Fighters are baked SMOOTH (painterly) from the hero art, so filter linear
	# rather than nearest — keeps the in-match look consistent with the menus.
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.position.y = sprite_offset_y
	# Cosmetic skin: the select-screen pick for this slot wins; -1 falls back to
	# the dino's creator-equipped MetaSave skin (null material = DEFAULT,
	# unchanged). Display-only, no gameplay effect.
	var skin_idx: int = int(MatchConfig.skin_choices.get(player_id, -1))
	if skin_idx < 0:
		skin_idx = MetaSave.get_skin(sprite_role)
	var skin_mat := MatchConfig.skin_material(skin_idx)
	sprite.material = skin_mat
	sprite.play("idle" if sf.has_animation("idle") else "walk")
	polygon.visible = false
	# Prefer the live limb rig; the baked sheet stays as the fallback if a dino's
	# parts haven't been exported yet (gen_ralph_fighter.py <dino> --parts).
	# EXCEPT when the dino's layout is a video-baked motion sheet ("motion": true,
	# from gen_dino_motion.py): real animation frames replace the procedural rig
	# for that dino, so the two looks can be A/B'd per-dino during the rollout.
	var wants_rig: bool = not ANIM_LAYOUTS.get(sprite_role, {}).get("motion", false)
	if wants_rig:
		var r := DinoRig.new()
		r.scale = Vector2(sprite_scale, sprite_scale)
		r.position.y = sprite_offset_y
		if r.build_for(sprite_role, skin_mat):
			rig = r
			add_child(rig)
			rig.set_facing(true)
			sprite.visible = false
		else:
			r.free()
	_add_contact_shadow()

# A grounded CONTACT SHADOW: a soft dark oval cast on the floor at the feet (the
# footing line), flattened like a real cast shadow so the fighter reads as standing
# ON the surface, not floating. Also doubles as separation from a busy arena ground.
# Drawn as the first child so the sprite/rig render on top of it. Look-only.
func _add_contact_shadow() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(0.0, 0.0, 0.0, 0.42))   # core of the cast shadow
	grad.set_color(1, Color(0.0, 0.0, 0.0, 0.0))     # soft feathered rim
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var shadow := Sprite2D.new()
	shadow.name = "ContactShadow"
	shadow.texture = tex
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Sit on the ground at the feet. By the footing convention sprite_offset_y =
	# 7.6 - 66*scale, so offset_y + 66*scale lands on the ~7.6 ground line for every
	# dino regardless of the scale boost.
	shadow.position.y = sprite_offset_y + 66.0 * sprite_scale
	var w: float = sprite_scale * 1.45
	shadow.scale = Vector2(w, w * 0.30)               # flat oval = a cast shadow, not a halo
	add_child(shadow)
	move_child(shadow, 0)

func _physics_process(delta: float) -> void:
	if is_falling:
		_process_fall(delta)
		return
	# FLOPPY stage 3: while a foe is holding you, you're out of control — dragged,
	# limp, mashing to break free. Takes priority over everything else.
	if grabbed_by != null:
		_process_grabbed(delta)
		return
	# FLOPPY stage 2: while floored you can't act — you just slide and the rig
	# tumbles. No AI, no inputs, no attacks; movement keeps your momentum.
	if is_downed:
		_process_downed(delta)
		return
	if is_cpu and ai != null:
		ai.think(self, _find_nearest_opponent(), delta)
	update_facing()
	_process_input_actions()
	update_guard_break(delta)
	update_dodge(delta)
	update_attack(delta)
	update_movement(delta)
	if grabbing != null:
		_update_grab_hold(delta)
	update_block_regen(delta)
	update_timers(delta)
	update_visual()
	update_sprite_animation()
	var current_offset := current_attack_hitbox_offset if attack_phase != AttackPhase.IDLE else attack_hitbox_offset
	hitbox.position = facing * current_offset
	if weapon_visual and weapon_visual.visible:
		# Melee weapons SWING through the attack (cock back on windup, chop down on
		# active, ease home on recovery) so a weapon hit reads as a real strike, not
		# a static prop. Ranged weapons (bow) don't swing — they fire.
		var fsign := 1.0 if facing.x >= 0.0 else -1.0
		var sw := Vector2.ZERO if wpn_projectile else _weapon_swing()
		weapon_visual.rotation = facing.angle() + deg_to_rad(sw.x) * fsign
		weapon_visual.position = facing * (grip_offset.x + sw.y) + Vector2(0, grip_offset.y)
		# Facing left rotates the sprite past 90°; un-mirror it so the blade's
		# top edge stays up.
		if weapon_visual is Sprite2D:
			weapon_visual.flip_v = facing.x < 0.0

func _action(name: String) -> String:
	return "%s_%s" % [player_id, name]

func _process_input_actions() -> void:
	if is_cpu and ai != null:
		_process_cpu_actions()
		return
	if Input.is_action_just_pressed(_action("attack")) and can_attack():
		start_attack(false)
	if Input.is_action_just_pressed(_action("heavy")) and can_attack():
		start_attack(true)
	if Input.is_action_just_pressed(_action("special")) and can_special():
		start_special()
	if Input.is_action_just_pressed(_action("swap")):
		_swap_weapon()
	# RT: hurl a held foe if you have one, else throw your weapon.
	if Input.is_action_just_pressed(_action("throw")):
		if grabbing != null:
			throw_grabbed()
		elif can_throw():
			throw_weapon()
	# LT: grab a foe in front if one's there, else pick up a weapon.
	if Input.is_action_just_pressed(_action("pickup")):
		if can_grab() and _foe_in_grab_range() != null:
			begin_grab(_foe_in_grab_range())
		elif can_pickup():
			try_pickup()
	if Input.is_action_just_pressed(_action("block")) and can_start_block():
		start_block()
	elif Input.is_action_just_released(_action("block")) and defense_state == DefenseState.BLOCKING:
		end_block()
	if Input.is_action_just_pressed(_action("dodge")) and can_dodge():
		start_dodge()
	if Input.is_action_just_pressed(_action("emote")):
		play_emote()

func _process_cpu_actions() -> void:
	# FLOPPY: hurl a held foe, or reach out and grab one.
	if ai.consume_throw_grabbed() and grabbing != null:
		throw_grabbed()
	if ai.consume_grab() and can_grab():
		var foe := _foe_in_grab_range()
		if foe != null:
			begin_grab(foe)
	if ai.consume_throw() and can_throw():
		throw_weapon()
	if ai.consume_pickup() and can_pickup():
		try_pickup()
	if ai.consume_attack() and can_attack():
		start_attack(false)
	if ai.consume_heavy() and can_attack():
		start_attack(true)
	if ai.consume_special() and can_special():
		start_special()
	if ai.block_held and can_start_block():
		start_block()
	elif not ai.block_held and defense_state == DefenseState.BLOCKING:
		end_block()
	if ai.consume_dodge() and can_dodge():
		start_dodge()

# --- Emotes -------------------------------------------------------------------
var emote_idx: int = 0
var _emote_bubble: Node2D = null

# Pop the next quick-taunt emote in a speech bubble above the head. Art-free for
# now (MatchConfig.EMOTES text); cycles through the list on each tap.
func play_emote() -> void:
	if MatchConfig.EMOTES.is_empty():
		return
	var emote: Dictionary = MatchConfig.EMOTES[emote_idx % MatchConfig.EMOTES.size()]
	emote_idx += 1
	if is_instance_valid(_emote_bubble):
		_emote_bubble.queue_free()
	_emote_bubble = _build_emote_bubble(String(emote.get("text", "!")))
	add_child(_emote_bubble)
	play_scene_sfx("emote", 0.12)

func _build_emote_bubble(txt: String) -> Node2D:
	var root := Node2D.new()
	root.z_index = 50
	# Sit just above the head; the sprite spans ~80*scale up from the body origin.
	var head_y: float = sprite_offset_y - 80.0 * sprite_scale - 28.0
	root.position = Vector2(0, head_y)
	var w: float = maxf(58.0, txt.length() * 17.0 + 26.0)
	var h := 44.0
	var accent: Color = MatchConfig.PLAYER_COLORS.get(player_id, Color("e6c878"))
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f5f1e6")
	sb.border_color = accent
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(-w / 2.0, -h / 2.0)
	panel.size = Vector2(w, h)
	root.add_child(panel)
	# Little downward tail toward the dino.
	var tail := Polygon2D.new()
	tail.color = accent
	tail.polygon = PackedVector2Array([Vector2(-9, h / 2.0 - 2), Vector2(9, h / 2.0 - 2), Vector2(0, h / 2.0 + 12)])
	root.add_child(tail)
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color("2a2118"))
	lbl.position = Vector2(-w / 2.0, -h / 2.0)
	lbl.size = Vector2(w, h)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(lbl)
	# Pop in, hold, fade out, free.
	root.scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(root, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(root, "position:y", head_y - 12.0, 0.22).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.9)
	tw.tween_property(root, "modulate:a", 0.0, 0.35)
	tw.tween_callback(root.queue_free)
	return root

# Nearest active opposing dino, or null. Active = visible (inactive slots are
# hidden by main.gd). Used by the CPU brain as its target.
func _find_nearest_opponent() -> Node:
	var best: Node = null
	var best_score := INF
	for other in get_parent().get_children():
		if other == self or not (other is CharacterBody2D):
			continue
		if not ("player_id" in other) or other.player_id == player_id:
			continue
		if MatchConfig.same_side(player_id, other.player_id):
			continue  # don't pick a teammate as the AI's target
		if not other.visible:
			continue
		var score := global_position.distance_squared_to(other.global_position)
		# Team focus-fire: weight a low-HP enemy as if it were closer, so allied
		# CPUs converge on the weakest foe and finish it together. FFA stays nearest.
		if MatchConfig.teams_enabled and "hp" in other and "max_hp" in other and other.max_hp > 0:
			score *= 0.45 + 0.55 * (float(other.hp) / float(other.max_hp))
		if score < best_score:
			best_score = score
			best = other
	return best

func update_sprite_animation() -> void:
	var attacking := attack_phase == AttackPhase.WINDUP or attack_phase == AttackPhase.ACTIVE
	var moving := velocity.length() > 12.0
	# Live limb rig path: feed it facing / walk speed / state; springs do the rest.
	if rig != null:
		if facing.x > 0.05:
			rig.set_facing(true)
		elif facing.x < -0.05:
			rig.set_facing(false)
		rig.set_walk_speed(velocity.length())
		rig.set_motion(velocity.x)
		rig.play("attack" if attacking else ("walk" if moving else "idle"))
		return
	if not sprite.visible or sprite.sprite_frames == null:
		return
	# flip_h is relative to the source art's default facing: sprites drawn facing
	# left (sprite_faces_left) need the opposite flip to face their movement.
	if facing.x > 0.05:
		sprite.flip_h = sprite_faces_left
	elif facing.x < -0.05:
		sprite.flip_h = not sprite_faces_left
	# Motion-sheet states (video-baked sheets carry ko/hit/dodge/heavy clips the
	# 3-anim fallback sheets don't). Priority: downed > flinch > dodge > attack.
	# Every branch requires the clip to exist, so old sheets behave exactly as
	# before and a partial sheet (pilot = walk+attack only) degrades per-state.
	var sf := sprite.sprite_frames
	if is_downed and sf.has_animation("ko"):
		if sprite.animation != "ko":
			sprite.play("ko")
		return
	if hit_anim_timer > 0.0 and not attacking and sf.has_animation("hit"):
		if sprite.animation != "hit":
			sprite.play("hit")
		return
	if defense_state == DefenseState.DODGING and sf.has_animation("dodge"):
		if sprite.animation != "dodge":
			sprite.play("dodge")
		return
	if attacking:
		var atk := "heavy" if current_is_heavy and sf.has_animation("heavy") else "attack"
		if sprite.animation != atk:
			sprite.play(atk)
		return
	var target := "walk" if moving else "idle"
	if not sf.has_animation(target):
		target = "idle" if moving else "walk"   # partial pilot sheet: best available
		if not sf.has_animation(target):
			return
	if sprite.animation != target:
		sprite.play(target)

# --- Capability checks ---

func can_attack() -> bool:
	return not is_downed and grabbing == null and grabbed_by == null \
		and attack_phase == AttackPhase.IDLE \
		and defense_state == DefenseState.NORMAL

func can_start_block() -> bool:
	return not is_downed and grabbing == null and grabbed_by == null \
		and attack_phase == AttackPhase.IDLE \
		and defense_state == DefenseState.NORMAL

func can_special() -> bool:
	return not is_downed and grabbing == null and grabbed_by == null \
		and special_type != "none" \
		and special_cooldown_timer <= 0.0 \
		and attack_phase == AttackPhase.IDLE \
		and defense_state == DefenseState.NORMAL

func can_throw() -> bool:
	return not is_downed and grabbed_by == null \
		and _active_weapon_id() != "fists" \
		and attack_phase == AttackPhase.IDLE \
		and defense_state == DefenseState.NORMAL

func can_pickup() -> bool:
	return not is_downed and grabbed_by == null \
		and defense_state != DefenseState.DODGING \
		and defense_state != DefenseState.GUARD_BROKEN

func can_dodge() -> bool:
	if is_downed or grabbed_by != null:
		return false
	if dodge_cooldown_timer > 0.0:
		return false
	if slow_overlap_count > 0 or timed_slow_timer > 0.0:
		return false
	if defense_state == DefenseState.DODGING or defense_state == DefenseState.GUARD_BROKEN:
		return false
	if attack_phase == AttackPhase.WINDUP or attack_phase == AttackPhase.ACTIVE:
		return false
	if block_durability < dodge_block_cost:
		return false
	return true

# Queried by the CPU brain (dino_ai.gd).
func is_swinging() -> bool:
	return attack_phase == AttackPhase.WINDUP or attack_phase == AttackPhase.ACTIVE

# Locked in attack recovery: can't block, dodge, or re-attack. The CPU treats this
# (and guard-break) as a free-punish window.
func is_recovering() -> bool:
	return attack_phase == AttackPhase.RECOVERY

# Dodge i-frames double as a floe-to-floe leap on Frozen Floes (main.gd checks this).
func is_dodging() -> bool:
	return defense_state == DefenseState.DODGING

func is_guard_broken() -> bool:
	return defense_state == DefenseState.GUARD_BROKEN

# --- Facing + input direction ---

func update_facing() -> void:
	var dir := get_input_direction()
	if dir != Vector2.ZERO:
		facing = dir

func get_input_direction() -> Vector2:
	if is_cpu and ai != null:
		return ai.move_dir
	var d := Vector2.ZERO
	if Input.is_action_pressed(_action("up")):
		d.y -= 1.0
	if Input.is_action_pressed(_action("down")):
		d.y += 1.0
	if Input.is_action_pressed(_action("left")):
		d.x -= 1.0
	if Input.is_action_pressed(_action("right")):
		d.x += 1.0
	return d.normalized()

# --- Movement ---

func update_movement(delta: float) -> void:
	if defense_state == DefenseState.DODGING:
		velocity = dodge_velocity
		move_and_slide()
		return

	if defense_state == DefenseState.GUARD_BROKEN:
		velocity = velocity.move_toward(Vector2.ZERO, ground_friction * delta)
		move_and_slide()
		_apply_current(delta)
		return

	var movement_locked := attack_phase == AttackPhase.WINDUP or attack_phase == AttackPhase.ACTIVE
	var direction := Vector2.ZERO
	if not movement_locked:
		direction = get_input_direction()

	var accel := ground_accel if current_surface == Surface.GROUND else ice_accel
	var friction := ground_friction if current_surface == Surface.GROUND else ice_friction
	# FLOPPY: momentum locomotion. Keep ice even slippier than floppy-ground so
	# surfaces still read differently.
	var floppy: bool = MatchConfig.floppy_mode
	if floppy:
		accel = floppy_accel if current_surface == Surface.GROUND else minf(ice_accel, floppy_accel)
		# Friction scaled by top speed (see FLOPPY_REF_SPEED) → constant glide TIME, so
		# fast dinos don't slide off the stage and slow ones still feel loose.
		var fric: float = floppy_friction * (max_speed * floppy_speed_mult) / FLOPPY_REF_SPEED
		# Ice/lava slippier than ground but PROPORTIONALLY (see floppy_ice_factor) — the
		# old minf(ice_friction, fric) floor collapsed fast dinos into an ice rink.
		friction = fric if current_surface == Surface.GROUND else fric * floppy_ice_factor

	var move_factor: float = 1.0
	if defense_state == DefenseState.BLOCKING:
		move_factor = block_move_factor
	if slow_overlap_count > 0 or timed_slow_timer > 0.0:
		move_factor *= SLOW_MOVE_FACTOR
		accel *= SLOW_ACCEL_FACTOR
	if floppy:
		move_factor *= floppy_speed_mult
	# Lugging a limp foe is heavy — your top speed sags while you carry one.
	if grabbing != null:
		move_factor *= GRAB_CARRY_SLOW

	# Bleed off knockback launch speed at a fixed rate so a big hit can't skate
	# you across an ice map. Only the speed above max_speed is affected, so it
	# never touches normal locomotion (and self-dash sets the flag false).
	if knockback_active:
		var kb_speed := velocity.length()
		if kb_speed > max_speed:
			velocity = velocity.normalized() * maxf(max_speed, kb_speed - KNOCKBACK_DECEL * delta)
		else:
			knockback_active = false

	# Self-dash lunge: bleed the launch speed at a FIXED rate so floppy's low
	# locomotion friction can't turn a heavy/special lunge into a fly-off-the-map.
	# (An incoming hit's knockback takes priority — it overrides the lunge.)
	if dash_active and not knockback_active:
		var d_speed := velocity.length()
		if d_speed > max_speed:
			velocity = velocity.normalized() * maxf(max_speed, d_speed - DASH_DECEL * delta)
		else:
			dash_active = false

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed * move_factor * powerup_speed_mult, accel * delta)
	else:
		# Released the stick: in floppy, brake harder so you plant where you aimed
		# instead of skating on (active drive above stays loose — it uses accel).
		var brake := friction * floppy_release_brake if floppy else friction
		velocity = velocity.move_toward(Vector2.ZERO, brake * delta)

	move_and_slide()
	_apply_current(delta)

# Environmental drift (e.g. White Water Falls current). Applied as a real
# displacement so it respects walls and never accumulates into the velocity.
func _apply_current(delta: float) -> void:
	if current_push != Vector2.ZERO:
		move_and_collide(current_push * delta)

# FLOPPY stage 2 — being floored. You keep the blow's momentum (and can slide off
# an edge for a ring-out, very Gang Beasts) but can't act until you scramble up.
func _process_downed(delta: float) -> void:
	down_timer -= delta
	var friction: float = floppy_friction if MatchConfig.floppy_mode else ground_friction
	if knockback_active:
		var sp := velocity.length()
		if sp > max_speed:
			velocity = velocity.normalized() * maxf(max_speed, sp - KNOCKBACK_DECEL * delta)
		else:
			knockback_active = false
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	_apply_current(delta)
	update_timers(delta)
	update_visual()
	update_sprite_animation()
	if down_timer <= 0.0:
		get_up()

func knock_down(dir: Vector2, power: float) -> void:
	# Anti-juggle: just got up, so this hit shoves you (knockback already applied)
	# but can't put you back on the floor — you get a fair beat to act.
	if knockdown_immune_timer > 0.0 and not is_downed:
		return
	if is_downed:
		down_timer = maxf(down_timer, DOWN_DURATION * 0.6)  # re-floored: top it up
		if rig != null:
			rig.topple(dir, power)
		return
	is_downed = true
	down_timer = DOWN_DURATION
	# Drop whatever you were doing — you're on the floor now.
	attack_phase = AttackPhase.IDLE
	defense_state = DefenseState.NORMAL
	update_block_bar()
	if grabbing != null:
		_drop_grab()  # can't keep holding a foe while you're being floored
	play_scene_sfx("drop_land", 0.12)
	if rig != null:
		rig.topple(dir, power)

func get_up() -> void:
	is_downed = false
	down_timer = 0.0
	invuln_timer = maxf(invuln_timer, DOWN_GETUP_INVULN)  # brief grace as you rise
	knockdown_immune_timer = DOWN_IMMUNE_AFTER           # can't be juggled straight back down

# --- FLOPPY stage 3: GRAB / carry / throw ------------------------------------

func can_grab() -> bool:
	return MatchConfig.floppy_mode \
		and not is_downed and grabbing == null and grabbed_by == null \
		and grab_cooldown <= 0.0 \
		and attack_phase == AttackPhase.IDLE \
		and defense_state == DefenseState.NORMAL

# Nearest grabbable foe within reach and roughly in front (facing). Skips
# teammates, the already-grabbed, the dodging/invulnerable, and corpses.
func _foe_in_grab_range() -> Node:
	var best: Node = null
	var best_d := GRAB_RANGE
	for other in get_parent().get_children():
		if other == self or not (other is CharacterBody2D):
			continue
		if not ("player_id" in other) or other.player_id == player_id:
			continue
		if MatchConfig.same_side(player_id, other.player_id) or not other.visible:
			continue
		if other.grabbed_by != null or other.is_falling:
			continue
		if other.invuln_timer > 0.0 or other.defense_state == DefenseState.DODGING:
			continue
		var to_foe: Vector2 = other.global_position - global_position
		var d := to_foe.length()
		if d > best_d:
			continue
		if facing.normalized().dot(to_foe.normalized()) < 0.25:  # must be in front
			continue
		best_d = d
		best = other
	return best

func begin_grab(foe: Node) -> void:
	if foe == null or not is_instance_valid(foe):
		return
	grabbing = foe
	grab_hold_timer = GRAB_MAX_HOLD
	foe._on_grabbed_by(self)
	play_scene_sfx("pickup", 0.1)

# Called on the foe when someone grabs them: go limp, drop everything, get dragged.
func _on_grabbed_by(g: Node) -> void:
	if grabbing != null:
		_drop_grab()  # you can't hold someone while you're being grabbed
	grabbed_by = g
	grab_escape = 0.0
	is_downed = false
	down_timer = 0.0
	attack_phase = AttackPhase.IDLE
	defense_state = DefenseState.NORMAL
	update_block_bar()
	velocity = Vector2.ZERO
	if rig != null:
		rig.set_held(true)

# Grabber side: tick the hold timer (auto-release if it runs out).
func _update_grab_hold(delta: float) -> void:
	var f := grabbing
	if not is_instance_valid(f) or f.grabbed_by != self:
		grabbing = null
		return
	grab_hold_timer -= delta
	if grab_hold_timer <= 0.0:
		_drop_grab()

# Grabbed side: get carried in front of the holder, limp, and mash to escape.
func _process_grabbed(delta: float) -> void:
	var g := grabbed_by
	if not is_instance_valid(g) or g.grabbing != self:
		_clear_grabbed()
		return
	# Carried at arm's/neck's length in front, but at the HOLDER's grip height, so a
	# foe dangles from Steve's mouth (high) or is held low by Gus — matching where
	# that dino grabs. Forward stays large (foes are bigger than weapons).
	var hold: Vector2 = g.global_position + g.facing.normalized() * GRAB_HOLD_DIST + Vector2(0, g.grip_offset.y)
	# Trail toward the hold point instead of snapping to it, so the limp foe swings
	# and drags behind the carrier like dead weight rather than riding rigidly.
	global_position = global_position.lerp(hold, GRAB_CARRY_LAG)
	velocity = Vector2.ZERO
	if g.facing != Vector2.ZERO:
		facing = (-g.facing).normalized()  # held foe faces its captor
	# Struggle free: humans mash any action; CPUs build escape on a timer.
	if is_cpu:
		grab_escape += GRAB_ESCAPE_CPU_RATE * delta
	else:
		for a in ["attack", "heavy", "dodge", "special", "block", "pickup", "throw"]:
			if Input.is_action_just_pressed(_action(a)):
				grab_escape += GRAB_ESCAPE_PER_MASH
	if grab_escape >= 1.0:
		_escape_grab()
		return
	update_timers(delta)
	update_visual()
	update_sprite_animation()

# RT while holding: launch the foe (big knockback -> they topple + skid off).
func throw_grabbed() -> void:
	var foe := grabbing
	grabbing = null
	grab_cooldown = GRAB_COOLDOWN
	if not is_instance_valid(foe):
		return
	var dir := facing.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	foe._released(dir * GRAB_THROW_KB, true)
	play_scene_sfx("throw", 0.12)
	# The thrower heaves the whole body forward — a big follow-through lurch sells
	# the effort of the yeet on the giving end.
	if rig != null:
		rig.connect_recoil(1.2)
	# The throw is the biggest, highest-commitment verb in floppy — give it a jolt
	# so the yeet has weight (it was the only impact moment firing no screen shake).
	# A crisp freeze-frame at the release punctuates the heave before the foe skids.
	var sr := get_tree().current_scene
	if sr and sr.has_method("shake"):
		sr.shake(15.0, 0.24)
	if sr and sr.has_method("hit_pause"):
		sr.hit_pause(0.07, 0.22)

# Hold timer expired: just let go (no launch).
func _drop_grab() -> void:
	var foe := grabbing
	grabbing = null
	grab_cooldown = GRAB_COOLDOWN
	if is_instance_valid(foe):
		foe._released(Vector2.ZERO, false)

# Foe broke free on their own.
func _escape_grab() -> void:
	var g := grabbed_by
	_clear_grabbed()
	if is_instance_valid(g):
		g.grabbing = null
		g.grab_cooldown = GRAB_COOLDOWN

# Released (thrown or dropped). `thrown` => launched hard enough to be floored.
func _released(kb: Vector2, thrown: bool) -> void:
	grabbed_by = null
	grab_escape = 0.0
	if rig != null:
		rig.set_held(false)
	if thrown:
		if knockback_resist > 0.0:
			kb *= (1.0 - knockback_resist)   # a tossed late-wave foe flies less far
		velocity = kb
		knockback_active = true
		invuln_timer = 0.0
		knock_down(kb.normalized(), kb.length() / 500.0)

# The holder vanished (died / fell) — just come free.
func _clear_grabbed() -> void:
	grabbed_by = null
	grab_escape = 0.0
	if rig != null:
		rig.set_held(false)

# Drop both sides of any grab — called when I die or fall so links never dangle.
func _release_all_grabs() -> void:
	if is_instance_valid(grabbing):
		grabbing._clear_grabbed()
	grabbing = null
	if is_instance_valid(grabbed_by):
		grabbed_by.grabbing = null
		grabbed_by.grab_cooldown = GRAB_COOLDOWN
	grabbed_by = null

# --- Attack ---

func start_attack(heavy: bool = false) -> void:
	knockback_active = false  # self-dash lunges decay via dash_active, not knockback
	dash_active = false
	current_is_special = false
	current_is_heavy = heavy
	if heavy:
		current_attack_damage = heavy_damage
		current_attack_knockback = heavy_knockback
		current_attack_active = heavy_active
		current_attack_recovery = heavy_recovery
		current_attack_hitbox_size = heavy_hitbox_size
		current_attack_hitbox_offset = heavy_hitbox_offset
		attack_timer = heavy_windup
		if heavy_self_dash > 0.0:
			velocity = facing * heavy_self_dash
			dash_active = true
	else:
		current_attack_damage = attack_damage
		current_attack_knockback = attack_knockback
		current_attack_active = attack_active
		current_attack_recovery = attack_recovery
		current_attack_hitbox_size = attack_hitbox_size
		current_attack_hitbox_offset = attack_hitbox_offset
		attack_timer = attack_windup
	# Active weapon modifies light + heavy (the signature special is unaffected).
	current_attack_damage = int(round(current_attack_damage * wpn_dmg * powerup_dmg_mult))
	current_attack_knockback *= wpn_kb
	current_attack_hitbox_offset += wpn_range
	current_attack_recovery *= wpn_recovery
	attack_timer *= wpn_windup
	attack_phase = AttackPhase.WINDUP
	attack_phase_dur = maxf(attack_timer, 0.001)
	play_scene_sfx("swing", 0.08)

func _refresh_weapon() -> void:
	var id: String = weapons[active_weapon] if active_weapon < weapons.size() else "fists"
	var w: Dictionary = MatchConfig.WEAPONS.get(id, {}) if MatchConfig else {}
	wpn_dmg = w.get("dmg", 1.0)
	wpn_kb = w.get("kb", 1.0)
	wpn_range = w.get("range", 0)
	wpn_windup = w.get("windup", 1.0)
	wpn_recovery = w.get("recovery", 1.0)
	wpn_projectile = w.get("projectile", false)
	# Rebuild the held visual: baked painterly sprite when one exists, the old
	# polygon silhouette otherwise. Fists = nothing in hand.
	if weapon_visual != null:
		weapon_visual.queue_free()
		weapon_visual = null
	var tex: Texture2D = MatchConfig.weapon_texture(id) if MatchConfig else null
	if tex != null:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# Shift along +X so the grip end sits at the hand, not the midpoint.
		sprite.offset = Vector2(tex.get_width() * 0.5 - 8.0, 0)
		weapon_visual = sprite
	else:
		var shape: Dictionary = MatchConfig.weapon_shape(id) if MatchConfig else {}
		var poly: PackedVector2Array = shape.get("poly", PackedVector2Array())
		if poly.size() > 0:
			var visual := Polygon2D.new()
			visual.polygon = poly
			visual.color = shape.get("color", Color.WHITE)
			weapon_visual = visual
	if weapon_visual != null:
		weapon_visual.z_index = 1
		add_child(weapon_visual)

func _active_weapon_id() -> String:
	return weapons[active_weapon] if active_weapon < weapons.size() else "fists"

# Point active_weapon at the first real (non-fists) slot. CPUs call this so they
# spawn already wielding their loadout weapon instead of waiting for a swap input.
func _equip_default_weapon() -> void:
	for i in range(weapons.size()):
		if weapons[i] != "fists":
			active_weapon = i
			break
	_refresh_weapon()

# Throw (RT): hurl the active weapon as a spinning projectile, then revert that
# slot to fists. Lands harder than a swing with the same weapon (THROW_*_MULT),
# but can sail off the platform edge and be lost (see weapon_item.gd).
func throw_weapon() -> void:
	var id := _active_weapon_id()
	if id == "fists":
		return
	var base_dmg := int(round(attack_damage * wpn_dmg))
	var dmg := int(round(base_dmg * THROW_DAMAGE_MULT))
	var kb := attack_knockback * wpn_kb * THROW_KB_MULT
	_spawn_thrown_weapon(id, dmg, kb)
	weapons[active_weapon] = "fists"
	_refresh_weapon()
	play_scene_sfx("throw", 0.06)

func _spawn_thrown_weapon(id: String, dmg: int, kb: float) -> void:
	var item := Area2D.new()
	item.set_script(preload("res://scripts/weapon_item.gd"))
	item.weapon_id = id
	item.travel_velocity = facing * THROW_SPEED
	item.damage = dmg
	item.knockback_force = kb
	item.source = self
	get_tree().current_scene.add_child(item)
	item.global_position = global_position + facing * 40.0 + Vector2(0, -6)
	item.rotation = facing.angle()

# Pickup (LT): grab the nearest weapon resting on the ground within reach and
# equip it (filling a free fists slot, or replacing the active one).
func try_pickup() -> void:
	var best: Node = null
	var best_d := PICKUP_RADIUS * PICKUP_RADIUS
	for item in get_tree().get_nodes_in_group("weapon_pickups"):
		if not is_instance_valid(item) or not item.is_grounded():
			continue
		var d: float = global_position.distance_squared_to(item.global_position)
		if d < best_d:
			best_d = d
			best = item
	if best == null:
		return
	var slot := _pickup_slot()
	weapons[slot] = best.weapon_id
	active_weapon = slot
	best.consume()
	_refresh_weapon()
	play_scene_sfx("pickup", 0.08)

# Prefer dropping a pickup into an empty (fists) slot; otherwise the active one.
func _pickup_slot() -> int:
	for i in range(weapons.size()):
		if weapons[i] == "fists":
			return i
	return active_weapon

func _swap_weapon() -> void:
	if weapons.size() < 2:
		return
	active_weapon = (active_weapon + 1) % weapons.size()
	_refresh_weapon()
	play_scene_sfx("block", 0.12)  # quick clink

func weapon_name() -> String:
	var id: String = weapons[active_weapon] if active_weapon < weapons.size() else "fists"
	var w: Dictionary = MatchConfig.WEAPONS.get(id, {}) if MatchConfig else {}
	return w.get("display_name", "")

# Signature move. Reuses the WINDUP→ACTIVE→RECOVERY attack flow; special_type
# drives the few unique behaviors (lifesteal in try_hit, screech AoE in
# update_attack). Cooldown-gated by can_special().
func start_special() -> void:
	special_cooldown_timer = special_cooldown
	knockback_active = false
	dash_active = false
	current_is_special = true
	current_is_heavy = false
	current_attack_damage = special_damage
	current_attack_knockback = special_knockback
	current_attack_active = special_active
	current_attack_recovery = special_recovery
	current_attack_hitbox_size = special_hitbox_size
	current_attack_hitbox_offset = special_hitbox_offset
	attack_timer = special_windup
	if special_self_dash > 0.0:
		velocity = facing * special_self_dash
		dash_active = true
	attack_phase = AttackPhase.WINDUP
	attack_phase_dur = maxf(attack_timer, 0.001)
	play_scene_sfx("swing", 0.06)

# Held-weapon swing pose for the current attack phase. Returns Vector2(angle_deg,
# reach_px): angle is the offset added to the facing angle (+ = chopping forward/
# down), reach is a small forward thrust on the active frame. Windup cocks it back
# overhead, active whips it down through the arc, recovery eases it home.
func _weapon_swing() -> Vector2:
	var p := clampf(1.0 - attack_timer / attack_phase_dur, 0.0, 1.0)
	match attack_phase:
		AttackPhase.WINDUP:
			var e := 1.0 - (1.0 - p) * (1.0 - p)         # ease-out: snap up, then hold cocked
			return Vector2(-98.0 * e, -2.0 * e)
		AttackPhase.ACTIVE:
			return Vector2(lerpf(-98.0, 62.0, p), sin(p * PI) * 12.0)  # whip down + thrust
		AttackPhase.RECOVERY:
			var e := 1.0 - (1.0 - p) * (1.0 - p)
			return Vector2(lerpf(62.0, 0.0, e), 0.0)     # settle back to the held rest pose
		_:
			return Vector2.ZERO

func update_attack(delta: float) -> void:
	if attack_phase == AttackPhase.ACTIVE:
		for body in hitbox.get_overlapping_bodies():
			try_hit(body)

	if attack_phase == AttackPhase.IDLE:
		return
	attack_timer -= delta
	if attack_timer > 0.0:
		return

	match attack_phase:
		AttackPhase.WINDUP:
			attack_phase = AttackPhase.ACTIVE
			attack_timer = current_attack_active
			attack_phase_dur = maxf(current_attack_active, 0.001)
			if current_is_special and (special_type == "screech" or special_type == "stomp"):
				_do_screech()
			elif current_is_special and special_type == "tail_smash":
				_do_tail_smash()  # FRANK: shockwave in every direction, no safe side
			elif current_is_special and special_type == "spikes":
				_spawn_spike_volley()
			elif not current_is_special and wpn_projectile:
				_spawn_projectile()  # bow & other ranged weapons fire instead of swinging
			elif current_is_heavy and heavy_attack_type == "projectile":
				_spawn_projectile()
			else:
				if hitbox_shape.shape is RectangleShape2D:
					hitbox_shape.shape.size = current_attack_hitbox_size
				hitbox_shape.disabled = false
				hitbox_visual.visible = show_hitbox_debug
				hit_targets_this_swing.clear()
				_spawn_attack_swipe()
		AttackPhase.ACTIVE:
			attack_phase = AttackPhase.RECOVERY
			attack_timer = current_attack_recovery
			attack_phase_dur = maxf(current_attack_recovery, 0.001)
			hitbox_shape.disabled = true
			hitbox_visual.visible = false
		AttackPhase.RECOVERY:
			attack_phase = AttackPhase.IDLE
			attack_timer = 0.0
			current_is_special = false

func try_hit(body: Node) -> void:
	if body == self:
		return
	if body in hit_targets_this_swing:
		return
	if not body.has_method("take_damage"):
		return
	hit_targets_this_swing.append(body)
	var dmg: int = current_attack_damage
	# EXECUTIONER: extra damage when the foe is already low.
	if run_execute > 0.0 and "hp" in body and "max_hp" in body and body.max_hp > 0:
		if float(body.hp) <= 0.35 * float(body.max_hp):
			dmg = int(round(dmg * (1.0 + run_execute)))
	var kb: Vector2 = facing * current_attack_knockback
	if beast_active:
		dmg = int(round(dmg * BEAST_DMG_MULT))
		kb *= BEAST_KB_MULT
	body.take_damage(dmg, kb, self)
	# Attacker follow-through: our own torso lurches into the blow so a clean
	# connect has weight on the giving end, not just the receiving one.
	if rig != null:
		rig.connect_recoil(float(dmg) / 24.0)
	var root := get_tree().current_scene
	if root and root.has_method("add_dp"):
		root.add_dp(player_id, 10)
	# Lifesteal stacks the chomp special's innate drain with the VAMPIRE run upgrade.
	var lifesteal: float = run_lifesteal
	if current_is_special and special_lifesteal > 0.0:
		lifesteal += special_lifesteal
	if lifesteal > 0.0:
		hp = min(max_hp, hp + int(dmg * lifesteal))
		update_hp_bar()
	# DASH CLAW: landing the rake renews the hunt — most of the cooldown refunds.
	if current_is_special and special_type == "dash_claw":
		special_cooldown_timer = minf(special_cooldown_timer, special_cooldown * 0.35)

# --- Defense actions ---

func start_block() -> void:
	defense_state = DefenseState.BLOCKING

func end_block() -> void:
	if defense_state == DefenseState.BLOCKING:
		defense_state = DefenseState.NORMAL

func start_dodge() -> void:
	var dir := get_input_direction()
	if dir == Vector2.ZERO:
		dir = facing
	defense_state = DefenseState.DODGING
	dodge_velocity = dir * (dodge_distance / dodge_duration)
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	afterimage_timer = 0.0
	_spawn_dust(-dir)  # kick a puff of dust off the ground, opposite the dash
	block_durability = max(0.0, block_durability - dodge_block_cost)
	update_block_bar()
	# Cancel any in-progress attack so dodge takes over cleanly
	attack_phase = AttackPhase.IDLE
	attack_timer = 0.0
	current_is_special = false
	hitbox_shape.disabled = true
	hitbox_visual.visible = false
	play_scene_sfx("dodge", 0.1)

func update_dodge(delta: float) -> void:
	if defense_state == DefenseState.DODGING:
		dodge_timer -= delta
		afterimage_timer -= delta
		if afterimage_timer <= 0.0 and sprite.visible and sprite.sprite_frames != null:
			_spawn_afterimage()
			afterimage_timer = AFTERIMAGE_INTERVAL
		if dodge_timer <= 0.0:
			defense_state = DefenseState.NORMAL
			dodge_velocity = Vector2.ZERO

func _spawn_afterimage() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # match the painterly sprite
	ghost.global_position = global_position + Vector2(0, sprite_offset_y)
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(dino_color.r, dino_color.g, dino_color.b, 0.55)
	ghost.z_index = -1
	get_tree().current_scene.add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ghost.queue_free)

# Impact burst at the contact point: a soft flash ring + a few bright shards
# spraying along the hit. Cosmetic only (complements the painterly fighters);
# scaled by damage, beefier on a KO. `dir` is the knockback heading (spray way).
func _spawn_hit_burst(pos: Vector2, dir: Vector2, dmg: int, lethal: bool) -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var sc: float = clampf(0.6 + dmg * 0.02, 0.6, 1.8) * (1.7 if lethal else 1.0)
	var col: Color = Color(1.0, 0.86, 0.4) if lethal else Color(1.0, 0.96, 0.72)
	# Soft expanding flash ring.
	var flash := Polygon2D.new()
	var ring := PackedVector2Array()
	for i in range(12):
		var a: float = TAU * i / 12.0
		ring.append(Vector2(cos(a), sin(a)) * 16.0)
	flash.polygon = ring
	flash.color = Color(col.r, col.g, col.b, 0.5)
	flash.position = pos
	flash.z_index = 40
	flash.scale = Vector2.ONE * 0.3 * sc
	root.add_child(flash)
	var ft := flash.create_tween()
	ft.tween_property(flash, "scale", Vector2.ONE * sc, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ft.parallel().tween_property(flash, "modulate:a", 0.0, 0.18)
	ft.tween_callback(flash.queue_free)
	# Shards spraying along the hit.
	for i in range(5 + (4 if lethal else 0)):
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(8, 0), Vector2(-3, 2)])
		shard.color = col
		shard.position = pos
		shard.z_index = 41
		var ang: float = dir.angle() + randf_range(-0.9, 0.9)
		shard.rotation = ang
		shard.scale = Vector2.ONE * sc
		root.add_child(shard)
		var dest: Vector2 = pos + Vector2(cos(ang), sin(ang)) * randf_range(24.0, 50.0) * sc
		var st := shard.create_tween()
		st.tween_property(shard, "position", dest, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(shard, "scale", Vector2.ZERO, 0.2)
		st.parallel().tween_property(shard, "modulate:a", 0.0, 0.2)
		st.tween_callback(shard.queue_free)

# KO flourish: a bright shockwave ring snapping outward from the fallen dino, so
# a KO reads as a climactic beat (on top of the existing shake + freeze + burst).
func _spawn_ko_flourish() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var ring := Line2D.new()
	var pts := PackedVector2Array()
	for i in range(33):
		var a: float = TAU * i / 32.0
		pts.append(Vector2(cos(a), sin(a)) * 30.0)
	ring.points = pts
	ring.closed = true
	ring.width = 6.0
	ring.default_color = Color(1, 1, 1, 0.9)
	ring.position = global_position + Vector2(0, sprite_offset_y * 0.5)
	ring.z_index = 45
	ring.scale = Vector2(0.2, 0.2)
	root.add_child(ring)
	var t := ring.create_tween()
	t.tween_property(ring, "scale", Vector2(2.3, 2.3), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(ring, "modulate:a", 0.0, 0.3)
	t.parallel().tween_property(ring, "width", 1.0, 0.3)
	t.tween_callback(ring.queue_free)

# Dodge dust: a few soft puffs kicked off the ground at the feet, spraying along
# `dir`, so the dash reads as an explosive push-off. Cosmetic.
func _spawn_dust(dir: Vector2) -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var ring := PackedVector2Array()
	for j in range(8):
		var a: float = TAU * j / 8.0
		ring.append(Vector2(cos(a), sin(a)) * 5.0)
	for i in range(4):
		var puff := Polygon2D.new()
		puff.polygon = ring
		puff.color = Color(0.82, 0.78, 0.68, 0.45)
		puff.position = global_position + Vector2(randf_range(-6, 6), randf_range(-4, 6))
		puff.z_index = 1
		root.add_child(puff)
		var dest: Vector2 = puff.position + dir.rotated(randf_range(-0.6, 0.6)) * randf_range(14.0, 30.0)
		var t := puff.create_tween()
		t.tween_property(puff, "position", dest, 0.3).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(puff, "scale", Vector2.ONE * 2.2, 0.3)
		t.parallel().tween_property(puff, "modulate:a", 0.0, 0.3)
		t.tween_callback(puff.queue_free)

# [experiment] Grant a map power-up: instant heal, or a temp speed/damage buff
# with a pulsing aura. Temp buffs revert via powerup_timer in update_timers().
func apply_powerup(kind: String) -> void:
	match kind:
		"heal":
			hp = min(max_hp, hp + 35)
			update_hp_bar()
			_spawn_hit_burst(global_position + Vector2(0, sprite_offset_y * 0.5), Vector2.UP, 18, false)
		"speed":
			powerup_speed_mult = 1.4
			powerup_timer = 7.0
			_set_powerup_aura(Color(0.4, 0.95, 1.0))
		"power":
			powerup_dmg_mult = 1.35
			powerup_timer = 7.0
			_set_powerup_aura(Color(1.0, 0.55, 0.3))

func _end_powerup() -> void:
	powerup_speed_mult = 1.0
	powerup_dmg_mult = 1.0
	powerup_timer = 0.0
	if is_instance_valid(powerup_aura):
		powerup_aura.queue_free()
	powerup_aura = null

func _set_powerup_aura(col: Color) -> void:
	if is_instance_valid(powerup_aura):
		powerup_aura.queue_free()
	var aura := Polygon2D.new()
	var ring := PackedVector2Array()
	for j in range(16):
		var a: float = TAU * j / 16.0
		ring.append(Vector2(cos(a), sin(a)) * 22.0)
	aura.polygon = ring
	aura.color = Color(col.r, col.g, col.b, 0.28)
	aura.position = Vector2(0, sprite_offset_y * 0.4)
	aura.z_index = -1
	add_child(aura)
	powerup_aura = aura
	var tw := aura.create_tween().set_loops()
	tw.tween_property(aura, "scale", Vector2.ONE * 1.18, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(aura, "scale", Vector2.ONE * 0.9, 0.5).set_trans(Tween.TRANS_SINE)

# [experiment] Landed a clean hit — extend the combo, pop the counter at 2+.
func register_combo_hit() -> void:
	combo_count += 1
	combo_timer = 1.6
	if combo_count >= 2:
		_show_combo(combo_count)

func _show_combo(n: int) -> void:
	# Parent to the dino so it inherits the world transform (a Control floats
	# reliably in the 2D world this way, and rides along above the head).
	var lbl := Label.new()
	lbl.text = "%d HIT!" % n
	lbl.add_theme_font_size_override("font_size", 22 + mini(n, 6) * 3)
	var hot: float = clampf(float(n - 2) / 6.0, 0.0, 1.0)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95 - hot * 0.55, 0.3))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0, 0.95))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(120, 32)
	lbl.position = Vector2(-60, sprite_offset_y - 78.0)
	lbl.pivot_offset = Vector2(60, 16)
	lbl.z_index = 46
	lbl.top_level = true  # ignore the dino's flip/scale; use our own world placement
	lbl.global_position = global_position + Vector2(-60, sprite_offset_y - 78.0)
	lbl.scale = Vector2(0.4, 0.4)
	add_child(lbl)
	var ty: float = lbl.global_position.y
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "global_position:y", ty - 20.0, 0.7)
	tw.tween_interval(0.4)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.3)
	tw.tween_callback(lbl.queue_free)

func guard_break() -> void:
	defense_state = DefenseState.GUARD_BROKEN
	guard_break_timer = guard_break_duration
	block_durability = 0.0
	update_block_bar()
	play_scene_sfx("guard_break", 0.05)
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_method("on_guard_break"):
		scene_root.on_guard_break()

func update_guard_break(delta: float) -> void:
	if defense_state == DefenseState.GUARD_BROKEN:
		guard_break_timer -= delta
		if guard_break_timer <= 0.0:
			defense_state = DefenseState.NORMAL

func update_block_regen(delta: float) -> void:
	if defense_state == DefenseState.BLOCKING or defense_state == DefenseState.GUARD_BROKEN:
		return
	if block_durability < max_block:
		block_durability = min(max_block, block_durability + block_regen * delta)
		update_block_bar()

# --- Damage ---

func take_damage(amount: int, knockback: Vector2, source: Node = null) -> void:
	if is_falling:
		return
	# Friendly fire is off: a teammate's hit (melee, AoE, projectile, thrown weapon)
	# does nothing — every damage path funnels through here, so this one check covers
	# them all.
	if source != null and "player_id" in source and MatchConfig.same_side(player_id, source.player_id):
		return
	if invuln_timer > 0.0:
		return
	if defense_state == DefenseState.DODGING:
		return

	# Knockback resistance (gauntlet foe scaling): absorb a fraction of the shove so
	# late-wave enemies are harder to ring out. Applied once here so every downstream
	# use — velocity, the knock_down threshold, block paths — sees the reduced blow.
	if knockback_resist > 0.0:
		knockback *= (1.0 - knockback_resist)

	if source != null:
		last_damaged_by = source
	# Baseline flash for any connecting hit (blocked hits return before the clean
	# path below, so they keep this soft version); a clean hit overrides it scaled.
	hit_flash_timer = 0.07
	hit_flash_strength = 0.0
	# A connecting hit (dodge/invuln/falling already returned above) — let the scene
	# react, e.g. BOMB TAG passes the bomb to whoever just got struck.
	if source != null:
		var sr := get_tree().current_scene
		if sr and sr.has_method("on_strike"):
			sr.on_strike(source, self)

	if defense_state == DefenseState.BLOCKING:
		play_scene_sfx("block", 0.08)
	else:
		var sfx_name: String = "hit_claw"
		if source != null and "hit_sfx_name" in source:
			sfx_name = source.hit_sfx_name
		play_scene_sfx(sfx_name, 0.1)

	if defense_state == DefenseState.BLOCKING:
		# NECK WHIP guard-crush: the whip chews through block durability, so
		# turtling against Steve cracks the guard open fast.
		var crush := 1.0
		if source != null and "special_type" in source and "current_is_special" in source \
				and source.current_is_special and source.special_type == "neck_whip":
			crush = 2.0
		var absorbed: float = min(block_durability, float(amount) * crush)
		block_durability -= absorbed
		var remaining: float = float(amount) - absorbed / crush
		velocity += knockback * block_knockback_factor
		knockback_active = true
		update_block_bar()
		if block_durability <= 0.0:
			guard_break()  # fires its own guard-break juice
			if remaining > 0.0:
				if not ringout_only:
					hp -= int(remaining)
				velocity += knockback * (1.0 - block_knockback_factor)
				update_hp_bar()
				if hp <= 0 and not ringout_only:
					die()
					return
		else:
			notify_blocked(amount)
		invuln_timer = hitstun_invuln
		return

	if not ringout_only:
		hp -= amount
	# HEADBUTT armor: mid-charge Gus takes the damage but can't be shoved off course.
	var shoved := not (current_is_special and special_type == "headbutt" and attack_phase != AttackPhase.IDLE)
	if shoved:
		velocity += knockback
		knockback_active = true
	notify_hit(amount)
	# Impact flash scales with the blow so a jab and a haymaker read differently:
	# a clean hit flashes brighter + a touch longer the harder it lands.
	hit_flash_timer = clampf(0.08 + float(amount) * 0.003, 0.08, 0.17)
	hit_flash_strength = clampf((float(amount) - 10.0) / 35.0, 0.0, 1.0)
	# Motion-sheet flinch: long enough to read as a stagger, harder hits hold longer.
	hit_anim_timer = clampf(0.18 + float(amount) * 0.004, 0.18, 0.32)
	# Impact burst at the contact point (cosmetic): spray along the knockback.
	var kdir: Vector2 = knockback.normalized() if knockback.length() > 1.0 else facing
	_spawn_hit_burst(global_position - kdir * 16.0 + Vector2(0, sprite_offset_y * 0.5), kdir, amount, hp <= 0 and not ringout_only)
	# Limb flail: kick the rig's springs so head/legs/tail react to the blow.
	# Divisor is the single knob for how violently everyone reels — lower = more
	# whip (per-dino weight still reads through each profile's own hit_* values).
	if rig != null:
		rig.hit(kdir, float(amount) / 14.0)
	# FLOPPY stage 2: a hard enough shove takes your feet out from under you. (Not
	# on a lethal hit — that path goes to die() below.)
	var lethal := hp <= 0 and not ringout_only
	if MatchConfig.floppy_mode and shoved and not lethal and knockback.length() >= DOWN_KB_THRESHOLD:
		knock_down(kdir, knockback.length() / 500.0)
	combo_count = 0  # taking a clean hit breaks your own combo
	if source != null and source != self and source.has_method("register_combo_hit"):
		source.register_combo_hit()
	invuln_timer = hitstun_invuln
	update_hp_bar()
	# SPIKED HIDE: punish the attacker with a fraction of the damage they dealt.
	if run_thorns > 0.0 and source != null and source != self and source.has_method("take_reflect"):
		source.take_reflect(int(round(float(amount) * run_thorns)))
	if hp <= 0 and not ringout_only:
		die()

# Environmental damage tick (e.g. Laughing Lava). Bypasses block/invuln since
# you can't guard against fire, but dodge i-frames still let you slip a tick.
# Returns true if this tick was lethal so the arena can credit the KO.
func apply_burn(amount: int, knockback: Vector2) -> bool:
	if defense_state == DefenseState.DODGING:
		return false
	if not ringout_only:
		hp -= amount
	velocity += knockback
	knockback_active = true
	hit_flash_timer = 0.08
	update_hp_bar()
	return hp <= 0

# SPIKED HIDE reflection: chip damage with no knockback/invuln/recursion. Foes
# don't carry thorns, so a reflected hit can't bounce back and loop.
func take_reflect(amount: int) -> void:
	if amount <= 0 or is_falling:
		return
	if not ringout_only:
		hp -= amount
	hit_flash_timer = 0.08
	update_hp_bar()
	if hp <= 0 and not ringout_only:
		die()

func notify_hit(damage: int) -> void:
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_method("on_hit_landed"):
		scene_root.on_hit_landed(damage)

func notify_blocked(damage: int) -> void:
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_method("on_hit_blocked"):
		scene_root.on_hit_blocked(damage)

func _spawn_projectile() -> void:
	_make_spike(facing, current_attack_damage, current_attack_knockback)

# Stegosaurus Shooting Spikes: a 3-spike fan.
func _spawn_spike_volley() -> void:
	# Muzzle flash + a light kick so loosing the volley reads as a firm launch.
	_spawn_hit_burst(global_position + facing * 42.0 + Vector2(0, sprite_offset_y * 0.5), facing, 10, false)
	var sr := get_tree().current_scene
	if sr and sr.has_method("shake"):
		sr.shake(6.0, 0.10)
	for ang in [-0.26, 0.0, 0.26]:
		_make_spike(facing.rotated(ang), special_damage, special_knockback)

func _make_spike(dir: Vector2, dmg: int, kb: float) -> void:
	var projectile := Area2D.new()
	projectile.set_script(preload("res://scripts/spike_projectile.gd"))

	var visual := Polygon2D.new()
	visual.color = projectile_color
	visual.polygon = PackedVector2Array([
		Vector2(-14, 0), Vector2(0, -6), Vector2(14, 0), Vector2(0, 6)
	])
	projectile.add_child(visual)

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 12)
	shape_node.shape = shape
	projectile.add_child(shape_node)

	projectile.global_position = global_position + dir * 50.0
	projectile.rotation = dir.angle()
	projectile.travel_velocity = dir * projectile_speed
	projectile.damage = dmg
	projectile.knockback_force = kb
	projectile.lifetime = projectile_lifetime
	projectile.source = self

	get_tree().current_scene.add_child(projectile)

# Pterodactyl Paralyzing Screech: damage + shove + a timed slow (and dodge lock)
# on every opponent within special_radius, plus an expanding ring for feedback.
func _do_screech() -> void:
	_do_radial_special(special_slow_duration, Color(0.75, 0.55, 1.0, 0.4))

# FRANK's tail smash: a shockwave through the ground in every direction —
# sneaking up behind him is exactly as dangerous as standing in front.
func _do_tail_smash() -> void:
	_do_radial_special(0.0, Color(0.82, 0.62, 0.35, 0.45))

# Shared radial special: damage + outward knockback to every foe within
# special_radius; slow_duration > 0 also screech-slows them.
func _do_radial_special(slow_duration: float, ring_color: Color) -> void:
	for other in get_parent().get_children():
		if other == self or not (other is CharacterBody2D):
			continue
		if not ("player_id" in other) or other.player_id == player_id:
			continue
		if not other.visible:
			continue
		var to_other: Vector2 = other.global_position - global_position
		var d := to_other.length()
		if d > special_radius:
			continue
		var dir := to_other / d if d > 0.01 else Vector2.RIGHT
		if other.has_method("take_damage"):
			other.take_damage(special_damage, dir * special_knockback, self)
		if slow_duration > 0.0 and other.has_method("apply_screech"):
			other.apply_screech(slow_duration)
	# The AOE boom lands with weight whether or not it caught anyone: a solid
	# shake + a crisp freeze-frame punctuate the shockwave.
	var sr := get_tree().current_scene
	if sr:
		if sr.has_method("shake"):
			sr.shake(16.0, 0.28)
		if sr.has_method("hit_pause"):
			sr.hit_pause(0.06, 0.32)
	_spawn_radial_ring(ring_color)

# Called on a dino caught in a screech: slows it + locks dodge for the duration.
func apply_screech(duration: float) -> void:
	timed_slow_timer = maxf(timed_slow_timer, duration)

func _spawn_radial_ring(color: Color) -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var center := global_position
	# 1) Coloured shock FILL disc that snaps out to full radius and fades.
	var fill := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(32):
		var a := TAU * i / 32.0
		pts.append(Vector2(cos(a), sin(a)) * special_radius)
	fill.polygon = pts
	fill.color = color
	fill.global_position = center
	fill.scale = Vector2(0.15, 0.15)
	fill.z_index = -1
	root.add_child(fill)
	var ft := fill.create_tween()
	ft.tween_property(fill, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ft.parallel().tween_property(fill, "modulate:a", 0.0, 0.28)
	ft.tween_callback(fill.queue_free)
	# 2) Bright leading-edge RING snapping outward (tapering Line2D) -- the crack.
	var edge := Line2D.new()
	var ep := PackedVector2Array()
	for i in range(41):
		var a := TAU * i / 40.0
		ep.append(Vector2(cos(a), sin(a)) * special_radius)
	edge.points = ep
	edge.closed = true
	edge.width = 7.0
	edge.default_color = Color(1, 1, 1, 0.9)
	edge.global_position = center
	edge.scale = Vector2(0.15, 0.15)
	edge.z_index = 30
	root.add_child(edge)
	var et := edge.create_tween()
	et.tween_property(edge, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	et.parallel().tween_property(edge, "modulate:a", 0.0, 0.30)
	et.parallel().tween_property(edge, "width", 1.5, 0.24)
	et.tween_callback(edge.queue_free)
	# 3) Grit: dust shards flung outward around the perimeter for weight.
	for i in range(10):
		var a := TAU * i / 10.0 + randf_range(-0.15, 0.15)
		var d := Vector2(cos(a), sin(a))
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(7, 0), Vector2(-3, 2)])
		shard.color = Color(color.r, color.g, color.b, 0.9)
		shard.global_position = center + d * (special_radius * 0.35)
		shard.rotation = a
		shard.z_index = 31
		root.add_child(shard)
		var st := shard.create_tween()
		st.tween_property(shard, "global_position", center + d * special_radius, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(shard, "scale", Vector2.ZERO, 0.26)
		st.parallel().tween_property(shard, "modulate:a", 0.0, 0.26)
		st.tween_callback(shard.queue_free)

# A sweeping slash arc when a melee attack goes active. Shape/size/colour/speed
# differ by attack kind so light, heavy, and each special read distinctly.
func _spawn_attack_swipe() -> void:
	if current_is_special:
		match special_type:
			"dash_claw":  # three fanned claw rakes
				for k in range(3):
					_spawn_swipe(Color(0.5, 0.95, 1.0, 0.85), 48.0, 6.0, 55.0, 0.18, 42.0, (k - 1) * 18.0)
			"chomp":
				_spawn_swipe(Color(1.0, 0.45, 0.4, 0.85), 60.0, 22.0, 95.0, 0.20, 70.0)
			"headbutt":
				_spawn_swipe(Color(1.0, 0.9, 0.5, 0.85), 72.0, 26.0, 110.0, 0.24, 88.0)
			"neck_whip":  # long, wide green sweep
				_spawn_swipe(Color(0.55, 0.9, 0.55, 0.85), 80.0, 18.0, 150.0, 0.28, 120.0)
			"tail_smash":  # big brown close smash
				_spawn_swipe(Color(0.82, 0.62, 0.35, 0.9), 64.0, 30.0, 130.0, 0.22, 100.0)
			_:
				_spawn_swipe(Color(0.85, 0.7, 1.0, 0.8), 60.0, 18.0, 90.0, 0.20, 70.0)
	elif current_is_heavy:  # big slow wind-up swing
		_spawn_swipe(Color(1.0, 0.78, 0.35, 0.8), 72.0, 24.0, 108.0, 0.26, 88.0)
	else:  # quick light flick
		_spawn_swipe(Color(0.95, 0.97, 1.0, 0.75), 50.0, 14.0, 70.0, 0.15, 55.0)

func _spawn_swipe(color: Color, radius: float, thickness: float, span_deg: float, dur: float, sweep_deg: float, offset_deg: float = 0.0) -> void:
	var arc := Polygon2D.new()
	var span := deg_to_rad(span_deg)
	var pts := PackedVector2Array()
	var steps := 10
	for i in range(steps + 1):  # outer edge
		var a := -span * 0.5 + span * i / steps
		pts.append(Vector2(cos(a), sin(a)) * radius)
	for i in range(steps + 1):  # inner edge, back the other way
		var a := span * 0.5 - span * i / steps
		pts.append(Vector2(cos(a), sin(a)) * (radius - thickness))
	arc.polygon = pts
	arc.color = color
	arc.global_position = global_position
	arc.rotation = facing.angle() + deg_to_rad(offset_deg) - deg_to_rad(sweep_deg) * 0.5
	arc.z_index = 1
	get_tree().current_scene.add_child(arc)
	var tw := arc.create_tween()
	tw.tween_property(arc, "rotation", arc.rotation + deg_to_rad(sweep_deg), dur)
	tw.parallel().tween_property(arc, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(arc.queue_free)

func play_scene_sfx(sound_name: String, pitch_var: float = 0.05) -> void:
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_method("play_sfx"):
		scene_root.play_sfx(sound_name, pitch_var)

# --- Ring-out fall ---

# Begin a ring-out. main.gd calls this when the dino crosses the island boundary
# (instead of an instant respawn) and owns the kill credit (ringout_killer).
# go_up = launched off the TOP (spiral into the sky, recoverable by mashing);
# otherwise the dino tumbles off the bottom (a clean KO). center_y feeds the
# height-based shrink/fade of the sky launch.
func begin_ringout(go_up: bool = false, center_y: float = 360.0) -> void:
	if is_falling:
		return
	is_falling = true
	_release_all_grabs()  # don't drag a grab link off the edge
	is_downed = false
	fall_up = go_up
	fall_center_y = center_y
	fall_timer = SKY_MAX_TIME if go_up else FALL_DURATION
	spiral_angle = 0.0
	# Off the field: can't be hit, can't hit, no lingering states.
	invuln_timer = FALL_DURATION + 1.0
	attack_phase = AttackPhase.IDLE
	attack_timer = 0.0
	defense_state = DefenseState.NORMAL
	knockback_active = false
	current_push = Vector2.ZERO
	# Deferred: a KO can fire from inside a physics collision callback (e.g. a
	# weapon-item pickup), and the server forbids toggling shapes mid-flush.
	hitbox_shape.set_deferred("disabled", true)
	hitbox_visual.visible = false
	if weapon_visual:
		weapon_visual.visible = false
	velocity.y = -SKY_INITIAL_VY if go_up else maxf(velocity.y, FALL_INITIAL_VY)

func _process_fall(delta: float) -> void:
	if fall_up:
		_process_sky_launch(delta)
		return
	# Plain drop off the bottom — not recoverable.
	velocity.y += FALL_GRAVITY * delta
	global_position += velocity * delta
	rotation += FALL_SPIN * delta
	scale = scale.move_toward(Vector2(0.35, 0.35), delta * 1.1)
	modulate.a = clampf(fall_timer / FALL_DURATION, 0.0, 1.0)  # fade as it drops
	fall_timer -= delta
	if fall_timer <= 0.0:
		_finish_ringout()

# Sucked into the sky: constant upward pull + a swirl. Mashing kicks the dino
# back down; claw back into the safe zone to recover, or escape off the top = KO.
func _process_sky_launch(delta: float) -> void:
	velocity.y -= SKY_PULL * delta
	spiral_angle += SKY_SPIRAL_SPEED * delta
	velocity.x = sin(spiral_angle) * SKY_SPIRAL_AMP
	if _ringout_mash_pressed():
		velocity.y += MASH_BOOST
	global_position += velocity * delta
	rotation += FALL_SPIN * delta
	# Shrink + fade the higher it gets; mashing back down restores it.
	var span: float = maxf(fall_center_y - SKY_ESCAPE_Y, 1.0)
	var t: float = clampf((fall_center_y - global_position.y) / span, 0.0, 1.0)
	scale = Vector2.ONE.lerp(Vector2(0.35, 0.35), t)
	modulate.a = lerpf(1.0, 0.2, t)
	var scene_root := get_tree().current_scene
	# Clawed back over the field → recover (keep HP, no KO).
	if velocity.y > 0.0 and scene_root and scene_root.has_method("is_in_safe_zone") \
			and scene_root.is_in_safe_zone(global_position):
		_recover_ringout(scene_root)
		return
	# Escaped off the top, descended past the field beside it, or ran out of
	# struggle time → a completed ring-out (KO).
	fall_timer -= delta
	if global_position.y <= SKY_ESCAPE_Y or global_position.y >= fall_center_y + 320.0 \
			or fall_timer <= 0.0:
		_finish_ringout()

# A recovery mash: any of the action buttons this frame (CPUs flail randomly).
func _ringout_mash_pressed() -> bool:
	if is_cpu:
		return randf() < CPU_MASH_CHANCE
	for a in MASH_ACTIONS:
		if Input.is_action_just_pressed(_action(a)):
			return true
	return false

func _recover_ringout(scene_root: Node) -> void:
	is_falling = false
	fall_up = false
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	velocity = Vector2.ZERO
	invuln_timer = RECOVER_INVULN
	hitbox_shape.set_deferred("disabled", true)  # may run inside a physics flush
	hitbox_visual.visible = false
	if scene_root and scene_root.has_method("on_ringout_recovered"):
		scene_root.on_ringout_recovered(self)  # cancels the pending KO credit

func _finish_ringout() -> void:
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_method("on_ringout_complete"):
		scene_root.on_ringout_complete(self)  # main respawns + credits the kill
	else:
		respawn()

func die() -> void:
	_release_all_grabs()
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_method("on_ko_landed"):
		scene_root.on_ko_landed()
	_spawn_ko_flourish()
	if scene_root and scene_root.has_method("report_ko"):
		scene_root.report_ko(self, last_damaged_by)
	respawn()

# --- Timers + visuals ---

func update_timers(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta
	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer -= delta
	if grab_cooldown > 0.0:
		grab_cooldown -= delta
	if knockdown_immune_timer > 0.0:
		knockdown_immune_timer -= delta
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
	if hit_anim_timer > 0.0:
		hit_anim_timer -= delta
	if special_cooldown_timer > 0.0:
		special_cooldown_timer -= delta
	if timed_slow_timer > 0.0:
		timed_slow_timer -= delta
	if powerup_timer > 0.0:
		powerup_timer -= delta
		if powerup_timer <= 0.0:
			_end_powerup()
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0

func update_visual() -> void:
	var color := Color.WHITE
	match defense_state:
		DefenseState.BLOCKING:
			color = Color(0.55, 0.7, 1.3, 1.0)
		DefenseState.DODGING:
			color = Color(1, 1, 1, 0.35)
		DefenseState.GUARD_BROKEN:
			color = Color(1.4, 0.6, 1.4, 1.0)
	if (slow_overlap_count > 0 or timed_slow_timer > 0.0) and defense_state == DefenseState.NORMAL:
		color = Color(0.6, 0.85, 0.55, 1.0)
	if hit_flash_timer > 0.0:
		var b := lerpf(1.35, 1.95, hit_flash_strength)   # soft jab → bright haymaker white-out
		color = Color(b, b, b, 1.0)
	elif invuln_timer > 0.0 and defense_state != DefenseState.DODGING:
		var flash := int(invuln_timer * 30.0) % 2 == 0
		if flash:
			color.a *= 0.5
	# Soften the per-player tint to a hue HINT: a full multiply made sense on
	# the old flat sprites, but it crushes the painterly fighters (P2's 0.5-red
	# tint turned the red raptor near-black). 35% keeps who's-who readable
	# without destroying each species' palette.
	var sprite_tint: Color
	if MatchConfig and MatchConfig.teams_enabled:
		# Team mode: the whole side wears its team colour (RED / BLUE) so allies
		# read as one group and the two teams are easy to tell apart — a touch
		# stronger than the per-player hue hint, since that matters more here.
		var team_col: Color = MatchConfig.TEAM_COLORS.get(MatchConfig.side_of(player_id), Color.WHITE)
		sprite_tint = Color.WHITE.lerp(team_col, 0.5)
	else:
		sprite_tint = MatchConfig.PLAYER_TINTS.get(player_id, Color.WHITE) if MatchConfig else Color.WHITE
		sprite_tint = Color.WHITE.lerp(sprite_tint, 0.35)
	if beast_active:
		color *= BEAST_TINT  # gold glow marks the juggernaut
	polygon.modulate = color
	sprite.modulate = color * sprite_tint
	if rig != null:
		# Node2D.modulate propagates to every part sprite, so flash + player tint
		# cover the whole skeleton in one set.
		rig.modulate = color * sprite_tint

# --- THE BEAST (juggernaut) crown toggling ---
# Paired multiply/divide on the visual scale reverts exactly; HP swaps to a bonus
# pool (full heal on crowning), back to the base cap when the crown is lost.
func become_beast() -> void:
	if beast_active:
		return
	beast_active = true
	if _base_max_hp == 0:
		_base_max_hp = max_hp
	max_hp = _base_max_hp + BEAST_HP_BONUS
	hp = max_hp
	update_hp_bar()
	if sprite:
		sprite.scale *= BEAST_SCALE
	if polygon:
		polygon.scale *= BEAST_SCALE

func clear_beast() -> void:
	if not beast_active:
		return
	beast_active = false
	if _base_max_hp > 0:
		max_hp = _base_max_hp
	hp = min(hp, max_hp)
	update_hp_bar()
	if sprite:
		sprite.scale /= BEAST_SCALE
	if polygon:
		polygon.scale /= BEAST_SCALE

func update_hp_bar() -> void:
	pass

func update_block_bar() -> void:
	pass

# --- Surface (called by main.gd) ---

func enter_ice() -> void:
	ice_overlap_count += 1
	current_surface = Surface.ICE

func exit_ice() -> void:
	ice_overlap_count = max(0, ice_overlap_count - 1)
	if ice_overlap_count == 0:
		current_surface = Surface.GROUND

func enter_slow() -> void:
	slow_overlap_count += 1

func exit_slow() -> void:
	slow_overlap_count = max(0, slow_overlap_count - 1)

func enter_floe() -> void:
	floe_overlap_count += 1

func exit_floe() -> void:
	floe_overlap_count = max(0, floe_overlap_count - 1)

# --- Respawn ---

func respawn() -> void:
	_end_powerup()  # buffs don't carry across a death/respawn
	combo_count = 0
	combo_timer = 0.0
	is_falling = false
	fall_up = false
	fall_timer = 0.0
	spiral_angle = 0.0
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	global_position = spawn_point
	velocity = Vector2.ZERO
	current_surface = Surface.GROUND
	ice_overlap_count = 0
	slow_overlap_count = 0
	floe_overlap_count = 0
	current_push = Vector2.ZERO
	knockback_active = false
	# FLOPPY: clear any downed/grab state so a respawn or round-reset never lands
	# you on the floor or still tangled in a grab link.
	is_downed = false
	down_timer = 0.0
	knockdown_immune_timer = 0.0
	grab_cooldown = 0.0
	_release_all_grabs()
	if rig != null:
		rig.reset_pose()
	special_cooldown_timer = 0.0
	timed_slow_timer = 0.0
	current_is_special = false
	hp = max_hp
	block_durability = max_block
	invuln_timer = invuln_duration
	attack_phase = AttackPhase.IDLE
	attack_timer = 0.0
	defense_state = DefenseState.NORMAL
	dodge_timer = 0.0
	dodge_cooldown_timer = 0.0
	guard_break_timer = 0.0
	hitbox_shape.set_deferred("disabled", true)  # respawn may run inside a physics flush
	hitbox_visual.visible = false
	last_damaged_by = null
	hit_flash_timer = 0.0
	hit_flash_strength = 0.0
	hit_anim_timer = 0.0
	if not initial_weapons.is_empty():
		weapons = initial_weapons.duplicate()
		active_weapon = 0
		if is_cpu:
			_equip_default_weapon()  # CPUs come back armed; humans re-draw on fists
		else:
			_refresh_weapon()
	update_hp_bar()
	update_block_bar()
