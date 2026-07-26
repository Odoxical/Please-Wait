extends Control

@onready var label_old: RichTextLabel = $VictoryTextHex
@onready var label_new: RichTextLabel = $VictoryTextReadable

var hex_string="3E4F424A45435449564520434F4D504C4554450A3E52455455524E20544F204348415247494E472053544154494F4E"

var delay=3
var change_speed=1.5
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	label_old.text=hex_string
	label_new.text=(hex_string.hex_decode()).get_string_from_utf8()
	
	label_old.visible_characters=-1#Start with all charaters visible
	label_new.visible_characters=0#Start with all charaters visible
	start_text_transition()

#func start_text_transition() -> void:
	#var tween = create_tween()
	#
	## 1. Wait for 3 seconds before doing anything
	#tween.tween_interval(delay_before_switch)
	#
	## 2. Erase the old text glyph-by-glyph (animate from full length down to 0)
	#var old_length: int = label_old.text.length()
	#label_old.visible_characters = old_length
	#tween.tween_property(label_old, "visible_characters", 0, erase_duration)
	#
	## 3. Type out the new text glyph-by-glyph (animate from 0 up to full length)
	## Note: Use parallel() if you want the typing to start at the exact same time the erasing starts.
	## tween.parallel() 
	#
	#var new_length: int = label_new.text.length()
	#tween.tween_property(label_new, "visible_characters", new_length, type_duration)
