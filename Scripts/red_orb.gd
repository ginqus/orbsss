extends StaticBody2D


var destroy_particle: PackedScene = preload("res://Particles/orb_break.tscn")
@onready var player := get_node_or_null("/root/Main/Player")


func _destroy(direction: Vector2) -> void:
	queue_free()
	var particle: CPUParticles2D = destroy_particle.instantiate()
	get_tree().current_scene.add_child(particle)
	particle.global_position = global_position
	particle.emitting = true
	particle.direction = direction
	particle.color = GlobalVariables.blue_orb_color
	await particle.finished


func trigger(player: CharacterBody2D) -> void:
	if player.haptics_enabled:
		Input.vibrate_handheld(35)
	player.velocity.y = (
		-0.75 * Vector2(abs(player.velocity.x * 0.8), abs(player.velocity.y * 0.8 - 300)).length())
	player.velocity.x /= 5
	_destroy(player.velocity.normalized())


func Tween_To_Player():
	if is_instance_valid(player):
		look_at(player.position)
	var direction = Vector2(2000, 0).rotated(rotation)
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", global_position + direction, 1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
