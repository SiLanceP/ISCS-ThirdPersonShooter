extends CharacterBody3D

@export var speed: float = 30.0
@export var max_distance: float = 80.0
@export var damage: int = 1
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
var direction: Vector3 = Vector3.ZERO
var distance_traveled: float = 0.0

func setup(direction_vector: Vector3) -> void:
	direction = direction_vector.normalized()
	look_at_from_position(global_transform.origin, global_transform.origin + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	if direction == Vector3.ZERO:
		return

	var motion = direction * speed * delta
	var collision = move_and_collide(motion)
	distance_traveled += motion.length()

	if collision:
		handle_hit(collision)
		return

	if distance_traveled >= max_distance:
		queue_free()

func handle_hit(collision) -> void:
	spawn_impact(collision.get_position())

	var collider = collision.get_collider()
	if collider and collider.has_method("take_damage"):
		collider.take_damage(damage)

	queue_free()

func spawn_impact(impact_position: Vector3) -> void:
	if not explosion_scene:
		return
	var impact = explosion_scene.instantiate()
	impact.setup(0.25, 0.5, 0.2, Color(1, 0.9, 0.6, 1))
	get_tree().current_scene.add_child(impact)
	impact.global_transform.origin = impact_position
