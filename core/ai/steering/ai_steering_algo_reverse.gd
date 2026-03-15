extends State
class_name SteeringAlgoReverse


func compute(input: SteeringAlgo.AIInput) -> SteeringAlgo.AIOutput:
	var out := SteeringAlgo.AIOutput.new()

	var ideal_target := context.waypoints.advance_by_distance_smooth(input.car_idx, input.car_transform.origin, -5.0) as Vector3
	var local_target := input.car_transform.inverse() * ideal_target
	local_target.y = 0.0
	var angle: float  = context._get_angle_error(local_target, true)
	var pid_result: Array[float] = context.calculate_steering_input(
			angle, input.delta, input.pid_prev_error, input.pid_integral)
	var dot_forward  := input.car_transform.basis.tdotz(input.car_velocity)

	out.pid_prev_error = pid_result[1]
	out.pid_integral   = pid_result[2]
	out.steering       = signf(dot_forward) * pid_result[0]
	out.throttle         = 1.0
	out.brake            = 0.0
	out.gear             = CarTypes.Gear.REVERSE

	return out
