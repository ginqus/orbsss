extends Node


const SAVE_LOCATION := "user://orbsss.save"

@onready var plr = %Player
@onready var save_indicator := $"../UI/Save indicator"


var tween
func Save() -> void:
	var save_file = FileAccess.open(SAVE_LOCATION, FileAccess.WRITE)

	if plr.actual_score > plr.best_score:
		plr.best_score = plr.actual_score
	plr.coins_total = plr.coins_pre_round + plr.coins_this_round

	save_file.store_32(plr.best_score)
	save_file.store_32(plr.coins_total)
	save_file.close()

	save_indicator.show()
	save_indicator.modulate.a = 1
	if tween: tween.kill()
	await get_tree().create_timer(2).timeout
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(save_indicator, "modulate:a", 0, 1)

func Load() -> void:
	if not FileAccess.file_exists(SAVE_LOCATION):
		printerr("Файла сохранения не существует!")
		return
	else:
		var save_file = FileAccess.open(SAVE_LOCATION, FileAccess.READ)

		plr.best_score = save_file.get_32()
		plr.coins_pre_round = save_file.get_32()

		save_file.close()
