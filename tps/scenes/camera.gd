extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion:
		var mouse_event: Vector2 = event.screen_relative

func camera_look(mouse_movement: Vector2) -> void:
	camera_rotation += mouse_movement
	
	transform.basis = Basis()
	
	rotate_object_local(Vector3)
