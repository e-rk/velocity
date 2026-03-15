extends State
class_name SteeringAlgoFollowPath

const SPEED_RAMP_ACCEL      := 15.0
const SPEED_RAMP_BRAKE      := 20.0
const CORNER_SPEED_MARGIN   := 1.0

@export_range(0.0, 5.0, 0.01, "or_greater") var lookahead_scale: float = 0.5

func compute(input: SteeringAlgo.AIInput) -> SteeringAlgo.AIOutput:
	var out := SteeringAlgo.AIOutput.new()

	var speed = input.car_velocity.length()

	var lookahead_distance := clampf(speed * lookahead_scale, 10.0, 40.0)
	var lookahead = context.waypoints.advance_by_distance(input.car_idx, lookahead_distance)

	var ideal_target: Vector3 = context.waypoints.advance_by_distance_smooth(input.car_idx, input.car_transform.origin, lookahead_distance)

	context.optimize_mtx.lock()
	var steer_target := input.nav_waypoints.offset_vector_at_idx(lookahead, context.offsets, ideal_target)
	var ideal_tangent: Vector3 = context.waypoints.tangent_vector_at_offset(lookahead, context.offsets)
	var cte := context.waypoints.calculate_lateral_offset_from_shifted(input.car_idx, context.offsets, input.car_transform.origin) as float
	context.optimize_mtx.unlock()

	var local_target := input.car_transform.inverse() * steer_target
	local_target.y = 0.0
	var dot_forward  := input.car_transform.basis.tdotz(input.car_velocity)
	var angle: float = context._get_angle_error(local_target, false)

	var local_tangent := input.car_transform.basis.inverse() * ideal_tangent
	local_tangent.y = 0.0
	var heading_error := context._get_angle_error(local_tangent, false) as float

	var cte_angle := atan2(-cte, lookahead_distance)
	const HEADING_ERROR_WEIGHT = 0.5
	const CROSS_TRACK_ERROR_WEIGHT = 0.25
	var heading_weight := clampf(speed / 50.0, 0.0, 1.0) * HEADING_ERROR_WEIGHT
	var position_weight := 1.0 - heading_weight - CROSS_TRACK_ERROR_WEIGHT
	var error := position_weight * angle \
				+ heading_weight * heading_error \
				+ CROSS_TRACK_ERROR_WEIGHT * cte_angle

	var pid_result: Array[float] = context.calculate_steering_input(
			error, input.delta, input.pid_prev_error, input.pid_integral)
	var target_steering: float = pid_result[0]

	var local_linear_velocity = input.car_transform.basis.inverse() * input.car_velocity

	out.pid_prev_error = pid_result[1]
	out.pid_integral   = pid_result[2]
	out.steering = signf(dot_forward) * target_steering
	var speed_limit: float = context.get_lookahead_speed_limit(
			input.car_performance, input.car_handling_model,
			input.car_velocity.length(), input.car_idx, input.car_g_transfer, local_linear_velocity)

	var target_speed  := speed_limit * CORNER_SPEED_MARGIN
	var max_spd: float = input.car_performance.max_velocity()
	if target_speed  == INF: target_speed = max_spd
	target_speed       = minf(target_speed, max_spd)
	var current_speed := input.car_velocity.length()
	var speed_error   := target_speed - current_speed

	if speed_error >= 0.0:
		out.throttle = clamp(speed_error / SPEED_RAMP_ACCEL, 0.0, 1.0)
		out.brake    = 0.0
	else:
		out.throttle = 0.0
		out.brake    = clamp(-speed_error / SPEED_RAMP_BRAKE, 0.0, 1.0)

	out.gear = context.best_gear_for_torque(
			input.car_performance, input.car_handling_model,
			input.car_gear, current_speed)

	return out
