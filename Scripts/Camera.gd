extends Camera2D


var restartingScene : bool = false
var lastFramePosY : float = INF
var tween : Tween


@onready var timer = Timer.new()
func _ready():
	add_child(timer)

func _process(_delta):
	if has_node("%Player"):
		if %Player.position.y < position.y:
			tween = create_tween()
			tween.tween_property(self, "position:y", %Player.position.y, 0.1).set_trans(Tween.TRANS_SINE)
	elif !restartingScene:
		restartingScene = true
	else:
		await get_tree().create_timer(1, false, false, true).timeout
		get_tree().reload_current_scene()

# Сделать так, чтобы камера двигалась только вверх
	position.x = 0
	if lastFramePosY < position.y:
		position.y = lastFramePosY
	lastFramePosY = position.y

# Осуществить тряску экрана по таймеру, каждый цикл таймера - новый оффсет камеры
func shake(cycles: float, power: float, interval: float):
	interval *= get_physics_process_delta_time() / Engine.time_scale
	for cycle in range(cycles):
		var calc_offset: Vector2
		if cycle + 1 == cycles: calc_offset = Vector2.ZERO
		else:
			var intencity: float = (cycles / (cycle + 1))
			var rand_offset: Vector2 = Vector2.ZERO
			rand_offset.x = randf()
			rand_offset.y = 1 - rand_offset.x
			if cycle % 2 == 0: rand_offset *= -1
			calc_offset = Vector2(rand_offset.x * power * intencity, rand_offset.y * power * intencity)
		tween = create_tween()
		await tween.tween_property(self, "offset", calc_offset, interval).finished
