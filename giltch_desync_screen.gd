extends Control

@onready var label_old: RichTextLabel = $GlitchTextHex
@onready var label_new: RichTextLabel = $GlitchTextReadable
var hex_string = "4552524f523a203078303030303030374520435249544943414c2053494d2d424f445920444553594e432044455445435445442e200a53454520454e47494e454552204e4f5445203420464f522044455441494c53"
var delay = 1.0
var change_speed = 1.0

func _ready() -> void:
	label_old.text = hex_string
	label_new.text = hex_string.hex_decode().get_string_from_utf8()
	label_old.visible_characters = -1
	label_new.visible_characters = 0
	start_text_transition()

func start_text_transition() -> void:
	var tween = create_tween()
	tween.tween_interval(delay)

	# Erase old text left-to-right by shrinking from the front of the string
	var old_length := hex_string.length()
	tween.tween_method(_erase_old_text_step, 0, old_length, change_speed)

	# Type new text left-to-right, in parallel with the erase
	tween.parallel()
	var new_length := label_new.text.length()
	tween.tween_property(label_new, "visible_characters", new_length, change_speed)

func _erase_old_text_step(erased_chars: float) -> void:
	label_old.text = hex_string.substr(int(erased_chars))

func _on_return_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit_button_down() -> void:
	get_tree().quit()

func _on_to_level_select_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/Level Select.tscn")

func _on_to_main_menu_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
	
