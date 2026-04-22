extends Node3D
var height = 0
var ground_plane = Plane(Vector3.UP,height)

func _input(event):
	if event is InputEventMouseMotion
