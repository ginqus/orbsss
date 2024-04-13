extends CharacterBody2D


#region Переменные
var hasStarted : bool = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 0 # Получить гравитацию из настроек проекта

var Blue : Texture = preload("res://Sprites/Player/blue.png")
var RGB : Texture = preload("res://Sprites/Player/rgb.png")


@export var slowmode: float = 0.25
@export var death_particle: PackedScene
@export var orb_break_particle: PackedScene
@export var blue_orb: PackedScene
@export var red_orb: PackedScene
@export var purple_orb: PackedScene
@export var yellow_orb: PackedScene
@export var boss_1: PackedScene

@onready var ui := $"../UI"
@onready var save_manager := $"../Saving manager"

signal time_scale_changed

var config = ConfigFile.new()
const CONFIG_LOCATION := "user://orbsss-settings.cfg"
const SAVE_LOCATION = "user://orbsss.save"


var maxSpeed: float = 20.0
var sensitivity: float
var calcVelocity: float = 0.0
var mouseEnabled: bool
var endPos: Vector2
var startPos: Vector2
var direction: Vector2
var border_right: float
var border_up: float
var border_left: float
var aspect_ratio: float
var screen_center: Vector2
var SCREEN_CENTER_INGAME: Vector2
var new_stamina_value: float = 50.0
var prev_stamina_value: float
var accent_color: Color = Color(0, 0.573, 0.8)
var score: int = 0
var best_score: int = 0
var coins_this_round: int = 0
var coins_pre_round: int = 0
var coins_total: int = 0
var delta_factor: float = 1
var boss_spawned: bool = false
var haptics_enabled: bool

@onready var cam := %Camera
@onready var score_label := $"../UI/Current score"
@onready var coins_label := $"../UI/Coins"
@onready var save_indicator := $"../UI/Save indicator"
#endregion


func _ready():

	config.load(CONFIG_LOCATION)
	sensitivity = config.get_value("Settings", "Sensitivity", 11.0)
	haptics_enabled = config.get_value("Settings", "Vibration", true)

	if get_window().size.x == 864:
		get_window().size.x = 550
		get_window().position = Vector2(685, 0)
# Отключает управление, если игрок зажал еще до того, как началась игра
	if Input.is_action_pressed("left_click"):
		mouseEnabled = false
	else:
		mouseEnabled = true
# Границы экрана в игровых единицах
	border_right = float(get_viewport_rect().size.x - 864) / 2 + 864
	border_up = float(get_viewport_rect().size.y - 1728) / 2 + 1728
	border_left = border_right - get_viewport_rect().size.x
	aspect_ratio = get_viewport_rect().size.x / get_viewport_rect().size.y * 2 # Шире - больше, уже - меньше
	screen_center = get_viewport().size / 2
	SCREEN_CENTER_INGAME = cam.get_screen_center_position()
	for i in range(4):
		SpawnOrbs(300 * i - 300)
	%StaminaBar.get("theme_override_styles/fill").bg_color = accent_color

	save_manager.Load()
	Autosave()
	_slow_process()


func _physics_process(delta):

	delta *= delta_factor

#region Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
#endregion

#region Поворот по направлению куда летит игрок
	var currDir = velocity.normalized() # Рассчитать направление мяча
	if currDir.x == 0 && currDir.y == 0:
		var angle = atan2(currDir.y, currDir.x) * 180 / PI # Рассчитать угол направления по отношению к оси y
		rotation_degrees = angle # Обновить поворот мяча
	else:
		var angle = atan2(currDir.y, currDir.x) * 180 / PI - 270 # Рассчитать угол направления по отношению к оси x
		rotation_degrees = angle # Обновить поворот мяча

	var speed = velocity.length()
	scale.x = clamp(1 - speed / 3072.0, 0.6, 1)
#endregion

#region Главная физика
	if mouseEnabled and %StaminaBar.value > 0.1:
		if Input.is_action_just_pressed("left_click"):
			time_scale_changed.emit()
			startPos = get_viewport().get_mouse_position()

		if Input.is_action_pressed("left_click"):
			Engine.time_scale = slowmode
			endPos = get_viewport().get_mouse_position()
			calcVelocity = clamp((startPos.distance_to(endPos) * sensitivity), 500.0, maxSpeed * 100)
			direction = (endPos - startPos).normalized()

		if Input.is_action_just_released("left_click"):
			velocity = Vector2.ZERO
			velocity = direction * calcVelocity
			if not hasStarted:
				hasStarted = true
				gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 2
			Engine.time_scale = 1.0
			time_scale_changed.emit()

	elif Input.is_action_just_released("left_click") and not mouseEnabled:
		mouseEnabled = true
	elif %StaminaBar.value < 0.1:
		Engine.time_scale = 1.0
		time_scale_changed.emit()
	$"../UI/StaminaBar/Cross".visible = !%StaminaBar.value > 0.1
#endregion

#region Обработка столкновений
	var collision = move_and_collide(velocity * delta)
	if collision:

	# Если синий орб
		if collision.get_collider().is_in_group("blue_orb"):
			if haptics_enabled: Input.vibrate_handheld(35)
			cam.shake(5, 5, 4)
			velocity.y = -0.75 * Vector2(abs(velocity.x * 0.8), abs(velocity.y * 0.8 - 300)).length()
			velocity.x /= 5

			collision.get_collider().Destroy()

			IncreaseStamina(20)
			IncreaseScore(2)

	# Если красный орб
		if collision.get_collider().is_in_group("red_orb"):
			die()

	# Если фиолетовый орб
		if collision.get_collider().is_in_group("purple_orb"):
			if haptics_enabled: Input.vibrate_handheld(35)
			cam.shake(5, 5, 4)
			velocity.x = cos(collision.get_collider().rotation - PI/2) * 1000
			velocity.y = sin(collision.get_collider().rotation - PI/2) * 1000
			if velocity.y < 700: velocity.y *= 1.5 # Когда фиолетовый орб направлен наверх, увеличить отдачу

			collision.get_collider().Destroy()

			IncreaseStamina(30)
			IncreaseScore(5)

	# Если желтый орб
		if collision.get_collider().is_in_group("yellow_orb"):
			if haptics_enabled: Input.vibrate_handheld(35)
			cam.shake(5, 5, 4)
			velocity.y = -0.75 * Vector2(abs(velocity.x * 0.8), abs(velocity.y * 0.8 - 300)).length()
			velocity.x /= 5

			collision.get_collider().Destroy()

			IncreaseStamina(40)
			IncreaseScore(10)
			coins_this_round += 1
			coins_label.text = str(coins_this_round)

	# Если зеленый орб
		if collision.get_collider().is_in_group("green_orb"):
			velocity.y = 0.75 * Vector2(abs(velocity.x * 0.8), abs(velocity.y * 0.8 + 300)).length()
			velocity.x /= 5

			if is_instance_valid(boss_1):
				collision.get_collider().Parry()
				IncreaseStamina(50)
				IncreaseScore(10)
			else:
				collision.get_collider().Destroy()
				IncreaseStamina(100)
				IncreaseScore(50)
#endregion

#region Если игрок за пределами экрана, убить его
	if (position.x > border_right + 64
			or position.x < border_right - get_viewport_rect().size.x - 64
			or position.y > border_up + cam.position.y - 600
			or position.y > border_up + 64):
		die()
#endregion

#region Спавн орбов
	if prev_pos - cam.position.y > 300:
		prev_pos = cam.position.y
		SpawnOrbs()
#endregion

#region Стамина
	if hasStarted:
		new_stamina_value = clamp(0, new_stamina_value - 0.6, 100)
		var tw = create_tween()
		tw.tween_property(%StaminaBar, "value", new_stamina_value, 0.1)


var tween
func IncreaseStamina(val):
	new_stamina_value += val

	%StaminaBar.get("theme_override_styles/fill").bg_color = accent_color + Color(0.025 * val, 0.025 * val, 0.025 * val)
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(%StaminaBar.get("theme_override_styles/fill"), "bg_color", accent_color, 0.2)
#endregion


func _process(_delta):
	score_label.text = str(score)


# Когда игрок нажимает на паузу, отключить управление
func _on_pause_button_down():
	mouseEnabled = false


func die():
	save_manager.Save()
	time_scale_changed.emit()
	cam.shake(10, 20, 4)
	Engine.time_scale = 1
	var death_effect = death_particle.instantiate()
	get_tree().current_scene.add_child(death_effect)
	death_effect.global_position = global_position
	death_effect.emitting = true
# Если игрок умер за пределами экрана, то направление партиклов сделать в обратную сторону
	if position.x > border_right + 64:
		death_effect.direction = Vector2(-1, 0)
	elif position.x < border_right - get_viewport_rect().size.x - 64:
		death_effect.direction = Vector2(1, 0)
	elif position.y > border_up + 64 or position.y > border_up + cam.position.y - 600:
		death_effect.direction = Vector2(0, -1)
	else:
		death_effect.direction = velocity.normalized()
	death_effect.initial_velocity_min = max(velocity.length(), 1000) * 0.25
	death_effect.initial_velocity_max = max(velocity.length(), 1000) * 0.75
	death_effect.color = Color(0, 0.5, 1, 1)
	mouseEnabled = false
	if haptics_enabled: Input.vibrate_handheld(100)
	queue_free()


func _slow_process():
	await get_tree().create_timer(2, false, false, true).timeout

	# Отсылка на Субнатику и The Stanley Parable 🗣🗣🔥🔥🔥🥵🥵
	#if score > ("4546B".hex_to_int() / float(427)) and coins_this_round > 15:
	if score >= 600 and coins_this_round >= 20 and not boss_spawned:
		boss_spawned = true
		Spawn_boss()

	_slow_process()


#region Спавн орбов
var max_orbs: int = 3
var prev_pos: float = 1000.0
var last_time_empty: int = 0 # Чтобы не могло быть 0 орбов больше одного раза подряд


func SpawnOrbs(vertical_offset = 0):

	var orb_count: int = randi_range(0 + last_time_empty, max_orbs)
	var gap: float = 0
	if not orb_count == 0: gap = (get_viewport_rect().size.x / 6) * (3.0 / orb_count)

	if orb_count == 0: last_time_empty = 1
	else: for i in range(orb_count):
		var indx = i + 1
		var offset_x = randf_range(-gap * 0.75, gap * 0.75)
		var offset_y = randf_range(-90, 90) + vertical_offset
		var orb_pos_x = (indx * gap + i * gap) + (864 - get_viewport_rect().size.x) / 2

		var orb
		var rand_rotation
		var chance = randi_range(1, 100)
		if chance >= 50: orb = blue_orb.instantiate(); rand_rotation = 0
		elif chance >= 30: orb = red_orb.instantiate(); rand_rotation = randi_range(-180, 180)
		elif chance >= 10: orb = purple_orb.instantiate(); rand_rotation = randi_range(-180, 180)
		else: orb = yellow_orb.instantiate(); rand_rotation = randi_range(-180, 180)
		get_parent().add_child.call_deferred(orb)
		orb.position.x = orb_pos_x + offset_x
		orb.position.y = cam.position.y - 1000 + offset_y
		orb.rotation_degrees = rand_rotation
		last_time_empty = 0
#endregion


#region Счет
var actual_score := 0
func IncreaseScore(amount):
	tween = create_tween()
	tween.tween_property(self, "score", actual_score + amount, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	actual_score += amount
#endregion


func Autosave():
	await get_tree().create_timer(60).timeout
	save_manager.Save()
	Autosave()


func Spawn_boss():
	await get_tree().create_timer(1).timeout
	var boss = boss_1.instantiate()
	get_tree().current_scene.add_child.call_deferred(boss)
	boss.position.x = SCREEN_CENTER_INGAME.x
	boss.position.y = cam.get_screen_center_position().y - 1500
