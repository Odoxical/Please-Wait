class_name FootController
extends Node

signal foot_selected(foot_id: int)
signal foot_moved(foot_id: int, direction: Vector3)

var panic_mode = Globals.panic_mode

@export var config: FootConfig

@onready var move_speed = config.move_speed

@onready var body: Node3D = $"../Body"
@onready var _ik_nodes: Array[SkeletonIK3D] = [
	$"../Body/Skeleton3D/leg_fl",
	$"../Body/Skeleton3D/leg_fr",
	$"../Body/Skeleton3D/leg_rl",
	$"../Body/Skeleton3D/leg_rr",
]
@onready var feet: Array[FootTarget] = [
	$"../FootTargets/FootTarget_FL",
	$"../FootTargets/FootTarget_FR",
	$"../FootTargets/FootTarget_RL",
	$"../FootTargets/FootTarget_RR",
]

@onready var state=FootTarget.FootState
@onready var grounded=FootTarget.FootState.GROUNDED

const ACTION_SELECT := ["select_foot_1", "select_foot_2", "select_foot_3", "select_foot_4"]
const ACTION_MOVE_FORWARD  := "move_forward"
const ACTION_MOVE_BACK     := "move_back"
const ACTION_MOVE_LEFT     := "move_left"
const ACTION_MOVE_RIGHT    := "move_right"
const ACTION_MOVE_UP       := "move_up"
const ACTION_MOVE_DOWN     := "move_down"

var active_foot_index: int = 0
var _body_tween: Tween


func _ready() -> void:
	for ik in _ik_nodes:
		ik.start()
	for foot in feet:
		foot.body_ref = body
		foot.foot_placed.connect(_on_foot_placed)
	_update_selection()


func _unhandled_input(event: InputEvent) -> void:
	for i in ACTION_SELECT.size():
		if event.is_action_pressed(ACTION_SELECT[i]):
			active_foot_index = i
			_update_selection()
			foot_selected.emit(i)
			return
	if event.is_action_pressed("panic"):
		if panic_mode==true:
			move_speed = config.panic_move_speed
		else:
			move_speed = config.move_speed

	if event.is_action_pressed("ui_focus_next"):
		active_foot_index = (active_foot_index + 1) % feet.size()
		_update_selection()
	elif event.is_action_pressed("ui_focus_prev"):
		active_foot_index = (active_foot_index - 1 + feet.size()) % feet.size()
		_update_selection()

	if event.is_action_pressed(ACTION_MOVE_UP):
		feet[active_foot_index].lift()
	elif event.is_action_pressed(ACTION_MOVE_DOWN):
		feet[active_foot_index].place()


func _process(delta: float) -> void:
	var foot: FootTarget = feet[active_foot_index]
	if foot.state != FootTarget.FootState.LIFTED:
		return

	var dir := Vector3.ZERO
	if Input.is_action_pressed(ACTION_MOVE_FORWARD) and state != grounded: dir.z -= 1.0
	if Input.is_action_pressed(ACTION_MOVE_BACK)and state != grounded:    dir.z += 1.0
	if Input.is_action_pressed(ACTION_MOVE_LEFT)and state != grounded:    dir.x -= 1.0
	if Input.is_action_pressed(ACTION_MOVE_RIGHT)and state != grounded:   dir.x += 1.0


	if dir == Vector3.ZERO:
		return

	dir = dir.normalized()
	var raw_pos : Vector3 = foot.global_position + dir * move_speed * delta
	var rest := foot.get_rest_world_pos()
	var clamped := rest + (raw_pos - rest).limit_length(config.max_reach)

	foot.global_position = Vector3(clamped.x, foot.global_position.y, clamped.z)
	foot_moved.emit(active_foot_index, dir)


func _update_selection() -> void:
	for i in feet.size():
		feet[i].is_selected = (i == active_foot_index)


func _on_foot_placed(_foot: FootTarget) -> void:
	var centroid := Vector3.ZERO
	for f in feet:
		centroid += f.global_position
	centroid /= feet.size()

	var target := Vector3(centroid.x, body.global_position.y, centroid.z)
	if target.distance_squared_to(body.global_position) < 0.0001:
		return

	if _body_tween:
		_body_tween.kill()
	_body_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_body_tween.tween_property(body, "global_position", target, config.archaic_variable)
