class_name FootTarget
extends Marker3D

signal foot_placed(foot: FootTarget)

@export var config: FootConfig
@export var rest_offset: Vector3 #Where the foot starts at. Changeable in inspector.
@export var foot_id: int #Tells what foot it is. Changeable in inspector.
var is_selected = false
var is_moving = false
var body_ref: Node3D #Gets the body. I have no idea why this is used and not something resolved around hierarchy.

var _tween: Tween


func move_foot(direction: Vector3) -> void:
	if is_moving:
		return
	var target_pos: Vector3 = global_position + direction * config.move_speed * get_process_delta_time()
	_step_to(target_pos)


func step_to_position(world_pos: Vector3) -> void:
	if is_moving:
		return
	_step_to(world_pos) #Why is this world_pos and not target_pos? 


func _step_to(destination) -> void:
	is_moving = true
	var start = global_position #Gets the position the step starts at.
	var peak = (start + destination) / 2.0 #+ Vector3.UP * config.lift_height #The previous is code made from the ai misunderstanding us,
	# and thinking that I wanted it to take a step every few seconds.
	#Yould think that changing (start+destination)/2.0 to (start+destination)/3.0 would decrease the amount it moves. It doesn't.

	if _tween: #attempting to read this block is like trying to read the carvings of a clay tablet while underwater.
		_tween.kill() #If block is triggered while tween is still happening, stop the tween.
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT) # Problem point 1

	_tween.tween_method(_set_pos_arc.bind(start, peak), 0.0, 1.0, config.step_duration / 2.0) #Possible Problem point 2
	_tween.tween_method(_set_pos_arc.bind(peak, destination), 0.0, 1.0, config.step_duration / 2.0) #Possible Problem point 3
	_tween.tween_callback(_on_step_complete)


func _set_pos_arc(t: float, from: Vector3, to: Vector3) -> void: #I have no idea what this does
	global_position = from.lerp(to, t)


func _on_step_complete() -> void:
	is_moving = false
	foot_placed.emit(self)


func get_rest_world_pos() -> Vector3:
	if body_ref:
		return body_ref.global_position + body_ref.global_basis * rest_offset
	return global_position
