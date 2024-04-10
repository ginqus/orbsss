extends Line2D

var timescaleFactor

@export_category('Trail')
@export var length : = 10

@onready var parent : Node2D = get_parent()
var offset : = Vector2.ZERO

func _ready() -> void:
	offset = position
	top_level = true


func _physics_process(_delta: float) -> void:
	global_position = Vector2.ZERO

	if Engine.time_scale == 1:
		var point : = parent.global_position + offset
		add_point(point, 0)
	elif Engine.time_scale == %Player.slowmode and Engine.get_process_frames() % int(round(1 / %Player.slowmode)) == 0:
		var point : = parent.global_position + offset
		add_point(point, 0)
	
	if get_point_count() > length:
		remove_point(get_point_count() - 1)
