extends "res://scenes/target.gd"

@export var move_speed: float = 2.0
@export var move_distance: float = 3.0
@export var move_axis: Vector3 = Vector3(0, 0, 1)
var _start_position: Vector3
var _move_direction: float = 1.0

func _ready() -> void:
	_start_position = global_position
	var axes = [Vector3(0,0,1), Vector3(0,1,0)]
	move_axis = axes[randi() % axes.size()]

func _physics_process(delta: float) -> void:
	var dist = (global_position - _start_position).dot(move_axis.normalized())
	if dist >= move_distance:
		_move_direction = -1.0
	elif dist <= 0.0:
		_move_direction = 1.0
	move_and_collide(move_axis.normalized() * _move_direction * move_speed * delta)
