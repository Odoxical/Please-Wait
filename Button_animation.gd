extends Button

var locked = false  # set once by the parent; true means "never blink, stay off"

func _process(delta: float) -> void:
	if locked:
		disabled = true
		return
	var is_odd_second = Time.get_time_dict_from_system().second % 2 != 0
	if is_odd_second and not is_hovered():
		disabled = true
	else:
		disabled = false
