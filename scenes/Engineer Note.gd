extends Area3D

var regex = RegEx.new()

func _ready() -> void:
	# Compile the regex once when the node loads (\d+ finds digits)
	regex.compile("\\d+")

func get_numbers(child_node: Node) -> int:
	var result = regex.search(child_node.name)
	if result:
		# Extract the matched text and convert to an integer
		return int(result.get_string())
	return -1 # Return a fallback if no number is found

func _on_body_entered(body: Node3D) -> void:
	# Store the returned integer from the function into a local variable
	var collected_id = get_numbers(get_child(0))-1
	
	if collected_id != -1:
		Globals.engineer_notes[collected_id] = 1
		print("Note Collected: ", collected_id)
		print(Globals.engineer_notes)
	else:
		print("Error: First child node name does not contain a number!")
