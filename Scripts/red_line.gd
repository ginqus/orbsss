extends StaticBody2D


@onready var sprite: Sprite2D = $Sprite2D


var rotation_speed: float = 0

func _ready() -> void:
	var og_width := sprite.get_rect().size.x
	var og_scale := sprite.scale.x
	var screen_width := get_viewport_rect().size.x
	scale.x = screen_width / og_width * 0.85 / og_scale
	scale.y = screen_width / og_width * 0.85 / og_scale


	if randf() > 0.5:
		rotation_speed = randf_range(20, 40)
	else:
		rotation_speed = randf_range(-20, -40)

	_rotate_loop()


func _rotate_loop() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation_degrees", rotation_degrees + rotation_speed, 0.2)
	await tween.finished
	_rotate_loop()
