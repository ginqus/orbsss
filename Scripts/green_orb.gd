extends StaticBody2D

var orb_break_particle := load("res://Scenes/Prefabs/orb_break_particle.tscn")
@onready var boss_1 := $/root/MainLevel/Boss1
@onready var player := get_node_or_null("/root/MainLevel/Player")
@onready var collision := $CollisionShape2D
@onready var hitstop_flash := $"/root/MainLevel/UI/Hitstop flash"
@onready var cam: Camera2D = $"/root/MainLevel/Camera"
var tween


func Destroy():
	var orb_break_effect = orb_break_particle.instantiate()
	get_tree().current_scene.add_child(orb_break_effect)
	orb_break_effect.global_position = global_position
	orb_break_effect.self_modulate = Color(0, 1, 0.25, 1)
	orb_break_effect.emitting = true
	queue_free()


func Tween_To_Player():
	if is_instance_valid(player): look_at(player.position)
	var direction = Vector2(2000, 0).rotated(rotation)
	tween = create_tween()
	tween.tween_property(self, "global_position", global_position + direction, 1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)


func Parry():
	collision.disabled = true
	hitstop_flash.show()
	tween.kill()
	player.delta_factor = 0
	if is_instance_valid(boss_1):
		look_at(boss_1.global_position)
		var timer = get_tree().create_timer(0.1, false, false, true)
		timer.timeout.connect(boss_1.Damage)
	var direction = Vector2(2000, 0).rotated(rotation)

	cam.shake(5, 12, 4)
	await get_tree().create_timer(0.25, false, false, true).timeout

	hitstop_flash.hide()
	if is_instance_valid(player): player.delta_factor = 1
	tween = create_tween()
	await tween.tween_property(self, "global_position", global_position + direction, 0.3).finished
	queue_free()
