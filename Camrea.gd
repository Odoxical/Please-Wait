extends Node3D



func physics_process(delta: float) -> void:
	var cam := $Camera3D
	var mouse_position = get_viewport().get_mouse_position()
	print(mouse_position)
	pass
