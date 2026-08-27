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

	# Only used for the COM dot's height — the COM isn't a real foot,##
	# so there's no "actual" height to give it; average is still fine here##
	var ground_y := 0.0
	for f in feet:
		ground_y += f.y
	ground_y = ground_y / feet.size() + 0.05

	var com = bot._visual_com
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
		# Look each hull point back up against its real foot so the##
		# polygon can use that foot's actual height, not an average##
		var hull3: Array = []##
		for p in hull:##
			hull3.append(_foot_at(feet, p) + Vector3(0, 0.05, 0))##
		for i in range(1, hull3.size() - 1):
			_tri3(hull3[0], hull3[i], hull3[i + 1], poly_col)##
	elif feet.size() == 2:
		var a: Vector3 = feet[0]##
		var b: Vector3 = feet[1]##
		var a2 := Vector2(a.x, a.z)##
		var b2 := Vector2(b.x, b.z)##
		var side = (b2 - a2).normalized().orthogonal() * 0.06##
		var a1 = Vector3(a2.x - side.x, a.y + 0.05, a2.y - side.y)##
		var a3 = Vector3(a2.x + side.x, a.y + 0.05, a2.y + side.y)##
		var b1 = Vector3(b2.x + side.x, b.y + 0.05, b2.y + side.y)##
		var b3 = Vector3(b2.x - side.x, b.y + 0.05, b2.y - side.y)##
		_tri3(a1, a3, b1, poly_col)##
		_tri3(a1, b1, b3, poly_col)##
	else:
		_circle3(feet[0], 0.3, poly_col)##
	_circle(com2, 0.16, ground_y + 0.03, com_col)
	im.surface_end()

func _tri3(a: Vector3, b: Vector3, c: Vector3, col: Color):##
	im.surface_set_color(col)##
	im.surface_add_vertex(a)##
	im.surface_set_color(col)##
	im.surface_add_vertex(b)##
	im.surface_set_color(col)##
	im.surface_add_vertex(c)##

func _circle3(center: Vector3, radius: float, col: Color):##
	var steps := 14##
	var c2 := Vector2(center.x, center.z)##
	var y = center.y + 0.05##
	for i in steps:##
		var a0 = TAU * i / steps##
		var a1 = TAU * (i + 1) / steps##
		var p0 = c2 + Vector2.from_angle(a0) * radius##
		var p1 = c2 + Vector2.from_angle(a1) * radius##
		_tri3(Vector3(c2.x, y, c2.y), Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), col)##

func _foot_at(feet: Array, p: Vector2) -> Vector3:##
	var best: Vector3 = Vector3(p.x, 0, p.y)##
	var best_dist = INF##
	for f in feet:##
		var d = Vector2(f.x, f.z).distance_to(p)##
		if d < best_dist:##
			best_dist = d##
			best = f##
	return best##

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
