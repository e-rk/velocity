extends State
class_name BehaviorAlgoRacing

@export_range(0.0, 10.0, 0.1, "or_greater") var STUCK_TIMEOUT  := 4.0
@export_range(0.0, 10.0, 0.1, "or_greater") var MIN_SPEED      := 5.5

var stuck_timer := 0.0


func enter():
	stuck_timer = 0.0
	context.steering_controller.set_state(context.steering_controller.follow_path)


func decide(player: Player, delta: float):
	if player.car.linear_velocity.length() < MIN_SPEED:
		stuck_timer += delta
		if stuck_timer >= STUCK_TIMEOUT:
			context.set_state(context.state_recover)
	else:
		stuck_timer = 0.0
