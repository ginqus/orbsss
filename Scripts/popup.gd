extends CanvasLayer


@onready var title_label: Label = $Panel/Title
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var button_container: HFlowContainer = $Panel/HFlowContainer
@onready var close_button: Button = $Panel/Close

var is_clickable_instantly: bool = true
var big_ass_buttons_enabled: bool = true


func _ready() -> void:
	await RenderingServer.frame_post_draw

	GlobalVariables.popup_order.append(get_path())

	var screenshot: Image = get_viewport().get_texture().get_image()
	var blurred: Image = GlobalVariables.blur_image(screenshot)

	$Blur.texture = ImageTexture.create_from_image(blurred)

	button_container.size.x = get_viewport().get_visible_rect().size.x - 16
	button_container.global_position.x = 8
	animation.play("open")
	await animation.animation_finished
	for button in button_container.get_children():
		button.disabled = false
		close_button.disabled = false


func set_title(title: String) -> void:
	title_label.text = title


func add_buttons(buttons: Array = []) -> void:
	for button: Array in buttons:
		var button_text: String = button[0]
		var callback: Callable = button[1] if button.size() > 1 else close
		var color: String = button[2] if button.size() > 2 else "white"
		var new_button: Button = Button.new()

		new_button.text = button_text
		new_button.connect("pressed", callback)
		if big_ass_buttons_enabled:
			#new_button.custom_minimum_size.x = 216
			# TODO: godot flow container fill
			new_button.custom_minimum_size.x = (
				button_container.size.x / buttons.size()
				- button_container["theme_override_constants/h_separation"] / 2)
		if not is_clickable_instantly:
			new_button.disabled = true
			close_button.disabled = true

		var theme: Theme = preload("res://Themes/frozen_dark/themes/ui_button_popup.tres")
		var style: StyleBox = theme.get_stylebox("pressed", "Button").duplicate()
		match color:
			"white":
				pass
			"red":
				style.set("bg_color", Color.hex(0xff808aff))
			"green":
				style.set("bg_color", Color.hex(0x80ff8aff))

		new_button.add_theme_stylebox_override("pressed", style)

		button_container.add_child(new_button)


func close() -> void:
	GlobalVariables.popup_order.pop_back()
	toggle_buttons()
	animation.seek(0.25)
	animation.speed_scale = 1.5
	animation.play_backwards("open")
	await animation.animation_finished
	queue_free()


func toggle_buttons() -> void:
	for button: Button in button_container.get_children():
		button.disabled = not button.disabled


func _on_close_pressed() -> void:
	close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if GlobalVariables.popup_order.back() == get_path():
			_on_close_pressed()
