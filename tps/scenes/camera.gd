extends Node3D

@export var character: CharacterBody3D
@export var edge_spring_arm: SpringArm3D
@export var rear_spring_arm: SpringArm3D
@export var camera: Camera3D

@export var camera_alignment_speed: float = .18
@export var aim_rear_spring_length: float = .5
@export var aim_edge_spring_length: float = .5
@export var aim_speed: float = .2
@export var aim_fov: float = 50

var camera_rotation: Vector2 = Vector2.ZERO
var mouse_sensitivity: float = 0.001
var max_y_rotation: float = 1.2
var camera_tween: Tween

@onready var default_edge_spring_arm_length: float = edge_spring_arm.spring_length
@onready var default_rear_spring_arm_length: float = rear_spring_arm.spring_length
@onready var default_fov: float = camera.fov

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
		
	if event.is_action_pressed("swap_camera_alignment"):
		swap_camera_alignment()

	if event.is_action_pressed("aim"):
		enter_aim()
	if event.is_action_released("aim"):
		exit_aim()

func camera_look(mouse_movement: Vector2) -> void:
	camera_rotation += mouse_movement

	transform.basis = Basis()
	character.transform.basis = Basis()

	character.rotate_object_local(Vector3(0,1,0), -camera_rotation.x)
	rotate_object_local(Vector3(1,0,0), -camera_rotation.y)

	camera_rotation.y = clamp(camera_rotation.y, -max_y_rotation, max_y_rotation)
	
func swap_camera_alignment() -> void:
	var new_pos: float = default_edge_spring_arm_length * -sign(edge_spring_arm.spring_length)
	set_rear_spring_arm_position(new_pos, camera_alignment_speed)
	
func set_rear_spring_arm_position(pos: float, speed: float) -> void:
	if camera_tween:
		camera_tween.kill()

	camera_tween = get_tree().create_tween()
	camera_tween.tween_property(edge_spring_arm, "spring_length", pos, speed)

func enter_aim() -> void:
	if camera_tween:
		camera_tween.kill()

	camera_tween = get_tree().create_tween()
	camera_tween.set_parallel()
	
	camera_tween.tween_property(camera, "fov", aim_fov, aim_speed)
	camera_tween.tween_property(edge_spring_arm, "spring_length", aim_edge_spring_length * sign(edge_spring_arm.spring_length), aim_speed)
	camera_tween.tween_property(rear_spring_arm, "spring_length", aim_rear_spring_length, aim_speed)

func exit_aim() -> void:
	if camera_tween:
		camera_tween.kill()

	camera_tween = get_tree().create_tween()
	camera_tween.set_parallel()

	camera_tween.tween_property(camera, "fov", default_fov, aim_speed)
	camera_tween.tween_property(edge_spring_arm, "spring_length", default_edge_spring_arm_length * sign(edge_spring_arm.spring_length), aim_speed)
	camera_tween.tween_property(rear_spring_arm, "spring_length", default_rear_spring_arm_length, aim_speed)
