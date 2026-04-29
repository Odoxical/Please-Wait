extends CharacterBody3D

var height = 0
var ground_plane = Plane(Vector3.UP,height)
var speed_factor : float

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		print(event.relative)
		position.x += event.relative.x * speed_factor
		position.z += event.relative.y * speed_factor
	if Input.is_action_pressed("Scroll_Up"):
		position.y += 10*speed_factor
	if Input.is_action_pressed("Scroll_Down"):
		position.y -= 10*speed_factor
	if Input.is_action_pressed("escape_mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta):
	speed_factor = delta
