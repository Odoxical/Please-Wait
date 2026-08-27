extends Control

@export var bot: Node3D

func _process(_delta):
	queue_redraw()

func _draw():
	if !bot || !bot.selected_leg:
		return
	var font = ThemeDB.fallback_font

	var lines = [
		"U / I / J / K or Tab — select leg",
		"W A S D — move foot (camera relative)",
		"E / Q — raise / lower foot",
		"Space — stomp foot down",
		"Arrow keys — lean body",
	]
	var y := 24.0
	for line in lines:
		draw_string(font, Vector2(16, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.85))
		y += 20.0

	# Leg diagram, top row = front legs; filled = planted, outline = selected
	var box := Vector2(44, 44)
	var gap := 8.0
	var origin := Vector2(24, size.y - 2 * box.y - gap - 24)
	draw_string(font, origin + Vector2(0, -10), "FRONT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.6))
	var cells = [
		[bot.fl_leg, Vector2(0, 0), "U"],
		[bot.fr_leg, Vector2(1, 0), "I"],
		[bot.bl_leg, Vector2(0, 1), "J"],
		[bot.br_leg, Vector2(1, 1), "K"],
	]
	for cell in cells:
		var leg = cell[0]
		var rect = Rect2(origin + Vector2(cell[1].x * (box.x + gap), cell[1].y * (box.y + gap)), box)
		var is_planted = bot.planted.get(leg, false)
		var is_pivot_leg = bot.is_pivoting && bot.pivot_leg == leg##
		var fill = Color("purple")
		if is_planted: 
			if is_pivot_leg:##
				fill = Color(0.6, 0.6, 0.4, 0.9)
			else:
				fill = Color(0.3, 0.34, 0.4, 0.9) 
		else:
			fill = Color(0.18, 0.2, 0.24, 0.45)
		draw_rect(rect, fill)
		if is_pivot_leg:##
			draw_rect(rect, bot.pivot_highlight_material.albedo_color, false, 3.0)##
		elif leg == bot.selected_leg:##
			draw_rect(rect, bot.highlight_material.albedo_color, false, 3.0)##
		var label_col = Color(1, 1, 1, 0.9) if (leg == bot.selected_leg || is_pivot_leg) else Color(1, 1, 1, 0.55)##
		draw_string(font, rect.position + Vector2(16, 28), cell[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, label_col)
		
	if bot.is_tipping:
		draw_string(font, Vector2(size.x / 2 - 64, 64), "TIPPING!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 0.25, 0.15))
