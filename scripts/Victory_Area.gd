extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Food Item"):
		print(">OBJECTIVE COMPLETED. >RETURN TO CHARGING DOCK")
		get_tree().change_scene_to_file("res://scenes/victory_screen.tscn")
