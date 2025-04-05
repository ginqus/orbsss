extends CanvasLayer


@onready var animation:         AnimationPlayer = $AnimationPlayer
@onready var preview_container: HBoxContainer = $Control/FadeMask/SmoothScrollContainer/HBoxContainer
@onready var smooth_scroll:     SmoothScrollContainer = $Control/FadeMask/SmoothScrollContainer
@onready var preview_panel:     Panel = $Control/Preview

@onready var preview_scn: PackedScene = preload("res://Instances/theme_preview.tscn")

var theme_list: Array


func _ready() -> void:
	await RenderingServer.frame_post_draw

	GlobalVariables.popup_order.append(get_path())

	var screenshot: Image = get_viewport().get_texture().get_image()
	var blurred: Image = GlobalVariables.blur_image(screenshot)

	$Blur.texture = ImageTexture.create_from_image(blurred)

	var dir: DirAccess = DirAccess.open("res://Themes/")
	theme_list = dir.get_directories()
	animation.play("open")
	_load_themes()


func _load_themes() -> void:
	const theme_preview_width := 208
	const theme_preview_padding := 24
	var preview_panel_width: float = get_viewport().get_visible_rect().size.x - 16
	var blank_space_size := (
		preview_panel_width - theme_preview_padding * 2) / 2 - theme_preview_width / 2.0
	var blank_space: ColorRect = ColorRect.new()
	blank_space.custom_minimum_size.x = blank_space_size
	blank_space.color = Color.TRANSPARENT
	preview_container.add_child(blank_space)
	for theme: String in theme_list:
		var preview: Control = preview_scn.instantiate()
		preview_container.add_child(preview)
		var preview_path: String = "res://Themes/" + theme + "/preview.svg"
		preview.set_preview_image(preview_path)
		preview.set_preview_title(theme.replace('_', ' '))
	preview_container.add_child(blank_space.duplicate())


func _on_smooth_scroll_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and smooth_scroll.is_scrolling:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var preview_width := 256 + preview_container.get_theme_constant("separation")
			var nearest_value: int
			if smooth_scroll.velocity.x <= -200:
				# Turns out, you can't just ceil/floor to the closest number,
				# so here we are just dividing by preview width, ceil/floor
				# that, and multiply again, effectively ceiling/flooring to the
				# nearest number.
				nearest_value = ceili(
					(smooth_scroll.scroll_horizontal) / float(preview_width)) \
					* preview_width
			elif smooth_scroll.velocity.x >= 200:
				nearest_value = floori(
					(smooth_scroll.scroll_horizontal) / float(preview_width)) \
					* preview_width
			else:
				nearest_value = snappedi(smooth_scroll.scroll_horizontal, preview_width)
			var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(smooth_scroll, "scroll_horizontal", nearest_value, 0.2)


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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if GlobalVariables.popup_order.back() == get_path():
			_on_back_pressed()
