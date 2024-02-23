extends HandlingModel
class_name HandlingModelRE

func torque_for_rpm(params: Dictionary, rpm: float) -> float:
	var performance = params["performance"]
	var torque_curve = performance.torque_curve()
	var torque_div = rpm / 500
	var torque_idx = floor(torque_div)
	torque_idx = clampi(torque_idx, 0, 19)
	var torque_next = torque_idx + 1
	var torque_1 = torque_curve[torque_idx]
	var torque_2 = torque_curve[torque_next]
	var factor = torque_div - torque_idx
	return lerp(torque_1, torque_2, factor)

func gear_effective_ratio(params: Dictionary, gear: CarTypes.Gear) -> float:
	var performance = params["performance"]
	var velocity_to_rpm = performance.gear_velocity_to_rpm(gear)
	var gear_efficiency = performance.gear_efficiency(gear)
	var mass = performance.mass()
	return velocity_to_rpm  * gear_efficiency / (10 * mass)

func traction_powertrain(params: Dictionary, rpm: float) -> float:
	var gear = params["gear"]
	var torque = torque_for_rpm(params, rpm)
	var gear_ratio = self.gear_effective_ratio(params, gear)
	var torque_output = torque * gear_ratio
	if gear == CarTypes.Gear.GEAR_1:
		torque_output = min(torque_output, 10)
	elif gear == CarTypes.Gear.REVERSE:
		torque_output = max(torque_output, -6)
	else:
		torque_output = min(torque_output, 8)
	return torque_output

func drag_coefficient(params: Dictionary) -> float:
	const COEFF1 = 3.0 / 2.0
	const COEFF2 = 0.98
	const COEFF3 = 0.36757159
	var performance = params["performance"]
	var max_gear = performance.max_gear()
	var max_velocity = performance.max_velocity()
	var velocity_to_rpm = performance.gear_velocity_to_rpm(max_gear)
	var rpm_for_max_speed = velocity_to_rpm * max_velocity
	var torque_for_max_speed = self.torque_for_rpm(params, rpm_for_max_speed)
	var mass = performance.mass()
	var result = torque_for_max_speed * velocity_to_rpm / (10 * mass)
	result = COEFF1 * result * COEFF2 / (max_velocity**3 * COEFF3)
	return result

func drag(params: Dictionary) -> float:
	const DRAG_INIT = 0.2450477
	var basis = params["basis_to_road"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var performance = params["performance"]
	var result = DRAG_INIT * self.drag_coefficient(params)
	var velocity_max_diff = abs(velocity_local.z) - performance.max_velocity()
	result = result * velocity_local.z ** 3
	if velocity_max_diff > 0:
		result += (velocity_max_diff ** 2) * 0.01
	return result

func calculate_speed_xz(params: Dictionary) -> float:
	var basis = params["basis_to_road"]
	var velocity_xz = basis.inverse() * params["linear_velocity"]
	velocity_xz.y = 0
	var speed_xz = velocity_xz.length()
	return speed_xz if velocity_xz.z > 0 else -speed_xz

func angular_velocity_factor(params: Dictionary) -> float:
	const SOME_FACTOR = 0.0125
	const SOME_OFFSET = -0.25
	const UPPER_LIMIT = 1
	const LOWER_LIMIT = 0.1
	var result = 0
	if params["has_contact_with_ground"]:
		var angular_velocity = params["angular_velocity"]
		var inertia_inv = params["inertia_inv"]
		var mass = params["mass"]
		var gear = params["gear"]
		var speed_xz = calculate_speed_xz(params)
		var velocity_factor = speed_xz * SOME_FACTOR + SOME_OFFSET
		velocity_factor = clamp(velocity_factor, LOWER_LIMIT, UPPER_LIMIT)
		var ang_vel = abs(angular_velocity.y)
		result = -velocity_factor * ang_vel * 32 * mass * inertia_inv.y
		if gear == CarTypes.Gear.REVERSE:
			result /= 2
	return -result

func vehicle_slip_angle_tg(params: Dictionary) -> float:
	const VELOCITY_LONGITUDAL_THRESHOLD = 0.5
	var basis = params["basis_to_road"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var result = 0
	if VELOCITY_LONGITUDAL_THRESHOLD < abs(velocity_local.z):
		result = velocity_local.x / velocity_local.z
	return result

func vehicle_slip_angle(params: Dictionary) -> float:
	return vehicle_slip_angle_tg(params)

func slip_angle_factor(params: Dictionary) -> float:
	const MEDIUM_VELOCITY_THRESHOLD = 13.4
	const HIGH_VELOCITY_THRESHOLD = 26.7
	const MEDIUM_VELOCITY_SLIP_ANGLE_THRESHOLD = 0.15
	const HIGH_VELOCITY_SLIP_ANGLE_THRESHOLD = 0.05
	var steering = params["current_steering"]
	var basis = params["basis_to_road"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var slip_angle = self.vehicle_slip_angle(params)
	var is_same_dir = (slip_angle * steering) > 0
	var result := 1.0
	if params["handbrake"] == false and is_same_dir:
		if HIGH_VELOCITY_THRESHOLD < velocity_local.z:
			if HIGH_VELOCITY_SLIP_ANGLE_THRESHOLD < abs(slip_angle):
				result = 2 * abs(slip_angle)
		elif MEDIUM_VELOCITY_THRESHOLD < velocity_local.z:
			if MEDIUM_VELOCITY_SLIP_ANGLE_THRESHOLD < abs(slip_angle):
				result = 2 * abs(slip_angle)
		result = min(1.0, result)
	elif params["handbrake"] == true and !is_same_dir:
		result = 0.85 - abs(velocity_local.z) * 0.0056
		result = max(result, 0.55)
	return result

func steering_angle_factor(params: Dictionary) -> float:
	if !params["has_contact_with_ground"]:
		return 0.0
	var result = 0
	var steering = params["current_steering"]
	var basis = params["basis_to_road"]
	var performance = params["performance"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var slip_angle_factor = self.slip_angle_factor(params)
	steering *= slip_angle_factor
	if 40.0 < abs(velocity_local.z):
		var something = 0.015 * abs(velocity_local.z)
		something = clamp(something, 1, 1.5)
		steering = steering / something
	result = performance.minimum_steering_acceleration() * 1.5 * 0.00277777777 * steering * 0.0078125
	result = clamp(result, -1.0, 1.0)
	return result
