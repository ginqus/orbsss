extends CanvasLayer


@onready var play_button:     Button = $VBoxContainer/Play
@onready var settings_button: Button = $VBoxContainer/Settings
@onready var menu_button:     Button = $VBoxContainer/MainMenu
@onready var animation:       AnimationPlayer = $AnimationPlayer
@onready var coin_label:      Label = $Stats/Coins
@onready var best_score:      Label = $Stats/BestScoreLabel/BestScore  # TODO: make it work dammit

var popup_dialog: PackedScene = preload("res://Instances/popup.tscn")
var settings_scn: PackedScene = preload("res://Instances/settings.tscn")


func _ready() -> void:
	await RenderingServer.frame_post_draw

	GlobalVariables.popup_order.append(get_path())

	var screenshot: Image = get_viewport().get_texture().get_image()
	var blurred: Image = GlobalVariables.blur_image(screenshot)

	$Blur.texture = ImageTexture.create_from_image(blurred)

	animation.play('open')

	load_data()


func _on_play_pressed() -> void:
	_close()


func _on_settings_pressed() -> void:
	var settings: CanvasLayer = settings_scn.instantiate()
	get_tree().root.add_child(settings)


func _on_main_menu_pressed() -> void:
	var popup: CanvasLayer = popup_dialog.instantiate()
	var buttons: Array = [
		[tr("KEY_NO")],
		[tr("KEY_YES"), func _on_yes_pressed() -> void:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://Scenes/menu.tscn")
			popup.close(), "red"],
	]
	get_tree().root.add_child(popup)
	popup.add_buttons(buttons)
	popup.set_title(tr("KEY_CONFIRM_MENU"))


func _close() -> void:
	GlobalVariables.popup_order.pop_back()
	Engine.time_scale = 0.1
	animation.seek(0.25)
	animation.speed_scale = 2 / Engine.time_scale
	animation.play_backwards('open')
	await animation.animation_finished
	get_tree().paused = false
	hide()
	await _speed_up_time()
	queue_free()


func _speed_up_time() -> void:  # We can't use Tween because Tween is affected by Engine.time_scale
	for i in range(10):
		Engine.time_scale = (i + 1) / 10.0
		await get_tree().create_timer(0.02, true, false, true).timeout


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if GlobalVariables.popup_order.back() == get_path():
			_on_play_pressed()


func _on_restart_pressed() -> void:
	var popup: CanvasLayer = popup_dialog.instantiate()
	var buttons: Array = [
		[tr("KEY_NO")],
		[tr("KEY_YES"), func _on_yes_pressed() -> void:
			get_tree().paused = false
			get_tree().reload_current_scene()
			popup.close(), "red"],
	]
	get_tree().root.add_child(popup)
	popup.add_buttons(buttons)
	popup.set_title(tr("KEY_CONFIRM_RESTART"))


func load_data() -> void:
	coin_label.text = str(int(SaveSystem.get_var("coins", 0)))
	best_score.text = str(int(SaveSystem.get_var("best_score", 0)))
