extends Camera2D


@onready var player: CharacterBody2D = $"../Player"
@onready var default_offset_y: float = offset.y
@onready var overlay: TextureRect = $BackgroundOverlay
var prev_position: float = position.y
var tween: Tween
var overlay_init_position: Vector2
var init_offset: Vector2


func _ready() -> void:
	await get_tree().process_frame
	overlay_init_position = overlay.position
	init_offset = offset


func _process(_delta: float) -> void:
	if not player.is_killed:
		if not prev_position < player.position.y:
			tween = create_tween()
			tween.tween_property(self, "position:y", player.position.y, 0.5)
			prev_position = position.y


# Perform timed screen shake, each timer cycle is a new camera offset
func shake(cycles: float, power: float, interval: float) -> void:
	interval *= get_physics_process_delta_time() / Engine.time_scale
	var last_rand_offset: Vector2 = Vector2(1, 1)
	for cycle in range(cycles):
		var calc_offset: Vector2
		if cycle + 1 == cycles:
			calc_offset = Vector2.ZERO
			calc_offset.y += default_offset_y
		else:
			var intensity: float = (cycles / (cycle + 1))
			var rand_offset: Vector2 = Vector2.ZERO

			rand_offset.x = randf_range(1, 0.5) if randf() > 0.5 else randf_range(-1, -0.5)
			rand_offset.y = randf_range(1, 0.5) if randf() > 0.5 else randf_range(-1, -0.5)
			if sign(last_rand_offset) == sign(rand_offset):
				var chance: float = randf()
				if chance > 0.67:
					rand_offset.x = -rand_offset.x
				elif chance > 0.33:
					rand_offset.y = -rand_offset.y
				else:
					rand_offset.y = -rand_offset.y
					rand_offset.x = -rand_offset.x

			last_rand_offset = rand_offset
			calc_offset = Vector2(
				rand_offset.x * power * intensity, rand_offset.y * power * intensity + default_offset_y)
		tween = create_tween().set_trans(Tween.TRANS_CIRC)
		tween.tween_property(self, "offset", calc_offset, interval)
		tween.parallel().tween_property(
			overlay, "position", overlay_init_position + (calc_offset - init_offset), interval)
		await tween.finished
