extends Area2D
# A weapon that exists in the world rather than in a dino's hands. Two lives:
#
#   FLYING   – just thrown (RT). Spins through the air, hits the first opponent
#              it touches for MORE than the same weapon swung, then drops where
#              it lands. A throw that clears the platform edge is lost for good.
#   GROUNDED – sitting on the floor, in the "weapon_pickups" group, waiting for
#              any dino to grab it with LT (dino.gd does the proximity search).
#
# Built entirely from code by dino.gd (no scene), so set weapon_id + the launch
# fields before add_child(); _ready() draws the silhouette to match.

enum Mode { FLYING, GROUNDED }

const SPIN_SPEED := 16.0     ## rad/s tumble while airborne
const FLIGHT_TIME := 0.8     ## seconds aloft before it drops to the ground
const EDGE_MARGIN := 140.0   ## how far past the platform it may sail before it's gone
const LAND_BOUNCE := 0.16    ## squash-settle when it touches down

var weapon_id: String = "sword"
var mode: int = Mode.FLYING
var travel_velocity: Vector2 = Vector2.ZERO
var damage: int = 0
var knockback_force: float = 0.0
var source: Node = null      ## thrower; immune while the weapon is in flight
var flight_timer: float = FLIGHT_TIME
var has_hit: bool = false

func _ready() -> void:
	_build_visual()
	body_entered.connect(_on_body_entered)
	add_to_group("weapon_items")  # cleared between rounds by main.gd

func _build_visual() -> void:
	var shape_data: Dictionary = MatchConfig.weapon_shape(weapon_id)
	var visual := Polygon2D.new()
	visual.polygon = shape_data.get("poly", PackedVector2Array())
	visual.color = shape_data.get("color", Color.WHITE)
	visual.z_index = 1
	add_child(visual)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 20)
	col.shape = rect
	add_child(col)

func _physics_process(delta: float) -> void:
	if mode != Mode.FLYING:
		return
	global_position += travel_velocity * delta
	rotation += SPIN_SPEED * delta
	flight_timer -= delta
	# Sailed well clear of the platform: gone, no pickup left behind.
	if _beyond_edge(global_position):
		queue_free()
		return
	if flight_timer <= 0.0:
		_land()

func _on_body_entered(body: Node) -> void:
	if mode != Mode.FLYING or has_hit:
		return
	if body == source:
		return
	if not body.has_method("take_damage"):
		return
	has_hit = true
	var dir := travel_velocity.normalized()
	body.take_damage(damage, dir * knockback_force, source)
	_land()  # drop at the point of impact

# End of flight: become a pickup if we're still over the platform, otherwise
# we've gone over the edge — drop into the void.
func _land() -> void:
	if not _over_platform(global_position):
		queue_free()
		return
	mode = Mode.GROUNDED
	travel_velocity = Vector2.ZERO
	rotation = 0.0
	has_hit = true
	add_to_group("weapon_pickups")
	var rest := scale
	scale = rest * 1.35
	var tw := create_tween()
	tw.tween_property(self, "scale", rest, LAND_BOUNCE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func is_grounded() -> bool:
	return mode == Mode.GROUNDED

# Called by a dino that grabs this off the ground.
func consume() -> void:
	queue_free()

# True while p sits on the island (safe ground = becomes a pickup). Islands ring
# out on the painted safe_polygon, so test that shoreline where it exists; the
# inscribed safe_rect is only a fallback for arenas without a polygon.
func _over_platform(p: Vector2) -> bool:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return true  # unbounded arena: anywhere is fine
	if "safe_polygon" in scene_root and scene_root.safe_polygon.size() >= 3:
		return Geometry2D.is_point_in_polygon(p, scene_root.safe_polygon)
	if "safe_rect" in scene_root:
		return (scene_root.safe_rect as Rect2).has_point(p)
	return true

# True once p has sailed a margin (EDGE_MARGIN) past the arena edge — a thrown
# weapon that clears the shoreline by this much is lost for good.
func _beyond_edge(p: Vector2) -> bool:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return false
	if "safe_polygon" in scene_root and scene_root.safe_polygon.size() >= 3:
		var poly: PackedVector2Array = scene_root.safe_polygon
		if Geometry2D.is_point_in_polygon(p, poly):
			return false
		var center := Vector2.ZERO
		for v in poly:
			center += v
		center /= poly.size()
		var pulled: Vector2 = p + (center - p).normalized() * EDGE_MARGIN
		return not Geometry2D.is_point_in_polygon(pulled, poly)
	if "safe_rect" in scene_root:
		return not (scene_root.safe_rect as Rect2).grow(EDGE_MARGIN).has_point(p)
	return false
