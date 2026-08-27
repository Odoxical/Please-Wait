extends Control

func _on_start_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/Level Select.tscn")

func _on_l_0r_3_button_down() -> void:
	pass # Replace with function body.

func _on_leave_button_down() -> void:
	get_tree().quit()

func _on_settings_button_down() -> void:
	pass # Replace with function body.
