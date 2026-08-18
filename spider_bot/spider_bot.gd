extends Node3D

@export var move_speed: float = 5.0
@export var leg_move_speed: float = 4.0
@export var ground_offset: float = 0.5
@export var max_leg_reach: float = 4.0
@export var gravity: float = 20.0
@export var plant_threshold: float = 0.3
@export var body_recenter_speed: float = 3.0
@export var tip_acceleration: float = 6.0
# Rest position of a foot in body-local space; x/z are mirrored per leg
@export var home_offset := Vector3(3.59, -2.11, 3.55)
@export var lean_speed: float = 2.0
@export var max_lean: float = 1.0
@export var com_balance_bias: float = 1.0
@export var com_visual_lerp_speed: float = 6.0

@onready var fl_leg = $FrontLeftIKTarget
@onready var fr_leg = $FrontRightIKTarget
@onready var bl_leg = $BackLeftIKTarget
@onready var br_leg = $BackRightIKTarget

@export var pivot_turn_speed: float = 1.5 # radians/sec while pivoting ##

var is_pivoting := false ##
var pivot_leg: Node3D ## 
var highlight_material: StandardMaterial3D ##

var _biased_com := Vector3.ZERO
var _visual_com := Vector3.ZERO

var selected_leg: Node3D
var home_offsets := {}
var init_frames := 0
var highlight: MeshInstance3D
var planted := {}
var fall_velocity := 0.0
var is_tipping := false
var tip_velocity := 0.0
var leg_order: Array = []
var leg_names := {}
var snap_requested := false
var lean_offset := Vector2.ZERO

func _ready():
	home_offsets = {
		fl_leg: Vector3(-home_offset.x, home_offset.y, -home_offset.z),
		fr_leg: Vector3(home_offset.x, home_offset.y, -home_offset.z),
		bl_leg: Vector3(-home_offset.x, home_offset.y, home_offset.z),
		br_leg: Vector3(home_offset.x, home_offset.y, home_offset.z),
	}
	for leg in home_offsets:
		leg.global_position = global_transform * home_offsets[leg]

	leg_order = [fl_leg, fr_leg, br_leg, bl_leg]
	leg_names = {
		fl_leg: "Front Left",
		fr_leg: "Front Right",
		bl_leg: "Back Left",
		br_leg: "Back Right",
	}

	_biased_com = global_position
	_visual_com = global_position

	_create_highlight()
	_select_leg(fl_leg)

func _create_highlight():
	highlight = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.4)
	mat.emission_energy_multiplier = 3.0
	sphere.material = mat
	highlight_material = mat##
	highlight.mesh = sphere
	highlight.top_level = true
	add_child(highlight)

func _select_leg(leg: Node3D):
	is_pivoting = false##
	pivot_leg = null##
	selected_leg = leg
	print("Selected leg: " + leg_names[leg])

func _toggle_pivot(leg: Node3D):##
	if is_pivoting && pivot_leg == leg:##
		is_pivoting = false##
		pivot_leg = null##
		print("Pivot mode off")##
		return##
##
	if !planted.get(leg, false):##
		print("Can't pivot around " + leg_names[leg] + " — it's not on the ground")##
		return##
##
	selected_leg = leg##
	pivot_leg = leg##
	is_pivoting = true##
	print("Pivoting around: " + leg_names[leg])##

func _handle_pivot(delta):##
	if !pivot_leg:##
		return##
	var turn_input = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))##
	if absf(turn_input) < 0.001:##
		return##

	var angle = turn_input * pivot_turn_speed * delta##
	var pivot_point = pivot_leg.global_position##
	var rot = Basis(Vector3.UP, angle)##

	# Spin the body around the planted foot
	global_position = pivot_point + rot * (global_position - pivot_point)##
	global_transform.basis = (rot * global_transform.basis).orthonormalized()##

	# Drag every other foot along the same rotation so they stay
	# attached to the body instead of getting left behind
	for leg in home_offsets:##
		if leg == pivot_leg:##
			continue##
		var pos = pivot_point + rot * (leg.global_position - pivot_point)##
		var floor_y = _ground_height(pos)##
		if floor_y > -INF:##
			pos.y = floor_y##
		leg.global_position = pos##

func _input(event):
	if event is InputEventKey && event.pressed && !event.echo:
		match event.physical_keycode:
			KEY_U:
				_select_leg(fl_leg)
			KEY_I:
				_select_leg(fr_leg)
			KEY_J:
				_select_leg(bl_leg)
			KEY_K:
				_select_leg(br_leg)
			KEY_TAB:
				var i = leg_order.find(selected_leg)
				_select_leg(leg_order[(i + 1) % leg_order.size()])
			KEY_SPACE:
				snap_requested = true

func _process(delta):
	# While tipping over, the fall owns the body — don't fight it
	if !is_tipping:
		var plane1 = Plane(bl_leg.global_position, fl_leg.global_position, fr_leg.global_position)
		var plane2 = Plane(fr_leg.global_position, br_leg.global_position, bl_leg.global_position)
		var avg_normal = ((plane1.normal + plane2.normal) / 2).normalized()
	
		var target_basis = _basis_from_normal(avg_normal)
		transform.basis = lerp(transform.basis, target_basis, move_speed * delta).orthonormalized()
	
		# Keep the body centered over the feet (plus any deliberate lean)
		# so stepping legs forward pulls the body along with them
		var centroid = (fl_leg.position + fr_leg.position + bl_leg.position + br_leg.position) / 4
		var lean_world = transform.basis * Vector3(lean_offset.x, 0, lean_offset.y)
		var horiz_target = Vector3(centroid.x + lean_world.x, position.y, centroid.z + lean_world.z)
		position = lerp(position, horiz_target, body_recenter_speed * delta)
	
		# Only feet that are on the ground can support the body — raised feet
		# must not push the body upward
		var avg = Vector3.ZERO
		var support_count = 0
		for leg in home_offsets:
			if planted.get(leg, true):
				avg += leg.position
				support_count += 1
		if support_count > 0:
			avg /= support_count
			var target_pos = avg + transform.basis.y * ground_offset
			var distance = transform.basis.y.dot(target_pos - position)
			position = lerp(position, position + transform.basis.y * distance, move_speed * delta)
	
	# Smoothly chase the biased COM for the indicator to read
	_visual_com = _visual_com.lerp(_biased_com, com_visual_lerp_speed * delta)
	
	if selected_leg:
		highlight.global_position = selected_leg.global_position
	
	if highlight_material:
		var c = Color(1.0, 0.55, 0.1) if is_pivoting else Color(0.2, 1.0, 0.4)
		highlight_material.albedo_color = c
		highlight_material.emission = c

func _physics_process(delta):
	# CSG collision isn't ready on the very first frames; settle the
	# starting pose onto the ground before accepting input
	if init_frames < 5:
		init_frames += 1
		for leg in home_offsets:
			leg.global_position = _snap_to_ground(global_transform * home_offsets[leg])
		return

	_update_planted()

	var support: Array = []
	for leg in home_offsets:
		if planted[leg]:
			support.append(leg)

	if support.is_empty():
		is_tipping = false
		_apply_gravity(delta)
	else:
		fall_velocity = 0.0
		var pivot = _find_tip_pivot(support)
		if pivot.is_empty():
			is_tipping = false
			tip_velocity = 0.0
		else:
			is_tipping = true
			_apply_tipping(pivot[0], pivot[1], delta)

	_handle_lean(delta)
	if is_pivoting:
		_handle_pivot(delta)
	else:
		_handle_leg_input(delta)

	if snap_requested:
		snap_requested = false
		if selected_leg:
			selected_leg.global_position = _snap_to_ground(selected_leg.global_position)

func _handle_lean(delta):
	# Arrow keys shift the body's centre of mass — an active balance tool
	var lean_x = Input.get_axis("ui_left", "ui_right")
	var lean_z = Input.get_axis("ui_up", "ui_down")
	lean_offset.x = clampf(lean_offset.x + lean_x * lean_speed * delta, -max_lean, max_lean)
	lean_offset.y = clampf(lean_offset.y + lean_z * lean_speed * delta, -max_lean, max_lean)

func _update_planted():
	for leg in home_offsets:
		var floor_y = _ground_height(leg.global_position)
		planted[leg] = floor_y > -INF && leg.global_position.y <= floor_y + plant_threshold

# Returns [pivot_point, pivot_axis] to tip around, or [] if the body is
# stable: stable means the centre of mass sits over the support polygon
# formed by the planted feet
func _find_tip_pivot(support: Array) -> Array:
	var com = global_position
	# Pretend the centre of gravity sits a bit further from any leg
	# that's currently lifted, shifting it toward the remaining support
	# feet. This stops a single leg lifting for a step from immediately
	# pushing the COM outside the (now smaller) support polygon.
	for leg in home_offsets:
		if !support.has(leg):
			var away = com - leg.global_position
			away.y = 0
			if away.length() > 0.001:
				com += away.normalized() * com_balance_bias
	_biased_com = com   # always capture final value for the visual

	if support.size() == 1:
		# Single foot: pivot about it, falling away in the direction of the body
		var foot = support[0].global_position
		var fall_dir = com - foot
		fall_dir.y = 0
		if fall_dir.length() < 0.01:
			fall_dir = -global_transform.basis.z
			fall_dir.y = 0
		var axis = Vector3.UP.cross(fall_dir.normalized()).normalized()
		return [foot, axis]

	if support.size() == 2:
		# Two feet form a line, never a stable polygon — tip over that line
		var a = support[0].global_position
		var b = support[1].global_position
		return [a, (b - a).normalized()]

	# 3+ feet: stable only if the centre of mass is inside their hull
	var points := PackedVector2Array()
	for leg in support:
		var p = leg.global_position
		points.append(Vector2(p.x, p.z))
	var hull = Geometry2D.convex_hull(points)
	var com2 = Vector2(com.x, com.z)
	if Geometry2D.is_point_in_polygon(com2, hull):
		return []

	# Outside the polygon: tip over the hull edge closest to the centre of mass
	var best_dist = INF
	var best_a = Vector3.ZERO
	var best_b = Vector3.ZERO
	for i in hull.size() - 1:
		var closest = Geometry2D.get_closest_point_to_segment(com2, hull[i], hull[i + 1])
		var d = com2.distance_to(closest)
		if d < best_dist:
			best_dist = d
			best_a = _foot_at(support, hull[i])
			best_b = _foot_at(support, hull[i + 1])
	return [best_a, (best_b - best_a).normalized()]

func _foot_at(support: Array, p: Vector2) -> Vector3:
	for leg in support:
		var fp = leg.global_position
		if Vector2(fp.x, fp.z).is_equal_approx(p):
			return fp
	return Vector3(p.x, global_position.y, p.y)

func _apply_tipping(pivot_point: Vector3, axis: Vector3, delta):
	# Gravity torque about the pivot edge decides which way we rotate
	var torque = (global_position - pivot_point).cross(Vector3.DOWN).dot(axis)
	tip_velocity += signf(torque) * tip_acceleration * delta
	var angle = tip_velocity * delta
	if absf(angle) < 0.000001:
		return

	var rot = Basis(axis, angle)
	global_position = pivot_point + rot * (global_position - pivot_point)
	global_transform.basis = (rot * global_transform.basis).orthonormalized()

	# Raised feet swing with the body; whichever touches down first
	# becomes the new support and can stop the fall
	for leg in home_offsets:
		if !planted.get(leg, false):
			var pos = pivot_point + rot * (leg.global_position - pivot_point)
			var floor_y = _ground_height(pos)
			if pos.y < floor_y:
				pos.y = floor_y
			leg.global_position = pos

func _apply_gravity(delta):
	# No feet on the ground: the body falls, carrying the raised feet
	# with it until they touch down
	fall_velocity += gravity * delta
	var drop = fall_velocity * delta
	global_position.y -= drop
	for leg in home_offsets:
		var pos = leg.global_position
		pos.y -= drop
		var floor_y = _ground_height(pos)
		if pos.y < floor_y:
			pos.y = floor_y
		leg.global_position = pos

func _handle_leg_input(delta):
	if !selected_leg:
		return
		return
	else:
		var forward_input = float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
		var right_input = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
		var up_input = float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q))
		# Move on the world XZ plane relative to the camera, so W is always
		# "away from the viewer" no matter how the body has twisted
		if planted.get(selected_leg, false):
			forward_input = 0.0
			right_input   = 0.0
		var cam = get_viewport().get_camera_3d()
		var view_basis = cam.global_transform.basis if cam else transform.basis
		var forward = -view_basis.z
		forward.y = 0
		forward = forward.normalized()
		var right = view_basis.x
		right.y = 0
		right = right.normalized()

		var motion = forward * forward_input + right * right_input + Vector3.UP * up_input
		var new_pos = selected_leg.global_position + motion * leg_move_speed * delta

		# Keep the foot within reach of its rest position on the body
		var anchor = global_transform * home_offsets[selected_leg]
		var offset = new_pos - anchor
		if offset.length() > max_leg_reach:
			new_pos = anchor + offset.normalized() * max_leg_reach

		# Don't let the foot go below the ground
		var floor_y = _ground_height(new_pos)
		if new_pos.y < floor_y:
			new_pos.y = floor_y

		selected_leg.global_position = new_pos
	

func _ground_height(pos: Vector3) -> float:
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 10.0, pos + Vector3.DOWN * 10.0)
	query.collision_mask = 1
	var hit = space.intersect_ray(query)
	if hit:
		return hit.position.y
	return -INF

func _snap_to_ground(pos: Vector3) -> Vector3:
	var floor_y = _ground_height(pos)
	if floor_y > -INF:
		pos.y = floor_y
	return pos

func _basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()
	result.x = normal.cross(transform.basis.z)
	result.y = normal
	result.z = transform.basis.x.cross(normal)

	result = result.orthonormalized()
	result.x *= scale.x
	result.y *= scale.y
	result.z *= scale.z

	return result
