extends VBoxContainer


const config_location := "user://ballin-settings.cfg"
var config = ConfigFile.new()
@onready var fps_toggle := $FPSToggle
@onready var blur_toggle := $BlurToggle
@onready var blur_texture := $"../BlurTextureRect"
@onready var sensitivity := $"Sensitivity slider"

func _ready():
	config.load(config_location)

	fps_toggle.button_pressed = config.get_value("Settings", "ShowFPS", false)
	blur_toggle.button_pressed = config.get_value("Settings", "ShowBlur", true)
	sensitivity.value = config.get_value("Settings", "Sensitivity", 11.0)

func Save():
	config.load(config_location)
	config.set_value("Settings", "ShowFPS", fps_toggle.button_pressed)
	config.set_value("Settings", "ShowBlur", blur_toggle.button_pressed)
	config.set_value("Settings", "Sensitivity", sensitivity.value)
	config.save(config_location)


func _on_fps_toggle_pressed():
	if get_tree().current_scene.name == "MainLevel" and fps_toggle.button_pressed:
		%FPS._show()
	elif get_tree().current_scene.name == "MainLevel" and !fps_toggle.button_pressed:
		%FPS._hide()
	Save()

func _on_blur_toggle_pressed():
	if blur_toggle.button_pressed: blur_texture.show()
	else: blur_texture.hide()
	Save()

func _on_sensitivity_slider_drag_ended(value_changed):
	if value_changed:
		Save()
		if get_tree().current_scene.name == "MainLevel":
			%Player.sensitivity = sensitivity.value
