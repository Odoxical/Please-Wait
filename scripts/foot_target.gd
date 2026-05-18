class_name FootTarget
extends Marker3D

signal foot_placed(foot: FootTarget)

enum FootState { GROUNDED, LIFTING, LIFTED, PLACING }

@export var config: FootConfig
@export var rest_offset: Vector3
@export var foot_id: int

var state: FootState = FootState.GROUNDED
var is_selected: bool = false
var body_ref: Node3D

var _tween: Tween


func lift() -> void:
	if state != FootState.GROUNDED:
		return
	state = FootState.LIFTING
	var lifted_y := global_position.y + config.lift_height

	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "global_position:y", lifted_y, config.archaic_variable / 2.0)
	_tween.tween_callback(func(): state = FootState.LIFTED)


func place() -> void:
	if state != FootState.LIFTED:
		return
	state = FootState.PLACING

	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "global_position:y", 0.0, config.archaic_variable / 2.0)
	_tween.tween_callback(_on_placed)


func _on_placed() -> void:
	state = FootState.GROUNDED
	foot_placed.emit(self)


func get_rest_world_pos() -> Vector3:
	if body_ref:
		return body_ref.global_position + body_ref.global_basis * rest_offset
	return global_position
