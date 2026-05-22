extends CharacterBody2D

enum Surface { GROUND, ICE }
enum AttackPhase { IDLE, WINDUP, ACTIVE, RECOVERY }
enum DefenseState { NORMAL, BLOCKING, DODGING, GUARD_BROKEN }

const SHEET_PLAYER := "res://assets/sprites/playersprites_revision.png"
const SHEET_REF := "res://assets/sprites/rynosaurlandcharacters.png"
const SHEET_ENEMY := "res://assets/sprites/enemysprites_revision.png"
const SHEET_HD := "res://assets/sprites/trex_handdrawn.png"

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
	# Hand-drawn Ralph. To use in a match: set DINOS["trex"].sprite_role="trex_hd",
	# sprite_scale ~0.8, sprite_offset_y ~-22 in match_config.gd.
	"trex_hd": {
		"sheet": SHEET_HD,
		"idle":   {"loop": true,  "speed": 5.0,  "rects": [Rect2(0, 0, 151, 110), Rect2(151, 0, 151, 110)]},
		"walk":   {"loop": true,  "speed": 9.0,  "rects": [Rect2(302, 0, 151, 110), Rect2(453, 0, 151, 110), Rect2(604, 0, 151, 110), Rect2(755, 0, 151, 110)]},
		"attack": {"loop": false, "speed": 11.0, "rects": [Rect2(906, 0, 151, 110), Rect2(1057, 0, 151, 110), Rect2(1208, 0, 151, 110)]},
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

@export_group("Appearance")
@export var dino_color: Color = Color(0.4, 0.8, 0.6, 1.0)
@export var show_hitbox_debug: bool = false

@export_group("Audio")
@export var hit_sfx_name: String = "hit_claw"

@export_group("Sprite")
@export var sprite_role: String = "raptor"
@export var sprite_scale: float = 2.5
@export var sprite_offset_y: float = -10.0

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

var current_attack_damage: int = 0
var current_attack_knockback: float = 0.0
var current_attack_active: float = 0.0
var current_attack_recovery: float = 0.0
var current_attack_hitbox_size: Vector2 = Vector2.ZERO
var current_attack_hitbox_offset: float = 0.0
var current_is_heavy: bool = false

const AFTERIMAGE_INTERVAL := 0.05

func _ready() -> void:
	_apply_config_preset()
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

func _setup_sprite() -> void:
	if not sprite_role in ANIM_LAYOUTS:
		sprite.visible = false
		return
	var layouts = ANIM_LAYOUTS[sprite_role]
	var sheet_path: String = layouts.get("sheet", SHEET_PLAYER)
	if not ResourceLoader.exists(sheet_path):
		sprite.visible = false
		return
	var sheet: Texture2D = load(sheet_path)
	if sheet == null:
		sprite.visible = false
		return
	var sf := SpriteFrames.new()
	for anim_name in layouts:
		if anim_name == "sheet":
			continue
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, layouts[anim_name].loop)
		sf.set_animation_speed(anim_name, layouts[anim_name].speed)
		for rect in layouts[anim_name].rects:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = rect
			sf.add_frame(anim_name, atlas)
	sprite.sprite_frames = sf
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.position.y = sprite_offset_y
	sprite.play("idle")
	polygon.visible = false

func _physics_process(delta: float) -> void:
	_process_input_actions()
	update_facing()
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

func _action(name: String) -> String:
	return "%s_%s" % [player_id, name]

func _process_input_actions() -> void:
	if Input.is_action_just_pressed(_action("attack")) and can_attack():
		start_attack(false)
	if Input.is_action_just_pressed(_action("heavy")) and can_attack():
		start_attack(true)
	if Input.is_action_just_pressed(_action("block")) and can_start_block():
		start_block()
	elif Input.is_action_just_released(_action("block")) and defense_state == DefenseState.BLOCKING:
		end_block()
	if Input.is_action_just_pressed(_action("dodge")) and can_dodge():
		start_dodge()

func update_sprite_animation() -> void:
	if not sprite.visible or sprite.sprite_frames == null:
		return
	if facing.x < -0.05:
		sprite.flip_h = true
	elif facing.x > 0.05:
		sprite.flip_h = false
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

func can_dodge() -> bool:
	if dodge_cooldown_timer > 0.0:
		return false
	if defense_state == DefenseState.DODGING or defense_state == DefenseState.GUARD_BROKEN:
		return false
	if attack_phase == AttackPhase.WINDUP or attack_phase == AttackPhase.ACTIVE:
		return false
	if block_durability < dodge_block_cost:
		return false
	return true

# --- Facing + input direction ---

func update_facing() -> void:
	var dir := get_input_direction()
	if dir != Vector2.ZERO:
		facing = dir

func get_input_direction() -> Vector2:
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

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed * move_factor, accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

# --- Attack ---

func start_attack(heavy: bool = false) -> void:
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
	attack_phase = AttackPhase.WINDUP
	play_scene_sfx("swing", 0.08)

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
			if current_is_heavy and heavy_attack_type == "projectile":
				_spawn_projectile()
			else:
				if hitbox_shape.shape is RectangleShape2D:
					hitbox_shape.shape.size = current_attack_hitbox_size
				hitbox_shape.disabled = false
				hitbox_visual.visible = show_hitbox_debug
				hit_targets_this_swing.clear()
		AttackPhase.ACTIVE:
			attack_phase = AttackPhase.RECOVERY
			attack_timer = current_attack_recovery
			hitbox_shape.disabled = true
			hitbox_visual.visible = false
		AttackPhase.RECOVERY:
			attack_phase = AttackPhase.IDLE
			attack_timer = 0.0

func try_hit(body: Node) -> void:
	if body == self:
		return
	if body in hit_targets_this_swing:
		return
	if not body.has_method("take_damage"):
		return
	hit_targets_this_swing.append(body)
	body.take_damage(current_attack_damage, facing * current_attack_knockback, self)

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
	if invuln_timer > 0.0:
		return
	if defense_state == DefenseState.DODGING:
		return

	if source != null:
		last_damaged_by = source
	hit_flash_timer = 0.08
	notify_hit(amount)

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
		update_block_bar()
		if block_durability <= 0.0:
			guard_break()
			if remaining > 0.0:
				hp -= int(remaining)
				velocity += knockback * (1.0 - block_knockback_factor)
				update_hp_bar()
				if hp <= 0:
					die()
					return
		invuln_timer = hitstun_invuln
		return

	hp -= amount
	velocity += knockback
	invuln_timer = hitstun_invuln
	update_hp_bar()
	if hp <= 0:
		die()

func notify_hit(damage: int) -> void:
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_method("on_hit_landed"):
		scene_root.on_hit_landed(damage)

func _spawn_projectile() -> void:
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

	projectile.global_position = global_position + facing * 50.0
	projectile.rotation = facing.angle()
	projectile.travel_velocity = facing * projectile_speed
	projectile.damage = current_attack_damage
	projectile.knockback_force = current_attack_knockback
	projectile.lifetime = projectile_lifetime
	projectile.source = self

	get_tree().current_scene.add_child(projectile)

func play_scene_sfx(sound_name: String, pitch_var: float = 0.05) -> void:
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_method("play_sfx"):
		scene_root.play_sfx(sound_name, pitch_var)

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

func update_visual() -> void:
	var color := Color.WHITE
	match defense_state:
		DefenseState.BLOCKING:
			color = Color(0.55, 0.7, 1.3, 1.0)
		DefenseState.DODGING:
			color = Color(1, 1, 1, 0.35)
		DefenseState.GUARD_BROKEN:
			color = Color(1.4, 0.6, 1.4, 1.0)
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

# --- Respawn ---

func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	current_surface = Surface.GROUND
	ice_overlap_count = 0
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
	update_hp_bar()
	update_block_bar()
