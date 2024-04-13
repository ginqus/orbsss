extends VBoxContainer


const config_location := "user://orbsss-settings.cfg"
var config: ConfigFile = ConfigFile.new()
@onready var fps_toggle: Button = $FPSToggle
@onready var blur_toggle: Button = $BlurToggle
@onready var blur_texture: TextureRect = $"../BlurTextureRect"
@onready var sensitivity: HSlider = $"Sensitivity slider"
@onready var vibration_toggle: Button = $"Vibration toggle"

func _ready():
	config.load(config_location)

	fps_toggle.button_pressed = config.get_value("Settings", "ShowFPS", false)
	blur_toggle.button_pressed = config.get_value("Settings", "ShowBlur", true)
	vibration_toggle.button_pressed = config.get_value("Settings", "Vibration", true)
	sensitivity.value = config.get_value("Settings", "Sensitivity", 11.0)

	if blur_toggle.button_pressed: blur_texture.show()
	else: blur_texture.hide()
	Save()

func Save():
	config.load(config_location)
	config.set_value("Settings", "ShowFPS", fps_toggle.button_pressed)
	config.set_value("Settings", "ShowBlur", blur_toggle.button_pressed)
	config.set_value("Settings", "Sensitivity", sensitivity.value)
	config.set_value("Settings", "Vibration", vibration_toggle.button_pressed)
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


func _on_vibration_toggle_pressed() -> void:
	Save()
	if get_tree().current_scene.name == "MainLevel":
		%Player.haptics_enabled = vibration_toggle.button_pressed
