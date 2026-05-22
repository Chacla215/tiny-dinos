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
	var scene_root := get_tree().current_scene
	if scene_root and "safe_rect" in scene_root:
		var safe_rect: Rect2 = scene_root.safe_rect
		var expanded := safe_rect.grow(80)
		if not expanded.has_point(position):
			queue_free()

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
