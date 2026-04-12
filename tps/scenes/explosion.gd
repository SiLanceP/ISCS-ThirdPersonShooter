extends Node3D

@export var duration: float = 0.35
@export var start_scale: float = 0.2
@export var end_scale: float = 1.0
@export var base_color: Color = Color(1, 0.8, 0.3, 1)

func setup(start_scale_: float, end_scale_: float, duration_: float, base_color_: Color) -> void:
	start_scale = start_scale_
	end_scale = end_scale_
	duration = duration_
	base_color = base_color_

func _ready() -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = SphereMesh.new()
	mesh_instance.mesh.radius = 0.5
	mesh_instance.mesh.radial_segments = 10
	mesh_instance.mesh.rings = 8

	var material = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.emission_enabled = true
	material.emission = base_color * 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	var light = OmniLight3D.new()
	light.light_color = base_color
	light.light_energy = 8.0
	light.omni_range = 5.0
	light.shadow_enabled = false

	add_child(mesh_instance)
	add_child(light)

	mesh_instance.scale = Vector3.ONE * start_scale
	
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE * end_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(light, "light_energy", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "queue_free"))
