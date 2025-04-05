extends CanvasLayer


@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var update_on_startup: CheckBox = $SmoothScrollContainer/VBoxContainer/UpdateOnStartup


func _ready() -> void:
	await RenderingServer.frame_post_draw

	GlobalVariables.popup_order.append(get_path())

	var screenshot: Image = get_viewport().get_texture().get_image()
	var blurred: Image = GlobalVariables.blur_image(screenshot)

	$Blur.texture = ImageTexture.create_from_image(blurred)

	animation.play("open")
	_load_config()


func _load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(GlobalVariables.CONFIG_DIR)
	update_on_startup.button_pressed = config.get_value("player", "show_update_on_startup", true)


func _on_back_pressed() -> void:
	_close()


func _close() -> void:
	GlobalVariables.popup_order.pop_back()
	animation.current_animation = "open"
	animation.speed_scale = 1.6
	animation.seek(0.4)
	animation.play_backwards("open")
	await animation.animation_finished
	queue_free()


func _on_update_on_startup_pressed() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(GlobalVariables.CONFIG_DIR)
	config.set_value("player", "show_update_on_startup", update_on_startup.button_pressed)
	config.save(GlobalVariables.CONFIG_DIR)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if GlobalVariables.popup_order.back() == get_path():
			_on_back_pressed()
