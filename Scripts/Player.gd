extends CharacterBody2D


signal killed

var SLOWMODE_VALUE: float = 0.2
var MAX_SPEED: float = 1300.0
var TRAJECTORY_SPACING: float = 25
var DAMAGE_COOLDOWN: float = 0.4
var MAX_STAMINA: float = 100.0

# TODO: add these to settings
var sensitivity: float = 11.0
var haptics_enabled: bool = true
var is_reversed: bool = false

var drag_pos_start: Vector2
var drag_pos_end: Vector2
var direction: Vector2
var power: float
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_game_started: bool = false
var border_right: int
var border_up: int
var border_left: int
var camera: Camera2D
var health: int = 3
var is_killed: bool = false
var stamina: float = 100.0
var coins: int = 0
var score: int = 0
var visual_score: int = 0

var death_particle: PackedScene = preload("res://Particles/player_explode.tscn")

@onready var trail: Line2D = $Trail
@onready var trajectory: Line2D = $Trajectory
@onready var damage_cooldown: Timer = $DamageCooldown
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var healthbar: TextureProgressBar = $HUD/Healthbar
@onready var stamina_bar: TextureProgressBar = $HUD/Stamina
@onready var main: Node2D = null
@onready var hit_overlay: TextureRect = $HUD/HitOverlay
@onready var coin_label: Label = $HUD/Coins
@onready var score_label: Label = $HUD/Score


func _ready() -> void:
	if get_node_or_null("..") is Node2D:
		main = $".."
		killed.connect(main._on_player_killed)
	border_right = int(get_viewport_rect().size.x)
	border_up = int(get_viewport_rect().size.y)
	border_left = int(border_right - get_viewport_rect().size.x)
	camera = get_node_or_null("../Camera")
	_load_upgrades()


func _process(delta: float) -> void:
	if not is_killed:
		score_label.text = str(visual_score)

		# Add the gravity.
		if not is_on_floor() and is_game_started:
			velocity += get_gravity() * delta

		# Make the player always point to where it's heading.
		var current_direction: Vector2 = velocity.normalized().rotated(PI)
		var tween: Tween = create_tween()
		var rotation_diff: float = angle_difference(rotation, current_direction.angle())
		var offset: float = -PI / 2
		var rotation_next: float = rotation + rotation_diff + offset
		var speed: float = velocity.length()
		tween.tween_property(self, "rotation", rotation_next, 0.0)

		_apply_bounciness(speed, delta)
		_update_trail()
		if is_game_started:
			if not Input.is_action_pressed("left_click") or main and main.is_pause_button_held:
				decrease_stamina(20 * delta)

		if stamina > 0 and main and not main.is_pause_button_held or not main:
			if Input.is_action_just_pressed("left_click"):
				drag_pos_start = get_viewport().get_mouse_position()
				_interpolate_trail()
				_animate_trajectory('add')

			if Input.is_action_pressed("left_click"):
				if Engine.time_scale > 0.1:
					Engine.time_scale = SLOWMODE_VALUE
				drag_pos_end = get_viewport().get_mouse_position()
				var distance: float = drag_pos_start.distance_to(drag_pos_end)
				if distance > 0:
					power = clamp((distance * sensitivity), 200.0, MAX_SPEED)
				else:
					power = 0
				if not is_reversed:
					direction = (drag_pos_end - drag_pos_start).normalized()
				else:
					direction = (drag_pos_start - drag_pos_end).normalized()
				_update_trajectory_line()
				if is_game_started:
					decrease_stamina(200 * delta)

			if Input.is_action_just_released("left_click"):
				if not is_game_started:
					is_game_started = true

				var prev_velocity: Vector2 = velocity.normalized()
				const scale_impact_factor: float = 4.0

				_animate_trajectory('remove')
				velocity = direction * power
				if Engine.time_scale == SLOWMODE_VALUE:
					Engine.time_scale = 1.0

				var amount: int = int(1.0 / SLOWMODE_VALUE)
				var initial_point_count: int = trail.get_point_count()
				for i in range(trail.get_point_count()):
					var point_to_remove: int = initial_point_count - (i + 1)  # Remove starting from end
					if not i % amount == 0:  # Leave only every amountth trail point
						trail.remove_point(point_to_remove)

				var velocity_difference: float = prev_velocity.dot(velocity.normalized())
				velocity_difference = (abs(velocity_difference) + 1) / 2  # Make range from 0 to 1
				current_scale_velocity = velocity_difference * scale_impact_factor
		elif stamina <= 0:
			Engine.time_scale = 1
			if trajectory_visible:
				_animate_trajectory("remove")


		var collision: KinematicCollision2D = move_and_collide(velocity * delta)
		if collision:
			var collider: Object = collision.get_collider()
			if collider.is_in_group("orb"):
				collider.trigger(self)
				camera.shake(4, 2, 3)

			elif collider.is_in_group("hazard"):
				take_damage(collision)


func _load_upgrades() -> void:
	SLOWMODE_VALUE = 1.0 / (SaveSystem.get_var("slowmode_power_upgrade", 0) + 4)  # 0.25 - 0.14
	print("SLOWMO: ", SLOWMODE_VALUE)
	MAX_SPEED = 1300 + SaveSystem.get_var("speed_upgrade", 0) * 50  # 1300 - 1700
	print("SPEED: ", MAX_SPEED)
	TRAJECTORY_SPACING = 0.0075 + SaveSystem.get_var("trajectory_length_upgrade", 0) * 0.0015  # 0.01 - 0.02
	print("TRAJECTORY: ", TRAJECTORY_SPACING)
	DAMAGE_COOLDOWN = 0.4 + SaveSystem.get_var("invinc_time_upgrade", 0) * 0.1  # 0.4 - 0.8
	print("COOLDOWN: ", DAMAGE_COOLDOWN)
	MAX_STAMINA = 100 + SaveSystem.get_var("max_stamina_upgrade", 0) * 15  # 100 - 175
	print("STAMINA: ", MAX_STAMINA)
	stamina_bar.max_value = MAX_STAMINA
	stamina = MAX_STAMINA
	stamina_bar.value = MAX_STAMINA


func decrease_stamina(value: float) -> void:
	set_stamina(stamina - value)


func increase_stamina(value: float) -> void:
	set_stamina(stamina + value)


func set_stamina(value: float) -> void:
	stamina = clampf(value, 0.0, MAX_STAMINA)
	if stamina <= 15.0:
		stamina_bar.modulate.g = stamina / 15
		stamina_bar.modulate.b = stamina / 15
	else:
		stamina_bar.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(stamina_bar, "value", stamina, 0.1)


func decrease_score(value: int) -> void:
	set_score(score - value)


func increase_score(value: int) -> void:
	set_score(score + value)


func set_score(value: int) -> void:
	score = max(0, value)
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_property(self, "visual_score", score, 0.15)


func collect_coin() -> void:
	coins += 1
	coin_label.text = str(coins)
	var tween: Tween = healthbar.create_tween().set_ease(Tween.EASE_OUT).set_ignore_time_scale(true)
	tween.parallel().tween_property(
		coin_label, "scale", Vector2(0.8, 0.8), 0.1
	).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		coin_label, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_SPRING).set_delay(0.1)


func take_damage(collision: KinematicCollision2D = null) -> void:
	if collision:
		velocity = velocity.bounce(collision.get_normal()).normalized() * 800
	else:
		velocity = (camera.position - position).normalized() * 800
	if damage_cooldown.paused or damage_cooldown.is_stopped():
		health -= 1
		decrease_score(50)
		if health <= 0:
			healthbar.get_child(0).texture = load("res://Themes/frozen_dark/gui/broken_heart.svg")
			_kill_player()
		else:
			# If you run out of stamina, you'll likely fall and take damage,
			# hense we increase stamina so that the player can continue
			if haptics_enabled:
				Input.vibrate_handheld(75)
			increase_stamina(MAX_STAMINA)
			var tween: Tween = create_tween()
			hit_overlay.modulate = Color(Color.RED)
			hit_overlay.modulate.a = 0.25
			tween.tween_property(hit_overlay, "modulate:a", 0, 0.25)
			camera.shake(6, 6, 4)
			damage_cooldown.start(DAMAGE_COOLDOWN)
			_blink_on_damage()

		var tween_hb: Tween = healthbar.create_tween().set_ease(Tween.EASE_OUT)
		tween_hb.set_ignore_time_scale(true)
		tween_hb.tween_property(healthbar, "value", health, 0.4).set_trans(Tween.TRANS_EXPO)
		tween_hb.parallel().tween_property(
			healthbar, "scale", Vector2(0.8, 0.8), 0.1
		).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		tween_hb.parallel().tween_property(
			healthbar, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_SPRING).set_delay(0.1)


func regenerate(amount: int) -> void:
	if health < 3:
		health = min(3, health + amount)

		var tween: Tween = create_tween()
		hit_overlay.modulate = Color(Color.GREEN)
		hit_overlay.modulate.a = 0.25
		tween.tween_property(hit_overlay, "modulate:a", 0, 0.25)

		var tween_hb: Tween = healthbar.create_tween().set_ease(Tween.EASE_OUT)
		tween_hb.set_ignore_time_scale(true)
		tween_hb.tween_property(healthbar, "value", health, 0.4).set_trans(Tween.TRANS_EXPO)
		tween_hb.parallel().tween_property(
			healthbar, "scale", Vector2(0.8, 0.8), 0.1
		).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		tween_hb.parallel().tween_property(
			healthbar, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_SPRING).set_delay(0.1)


func _kill_player() -> void:
	is_killed = true

	camera.shake(10, 20, 4)
	if haptics_enabled:
		Input.vibrate_handheld(100)

	var tween: Tween = hit_overlay.create_tween()
	hit_overlay.modulate.a = 0.4
	tween.tween_property(hit_overlay, "modulate:a", 0, 0.5)

	Engine.time_scale = 1
	var death_effect: CPUParticles2D = death_particle.instantiate()
	get_tree().current_scene.add_child(death_effect)
	death_effect.global_position = global_position
	death_effect.emitting = true
	# If the player died off-screen, the direction of particles is reversed
	if position.x > border_right + 64:
		death_effect.direction = Vector2(-1, 0)
	elif position.x < border_right - get_viewport_rect().size.x - 64:
		death_effect.direction = Vector2(1, 0)
	elif position.y > border_up + 64 or position.y > border_up + camera.position.y - 600:
		death_effect.direction = Vector2(0, -1)
	else:
		death_effect.direction = velocity.normalized()
	death_effect.initial_velocity_min = max(velocity.length(), 1000) * 0.25
	death_effect.initial_velocity_max = max(velocity.length(), 1000) * 0.75
	death_effect.color = GlobalVariables.player_color

	emit_signal("killed")
	collision_shape.queue_free()
	sprite.queue_free()
	trail.queue_free()
	trajectory.queue_free()


func _blink_on_damage() -> void:  # Copied STRAIGHT from Terraria
	if not is_killed:
		var interval: float = DAMAGE_COOLDOWN / 10
		for i in range(10):
			if not is_killed:
				var tween: Tween = create_tween()
				tween.tween_property(sprite, "self_modulate:a", i % 2, interval)
				await tween.finished
			else:
				break
		if not is_killed:
			sprite.self_modulate.a = 1.0


# Code for making the ball look bouncier. Thanks to @t3ssel8r on YT <3 (and also
# ChatGPT. I'm sorry. Linear algebra (or whatever this is) is hard. I'm stupid.)
const damping_coefficient = 0.015
const inertial_coefficient = 0.002
const input_rate_coefficient = 0.0
var current_scale: float = 1.0
var current_scale_velocity: float = 0.0
var interpolated_scale: float = 1.0
var change_in_target_scale: float = 0.0  # Change in target scale per frame

func _apply_bounciness(speed: float, delta: float) -> void:
	var target_scale: float = clamp(1 - speed / 3072.0, 0.6, 1)

	# Calculate the change in target scale per frame
	change_in_target_scale = (target_scale - current_scale) / delta
	current_scale = target_scale

	# Calculate the acceleration using the second-order differential equation
	var acceleration: float = ((current_scale + input_rate_coefficient * change_in_target_scale
							   - interpolated_scale - damping_coefficient * current_scale_velocity)
							   / inertial_coefficient)

	current_scale_velocity += acceleration * delta
	interpolated_scale += current_scale_velocity * delta

	sprite.scale.x = interpolated_scale * 0.25
	#scale.x = interpolated_scale
	#get_child(0).scale.x = 1  # Don't scale CollisionShape2D


func _interpolate_trail() -> void:
	var amount: int = int(1.0 / SLOWMODE_VALUE)
	var point_position_list: Array
	var interpolated_point_position_list: Array
	for point: int in range(trail.get_point_count()):
		var point_position: Vector2 = trail.get_point_position(point)
		point_position_list.append(point_position)

	var index: int = -1
	for point_position: Vector2 in point_position_list:
		index += 1
		if index == 0:
			continue
		var last_point_position: Vector2 = trail.get_point_position(index - 1)
		var step: int = -1

		for interpolation: int in range(amount + 1):
			step += 1
			if step == 0:
				interpolated_point_position_list.append(last_point_position)
				continue
			var weight: float = float(step) / amount
			var interpolated_position: Vector2 = last_point_position.lerp(point_position, weight)
			interpolated_point_position_list.append(interpolated_position)

	trail.clear_points()
	for point_position: Vector2 in interpolated_point_position_list:
		trail.add_point(point_position)


func _update_trail() -> void:
	var trail_length: int = 12
	trail.add_point(global_position, 0)
	while trail.get_point_count() > trail_length / Engine.time_scale:
		trail.remove_point(trail.get_point_count() - 1)


func _update_trajectory_line() -> void:
	trajectory.clear_points()
	if power <= 0:
		return

	var max_points: int = 50
	var pos: Vector2 = global_position
	var vel: Vector2 = direction * power
	for i in max_points:
		trajectory.add_point(pos)
		vel.y += gravity * TRAJECTORY_SPACING
		pos += vel * TRAJECTORY_SPACING


var trajectory_tween: Tween
var trajectory_visible: bool
func _animate_trajectory(animation: String) -> void:
	if trajectory_tween:
		trajectory_tween.kill()
	trajectory_tween = trajectory.create_tween()
	match animation:
		'add':
			trajectory_visible = true
			trajectory_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			trajectory_tween.tween_property(trajectory, "modulate:a", 1, 0.05).from(0)
		'remove':
			trajectory_visible = false
			trajectory_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			await trajectory_tween.tween_property(trajectory, "modulate:a", 0, 0.15).from(1).finished
			trajectory.clear_points()
