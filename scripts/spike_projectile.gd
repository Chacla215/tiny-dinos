extends Area2D

var travel_velocity: Vector2 = Vector2.ZERO
var damage: int = 0
var knockback_force: float = 0.0
var lifetime: float = 1.5
var source: Node = null
var has_hit: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if has_hit:
		return
	position += travel_velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if _off_play_area(position):
		queue_free()

# A spike is gone once it sails a margin past the arena edge. Islands ring out on
# the painted safe_polygon, so test that shoreline where it exists (the inscribed
# safe_rect would cull spikes early over solid ground on oval stages).
func _off_play_area(p: Vector2) -> bool:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return false
	if "safe_polygon" in scene_root and scene_root.safe_polygon.size() >= 3:
		return _beyond_polygon(scene_root.safe_polygon, p, 80.0)
	if "safe_rect" in scene_root:
		return not (scene_root.safe_rect as Rect2).grow(80).has_point(p)
	return false

# True when p is more than `margin` outside the polygon: pull p toward the
# polygon center by `margin`; if it's still outside, it's truly cleared the edge.
func _beyond_polygon(poly: PackedVector2Array, p: Vector2, margin: float) -> bool:
	if Geometry2D.is_point_in_polygon(p, poly):
		return false
	var center := Vector2.ZERO
	for v in poly:
		center += v
	center /= poly.size()
	var pulled: Vector2 = p + (center - p).normalized() * margin
	return not Geometry2D.is_point_in_polygon(pulled, poly)

func _on_body_entered(body: Node) -> void:
	if has_hit:
		return
	if body == source:
		return
	if not body.has_method("take_damage"):
		return
	has_hit = true
	var dir := travel_velocity.normalized()
	body.take_damage(damage, dir * knockback_force, source)
	queue_free()
