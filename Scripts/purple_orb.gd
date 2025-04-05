extends StaticBody2D


var destroy_particle: PackedScene = preload("res://Particles/orb_break.tscn")


func _destroy(direction: Vector2) -> void:
	queue_free()
	var particle: CPUParticles2D = destroy_particle.instantiate()
	get_tree().current_scene.add_child(particle)
	particle.global_position = global_position
	particle.emitting = true
	particle.direction = direction
	particle.color = GlobalVariables.purple_orb_color
	await particle.finished


func trigger(player: CharacterBody2D) -> void:
	if player.haptics_enabled:
		Input.vibrate_handheld(35)
	player.velocity.x = cos(rotation - PI/2) * 1000
	player.velocity.y = sin(rotation - PI/2) * 1000

	player.increase_stamina(35)
	player.increase_score(5)

	_destroy(player.velocity.normalized())
