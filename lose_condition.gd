extends Area3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	


func _on_area_entered(body: Node3D) -> void:
	if body.is_in_group("Food"):
		print("You messy robot")
