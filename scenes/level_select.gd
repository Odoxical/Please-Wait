extends Node2D


func _on_level_1_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/Level 1.tscn")

func _on_level_2_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/Level 2.tscn")

func _on_level_3_button_down() -> void:
	get_tree().change_scene_to_file("res://control.tscn")

func _on_level_4_button_down() -> void:
	get_tree().change_scene_to_file("res://control.tscn")

func _on_level_5_button_down() -> void:
	get_tree().change_scene_to_file("res://control.tscn")

func _on_leave_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
