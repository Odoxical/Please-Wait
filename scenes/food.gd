extends Node3D

func check(body):
	if body.is_in_group("dirty"):
		print(">OBJECTIVE FAILED. >REASON: FOOD DROPPED ON DIRTY SURFACE. >RETURN TO CHARGING DOCK")
	elif body.name == "VictoryArea":
		print(">OBJECTIVE COMPLETED. >RETURN TO CHARGING DOCK")



func _on_steak__body_entered(body: Node) -> void:
	print("colliding")
	check(body)

func _on_apple_colisons_body_entered(body: Node) -> void:
	check(body)
