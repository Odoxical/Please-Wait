extends Node3D

# spring_demo.gd
#
# Attach to a Node3D as the root of an empty scene.
# Builds a vertical mass-spring system entirely in code using
# Generic6DOFJoint3D's built-in linear spring on the Y axis.
#
# Controls at runtime:
#   Space     → apply upward impulse   (compress the spring)
#   Down      → apply downward impulse (stretch the spring)
#   R         → reset bob to initial position
#
# Requires Godot 4.x (tested with Jolt and Bullet physics backends).
#
# Scene tree produced at runtime:
#
#   Node3D          ← this script
#   ├── Anchor      (StaticBody3D)
#   ├── Bob         (RigidBody3D)
#   ├── SpringJoint (Generic6DOFJoint3D)
#   ├── SpringHelix (MeshInstance3D  — redrawn every frame)
#   ├── Camera3D
#   └── DirectionalLight3D

# ── Spring parameters ─────────────────────────────────────────────────────────

@export_group("Spring")

## Spring stiffness constant k in N/m.
## For reference: critical damping occurs when damping = 2·√(mass·stiffness)
@export var spring_stiffness: float = 20.0

## Damping coefficient.  0 = no damping; ~2·√(k·m) = critical (no overshoot).
@export var spring_damping: float = 2.0

## Distance from anchor to the spring's zero-force (equilibrium) point.
## Gravity will shift the actual resting position a little below this — that
## is physically correct behaviour (identical to a real hanging spring).
@export var rest_length: float = 2.5


# ── Hanging body ──────────────────────────────────────────────────────────────

@export_group("Hanging Body")

@export var bob_mass: float = 1.0

## Extra downward offset applied at startup to kick the oscillation going.
@export var initial_displacement: float = 0.8


# ── Helix visual ──────────────────────────────────────────────────────────────

@export_group("Spring Visual")

@export var helix_coils: int = 8
@export var helix_radius: float = 0.15
@export var spring_color: Color = Color(0.25, 0.90, 0.40)


# ── Private references ────────────────────────────────────────────────────────

var _anchor : StaticBody3D
var _bob    : RigidBody3D
var _joint  : Generic6DOFJoint3D

var _helix_mi  : MeshInstance3D   # scene node that holds the mesh
var _helix_im  : ImmediateMesh    # rebuilt each frame to trace the coil
var _helix_mat : StandardMaterial3D


# ═════════════════════════════════════════════════════════════════════════════
# Lifecycle
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_create_anchor()
	_create_bob()
	_create_joint()
	_create_helix_visual()
	_create_camera_and_light()


func _process(_delta: float) -> void:
	_redraw_helix()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	if not is_instance_valid(_bob):
		return

	match event.keycode:
		KEY_SPACE:
			_bob.apply_central_impulse(Vector3(0.0,  5.0, 0.0))  # compress
		KEY_DOWN:
			_bob.apply_central_impulse(Vector3(0.0, -5.0, 0.0))  # stretch
		KEY_R:
			# Reset the bob to its starting position and kill velocity
			_bob.linear_velocity  = Vector3.ZERO
			_bob.angular_velocity = Vector3.ZERO
			_bob.global_position  = Vector3(0.0, -(rest_length + initial_displacement), 0.0)


# ═════════════════════════════════════════════════════════════════════════════
# Scene construction
# ═════════════════════════════════════════════════════════════════════════════

func _create_anchor() -> void:
	_anchor      = StaticBody3D.new()
	_anchor.name = "Anchor"
	add_child(_anchor)

	# A collision shape is required for the physics engine to acknowledge it.
	var col := CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	_anchor.add_child(col)

	# Visual — small grey ball marks the ceiling attachment point.
	var mi  := MeshInstance3D.new()
	var sm  := SphereMesh.new()
	sm.radius = 0.15
	sm.height = 0.30
	mi.mesh   = sm
	var mat           := StandardMaterial3D.new()
	mat.albedo_color   = Color(0.80, 0.80, 0.80)
	mi.material_override = mat
	_anchor.add_child(mi)


func _create_bob() -> void:
	_bob          = RigidBody3D.new()
	_bob.name     = "Bob"
	_bob.mass     = bob_mass
	# Start displaced so there is something to oscillate from the first frame.
	_bob.position = Vector3(0.0, -(rest_length + initial_displacement), 0.0)
	add_child(_bob)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size    = Vector3(0.5, 0.5, 0.5)
	col.shape   = box
	_bob.add_child(col)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.5, 0.5)
	mi.mesh = bm
	var mat          := StandardMaterial3D.new()
	mat.albedo_color  = Color(0.20, 0.45, 0.90)
	mi.material_override = mat
	_bob.add_child(mi)


func _create_joint() -> void:
	_joint      = Generic6DOFJoint3D.new()
	_joint.name = "SpringJoint"
	add_child(_joint)   # must be in the tree before accessing global_position

	# Link the two bodies.  get_path() returns an absolute NodePath which
	# Generic6DOFJoint3D resolves from the scene root — always valid here
	# because both bodies were already added via add_child().
	_joint.node_a = _anchor.get_path()
	_joint.node_b = _bob.get_path()

	# Place the joint at the anchor.  This becomes the origin of the joint's
	# local reference frame — all limit and spring values are in this frame.
	_joint.global_position = _anchor.global_position

	# ── X linear: locked ────────────────────────────────────────────────────
	# Setting lower == upper == 0 pins the axis; no spring applied.
	_lock_linear_axis(Vector3.AXIS_X)

	# ── Y linear: spring axis ───────────────────────────────────────────────
	#
	# We give the bob a generous travel range so the hard limits are only
	# ever reached if something extreme happens (very large impulse, etc.).
	_joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -(rest_length + 4.0))
	_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT,  0.5)

	# The spring pulls node_b toward the equilibrium point.
	# In joint-local Y coordinates: -rest_length means rest_length below the
	# anchor.  Gravity shifts the actual resting height a little further down.
	_joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
	_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS,        spring_stiffness)
	_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING,          spring_damping)
	_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT, -rest_length)

	# ── Z linear: locked ────────────────────────────────────────────────────
	_lock_linear_axis(Vector3.AXIS_Z)

	# ── All angular axes: locked ─────────────────────────────────────────────
	# Prevents the bob from spinning; it can only translate along Y.
	_lock_angular_axis(Vector3.AXIS_X)
	_lock_angular_axis(Vector3.AXIS_Y)
	_lock_angular_axis(Vector3.AXIS_Z)


## Constrain a linear axis to zero displacement (rigid — no spring).
func _lock_linear_axis(axis: int) -> void:
	match axis:
		Vector3.AXIS_X:
			_joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
			_joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
			_joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
		Vector3.AXIS_Y:
			_joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
			_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
			_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
		Vector3.AXIS_Z:
			_joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
			_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
			_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)


## Lock an angular axis so the bob cannot rotate around it.
func _lock_angular_axis(axis: int) -> void:
	match axis:
		Vector3.AXIS_X:
			_joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
			_joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
			_joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
		Vector3.AXIS_Y:
			_joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
			_joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
			_joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
		Vector3.AXIS_Z:
			_joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
			_joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
			_joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)


func _create_helix_visual() -> void:
	_helix_mi      = MeshInstance3D.new()
	_helix_mi.name = "SpringHelix"
	add_child(_helix_mi)

	_helix_im      = ImmediateMesh.new()
	_helix_mi.mesh = _helix_im

	_helix_mat                  = StandardMaterial3D.new()
	_helix_mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
	_helix_mat.albedo_color     = spring_color


func _create_camera_and_light() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(3.0, -(rest_length * 0.5), 6.0)
	cam.look_at(Vector3(0.0, -(rest_length * 0.5), 0.0), Vector3.UP)
	add_child(cam)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	add_child(light)


# ═════════════════════════════════════════════════════════════════════════════
# Per-frame helix drawing
# ═════════════════════════════════════════════════════════════════════════════

func _redraw_helix() -> void:
	if not is_instance_valid(_bob):
		return

	# Wipe last frame's geometry and rebuild the helix between the two endpoints.
	_helix_im.clear_surfaces()
	_helix_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var top    : Vector3 = _anchor.global_position
	var bottom : Vector3 = _bob.global_position
	var steps  : int     = helix_coils * 20   # vertices per revolution

	for i in range(steps + 1):
		var t     := float(i) / float(steps)
		var angle := t * float(helix_coils) * TAU   # radians around the axis
		# Linearly interpolate the coil's centre between anchor and bob,
		# then offset by the helix radius in the XZ plane.
		var centre := top.lerp(bottom, t)
		_helix_im.surface_add_vertex(centre + Vector3(
			cos(angle) * helix_radius,
			0.0,
			sin(angle) * helix_radius
		))

	_helix_im.surface_end()
	# clear_surfaces() removes surface materials, so re-apply every frame.
	_helix_mi.set_surface_override_material(0, _helix_mat)
