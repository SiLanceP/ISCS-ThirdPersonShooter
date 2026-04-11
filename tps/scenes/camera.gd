extends Node3D

@export var character: CharacterBody3D

var camera_rotation: Vector2 = Vector2.ZERO
var mouse_sensitivity: float = 0.001
var max_y_rotation: float = 1.2

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		camera_look(event.relative * mouse_sensitivity)

func camera_look(mouse_movement: Vector2) -> void:
	camera_rotation += mouse_movement

	transform.basis = Basis()
	character.transform.basis = Basis()

	character.rotate_object_local(Vector3(0,1,0), -camera_rotation.x)
	rotate_object_local(Vector3(1,0,0), -camera_rotation.y)

	camera_rotation.y = clamp(camera_rotation.y, -max_y_rotation, max_y_rotation)
