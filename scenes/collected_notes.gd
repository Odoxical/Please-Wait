extends Control

func _ready():
	var buttons = $GridContainer.get_children()
	for i in buttons.size():
		print("i")
		var child = buttons[i]
		if child is BaseButton:
			print(i, " ", child.name, " ", Globals.engineer_notes[i])
			if Globals.engineer_notes[i] != 1:
				print(Globals.engineer_notes[i])
				child.locked = true


func _on_note_1_button_down() -> void:
	pass # Replace with function body.


func _on_note_2_button_down() -> void:
	pass # Replace with function body.


func _on_note_3_button_down() -> void:
	pass # Replace with function body.


func _on_note_4_button_down() -> void:
	pass # Replace with function body.


func _on_note_5_button_down() -> void:
	pass # Replace with function body.


func _on_leave_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
