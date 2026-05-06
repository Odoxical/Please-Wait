extends Node3D
var selected_foot=false

func _unhandled_input(event):
	if Input.is_action_just_pressed("select_foot_1") and name=="Foot 1":
		selected_foot=true
		print("Foot 1 Selected succesfully")
	elif Input.is_action_just_pressed("select_foot_2") and name=="Foot 2":
		selected_foot=true
		print("Foot 2 Selected succesfully")
	elif Input.is_action_just_pressed("select_foot_3") and name=="Foot 3":
		selected_foot=true
		print("Foot 3 Selected succesfully")
	elif Input.is_action_just_pressed("select_foot_4") and name=="Foot 4":
		selected_foot=true
		print("Foot 4 Selected succesfully")
	if Input.is_action_just_pressed("select_foot_1") and not name=="Foot 1":
		selected_foot=false
		print("That was the wrong button to select ",name)
	elif Input.is_action_just_pressed("select_foot_2") and not name=="Foot 2":
		selected_foot=false
		print("That was the wrong button to select ",name)
	elif Input.is_action_just_pressed("select_foot_3") and not name=="Foot 3":
		selected_foot=false
		print("That was the wrong button to select " ,name)
	elif Input.is_action_just_pressed("select_foot_4") and not name=="Foot 4":
		selected_foot=false
		print("That was the wrong button to select ",name)
	else:
		pass


func _process(delta: float) -> void:
	if Input.is_action_pressed("move_forward"):
		position.x += 1+delta*1
		print("Moving")
		print(position.x)
	if Input.is_action_pressed("move_back"):
		position.x -= 1+delta*1
		print("Moving")
		print(position.x)
	if Input.is_action_pressed("move_left"):
		position.z += 1+delta*1
		print("Moving")
		print(position.z)
	if Input.is_action_pressed("move_right"):
		position.z -= 1+delta*10
		print("Moving")
		print(position.z)
