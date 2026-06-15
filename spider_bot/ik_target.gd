extends Marker3D

# Procedural stepping removed — legs are moved manually via spider_bot.gd.
# Exports kept so existing scene references still load.
@export var step_target: Node3D
@export var step_distance: float = 3.0

@export var adjacent_target: Node3D
@export var opposite_target: Node3D
