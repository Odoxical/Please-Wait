extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("move_forward"):
		position.x += delta*10
		print("Moving")
		print(position.x)
	if Input.is_action_pressed("move_back"):
		position.x -= delta*10
		print("Moving")
		print(position.x)
	if Input.is_action_pressed("move_left"):
		position.z += delta*10
		print("Moving")
		print(position.z)
	if Input.is_action_pressed("move_right"):
		position.z -= delta*10
		print("Moving")
		print(position.z)
