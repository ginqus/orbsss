extends Button


@onready var upgrade_power_bar: ProgressBar = $UpgradePower

var popup_dialog: PackedScene = preload("res://Instances/popup.tscn")

var upgrades_layer: CanvasLayer
var max_upgrade_power: int = 0
var upgrade_power: int = 0
var og_name: String
var upgrade_name: String
var price: int = 0


func _ready() -> void:
	call_deferred("_load_name")
	call_deferred("_load_data")


#func _process(delta: float) -> void:
	#if og_name == "KEY_SPEED":
		#print(int(SaveSystem.get_var(upgrade_name, 0)))
		#print("Upgrades: ", SaveSystem.current_state_dictionary)


func _load_name() -> void:
	match og_name:
		"KEY_SPEED":
			upgrade_name = "speed_upgrade"
		"KEY_TRAJECTORY":
			upgrade_name = "trajectory_length_upgrade"
		"KEY_STAMINA":
			upgrade_name = "max_stamina_upgrade"
		"KEY_INVINC_TIME":
			upgrade_name = "invinc_time_upgrade"
		"KEY_SLOWMODE":
			upgrade_name = "slowmode_power_upgrade"


func _load_data() -> void:
	print(upgrade_name)
	print(upgrade_power)
	upgrade_power = int(SaveSystem.get_var(upgrade_name, 0))
	upgrade_power_bar.value = upgrade_power
	if upgrade_power >= max_upgrade_power:
		disabled = true
		modulate.a = 0.5


func set_icon(filename: String) -> void:
	$Icon.texture = load("res://Themes/frozen_dark/gui/upgrades/" + filename)


func set_title(title: String) -> void:
	og_name = title
	$Name.text = tr(title)
	_set_description(title + "_DESC")


func _set_description(description: String) -> void:
	$Description.text = tr(description)


func set_price(amount: int) -> void:
	$Coin/Price.text = str(amount)
	price = amount


func set_max_upgrades(num: int) -> void:
	$UpgradePower.max_value = num
	max_upgrade_power = num


func upgrade() -> void:
	if upgrades_layer.coins >= price:
		if not upgrade_power >= max_upgrade_power:
			upgrades_layer.decrease_coins(price)
			SaveSystem.set_var(upgrade_name, upgrade_power + 1)
			SaveSystem.save()
			_set_upgrade_power(upgrade_power + 1)


func _set_upgrade_power(power: int) -> void:
	upgrade_power = power
	var tween := create_tween().set_trans(Tween.TRANS_CIRC)
	tween.tween_property(upgrade_power_bar, "value", upgrade_power, 0.33)
	if upgrade_power >= max_upgrade_power:
		disabled = true
		tween.parallel().tween_property(self, "modulate:a", 0.5, 0.33)


func _on_pressed() -> void:
	if upgrades_layer.coins >= price:
		var popup: CanvasLayer = popup_dialog.instantiate()
		var buttons: Array = [
			[tr("KEY_NO")],
			[tr("KEY_YES"), func _on_yes_pressed() -> void:
				upgrade()
				popup.close(), "green"],
		]
		get_tree().root.add_child(popup)
		popup.add_buttons(buttons)
		popup.set_title(tr("KEY_CONFIRM_UPGRADE"))
