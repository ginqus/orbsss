extends Button

# Thank you, Face, for open-sourcing GriddyCode from which I took the code <3
# https://github.com/face-hh/griddycode

var VERSION: String = ProjectSettings.get_setting("application/config/version")
var is_requesting: bool = false
var popup_dialog: PackedScene = preload("res://Instances/popup.tscn")
var animation: AnimationPlayer
var show_on_startup: bool = true

@onready var http: HTTPRequest = $HTTPRequest
@onready var toast: Label = $"../Toast"


func _ready() -> void:
	animation = get_child(1)
	_load_config()
	if show_on_startup and Engine.get_frames_drawn() == 0:  # If 0, the game has just started
		_on_pressed()


func _on_pressed() -> void:
	text = ""
	if is_requesting:
		return
	if not is_requesting:
		animation.play("loading")
	http.request("https://api.github.com/repos/ginqus/orbsss/releases/latest")
	is_requesting = true


func _on_http_request_request_completed(
		_result: int, _response_code: int,
		_headers: PackedStringArray, body: PackedByteArray) -> void:
	var json: Dictionary = JSON.parse_string(body.get_string_from_utf8())

	rotation_degrees = 0
	animation.stop()

	if not json.has("name"):
		_display_toast(tr("KEY_TOO_MANY_REQUESTS"), "error")
		return

	if not is_higher_version(json["name"]):
		#if OS.get_name() == "Android":
			#var toast_plugin: Object = Engine.get_singleton("ToastPlugin")
			#toast_plugin.showToast(tr("KEY_UP_TO_DATE"), 0, 0, 0, 0)
		_display_toast(tr("KEY_UP_TO_DATE"))
	else:
		var popup: CanvasLayer = popup_dialog.instantiate()

		var dont_show_again: Callable = func() -> void:
			var config: ConfigFile = ConfigFile.new()
			config.load(GlobalVariables.CONFIG_DIR)
			config.set_value("player", "show_update_on_startup", false)
			config.save(GlobalVariables.CONFIG_DIR)
			popup.close()

		var buttons: Array = [
			[tr("KEY_DOWNLOAD"), func open_url() -> void: OS.shell_open(json["html_url"]), "green"],
			[tr("KEY_DONT_SHOW"), dont_show_again, "red"],
		]
		get_tree().root.add_child(popup)
		popup.is_clickable_instantly = false
		popup.add_buttons(buttons)
		popup.set_title(tr("KEY_UPDATE_AVAILABLE"))

	is_requesting = false


func _load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(GlobalVariables.CONFIG_DIR)
	show_on_startup = config.get_value("player", "show_update_on_startup", true)


func _display_toast(_text: String, type: String = "") -> void:
	toast.show()
	toast.text = _text

	if type == "error":
		toast.modulate = Color(1, 0.5, 0.5)

	await get_tree().create_timer(2).timeout
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD)
	await tween.tween_property(toast, "modulate:a", 0, 1).finished
	toast.hide()
	toast.modulate.a = 1


func is_higher_version(new_version: String) -> bool:
	var current_components: PackedStringArray = VERSION.replace("v", "").split(".")
	var new_components: PackedStringArray = new_version.replace("v", "").split(".")

	for i in range(3):
		var current_num: String = current_components[i]
		var new_num: String = new_components[i]

		if new_num > current_num:
			return true
		elif new_num < current_num:
			return false

	return false  # Same version if we reach here


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	text = "KEY_ERROR"
