extends Node3D

func check(body):
	if body.is_in_group("dirty"):
		print(">OBJECTIVE FAILED. >REASON: FOOD DROPPED ON DIRTY SURFACE. >RETURN TO CHARGING DOCK")



func _on_apple_colisons__body_entered(body: Node) -> void:
	print("colliding")
	check(body)


func _on_steak_body_entered(body: Node) -> void:
	print("colliding")
	check(body)
