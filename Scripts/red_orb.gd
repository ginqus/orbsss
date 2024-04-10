extends StaticBody2D

var orb_break_particle := load("res://Scenes/Prefabs/orb_break_particle.tscn")


func Tween_To_Player():
	var player := get_node_or_null("/root/MainLevel/Player"); var tween
	if is_instance_valid(player): look_at(player.position)
	var direction = Vector2(2000, 0).rotated(rotation)
	tween = create_tween()
	tween.tween_property(self, "global_position", global_position + direction, 1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)


func Destroy():
	var orb_break_effect = orb_break_particle.instantiate()
	get_tree().current_scene.add_child(orb_break_effect)
	orb_break_effect.global_position = global_position
	orb_break_effect.self_modulate = Color(1, 0.05, 0.05, 1)
	orb_break_effect.emitting = true
	queue_free()
