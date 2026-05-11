extends Node3D
var selected_foot=false
var panic_mode=false
var Speed_factor=10

func _unhandled_input(event):
	if selected_foot==true:
		position.y = 0.25*(125-Speed_factor)
	else:
		position.y = 0
	if Input.is_action_just_pressed("panic") and panic_mode==false:
		Speed_factor=100
		panic_mode=true
		print(panic_mode)
	elif Input.is_action_just_pressed("panic") and panic_mode==true:
		Speed_factor=50
		panic_mode=false
		print(panic_mode)
	
	elif Input.is_action_just_pressed("select_foot_1") and name=="Foot 1":
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
	
	elif Input.is_action_just_released("select_foot_1") and name=="Foot 1":
		selected_foot=true
		position.y -= 0.25*(125-Speed_factor)
		print("Foot 1 Selected succesfully")
	elif Input.is_action_just_released("select_foot_2") and name=="Foot 2":
		selected_foot=true
		position.y -= 0.25*(125-Speed_factor)
		print("Foot 2 Selected succesfully")
	elif Input.is_action_just_released("select_foot_3") and name=="Foot 3":
		selected_foot=true
		position.y -= 0.25*(125-Speed_factor)
		print("Foot 3 Selected succesfully")
	elif Input.is_action_just_released("select_foot_4") and name=="Foot 4":
		selected_foot=true
		position.y -= 0.25*(125-Speed_factor)
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


func _process(delta: float) -> void:
	if Input.is_action_pressed("move_forward") and selected_foot==true:
		position.x -= delta*Speed_factor
		print("Moving")
		print(position.x)
	if Input.is_action_pressed("move_back") and selected_foot==true:
		position.x += delta*Speed_factor
		print("Moving")
		print(position.x)
	if Input.is_action_pressed("move_left") and selected_foot==true:
		position.z += delta*Speed_factor
		print("Moving")
		print(position.z)
	if Input.is_action_pressed("move_right") and selected_foot==true:
		position.z -= delta*Speed_factor
		print("Moving")
		print(position.z)
