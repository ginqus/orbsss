extends Node2D


@onready var player:   CharacterBody2D = $Player
@onready var parallax: Parallax2D = $Parallax2D
@onready var camera:   Camera2D = $Camera
@onready var overlay:  TextureRect = $Camera/BackgroundOverlay

const row_height: int = 300

var boss_scene: PackedScene = preload("res://Instances/boss_1.tscn")
var pause_menu: PackedScene = preload("res://Instances/pause_menu.tscn")
var blue_orb:   PackedScene = preload("res://Instances/blue_orb.tscn")
var purple_orb: PackedScene = preload("res://Instances/purple_orb.tscn")
var yellow_orb: PackedScene = preload("res://Instances/yellow_orb.tscn")
var green_orb:  PackedScene = preload("res://Instances/green_orb.tscn")
var red_orb:    PackedScene = preload("res://Instances/red_orb.tscn")
var red_line:   PackedScene = preload("res://Instances/red_line.tscn")

var screen_height: int
var is_pause_button_held: bool
var coins_before_round: int = 0
var boss_spawned: bool = false


func _ready() -> void:
	screen_height = int(get_viewport_rect().size.y)
	_spawn_initial_orbs()
	# Needed for the back gesture on Android to work.
	GlobalVariables.popup_order.clear()
	GlobalVariables.popup_order.append(get_path())
	# Make the background overlay take the entire screen.
	overlay.position = -get_viewport_rect().size / 2 + camera.offset
	overlay.set_deferred("size", get_viewport_rect().size)
	load_data()

	$Parallax2D/Background.texture.get_image().save_png("user://thatfuckingbirdthatihate.png")


func _process(_delta: float) -> void:
	parallax.screen_offset.y = camera.position.y + camera.offset.y
	if prev_pos - camera.position.y > row_height:
		prev_pos = camera.position.y
		spawn_row_of_orbs()

	if not player.is_killed:
		var player_relative_pos: Vector2 = player.position - camera.position
		#print(player_relative_pos)
		if (absf(player_relative_pos.x) - player.collision_shape.shape.radius
				> absf(get_viewport_rect().size.x / 2)
				or player_relative_pos.y - player.collision_shape.shape.radius
				> get_viewport_rect().size.y / 2 + camera.offset.y):
			player.take_damage()

	if OS.is_debug_build():
		if Input.is_action_just_pressed("right_click") and not boss_spawned:
			player.increase_score(110)

	if not player.is_killed:
		if player.score >= 500 and not boss_spawned:
			spawn_boss()


func spawn_boss() -> void:
	boss_spawned = true
	var boss := boss_scene.instantiate()
	add_child(boss)
	boss.position.y = camera.get_screen_center_position().y - 1500
	boss.position.x = get_viewport_rect().size.x / 2


func _on_pause_pressed() -> void:
	var pause: CanvasLayer = pause_menu.instantiate()
	add_child.call_deferred(pause)
	get_tree().paused = true
	is_pause_button_held = false
	save_data()


func load_data() -> void:
	coins_before_round = SaveSystem.get_var("coins", 0)


func save_data() -> void:
	SaveSystem.set_var("coins", coins_before_round + player.coins)
	if player.score > SaveSystem.get_var("best_score", 0):
		SaveSystem.set_var("best_score", player.score)
	SaveSystem.save()


func _on_pause_button_down() -> void:
	is_pause_button_held = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_pause_button_held = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # Android back gesture
		if GlobalVariables.popup_order.back() == get_path():
			_on_pause_pressed()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:  # Pause when game is not active
		if not get_tree().paused:
			_on_pause_pressed()


func _spawn_initial_orbs() -> void:
	var offset: int = 0
	while offset < camera.offset.y * 2 + screen_height:  # Multiplying by 2 just works
		spawn_row_of_orbs(offset)
		offset += row_height


var max_orbs: int = 3
var prev_pos: float = 1000.0
var last_time_empty: int = 0

func spawn_row_of_orbs(vertical_offset: int = 0) -> void:
	# TODO: test and delete code for empty rows if not needed
	var orb_count: int = randi_range(1 + last_time_empty, max_orbs)
	var gap: float = 0
	if not orb_count == 0:
		gap = (get_viewport_rect().size.x / 6) * (3.0 / orb_count)
	var pos_x: float

	if orb_count == 0:
		last_time_empty = 1
	else:
		for i in range(orb_count):
			var index: int = i + 1
			var offset_x: float = randf_range(-gap * 0.65, gap * 0.65)
			var offset_y: float = randf_range(-90, 90) + vertical_offset
			var orb_pos_x: float = index * gap + i * gap

			var orb: StaticBody2D
			var rand_rotation: int
			var chance: int = randi_range(1, 100)
			if chance >= 50:  # 50
				orb = blue_orb.instantiate()
				rand_rotation = 0
			elif chance >= 35:
				orb = red_orb.instantiate()
				rand_rotation = randi_range(-180, 180)
			elif chance >= 34:
				orb = green_orb.instantiate()
				rand_rotation = 0
			elif chance >= 30:
				orb = red_line.instantiate()
				pos_x = get_viewport_rect().size.x / 2
				rand_rotation = 0
			elif chance >= 10:
				orb = purple_orb.instantiate()
				rand_rotation = randi_range(-180, 180)
			else:
				orb = yellow_orb.instantiate()
				rand_rotation = randi_range(-180, 180)

			add_child(orb)
			if not pos_x:
				orb.position.x = orb_pos_x + offset_x
			else:
				orb.position.x = pos_x
			orb.position.y = (
				camera.position.y + camera.offset.y * 2  # Multiplying by 2 just works
				- screen_height / 2.0 + offset_y
			)
			orb.rotation_degrees = rand_rotation
			last_time_empty = 0
	#if OS.is_debug_build():
		#var min_value: float = debug_pos_y_arr.min() - 40
		#var max_value: float = debug_pos_y_arr.max() + 40
		#var rect: ColorRect = ColorRect.new()
		#rect.color = Color8(255, 0, 0, 64)
		#rect.position = Vector2(0, min_value)
		#rect.size = Vector2(get_viewport_rect().size.x, max_value - min_value)
		#add_child(rect)

		#var line: Line2D = Line2D.new()
		#line.default_color = Color.RED
		#line.width = 2
		#add_child(line)
		#line.add_point(Vector2i(0, min_value))
		#line.add_point(Vector2i(int(get_viewport_rect().size.x), min_value))


func _on_player_killed() -> void:
	await get_tree().create_timer(1, false, false, true).timeout
	get_tree().reload_current_scene()
	save_data()
	#ResourceLoader.load_threaded_request("res://Scenes/main.tscn")
#
#
	#var main_scene: PackedScene = (ResourceLoader.load_threaded_get("res://Scenes/main.tscn"))
	#get_tree().change_scene_to_packed.bind(main_scene).call_deferred()
	#await ResourceLoader.
	#var main_scene: PackedScene = ResourceLoader.load_threaded_get("res://Scenes/main.tscn")
	#get_tree().change_scene_to_packed.bind(main_scene).call_deferred()
