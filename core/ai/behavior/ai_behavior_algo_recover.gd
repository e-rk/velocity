extends State
class_name BehaviorAlgoRecover

@export_range(0, 10, 1, "or_greater") var recovery_attempts: int = 3
@export_range(0.0, 5.0, 0.1, "or_greater") var recovery_distance: float = 2.0

var stuck_counter := 0.0
var attempts := 0
var reversing := false


func enter():
	context.steering_controller.set_state(context.steering_controller.reverse)
	reversing = true
	stuck_counter = 0.0
	attempts = 0


func is_on_path(player: Player):
	var threshold := recovery_distance ** 2
	var position = player.car.global_position
	var path_point = context.steering_controller.waypoints.advance_by_distance_smooth(player.current_node_idx, position, 0.0)
	return position.distance_squared_to(path_point) <= threshold


func decide(player: Player, delta: float):
	if player.car.linear_velocity.length() < 1.5:
		stuck_counter += delta
	if stuck_counter >= 2.5:
		if reversing:
			context.steering_controller.set_state(context.steering_controller.follow_path)
			reversing = false
		else:
			context.steering_controller.set_state(context.steering_controller.reverse)
			reversing = true
		attempts += 1
		stuck_counter = 0.0
	if attempts >= recovery_attempts:
		context.reposition(player)
		return
	if is_on_path(player):
		context.set_state(context.state_racing)
