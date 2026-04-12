extends StaticBody3D

@export var health: int = 3
@export var hit_explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")
@export var death_explosion_scale: float = 3.0

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	spawn_explosion(death_explosion_scale, Color(1, 0.2, 0.2, 1))
	queue_free()

func spawn_explosion(explosion_scale: float, color: Color) -> void:
	if not hit_explosion_scene or not is_inside_tree():
		return
	var target_position = global_transform.origin
	var explosion = hit_explosion_scene.instantiate()
	explosion.setup(0.4, explosion_scale, 0.6, color)
	explosion.global_transform.origin = target_position
	get_tree().current_scene.add_child(explosion)
