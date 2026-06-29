extends Node3D

func check(body):
	if body.is_in_group("dirty"):
		print("You Dropped Food on the floor. You messy robot")



func _on_steak__body_entered(body: Node) -> void:
	check(body)

func _on_apple_colisons_body_entered(body: Node) -> void:
	check(body)
