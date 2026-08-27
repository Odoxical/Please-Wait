extends Control

@onready var label_old: RichTextLabel = $LoseTextHex
@onready var label_new: RichTextLabel = $LoseTextReadable
var hex_string = "594f552048415645204641494c454420415420594f5552205441534b0d0a524541534f4e3a20464f4f4420484153204245454e20554e4e45434553534152494c592044495254494544200d0a52455455524e20544f204348415247494e472053544154494f4e"
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
