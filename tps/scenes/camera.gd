extends Node3D

@export var character: NodePath
@export var edge_spring_arm: NodePath
@export var rear_spring_arm: NodePath
@export var camera: NodePath
@export var muzzle: NodePath
@export var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")

@export var camera_alignment_speed: float = .18
@export var aim_rear_spring_length: float = .5
@export var aim_edge_spring_length: float = .5
@export var aim_speed: float = .2
@export var aim_fov: float = 50
@export var fire_rate: float = 0.1

var autofire: bool = false
var fire_timer: float = 0.0
var is_aiming: bool = false

var camera_rotation: Vector2 = Vector2.ZERO
var mouse_sensitivity: float = 0.001
var max_y_rotation: float = 1.2
var camera_tween: Tween

enum CameraAlignment {LEFT = -1, RIGHT = 1, CENTRE = 0}
var current_camera_alignment: int = CameraAlignment.RIGHT

var default_edge_spring_arm_length: float = 0.0
var default_rear_spring_arm_length: float = 0.0
var default_fov: float = 0.0

var character_node: CharacterBody3D
var edge_spring_arm_node: SpringArm3D
var rear_spring_arm_node: SpringArm3D
var camera_node: Camera3D
var muzzle_node: Node3D
var gun_node: MeshInstance3D

var laser_pivot: Node3D
var laser_visual: MeshInstance3D
var default_gun_x_offset: float = 0.0

func _ready() -> void:
	character_node = get_node_or_null(character) as CharacterBody3D
	edge_spring_arm_node = get_node_or_null(edge_spring_arm) as SpringArm3D
	rear_spring_arm_node = get_node_or_null(rear_spring_arm) as SpringArm3D
	camera_node = get_node_or_null(camera) as Camera3D
	muzzle_node = get_node_or_null(muzzle) as Node3D
	
	if muzzle_node:
		gun_node = muzzle_node.get_node_or_null("Gun") as MeshInstance3D
		if gun_node:
			default_gun_x_offset = gun_node.position.x

	if edge_spring_arm_node:
		default_edge_spring_arm_length = edge_spring_arm_node.spring_length
	if rear_spring_arm_node:
		default_rear_spring_arm_length = rear_spring_arm_node.spring_length
	if camera_node:
		default_fov = camera_node.fov

	create_laser_sight()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func create_laser_sight() -> void:
	laser_pivot = Node3D.new()
	if gun_node:
		gun_node.add_child(laser_pivot)
	
	laser_visual = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.05, 0.05, 80.0)
	laser_visual.mesh = box_mesh
	laser_visual.position = Vector3(0, 0, -40.0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0, 1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(1, 0, 0) * 2.0
	laser_visual.material_override = material
	
	laser_pivot.add_child(laser_visual)

func get_crosshair_world_target() -> Vector3:
	"""Cast a ray from camera through screen center and find what it hits in the world"""
	if not camera_node:
		return Vector3.ZERO
	
	var viewport = get_viewport()
	var screen_center = viewport.get_visible_rect().get_center()
	var ray_origin = camera_node.project_ray_origin(screen_center)
	var ray_direction = camera_node.project_ray_normal(screen_center)
	
	# cast a ray in the world
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 10000.0)
	if character_node:
		query.exclude = [character_node.get_rid()]
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)
	
	# If we hit something, aim at that point.
	if result:
		return result.position
	else:
		return ray_origin + ray_direction * 10000.0

func _process(delta: float) -> void:
	# Update laser sight to show where we're aiming (for debugging parallax)
	if laser_pivot and gun_node:
		laser_pivot.visible = true
		
		# Get the world point the crosshair is pointing at
		var target_point = get_crosshair_world_target()
		var shoot_direction = (target_point - gun_node.global_position).normalized()
		
		# Position the PIVOT at the gun and rotate it
		laser_pivot.global_position = gun_node.global_position
		laser_pivot.look_at(gun_node.global_position + shoot_direction * 80.0, Vector3.UP)
	
	if autofire:
		fire_timer -= delta
		if fire_timer <= 0.0:
			shoot()
			fire_timer = fire_rate
	
	if muzzle_node and camera_node and character_node:
		var camera_forward = -camera_node.global_transform.basis.z
		var camera_up = camera_node.global_transform.basis.y
		var camera_right = camera_node.global_transform.basis.x
		
		var offset_distance = 0.3 * current_camera_alignment
		var muzzle_world_pos = character_node.global_transform.origin + camera_right * offset_distance + camera_up * 0.8 + camera_forward * 0.3
		
		muzzle_node.global_position = muzzle_world_pos
		muzzle_node.global_transform.basis = Basis.looking_at(camera_forward, camera_up)

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

	if event.is_action_pressed("fire"):
		autofire = true
		shoot()
		fire_timer = fire_rate
	if event.is_action_released("fire"):
		autofire = false
		fire_timer = 0.0

	if event.is_action_pressed("aim"):
		enter_aim()
	if event.is_action_released("aim"):
		exit_aim()

func shoot() -> void:
	if not projectile_scene or not gun_node:
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	if character_node:
		projectile.add_collision_exception_with(character_node)

	# Set the projectile's starting position to the gun's position
	projectile.global_transform.origin = gun_node.global_position

	# Get the world point the crosshair is pointing at
	var target_point = get_crosshair_world_target()
	var gun_to_target_direction = (target_point - gun_node.global_position).normalized()

	# Fire projectile toward that point
	projectile.setup(gun_to_target_direction)

func camera_look(mouse_movement: Vector2) -> void:
	camera_rotation += mouse_movement

	transform.basis = Basis()
	if character_node:
		character_node.transform.basis = Basis()

	if character_node:
		character_node.rotate_object_local(Vector3(0,1,0), -camera_rotation.x)
	rotate_object_local(Vector3(1,0,0), -camera_rotation.y)

	camera_rotation.y = clamp(camera_rotation.y, -max_y_rotation, max_y_rotation)
	
func swap_camera_alignment() -> void:
	match current_camera_alignment:
		CameraAlignment.RIGHT:
			set_current_camera_alignment(CameraAlignment.LEFT)
		CameraAlignment.LEFT:
			set_current_camera_alignment(CameraAlignment.RIGHT)
		CameraAlignment.CENTRE:
			return
	
	update_gun_orientation()
	var new_pos: float = default_edge_spring_arm_length * current_camera_alignment
	set_rear_spring_arm_position(new_pos, camera_alignment_speed)

func update_gun_orientation() -> void:
	if gun_node:
		var new_x = default_gun_x_offset * current_camera_alignment
		gun_node.position.x = new_x

func set_current_camera_alignment(alignment: CameraAlignment) -> void:
	current_camera_alignment = alignment
	
func set_rear_spring_arm_position(pos: float, speed: float) -> void:
	if camera_tween:
		camera_tween.kill()

	camera_tween = get_tree().create_tween()
	if edge_spring_arm_node:
		camera_tween.tween_property(edge_spring_arm_node, "spring_length", pos, speed)

func enter_aim() -> void:
	is_aiming = true
	if camera_tween:
		camera_tween.kill()

	camera_tween = get_tree().create_tween()
	camera_tween.set_parallel()

	if camera_node:
		camera_tween.tween_property(camera_node, "fov", aim_fov, aim_speed)
	if edge_spring_arm_node:
		camera_tween.tween_property(edge_spring_arm_node, "spring_length", aim_edge_spring_length * current_camera_alignment, aim_speed)
	if rear_spring_arm_node:
		camera_tween.tween_property(rear_spring_arm_node, "spring_length", aim_rear_spring_length, aim_speed)

func exit_aim() -> void:
	is_aiming = false
	if camera_tween:
		camera_tween.kill()

	camera_tween = get_tree().create_tween()
	camera_tween.set_parallel()

	if camera_node:
		camera_tween.tween_property(camera_node, "fov", default_fov, aim_speed)
	if edge_spring_arm_node:
		camera_tween.tween_property(edge_spring_arm_node, "spring_length", default_edge_spring_arm_length * current_camera_alignment, aim_speed)
	if rear_spring_arm_node:
		camera_tween.tween_property(rear_spring_arm_node, "spring_length", default_rear_spring_arm_length, aim_speed)
