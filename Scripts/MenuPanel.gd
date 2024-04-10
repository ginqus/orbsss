extends VBoxContainer


@onready var fps := get_child(0)
@onready var blur_texture := $"../BlurTextureRect"
@onready var saving_manager := $"../../../Saving manager"
@onready var best_score_label := $"../Info panel/Best score/Best score count"
@onready var total_coins_label := $"../Info panel/TextureRect/Total coins"
@onready var info_panel := $"../Info panel"
var back
var tween
var config = ConfigFile.new()
const config_location := "user://orbsss-settings.cfg"

func _ready():
	config.load(config_location)
	if get_tree().current_scene.name == "MainLevel":
		back = $"../Back"
	if get_tree().current_scene.name == "MainMenu":
		back = $/root/MainMenu/Back
	if !config.get_value("Settings", "ShowBlur", true):
		blur_texture.hide()


func _on_pause_pressed():
	%Menu.show()
	%Menu.modulate.a = 0.0
	scale = Vector2(0, 0)
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(%Menu, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(self, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if has_node("%Player"):
		%Player.mouseEnabled = false
		saving_manager.Save()
		best_score_label.text = str(%Player.best_score)
		total_coins_label.text = str(%Player.coins_total)
	get_tree().paused = true


func _on_resume_pressed():
	back.position.x = -256
	%Menu.hide()
	get_tree().paused = false

func _on_settings_pressed():
	if tween: tween.kill()
	tween = create_tween()
	%SettingsVBox.show()
	back.show(); back.modulate.a = 0; back.scale = Vector2(0.7, 0.7)
	tween.parallel().tween_property(back, "modulate:a", 1, 0.3)
	tween.parallel().tween_property(back, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(back, "position:x", 32, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	%MenuPanel.hide()
	info_panel.hide()

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Levels/menu.tscn")

func _on_back_pressed():
	tween = create_tween()
	tween.tween_property(back, "position:x", -208, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(back, "modulate:a", 0, 0.2).set_delay(0.1)
	tween.parallel().tween_property(back, "scale", Vector2(0.7, 0.7), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.05)
	%MenuPanel.show()
	info_panel.show()
	%SettingsVBox.hide()

func _on_fps_toggle_pressed():
	if get_tree().current_scene.name == "MainLevel":
		if %FPS.visible:
			%FPS._hide()
		else:
			%FPS._show()
