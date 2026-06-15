extends MeshInstance3D

# Stretches this mesh (a unit-height capsule) between two points each frame —
# a single rigid telescoping leg, no skeleton or IK needed.
@export var hip: Node3D
@export var foot: Node3D

func _process(_delta):
	if !hip || !foot:
		return
	var a = hip.global_position
	var b = foot.global_position
	var dir = b - a
	var length = dir.length()
	if length < 0.001:
		return

	var y_axis = dir / length
	var x_axis = y_axis.cross(Vector3.UP)
	if x_axis.length() < 0.01:
		x_axis = Vector3.RIGHT
	else:
		x_axis = x_axis.normalized()
	var z_axis = x_axis.cross(y_axis)

	global_transform = Transform3D(Basis(x_axis, y_axis * length, z_axis), (a + b) / 2)
