extends Label

var config = ConfigFile.new()
@export var FPSLabel = Node

func _ready():
	var err = config.load("user://ballin-settings.cfg")
	if err == OK:
		if config.get_value("Settings", "ShowFPS", false): _show()
		else: _hide()

func _show():
	FPSLabel.show()
	show()
func _hide():
	FPSLabel.hide()
	hide()

var fps = 0
func _process(_delta):
	set_text(str(Engine.get_frames_per_second()))
