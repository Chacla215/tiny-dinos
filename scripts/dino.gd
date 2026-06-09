extends CharacterBody2D

enum Surface { GROUND, ICE }
enum AttackPhase { IDLE, WINDUP, ACTIVE, RECOVERY }
enum DefenseState { NORMAL, BLOCKING, DODGING, GUARD_BROKEN }

const SHEET_PLAYER := "res://assets/sprites/playersprites_revision.png"
const SHEET_REF := "res://assets/sprites/rynosaurlandcharacters.png"
const SHEET_ENEMY := "res://assets/sprites/enemysprites_revision.png"

const ANIM_LAYOUTS := {
	"raptor": {
		"sheet": SHEET_PLAYER,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(99, 79, 22, 35), Rect2(125, 79, 23, 35)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(99, 127, 22, 35), Rect2(130, 129, 22, 35)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(97, 228, 32, 34), Rect2(136, 232, 22, 34)]},
	},
	"trex": {
		"sheet": SHEET_REF,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(221, 4, 19, 21), Rect2(247, 3, 19, 22)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(219, 30, 20, 21), Rect2(245, 29, 20, 22)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(245, 29, 20, 22)]},
	},
	"trike": {
		"sheet": SHEET_ENEMY,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(4, 438, 42, 50), Rect2(50, 437, 42, 50)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(96, 437, 42, 50), Rect2(150, 436, 42, 50), Rect2(196, 435, 42, 50), Rect2(246, 435, 42, 50)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(246, 435, 42, 50)]},
	},
	"pterry": {
		"sheet": SHEET_ENEMY,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(2, 200, 36, 30), Rect2(48, 199, 36, 30)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(99, 200, 36, 30), Rect2(2, 240, 36, 30), Rect2(48, 239, 36, 30), Rect2(99, 242, 36, 30)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(99, 242, 36, 30)]},
	},
	"bronto": {  # Goober (long red) from rynosaurlandcharacters — drawn facing left
		"sheet": SHEET_REF,
		"faces_left": true,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(2, 199, 34, 24), Rect2(49, 199, 34, 24)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(104, 199, 34, 24), Rect2(150, 199, 34, 24), Rect2(193, 199, 34, 24), Rect2(235, 199, 34, 24)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(235, 199, 34, 24)]},
	},
	"anky": {  # Tortuka (turtle) from rynosaurlandcharacters
		"sheet": SHEET_REF,
		"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(120, 0, 18, 30), Rect2(148, 0, 21, 30)]},
		"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(120, 0, 18, 30), Rect2(148, 0, 21, 30), Rect2(175, 0, 18, 30)]},
		"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(175, 0, 18, 30)]},
	},
}

@export var max_speed: float = 320.0
@export var ground_accel: float = 3000.0
@export var ground_friction: float = 3000.0
@export var ice_accel: float = 600.0
@export var ice_friction: float = 200.0

@export_group("Combat")
@export var max_hp: int = 100
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
## "none" | "chomp" (lifesteal) | "dash_claw" | "headbutt" | "screech" (AoE)
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
## True when the source sprite art faces left by default (e.g. bronto/Goober).
## Flips the flip_h logic so the dino visually faces its movement direction.
var sprite_faces_left: bool = false

@onready var polygon: Polygon2D = $Polygon2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
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
var afterimage_timer: float = 0.0
var ice_overlap_count: int = 0
var slow_overlap_count: int = 0
var floe_overlap_count: int = 0  # Frozen Floes: >0 means standing on safe ice
var current_push: Vector2 = Vector2.ZERO
var knockback_active: bool = false

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
var weapon_visual: Polygon2D = null  # held-weapon shape, oriented to facing
var initial_weapons: Array = []      # loadout to restore on respawn
var wpn_dmg: float = 1.0
var wpn_kb: float = 1.0
var wpn_range: float = 0.0
var wpn_windup: float = 1.0
var wpn_recovery: float = 1.0

const AFTERIMAGE_INTERVAL := 0.05
const SLOW_MOVE_FACTOR := 0.4
const SLOW_ACCEL_FACTOR := 0.6
## How fast knockback "launch" speed (the part above your normal max_speed)
## bleeds off, regardless of surface. Stops a hit from gliding you off an ice
## map while leaving normal ice-sliding and self-dash lunges untouched.
const KNOCKBACK_DECEL := 2000.0

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
	spawn_point = global_position
	hp = max_hp
	block_durability = max_block
	if MatchConfig and MatchConfig.PLAYER_COLORS.has(player_id):
		var player_color: Color = MatchConfig.PLAYER_COLORS[player_id]
		polygon.color = player_color
		player_marker.color = player_color
	else:
		polygon.color = dino_color

	_setup_sprite()

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
	# Player's chosen weapon overrides the default loadout (fists + their pick).
	if MatchConfig.weapon_choices.has(player_id):
		weapons = ["fists", MatchConfig.weapon_choices[player_id]]

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
		if anim_name == "sheet" or anim_name == "faces_left":
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
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.position.y = sprite_offset_y
	sprite.play("idle")
	polygon.visible = false

func _physics_process(delta: float) -> void:
	if is_falling:
		_process_fall(delta)
		return
	if is_cpu and ai != null:
		ai.think(self, _find_nearest_opponent(), delta)
	update_facing()
	_process_input_actions()
	update_guard_break(delta)
	update_dodge(delta)
	update_attack(delta)
	update_movement(delta)
	update_block_regen(delta)
	update_timers(delta)
	update_visual()
	update_sprite_animation()
	var current_offset := current_attack_hitbox_offset if attack_phase != AttackPhase.IDLE else attack_hitbox_offset
	hitbox.position = facing * current_offset
	if weapon_visual and weapon_visual.visible:
		weapon_visual.rotation = facing.angle()
		weapon_visual.position = facing * 18.0 + Vector2(0, -6)

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
	if Input.is_action_just_pressed(_action("throw")) and can_throw():
		throw_weapon()
	if Input.is_action_just_pressed(_action("pickup")) and can_pickup():
		try_pickup()
	if Input.is_action_just_pressed(_action("block")) and can_start_block():
		start_block()
	elif Input.is_action_just_released(_action("block")) and defense_state == DefenseState.BLOCKING:
		end_block()
	if Input.is_action_just_pressed(_action("dodge")) and can_dodge():
		start_dodge()

func _process_cpu_actions() -> void:
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

# Nearest active opposing dino, or null. Active = visible (inactive slots are
# hidden by main.gd). Used by the CPU brain as its target.
func _find_nearest_opponent() -> Node:
	var best: Node = null
	var best_d := INF
	for other in get_parent().get_children():
		if other == self or not (other is CharacterBody2D):
			continue
		if not ("player_id" in other) or other.player_id == player_id:
			continue
		if not other.visible:
			continue
		var d := global_position.distance_squared_to(other.global_position)
		if d < best_d:
			best_d = d
			best = other
	return best

func update_sprite_animation() -> void:
	if not sprite.visible or sprite.sprite_frames == null:
		return
	# flip_h is relative to the source art's default facing: sprites drawn facing
	# left (sprite_faces_left) need the opposite flip to face their movement.
	if facing.x > 0.05:
		sprite.flip_h = sprite_faces_left
	elif facing.x < -0.05:
		sprite.flip_h = not sprite_faces_left
	if attack_phase == AttackPhase.WINDUP or attack_phase == AttackPhase.ACTIVE:
		if sprite.animation != "attack":
			sprite.play("attack")
		return
	var moving := velocity.length() > 12.0
	var target := "walk" if moving else "idle"
	if sprite.animation != target:
		sprite.play(target)

# --- Capability checks ---

func can_attack() -> bool:
	return attack_phase == AttackPhase.IDLE \
		and defense_state == DefenseState.NORMAL

func can_start_block() -> bool:
	return attack_phase == AttackPhase.IDLE \
		and defense_state == DefenseState.NORMAL

func can_special() -> bool:
	return special_type != "none" \
		and special_cooldown_timer <= 0.0 \
		and attack_phase == AttackPhase.IDLE \
		and defense_state == DefenseState.NORMAL

func can_throw() -> bool:
	return _active_weapon_id() != "fists" \
		and attack_phase == AttackPhase.IDLE \
		and defense_state == DefenseState.NORMAL

func can_pickup() -> bool:
	return defense_state != DefenseState.DODGING \
		and defense_state != DefenseState.GUARD_BROKEN

func can_dodge() -> bool:
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

	var move_factor: float = 1.0
	if defense_state == DefenseState.BLOCKING:
		move_factor = block_move_factor
	if slow_overlap_count > 0 or timed_slow_timer > 0.0:
		move_factor *= SLOW_MOVE_FACTOR
		accel *= SLOW_ACCEL_FACTOR

	# Bleed off knockback launch speed at a fixed rate so a big hit can't skate
	# you across an ice map. Only the speed above max_speed is affected, so it
	# never touches normal locomotion (and self-dash sets the flag false).
	if knockback_active:
		var kb_speed := velocity.length()
		if kb_speed > max_speed:
			velocity = velocity.normalized() * maxf(max_speed, kb_speed - KNOCKBACK_DECEL * delta)
		else:
			knockback_active = false

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed * move_factor, accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_apply_current(delta)

# Environmental drift (e.g. White Water Falls current). Applied as a real
# displacement so it respects walls and never accumulates into the velocity.
func _apply_current(delta: float) -> void:
	if current_push != Vector2.ZERO:
		move_and_collide(current_push * delta)

# --- Attack ---

func start_attack(heavy: bool = false) -> void:
	knockback_active = false  # self-dash lunges shouldn't be damped as knockback
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
	else:
		current_attack_damage = attack_damage
		current_attack_knockback = attack_knockback
		current_attack_active = attack_active
		current_attack_recovery = attack_recovery
		current_attack_hitbox_size = attack_hitbox_size
		current_attack_hitbox_offset = attack_hitbox_offset
		attack_timer = attack_windup
	# Active weapon modifies light + heavy (the signature special is unaffected).
	current_attack_damage = int(round(current_attack_damage * wpn_dmg))
	current_attack_knockback *= wpn_kb
	current_attack_hitbox_offset += wpn_range
	current_attack_recovery *= wpn_recovery
	attack_timer *= wpn_windup
	attack_phase = AttackPhase.WINDUP
	play_scene_sfx("swing", 0.08)

func _refresh_weapon() -> void:
	var id: String = weapons[active_weapon] if active_weapon < weapons.size() else "fists"
	var w: Dictionary = MatchConfig.WEAPONS.get(id, {}) if MatchConfig else {}
	wpn_dmg = w.get("dmg", 1.0)
	wpn_kb = w.get("kb", 1.0)
	wpn_range = w.get("range", 0)
	wpn_windup = w.get("windup", 1.0)
	wpn_recovery = w.get("recovery", 1.0)
	if weapon_visual == null:
		weapon_visual = Polygon2D.new()
		weapon_visual.z_index = 1
		add_child(weapon_visual)
	var shape: Dictionary = MatchConfig.weapon_shape(id) if MatchConfig else {}
	var poly: PackedVector2Array = shape.get("poly", PackedVector2Array())
	weapon_visual.polygon = poly
	weapon_visual.color = shape.get("color", Color.WHITE)
	weapon_visual.visible = poly.size() > 0

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
	play_scene_sfx("swing", 0.05)

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
	play_scene_sfx("block", 0.1)  # quick clink as it's grabbed

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
	attack_phase = AttackPhase.WINDUP
	play_scene_sfx("swing", 0.06)

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
			if current_is_special and special_type == "screech":
				_do_screech()
			elif current_is_special and special_type == "spikes":
				_spawn_spike_volley()
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
	body.take_damage(current_attack_damage, facing * current_attack_knockback, self)
	var root := get_tree().current_scene
	if root and root.has_method("add_dp"):
		root.add_dp(player_id, 10)
	if current_is_special and special_lifesteal > 0.0:
		hp = min(max_hp, hp + int(current_attack_damage * special_lifesteal))
		update_hp_bar()

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
	ghost.global_position = global_position + Vector2(0, sprite_offset_y)
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(dino_color.r, dino_color.g, dino_color.b, 0.55)
	ghost.z_index = -1
	get_tree().current_scene.add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ghost.queue_free)

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
	if invuln_timer > 0.0:
		return
	if defense_state == DefenseState.DODGING:
		return

	if source != null:
		last_damaged_by = source
	hit_flash_timer = 0.08

	if defense_state == DefenseState.BLOCKING:
		play_scene_sfx("block", 0.08)
	else:
		var sfx_name: String = "hit_claw"
		if source != null and "hit_sfx_name" in source:
			sfx_name = source.hit_sfx_name
		play_scene_sfx(sfx_name, 0.1)

	if defense_state == DefenseState.BLOCKING:
		var absorbed: float = min(block_durability, float(amount))
		block_durability -= absorbed
		var remaining: float = float(amount) - absorbed
		velocity += knockback * block_knockback_factor
		knockback_active = true
		update_block_bar()
		if block_durability <= 0.0:
			guard_break()  # fires its own guard-break juice
			if remaining > 0.0:
				hp -= int(remaining)
				velocity += knockback * (1.0 - block_knockback_factor)
				update_hp_bar()
				if hp <= 0:
					die()
					return
		else:
			notify_blocked(amount)
		invuln_timer = hitstun_invuln
		return

	hp -= amount
	velocity += knockback
	knockback_active = true
	notify_hit(amount)
	invuln_timer = hitstun_invuln
	update_hp_bar()
	if hp <= 0:
		die()

# Environmental damage tick (e.g. Laughing Lava). Bypasses block/invuln since
# you can't guard against fire, but dodge i-frames still let you slip a tick.
# Returns true if this tick was lethal so the arena can credit the KO.
func apply_burn(amount: int, knockback: Vector2) -> bool:
	if defense_state == DefenseState.DODGING:
		return false
	hp -= amount
	velocity += knockback
	knockback_active = true
	hit_flash_timer = 0.08
	update_hp_bar()
	return hp <= 0

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
		if other.has_method("apply_screech"):
			other.apply_screech(special_slow_duration)
	_spawn_screech_ring()

# Called on a dino caught in a screech: slows it + locks dodge for the duration.
func apply_screech(duration: float) -> void:
	timed_slow_timer = maxf(timed_slow_timer, duration)

func _spawn_screech_ring() -> void:
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(28):
		var a := TAU * i / 28.0
		pts.append(Vector2(cos(a), sin(a)) * special_radius)
	ring.polygon = pts
	ring.color = Color(0.75, 0.55, 1.0, 0.4)
	ring.global_position = global_position
	ring.scale = Vector2(0.15, 0.15)
	ring.z_index = -1
	get_tree().current_scene.add_child(ring)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector2(1, 1), 0.25)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(ring.queue_free)

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
	hitbox_shape.disabled = true
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
	hitbox_shape.disabled = true
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
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_method("on_ko_landed"):
		scene_root.on_ko_landed()
	if scene_root and scene_root.has_method("report_ko"):
		scene_root.report_ko(self, last_damaged_by)
	respawn()

# --- Timers + visuals ---

func update_timers(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta
	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer -= delta
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
	if special_cooldown_timer > 0.0:
		special_cooldown_timer -= delta
	if timed_slow_timer > 0.0:
		timed_slow_timer -= delta

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
		color = Color(1.6, 1.6, 1.6, 1.0)
	elif invuln_timer > 0.0 and defense_state != DefenseState.DODGING:
		var flash := int(invuln_timer * 30.0) % 2 == 0
		if flash:
			color.a *= 0.5
	var sprite_tint: Color = MatchConfig.PLAYER_TINTS.get(player_id, Color.WHITE) if MatchConfig else Color.WHITE
	polygon.modulate = color
	sprite.modulate = color * sprite_tint

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
	hitbox_shape.disabled = true
	hitbox_visual.visible = false
	last_damaged_by = null
	hit_flash_timer = 0.0
	if not initial_weapons.is_empty():
		weapons = initial_weapons.duplicate()
		active_weapon = 0
		if is_cpu:
			_equip_default_weapon()  # CPUs come back armed; humans re-draw on fists
		else:
			_refresh_weapon()
	update_hp_bar()
	update_block_bar()
