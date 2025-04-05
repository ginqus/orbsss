extends CanvasLayer


@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var container: VBoxContainer = $SmoothScrollContainer/VBoxContainer
@onready var coin_label: Label = $Coin/CoinLabel

var upgrade_button: PackedScene = preload("res://Instances/upgrade.tscn")
var coins: int = 0


func _ready() -> void:
	await RenderingServer.frame_post_draw

	GlobalVariables.popup_order.append(get_path())

	var screenshot: Image = get_viewport().get_texture().get_image()
	var blurred: Image = GlobalVariables.blur_image(screenshot)

	$Blur.texture = ImageTexture.create_from_image(blurred)

	animation.play("open")

	_load_upgrades()
	coins = int(SaveSystem.get_var("coins", 0))
	coin_label.text = str(coins)


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


func decrease_coins(amount: int) -> void:
	set_coins(coins - amount)


func increase_coins(amount: int) -> void:
	set_coins(coins + amount)


func set_coins(amount: int) -> void:
	coins = amount
	coin_label.text = str(coins)
	SaveSystem.set_var("coins", amount)


var upgrades: Array = [
	{"name": "KEY_SPEED", "icon": "speed.svg", "price": 40, "max_upgrades": 8},
	{"name": "KEY_TRAJECTORY", "icon": "trajectory.svg", "price": 50, "max_upgrades": 5},
	{"name": "KEY_STAMINA", "icon": "stamina.svg", "price": 70, "max_upgrades": 5},
	{"name": "KEY_INVINC_TIME", "icon": "invinc_time.svg", "price": 50, "max_upgrades": 4},
	{"name": "KEY_SLOWMODE", "icon": "slowmode.svg", "price": 60, "max_upgrades": 3},
]
func _load_upgrades() -> void:
	for upgrade: Dictionary in upgrades:
		var upgrade_btn: Button = upgrade_button.instantiate()
		container.add_child(upgrade_btn)
		upgrade_btn.set_title(upgrade["name"])
		upgrade_btn.set_icon(upgrade["icon"])
		upgrade_btn.set_price(upgrade["price"])
		upgrade_btn.set_max_upgrades(upgrade["max_upgrades"])
		upgrade_btn.upgrades_layer = self
