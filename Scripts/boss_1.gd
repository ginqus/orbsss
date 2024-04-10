extends Node2D

@onready var wing_animation: AnimationPlayer = $wing/AnimationPlayer
@onready var chelicerea_animation: AnimationPlayer = $"left chelicera/AnimationPlayer"
@onready var body_animation: AnimationPlayer = $"body/anim stripes/AnimationPlayer"
@onready var lights = [
	$"wing/light left wing", $"wing/light right wing", $"left chelicera/light left chelicera",
	$"right chelicera/light right chelicera", $"body/belt/light ring", $"body/belt/light diamond"]
@onready var boss_parts = [$wing, $"left chelicera", $"right chelicera", $body]

var blue_orb:   PackedScene = load("res://Scenes/Prefabs/blue_orb.tscn")
var red_orb:    PackedScene = load("res://Scenes/Prefabs/red_orb.tscn")
var green_orb:  PackedScene = load("res://Scenes/Prefabs/green_orb.tscn")
var health_bar: PackedScene = load("res://Scenes/Prefabs/healthbar.tscn")

@onready var cam: Camera2D = $/root/MainLevel/Camera
@onready var player: CharacterBody2D = $/root/MainLevel/Player
@onready var stamina_bar: ProgressBar = $/root/MainLevel/UI/StaminaBar
@onready var score: Label = $"/root/MainLevel/UI/Current score"
@onready var ui: CanvasLayer = $"../UI"
@onready var explosion_sprite: AnimatedSprite2D = $"Explosion sprite"
@onready var explosion_sfx: AudioStreamPlayer = $"Explosion sound"

@onready var DEFAULT_STAMINA_SIZE: Vector2
@onready var DEFAULT_STAMINA_POSITION: Vector2
@onready var DEFAULT_SCORE_POSITION: Vector2
@onready var SCREEN_TOP := -get_viewport_rect().size.y
@onready var SCREEN_CENTER_INGAME: Vector2 = cam.get_screen_center_position()
@onready var BORDER_TOP: float = cam.get_screen_center_position().y - cam.get_viewport_rect().size.y / 2

var UI_CENTER_POSITION: float

@export var particle_lazer_charge: PackedScene
@export var particle_orb_appear: PackedScene
@export var particle_lazer: PackedScene

var pos: Vector2 = Vector2(0, -3500)
var tween: Tween
var attacking: bool = false
var raycast_check_enabled: bool = false
var health: float = 100
var damage_timer: Timer
var damage_bar: TextureProgressBar
var dead_as_hell: bool = false
var lazer_last_time: bool = false


func _ready():
	wing_animation.play("idle")
	chelicerea_animation.play("idle")
	body_animation.play("idle")
	Spawn_Animation()
	DEFAULT_STAMINA_SIZE = stamina_bar.size
	DEFAULT_STAMINA_POSITION = stamina_bar.position
	DEFAULT_SCORE_POSITION = score.position
	player.time_scale_changed.connect(Adjust_Tween_Speed)
	hp_bar = health_bar.instantiate()
	damage_timer = hp_bar.get_child(1)
	damage_bar = hp_bar.get_child(0)
	damage_timer.timeout.connect(func _update_damage_bar():
		tween = create_tween()
		if is_instance_valid(damage_bar): tween.tween_property(damage_bar, "value", health, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
	UI_CENTER_POSITION = stamina_bar.position.x + stamina_bar.size.x / 2


func Adjust_Tween_Speed():
	tween.set_speed_scale(1 / Engine.time_scale)


var hp_bar: TextureProgressBar
func Spawn_Animation():
	tween = create_tween()
	tween.set_speed_scale(1 / Engine.time_scale)
	tween.parallel().tween_property(self, "pos:y", -650, 4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(score, "global_position:y", -1500, 1).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(stamina_bar, "position", Vector2(-250, 600), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(1.4)
	await tween.parallel().tween_property(stamina_bar, "position:y", SCREEN_TOP, 1).set_trans(Tween.TRANS_CUBIC).set_delay(0.15).finished
	stamina_bar.rotation_degrees = -90; stamina_bar.position = Vector2(-400, 600)
	stamina_bar.size.x = 600

	hp_bar.position.y = BORDER_TOP - 1024
	hp_bar.global_position.x = UI_CENTER_POSITION - hp_bar.size.x / 2
	ui.add_child(hp_bar)
	var tw = create_tween()
	hp_bar.modulate.a = 0
	tw.tween_property(hp_bar, "modulate:a", 1, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(1.5)
	tw.set_parallel().tween_property(hp_bar, "position:y", 24, 3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(2).timeout
	if randi_range(0, 1) == 1: _attack_lazer()
	else: _attack_orbs()


func _physics_process(_delta: float) -> void:
	var tw = create_tween()
	tw.tween_property(self, "position:y", pos.y + cam.get_screen_center_position().y, 0.1).set_trans(Tween.TRANS_SINE)
	if not attacking and is_instance_valid(player):
		tw.tween_property(self, "rotation", rotation + get_angle_to(player.position) - PI/2, 0.15).set_trans(Tween.TRANS_SINE)


func _attack_lazer():
	if dead_as_hell: return
	var charge_particle = particle_lazer_charge.instantiate()
	var lazer_particle = particle_lazer.instantiate()

	add_child(charge_particle)
	charge_particle.position.y = 165
	chelicerea_animation.play("attack_lazer")

	await get_tree().create_timer(1.0, false).timeout
	attacking = true

	if dead_as_hell:  charge_particle.emitting = false; lazer_particle.emitting = false; return;
	await get_tree().create_timer(0.9, false).timeout
	cam.shake(20, 6, 4)
	add_child(lazer_particle)
	lazer_particle.position.y = 2000
	charge_particle.emitting = false
	raycast_check_enabled = true; _raycast_check(lazer_particle)

	if dead_as_hell: charge_particle.emitting = false; lazer_particle.emitting = false; return; 
	await get_tree().create_timer(1.0, false).timeout
	lazer_particle.emitting = false
	raycast_check_enabled = false; _raycast_check(lazer_particle)

	if dead_as_hell: charge_particle.emitting = false; lazer_particle.emitting = false; return; 
	await get_tree().create_timer(1.0, false).timeout
	lazer_particle.queue_free(); charge_particle.queue_free()

	if dead_as_hell: charge_particle.emitting = false; lazer_particle.emitting = false; return; 
	attacking = false
	if randi_range(0, 1) == 1 or lazer_last_time: _attack_orbs(); lazer_last_time = false
	else: _attack_lazer(); lazer_last_time = true


func _raycast_check(lazer_particle: CPUParticles2D):
	if raycast_check_enabled:
		await get_tree().create_timer(get_physics_process_delta_time(), false).timeout

		if is_instance_valid(player):
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(position, Vector2(0, 2000).rotated(rotation) + position)
			var result = space_state.intersect_ray(query)

			if result and result.collider.is_in_group("orb"): result.collider.Destroy()
			elif result and result.collider == player: player.die()

			_raycast_check(lazer_particle)


var tween_orbs: Tween
var green_in_row: int = 0
var red_in_row: int = 0
func _attack_orbs():
	var orb_type
	for orb_number in range(10):
		if dead_as_hell: return
		if is_instance_valid(player):
			var orb_spawn_particle = particle_orb_appear.instantiate()
			var orb_spawn_glow = particle_lazer_charge.instantiate()

			orb_type = randi_range(0, 1)
			orb_type = green_orb if orb_type == 0 else red_orb

			if orb_type == green_orb:
				red_in_row = 0
				green_in_row += 1
				if green_in_row > 2: orb_type = red_orb; green_in_row = 0; red_in_row = 1
			else:
				green_in_row = 0
				red_in_row += 1
				if red_in_row > 2: orb_type = green_orb; red_in_row = 0; green_in_row = 1

			if orb_type == green_orb:
				orb_spawn_particle.set_color(Color(0.8, 1, 0.8, 1))
				orb_spawn_glow.set_color(Color(0.409, 1, 0.555, 0.75))
			else:
				orb_spawn_particle.set_color(Color(1, 0.8, 0.8, 1))
				orb_spawn_glow.set_color(Color(1, 0.409, 0.555, 0.75))

			if randi_range(0, 1) == 0:
				add_child(orb_spawn_particle)
				orb_spawn_particle.position = Vector2(-200, 64)
				orb_spawn_particle.emitting = true

				add_child(orb_spawn_glow)
				orb_spawn_glow.speed_scale = 4
				orb_spawn_glow.position = Vector2(-200, 64)
				wing_animation.play("attack_orbs_left")

				await get_tree().create_timer(0.6, false).timeout
				orb_spawn_glow.emitting = false
				orb_type = orb_type.instantiate()
				add_sibling(orb_type)
				orb_type.position = Vector2(position.x - 200, position.y + 64 - rotation_degrees * 2)
				orb_type.scale.y *= 0.75
				orb_type.Tween_To_Player()
			else:
				add_child(orb_spawn_particle)
				orb_spawn_particle.position = Vector2(200, 64)
				orb_spawn_particle.emitting = true

				add_child(orb_spawn_glow)
				orb_spawn_glow.speed_scale = 4
				orb_spawn_glow.position = Vector2(200, 64)
				wing_animation.play("attack_orbs_right")

				await get_tree().create_timer(0.6, false).timeout
				orb_spawn_glow.emitting = false
				orb_type = orb_type.instantiate()
				add_sibling(orb_type)
				orb_type.position = Vector2(position.x + 200, position.y + 64 - rotation_degrees * 2)
				orb_type.scale.y *= 0.75
				orb_type.Tween_To_Player()
	_attack_lazer()


func Damage():
	if health > 0:
		damage_timer.start(0.7)
		health -= 10
		var tw = create_tween()
		if is_instance_valid(hp_bar): tw.tween_property(hp_bar, "value", health, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_flicker_lights()
		for i in range(5):
			position.x += randi_range(-40, 40)
			await get_tree().create_timer(0.1, false, false, true).timeout
			position.x = SCREEN_CENTER_INGAME.x
			await get_tree().create_timer(0.1, false, false, true).timeout
		if health <= 0:
			Die()


func Die():
	dead_as_hell = true

	raycast_check_enabled = false
	chelicerea_animation.stop()
	wing_animation.stop()
	body_animation.stop()
	for part in boss_parts: part.hide()

	explosion_sfx.play()
	explosion_sprite.show()
	explosion_sprite.play()
	await explosion_sprite.animation_finished
	explosion_sprite.hide()

	tween = create_tween()
	tween.tween_property(hp_bar, "modulate:a", 0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.set_parallel().tween_property(hp_bar, "position:y", hp_bar.position.y - 1000, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).finished
	hp_bar.queue_free()

	var tw = create_tween()
	tw.parallel().tween_property(stamina_bar, "position:x", -400, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).finished.connect(func reset_stamina_pos():
		stamina_bar.rotation_degrees = 0
		stamina_bar.position.x = UI_CENTER_POSITION - stamina_bar.size.x / 2
		stamina_bar.position.y = SCREEN_TOP
		stamina_bar.size.x = DEFAULT_STAMINA_SIZE.x
		stamina_bar.modulate.a = 0)
	tw.parallel().tween_property(score, "position:y", DEFAULT_SCORE_POSITION.y, 1).set_trans(Tween.TRANS_CUBIC).set_delay(0.15)
	tw.parallel().tween_property(stamina_bar, "position:y", DEFAULT_STAMINA_POSITION.y, 1).set_trans(Tween.TRANS_CUBIC).set_delay(0.15)
	await tw.parallel().tween_property(stamina_bar, "modulate:a", 1, 1).set_delay(0.5).finished

	queue_free()


func _flicker_lights():
	for light in lights: light.visible = false
	await get_tree().create_timer(0.4, false, false, true).timeout
	for light in lights: light.visible = true
	await get_tree().create_timer(0.1, false, false, true).timeout
	for light in lights: light.visible = false
	await get_tree().create_timer(0.25, false, false, true).timeout
	for light in lights: light.visible = true
