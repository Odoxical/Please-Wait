extends CharacterBody3D

var panic_mode = false
var height = 0
var ground_plane = Plane(Vector3.UP,height)
var speed_factor : float
var hand_target_y

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		print(event.relative)
		position.x += event.relative.x * speed_factor
		position.z += event.relative.y * speed_factor
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
	if panic_mode==false:
		speed_factor = delta
	else:
		speed_factor = delta*2
	position.y += velocity.y*speed_factor
	if panic_mode == false:
		velocity.y*=0.95
	else:
		velocity.y*=0.5
