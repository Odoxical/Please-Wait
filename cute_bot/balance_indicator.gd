extends MeshInstance3D

# Draws the support polygon of the planted feet on the ground, and a
# centre-of-mass dot that fades green -> red as it nears the polygon edge.
@export var bot: Node3D

var im := ImmediateMesh.new()

func _ready():
	mesh = im
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat

func _process(_delta):
	im.clear_surfaces()
	if !bot:
		return
	var feet: Array = []
	for leg in bot.planted:
		if bot.planted[leg]:
			feet.append(leg.global_position)
	if feet.is_empty():
		return

	var ground_y := 0.0
	for f in feet:
		ground_y += f.y
	ground_y = ground_y / feet.size() + 0.05

	var com = bot.global_position
	var com2 := Vector2(com.x, com.z)
	var margin = _stability_margin(feet, com2)
	var t = clampf(margin, 0.0, 1.0)
	var poly_col = Color(1, 0.25, 0.1, 0.3).lerp(Color(0.2, 1, 0.35, 0.3), t)
	var com_col = Color(1, 0.25, 0.1, 0.95).lerp(Color(0.2, 1, 0.35, 0.95), t)

	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	if feet.size() >= 3:
		var pts := PackedVector2Array()
		for f in feet:
			pts.append(Vector2(f.x, f.z))
		var hull = Geometry2D.convex_hull(pts)
		if hull.size() > 1 && hull[0] == hull[hull.size() - 1]:
			hull.remove_at(hull.size() - 1)
		for i in range(1, hull.size() - 1):
			_tri(hull[0], hull[i], hull[i + 1], ground_y, poly_col)
	elif feet.size() == 2:
		# Two feet: the "polygon" is a line — draw it as a thin strip
		var a := Vector2(feet[0].x, feet[0].z)
		var b := Vector2(feet[1].x, feet[1].z)
		var side = (b - a).normalized().orthogonal() * 0.06
		_tri(a - side, a + side, b + side, ground_y, poly_col)
		_tri(a - side, b + side, b - side, ground_y, poly_col)
	else:
		_circle(Vector2(feet[0].x, feet[0].z), 0.3, ground_y, poly_col)

	_circle(com2, 0.16, ground_y + 0.03, com_col)
	im.surface_end()

func _tri(a: Vector2, b: Vector2, c: Vector2, y: float, col: Color):
	im.surface_set_color(col)
	im.surface_add_vertex(Vector3(a.x, y, a.y))
	im.surface_set_color(col)
	im.surface_add_vertex(Vector3(b.x, y, b.y))
	im.surface_set_color(col)
	im.surface_add_vertex(Vector3(c.x, y, c.y))

func _circle(center: Vector2, radius: float, y: float, col: Color):
	var steps := 14
	for i in steps:
		var a0 = TAU * i / steps
		var a1 = TAU * (i + 1) / steps
		_tri(center, center + Vector2.from_angle(a0) * radius, center + Vector2.from_angle(a1) * radius, y, col)

# Distance from the centre of mass to the support polygon edge;
# positive = inside (stable), negative = outside (tipping)
func _stability_margin(feet: Array, com2: Vector2) -> float:
	if feet.size() == 1:
		return -com2.distance_to(Vector2(feet[0].x, feet[0].z))
	var pts := PackedVector2Array()
	for f in feet:
		pts.append(Vector2(f.x, f.z))
	if feet.size() == 2:
		var closest = Geometry2D.get_closest_point_to_segment(com2, pts[0], pts[1])
		return -com2.distance_to(closest)
	var hull = Geometry2D.convex_hull(pts)
	var inside = Geometry2D.is_point_in_polygon(com2, hull)
	var best = INF
	for i in hull.size() - 1:
		var closest = Geometry2D.get_closest_point_to_segment(com2, hull[i], hull[i + 1])
		best = minf(best, com2.distance_to(closest))
	return best if inside else -best
