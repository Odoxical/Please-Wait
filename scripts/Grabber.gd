extends CharacterBody3D

var panic_mode = false
var height = 0
var ground_plane = Plane(Vector3.UP,height)
var speed_factor : float
var hand_target_y
var arm_length=1

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		print(event.relative)
		if position.x >-arm_length and position.x<arm_length:
			position.x += event.relative.x * speed_factor
		elif position.x <-arm_length and event.relative.x * speed_factor>0:
			position.x += event.relative.x * speed_factor
		elif position.x >arm_length and event.relative.x * speed_factor<0:
			position.x += event.relative.x * speed_factor
		else:
			pass
			
		if position.z >-arm_length and position.z<arm_length:
			position.z += event.relative.y * speed_factor
		elif position.z <-arm_length and event.relative.y * speed_factor>0:
			position.z += event.relative.y * speed_factor
		elif position.z >arm_length and event.relative.y * speed_factor<0:
			position.z += event.relative.y * speed_factor
		else:
			pass
	if Input.is_action_pressed("Scroll_Up"):
		if panic_mode==false:
			velocity.y += 250*speed_factor
		else:
			velocity.y += 500*speed_factor
	if Input.is_action_pressed("Scroll_Down"):
		if panic_mode==false:
			velocity.y -= 250*speed_factor
		else:
			velocity.y -= 500*speed_factor
	if Input.is_action_pressed("escape_mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_action_just_pressed("panic"):
		if panic_mode==false:
			panic_mode=true
		elif panic_mode==true:
			panic_mode=false

func _process(delta):
	if panic_mode == true:
		arm_length=12
	else:
		arm_length=10
	
	if panic_mode==false:
		speed_factor = delta
	else:
		speed_factor = delta*2
	position.y += velocity.y*speed_factor
	if panic_mode == false:
		velocity.y*=0.95
	else:
		velocity.y*=0.5
