extends Node


const config_location := "user://orbsss-settings.cfg"
@onready var settings := $Settings
@onready var back := $Back
@onready var language := $Language
@onready var play := $Play
@onready var settings_panel := $SettingsPanel

var config := ConfigFile.new()
var is_language_opened := false
var savedLang : String


func _ready():
# Установить язык из сохранения. Если сохранения нет, установить язык из настроек
	config.load("user://orbsss-settings.cfg")
	if config.has_section_key("Settings", "Language"): savedLang = config.get_value("Settings", "Language")
	else: savedLang = OS.get_locale_language()
	if savedLang != null: TranslationServer.set_locale(savedLang)

func _on_settings_pressed():
	var tween = create_tween()
	settings.hide(); language.hide(); play.hide();
	settings_panel.show(); back.show()
	settings_panel.modulate.a = 0; back.modulate.a = 0; back.scale = Vector2(0.7, 0.7)
	tween.parallel().tween_property(back, "modulate:a", 1, 0.3)
	tween.parallel().tween_property(back, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(back, "position:x", 64, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(settings_panel, "modulate:a", 1, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

var progress = []
func _on_play_pressed():
	ResourceLoader.load_threaded_request("res://Scenes/Levels/main.tscn")
	ResourceLoader.load_threaded_get_status("res://Scenes/Levels/main.tscn", progress)
	_check_load_progress()

@onready var level_progressbar := $LevelProgressBar
func _check_load_progress():
	if progress[0] < 1.0:
		var tween = create_tween()
		ResourceLoader.load_threaded_get_status("res://Scenes/Levels/main.tscn", progress)
		tween.tween_property(level_progressbar, "value", progress[0] * 100, 0.1)
		await get_tree().create_timer(get_process_delta_time()).timeout
		_check_load_progress()
	elif ResourceLoader.load_threaded_get_status("res://Scenes/Levels/main.tscn") == 3:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get("res://Scenes/Levels/main.tscn"))


func _on_language_pressed():
	if is_language_opened: _language_close()
	else: _language_open()
	is_language_opened = !is_language_opened

func _language_open():
	var tween = create_tween()
	language.get_child(0).modulate.a = 0; language.get_child(1).modulate.a = 0;
	language.get_child(0).scale = Vector2(0.7, 0.7); language.get_child(1).scale = Vector2(0.7, 0.7);
	tween.parallel().tween_property(language.get_child(0), "position:x", 20, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(language.get_child(0), "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(language.get_child(0), "modulate:a", 1, 0.3)
	tween.parallel().tween_property(language.get_child(1), "position:x", 68, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1)
	tween.parallel().tween_property(language.get_child(1), "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(language.get_child(1), "modulate:a", 1, 0.3)

func _language_close():
	var tween = create_tween()
	tween.parallel().tween_property(language.get_child(1), "position:x", 536, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(language.get_child(1), "scale", Vector2(0.7, 0.7), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.15)
	tween.parallel().tween_property(language.get_child(1), "modulate:a", 0, 0.3).set_delay(0.1)
	tween.parallel().tween_property(language.get_child(0), "position:x", 536, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN).set_delay(0.1)
	tween.parallel().tween_property(language.get_child(0), "scale", Vector2(0.7, 0.7), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.15)
	tween.parallel().tween_property(language.get_child(0), "modulate:a", 0, 0.3).set_delay(0.1)

func _on_russian_pressed():
	config.load(config_location)
	TranslationServer.set_locale("ru")
	_language_close()
	is_language_opened = false
	config.set_value("Settings", "Language", "ru")
	config.save(config_location)

func _on_english_pressed():
	config.load(config_location)
	TranslationServer.set_locale("en")
	_language_close()
	is_language_opened = false
	config.set_value("Settings", "Language", "en")
	config.save(config_location)

func _on_back_pressed():
	var tween = create_tween()
	tween.tween_property(back, "position:x", -208, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(back, "modulate:a", 0, 0.2).set_delay(0.1)
	tween.parallel().tween_property(back, "scale", Vector2(0.7, 0.7), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.05)
	settings_panel.hide()
	settings.show()
	language.show()
	play.show()

#region DEBUG
func _on_deletecfg_pressed():
	config.clear()
	config.save(config_location)

func _on_viewcfg_pressed():
	print(config)
	print(config.get_sections())
	print(config.get_section_keys("Settings"))
	print("Language: ", config.get_value("Settings", "Language"))
	print("ShowFPS: ", config.get_value("Settings", "ShowFPS"))
	print("ShowVignette: ", config.get_value("Settings", "ShowVignette"))
#endregion


func _on_github_pressed() -> void:
	OS.shell_open('https://github.com/I-like-Portal-2/orbsss')
