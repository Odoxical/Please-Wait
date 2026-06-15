extends Camera3D

@export var follow_distance: float = 12.0
@export var follow_height: float = 5.0
@export var follow_speed: float = 4.0

@onready var target: Node3D = get_parent_node_3d()

func _ready():
	top_level = true
	make_current()
	global_position = _desired_position()

func _process(delta):
	global_position = global_position.lerp(_desired_position(), follow_speed * delta)
	look_at(target.global_position, Vector3.UP)

func _desired_position() -> Vector3:
	# Stay behind the body based on its yaw only, so body tilt doesn't bob the camera
	var back = target.global_transform.basis.z
	back.y = 0
	if back.length() < 0.01:
		back = Vector3.BACK
	back = back.normalized()
	return target.global_position + back * follow_distance + Vector3.UP * follow_height
