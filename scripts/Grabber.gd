extends CharacterBody3D
@export_category("Hand Config")
@export var normal_speed = 250
@export var panic_speed = 500
@export var normal_arm_length: float = 0.8
@export var panic_arm_length: float = 1.2
@export var normal_smoothing = 0.95
@export var panic_smoothing = 0.5
@export var mouse_sensitivity: float = 0.0015
@export var min_arm_length: float = 0.16
var panic_mode = false
var height = 0
var ground_plane = Plane(Vector3.UP, height)
var speed_factor: float
var arm_length = normal_arm_length
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var flat_pos = Vector2(position.x, position.z)
		var dist = flat_pos.length()
		var reach = clamp(dist / arm_length, 0.0, 1.0)
		var raw_move = Vector2(event.relative.x, event.relative.y) * mouse_sensitivity
		if dist > 0.001:
			var radial_dir = flat_pos.normalized()
			var tangent_dir = Vector2(-radial_dir.y, radial_dir.x)
			var radial_amount = raw_move.dot(radial_dir)
			var tangent_amount = raw_move.dot(tangent_dir)
			if radial_amount > 0.0:
				radial_amount *= 1.0 - reach * reach
			var move = radial_dir * radial_amount + tangent_dir * tangent_amount
			var new_pos = flat_pos + move
			if new_pos.length() > arm_length:
				new_pos = new_pos.normalized() * arm_length
			if new_pos.length() > 0.001 and new_pos.length() < min_arm_length:
				new_pos = new_pos.normalized() * min_arm_length
			position.x = new_pos.x
			position.z = new_pos.y
		else:
			var new_pos = flat_pos + raw_move
			if new_pos.length() > arm_length:
				new_pos = new_pos.normalized() * arm_length
			if new_pos.length() > 0.001 and new_pos.length() < min_arm_length:
				new_pos = new_pos.normalized() * min_arm_length
			position.x = new_pos.x
			position.z = new_pos.y
	if Input.is_action_pressed("Scroll_Up"):
		velocity.y += (panic_speed if panic_mode else normal_speed) * speed_factor/5
	if Input.is_action_pressed("Scroll_Down"):
		velocity.y -= (panic_speed if panic_mode else normal_speed) * speed_factor/5
	if Input.is_action_pressed("escape_mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_action_just_pressed("panic"):
		panic_mode = !panic_mode
func _process(delta):
	arm_length = panic_arm_length if panic_mode else normal_arm_length
	speed_factor = delta * (2.0 if panic_mode else 1.0)
	position.y += velocity.y * speed_factor
	velocity.y *= panic_smoothing if panic_mode else normal_smoothing
	var flat_pos = Vector2(position.x, position.z)
	if flat_pos.length() > 0.05:
		var angle = atan2(flat_pos.x, flat_pos.y) 
		rotation.y = angle+1.5
