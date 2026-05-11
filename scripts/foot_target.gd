class_name FootTarget
extends Marker3D

signal foot_placed(foot: FootTarget)

@export var config: FootConfig
@export var rest_offset: Vector3
@export var foot_id: int

var is_selected: bool = false
var is_moving: bool = false
var body_ref: Node3D

var _tween: Tween


func move_foot(direction: Vector3) -> void:
	if is_moving:
		return
	var target_pos: Vector3 = global_position + direction * config.move_speed * get_process_delta_time()
	_step_to(target_pos)


func step_to_position(world_pos: Vector3) -> void:
	if is_moving:
		return
	_step_to(world_pos)


func _step_to(destination: Vector3) -> void:
	is_moving = true
	var start: Vector3 = global_position
	var peak: Vector3 = (start + destination) / 2.0 + Vector3.UP * config.lift_height

	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_tween.tween_method(_set_pos_arc.bind(start, peak), 0.0, 1.0, config.step_duration / 2.0)
	_tween.tween_method(_set_pos_arc.bind(peak, destination), 0.0, 1.0, config.step_duration / 2.0)
	_tween.tween_callback(_on_step_complete)


func _set_pos_arc(t: float, from: Vector3, to: Vector3) -> void:
	global_position = from.lerp(to, t)


func _on_step_complete() -> void:
	is_moving = false
	foot_placed.emit(self)


func get_rest_world_pos() -> Vector3:
	if body_ref:
		return body_ref.global_position + body_ref.global_basis * rest_offset
	return global_position
