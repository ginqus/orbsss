extends Line2D

@export var lineCount : int = 25
var lineLength : float


func _physics_process(_delta):
	if %StaminaBar.value > 0.1:
		clear_points()

		if Input.is_action_pressed("left_click") and %Player.mouseEnabled:
			global_rotation = 0
			global_scale = Vector2(1, 1)
			global_skew = 0
			lineLength = 0.01 * (%Player.calcVelocity / %Player.maxSpeed)
			var vx = %Player.calcVelocity * %Player.direction.x / 30.85
			var vy = %Player.calcVelocity * %Player.direction.y / 30.85

			for i in range(lineCount):
				var t = i * lineLength
				var nextPos = Vector2(vx * t, vy * t + (t * t))
				add_point(position + nextPos, i)
	else: clear_points()
