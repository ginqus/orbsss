extends StaticBody2D

var orb_break_particle := load("res://Scenes/Prefabs/orb_break_particle.tscn")


func Destroy():
	var orb_break_effect = orb_break_particle.instantiate()
	get_tree().current_scene.add_child(orb_break_effect)
	orb_break_effect.global_position = global_position
	orb_break_effect.self_modulate = Color(0, 0.5, 1, 1)
	orb_break_effect.emitting = true
	queue_free()
