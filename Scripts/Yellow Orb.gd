extends StaticBody2D

@onready var sprite := $Sprite2D
var orb_break_particle := load("res://Scenes/Prefabs/orb_break_particle.tscn")
var tween : Tween


func _ready(): AnimLoop()


func AnimLoop():
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(sprite, "rotation", sprite.rotation + 20, 10)
	await get_tree().create_timer(10).timeout
	AnimLoop()


func Destroy():
	var orb_break_effect = orb_break_particle.instantiate()
	get_tree().current_scene.add_child(orb_break_effect)
	orb_break_effect.global_position = global_position
	orb_break_effect.self_modulate = Color(0.875, 0.6, 0, 1)
	orb_break_effect.emitting = true
	queue_free()
