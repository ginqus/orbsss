extends Control


@onready var play_btn:      Button = $Play
@onready var settings_btn:  Button = $Settings
@onready var exit_btn:      Button = $Exit
@onready var language_btn:  Button = $Language
@onready var english_btn:   Button = $Language/English
@onready var russian_btn:   Button = $Language/Russian

@onready var english_pos: float = english_btn.position.x
@onready var russian_pos: float = russian_btn.position.x

var popup_dialog: PackedScene = preload("res://Instances/popup.tscn")
var settings_scn: PackedScene = preload("res://Instances/settings.tscn")
var themes_scene: PackedScene = preload("res://Instances/themes.tscn")
var upgrades_scn: PackedScene = preload("res://Instances/upgrades.tscn")

var is_lang_open: bool = false
var locale: String = TranslationServer.get_locale()
var progress: Array


func _ready() -> void:
	_load_config()
	TranslationServer.set_locale(locale)
	GlobalVariables.popup_order.clear()
	GlobalVariables.popup_order.append(get_path())


func _on_language_pressed() -> void:
	if not is_lang_open:
		_open_language_menu()
	else:
		_close_language_menu()


func _open_language_menu() -> void:
	var new_pos: float = 0
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	is_lang_open = true
	new_pos = english_pos - 244
	tween.parallel().tween_property(english_btn, "position:x", new_pos, 0.3)
	new_pos = russian_pos - 244
	tween.parallel().tween_property(russian_btn, "position:x", new_pos, 0.3).set_delay(0.075)


func _close_language_menu() -> void:
	var new_pos: float = 0
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	is_lang_open = false
	new_pos = english_pos + 244
	tween.parallel().tween_property(english_btn, "position:x", new_pos, 0.3)
	new_pos = russian_pos + 244
	tween.parallel().tween_property(russian_btn, "position:x", new_pos, 0.3).set_delay(0.075)


func _on_english_pressed() -> void:
	TranslationServer.set_locale('en')
	_close_language_menu()
	_save_config()


func _on_russian_pressed() -> void:
	TranslationServer.set_locale('ru')
	_close_language_menu()
	_save_config()


func _save_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(GlobalVariables.CONFIG_DIR)
	locale = TranslationServer.get_locale()
	config.set_value("player", "locale", locale)
	config.save(GlobalVariables.CONFIG_DIR)


func _load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	var default_locale: String = TranslationServer.get_locale()
	config.load(GlobalVariables.CONFIG_DIR)
	locale = config.get_value("player", "locale", default_locale)


func _on_exit_pressed() -> void:
	var popup: CanvasLayer = popup_dialog.instantiate()
	var buttons: Array = [
		[tr("KEY_NO")],
		[tr("KEY_YES"), func _on_yes_pressed() -> void: get_tree().quit(), "red"],
	]
	get_tree().root.add_child(popup)
	popup.add_buttons(buttons)
	popup.set_title(tr("KEY_CONFIRM_EXIT"))


func _on_settings_pressed() -> void:
	var settings: CanvasLayer = settings_scn.instantiate()
	get_tree().root.add_child(settings)


func _on_play_pressed() -> void:
	ResourceLoader.load_threaded_request("res://Scenes/main.tscn")
	_update_progressbar_every_frame()


func _update_progressbar_every_frame() -> void:
	await get_tree().create_timer(get_process_delta_time()).timeout
	var progressbar: ProgressBar = play_btn.get_child(0)
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC)

	ResourceLoader.load_threaded_get_status("res://Scenes/main.tscn", progress)
	tween.tween_property(progressbar, "value", progress[0], 0.05)
	if progress[0] >= 1.0:
		var main_scene: PackedScene = ResourceLoader.load_threaded_get("res://Scenes/main.tscn")
		get_tree().change_scene_to_packed.bind(main_scene).call_deferred()
	_update_progressbar_every_frame()


func _on_github_pressed() -> void:
	OS.shell_open('https://github.com/ginqus/orbsss')


func _on_themes_pressed() -> void:
	var themes: CanvasLayer = themes_scene.instantiate()
	get_tree().root.add_child(themes)


func _on_upgrades_pressed() -> void:
	var upgrades: CanvasLayer = upgrades_scn.instantiate()
	get_tree().root.add_child(upgrades)


func _on_button_pressed() -> void:
	printerr("⚠️ INFO BUTTON NOT IMPLEMENTED ⚠️")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if GlobalVariables.popup_order.back() == get_path():
			_on_exit_pressed()
