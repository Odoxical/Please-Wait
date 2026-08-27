extends Button

func _process(delta: float) -> void:
	var time=Time.get_time_dict_from_system().second %10
	if time % 2 != 0 and not is_hovered():
		disabled=true
	else:
		disabled=false
