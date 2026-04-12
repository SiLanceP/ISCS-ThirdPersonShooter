extends Node3D

func _ready() -> void:
	create_crosshair()

func create_crosshair() -> void:
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"

	var cross = Control.new()
	cross.name = "Crosshair"
	cross.anchor_left = 0.5
	cross.anchor_top = 0.5
	cross.anchor_right = 0.5
	cross.anchor_bottom = 0.5
	cross.size = Vector2(16, 16)
	cross.position = Vector2(-8, -8)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var horizontal = ColorRect.new()
	horizontal.color = Color(1, 1, 1, 1)
	horizontal.size = Vector2(16, 2)
	horizontal.position = Vector2(0, 7)

	var vertical = ColorRect.new()
	vertical.color = Color(1, 1, 1, 1)
	vertical.size = Vector2(2, 16)
	vertical.position = Vector2(7, 0)

	cross.add_child(horizontal)
	cross.add_child(vertical)
	ui_layer.add_child(cross)
	add_child(ui_layer)
