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
	return velocity_to_rpm * gear_efficiency / (10 * mass)


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


func longitudal_drag_coefficient(params: Dictionary) -> float:
	const COEFF1 = 3.0 / 2.0
	const COEFF2 = 0.98
	const COEFF3 = 0.36757159
	var performance = params["performance"]
	var max_gear = performance.max_gear()
	var max_velocity = performance.max_velocity()
	var velocity_to_rpm = performance.gear_velocity_to_rpm(max_gear)
	var rpm_for_max_speed = velocity_to_rpm * max_velocity
	var rpm_idx = floor(rpm_for_max_speed / 500.0)
	var torque_curve = performance.torque_curve()
	var torque_for_max_speed = torque_curve[rpm_idx]
	var mass = performance.mass()
	var result = torque_for_max_speed * velocity_to_rpm / (10 * mass)
	result = COEFF1 * result * COEFF2 / (max_velocity ** 3 * COEFF3)
	return result


func drag(params: Dictionary) -> float:
	const DRAG_INIT = 0.2450477
	var basis = params["basis_to_road"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var performance = params["performance"]
	var result = DRAG_INIT * self.longitudal_drag_coefficient(params)
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
		var speed_xz = abs(params["speed_xz"])
		var velocity_factor = speed_xz * SOME_FACTOR + SOME_OFFSET
		velocity_factor = clamp(velocity_factor, LOWER_LIMIT, UPPER_LIMIT)
		var ang_vel = abs(angular_velocity.y)
		result = -velocity_factor * ang_vel * 32 * mass * inertia_inv.y
		if gear == CarTypes.Gear.REVERSE:
			result /= 2
	return -result


func wheel_planar_vector(params: Dictionary, wheel_data: Dictionary) -> Vector3:
	var basis = params["basis_to_road"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var planar_vector = -0.5 * velocity_local * 32
	var angular_velocity_factor = self.angular_velocity_factor(params)
	match wheel_data["type"]:
		CarTypes.Wheel.FRONT_RIGHT, CarTypes.Wheel.FRONT_LEFT:
			planar_vector.x += angular_velocity_factor
		CarTypes.Wheel.REAR_RIGHT, CarTypes.Wheel.REAR_LEFT:
			planar_vector.x -= angular_velocity_factor
	planar_vector.y = 0
	return planar_vector


func vehicle_slip_angle_tg(params: Dictionary) -> float:
	const VELOCITY_LONGITUDAL_THRESHOLD = 0.5
	var basis = params["basis_to_road"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var result = 0
	if VELOCITY_LONGITUDAL_THRESHOLD < abs(velocity_local.z):
		result = velocity_local.x / velocity_local.z
	return result


func vehicle_slip_angle(params: Dictionary) -> float:
	return params["slip_angle"]


func slip_angle_factor(params: Dictionary) -> float:
	const MEDIUM_VELOCITY_THRESHOLD = 13.4
	const HIGH_VELOCITY_THRESHOLD = 26.7
	const MEDIUM_VELOCITY_SLIP_ANGLE_THRESHOLD = 0.15
	const HIGH_VELOCITY_SLIP_ANGLE_THRESHOLD = 0.05
	var steering = params["current_steering"]
	var basis = params["basis_to_road"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var slip_angle = self.vehicle_slip_angle(params)
	var is_same_dir = (slip_angle * steering) >= 0
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


func steering_angle(params: Dictionary) -> float:
	if !params["has_contact_with_ground"]:
		return 0.0
	var result = 0
	var steering = params["current_steering"]
	var basis = params["basis_to_road"]
	var performance = params["performance"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var slip_angle_factor = self.slip_angle_factor(params)
	var steering_acceleration = performance.minimum_steering_acceleration()
	steering *= slip_angle_factor
	if 40.0 < abs(velocity_local.z):
		var velocity_factor = 0.015 * abs(velocity_local.z)
		velocity_factor = clamp(velocity_factor, 1, 1.5)
		steering = steering / velocity_factor
	result = steering_acceleration * 1.5 * 0.00277777777 * steering * 0.0078125
	result = clamp(result, -1.0, 1.0)
	return result


func turning_circle(
	params: Dictionary, local_angular_velocity: Vector3, velocity_local: Vector3
) -> Vector3:
	var performance = params["performance"]
	var steering = params["current_steering"]
	var throttle = params["throttle_input"]
	var brake = params["brake_input"]
	var gear = params["gear"]
	var slip_angle = self.vehicle_slip_angle(params)
	var turning_radius = performance.turning_circle_radius()
	var result = local_angular_velocity
	var radius = performance.turning_circle_radius()
	if throttle < 0.5 or brake < 0.75 or abs(steering) <= 64 or 5 < abs(velocity_local.z):
		if abs(steering) < 4 and gear == CarTypes.Gear.REVERSE:
			result.y *= 0.95
	else:
		result.y = 0
	if abs(velocity_local.z) < abs(velocity_local.x):
		if velocity_local.length() < 2.0:
			var factor = abs(result.y) * TAU * turning_radius * 0.5
			if factor <= abs(velocity_local.z) or factor <= abs(velocity_local.x):
				if 0.2 <= abs(slip_angle):
					factor = 0.95 * result.y
				else:
					factor = 0.90 * result.y
			else:
				var f = abs(velocity_local.z) / factor
				f = min(f, 0.98)
				factor = result.y * f
			result.y = factor
			var velocity_factor = 0.8
			if abs(velocity_local.z) < 5.0:
				velocity_factor = 0.7
	else:
		var factor = abs(result.y) * TAU * turning_radius * 0.5
		if factor <= abs(velocity_local.z) or factor <= abs(velocity_local.x):
			if abs(slip_angle) < 0.2:
				result.y *= 0.95
			else:
				result.y *= 0.99
		else:
			var f = abs(velocity_local.z) / factor
			f = min(f, 0.98)
			factor = result.y * f
			result.y = factor
	return result


func tire_factor(params: Dictionary) -> float:
	var tire_tuning = 1.0
	var weather = params["weather"]
	var result
	if weather == 0:
		result = 28.0 - (tire_tuning - 0.8) * 40
		result = 1 / max(16.0, result)
	elif weather == 1:
		result = 16.0 - (tire_tuning - 0.8) * 32
		result = 3.0 / max(6.0, result)
	elif weather == 2:
		result = 12.0 - (tire_tuning - 0.8) * 24
		result = 3.0 / max(4.0, result)
	return result


func steering_acceleration(
	params: Dictionary, wheel_data: Dictionary, planar_vector: Vector3
) -> float:
	var grip = wheel_data["grip"]
	var angle = atan2(planar_vector.x, abs(planar_vector.z))
	var grip_loss = grip - grip * tire_factor(params)
	var value = 0
	if is_gear_reverse(params):
		value = sin(angle / 2) * grip_loss * 2.0
	else:
		value = sin(angle / 2) * grip_loss * 4.0
	return value


func vector_rotate_y(v: Vector3, angle: float) -> Vector3:
	return v.rotated(Vector3.UP, angle * TAU)


func turned_steering_acceleration(params: Dictionary, wheel_data: Dictionary) -> float:
	var steering
	match wheel_data["type"]:
		CarTypes.Wheel.FRONT_RIGHT, CarTypes.Wheel.FRONT_LEFT:
			steering = steering_angle(params)
		CarTypes.Wheel.REAR_RIGHT, CarTypes.Wheel.REAR_LEFT:
			steering = 0
	var planar_vector = self.wheel_planar_vector(params, wheel_data)
	planar_vector = vector_rotate_y(planar_vector, -steering)
	return steering_acceleration(params, wheel_data, planar_vector)


func wheel_downforce_factor(params: Dictionary, wheel_data: Dictionary) -> float:
	const DOWNFORCE_THRESHOLD_SPEED = 10.0
	var basis = params["basis_to_road"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var performance = params["performance"]
	var downforce = performance.downforce_mult()
	if abs(velocity_local.z) < DOWNFORCE_THRESHOLD_SPEED:
		return downforce + 1.0
	# Missing body damage influence on downforce
	downforce = velocity_local.z * downforce
	var rear_factor = 1.5
	# Missing speed condition
	if !performance.has_spoiler():
		rear_factor *= 1.75
	match wheel_data["type"]:
		CarTypes.Wheel.FRONT_RIGHT, CarTypes.Wheel.FRONT_LEFT:
			downforce += 1.0
		CarTypes.Wheel.REAR_RIGHT, CarTypes.Wheel.REAR_LEFT:
			downforce = downforce * rear_factor + 1.0
	return max(downforce, 0)


func longitudal_acceleration(
	params: Dictionary, wheel_data: Dictionary, wheel_planar_vector: Vector3
) -> float:
	var performance = params["performance"]
	var traction = wheel_data["traction"]
	var throttle = params["throttle_input"]
	var lateral_grip_mult = performance.lateral_grip_multiplier()
	if 0.0 < traction or 0.0 < wheel_planar_vector.z:
		if (
			0.0 < traction
			and 0.0 < wheel_planar_vector.z
			and (throttle < 0.25 or params["gear"] == CarTypes.Gear.REVERSE)
		):
			traction = min(traction, wheel_planar_vector.z)
	elif throttle < 0.25 or not is_gear_reverse(params):
		traction = max(traction, wheel_planar_vector.z)
	traction = traction * lateral_grip_mult
	return traction


func orientation_to_ground(params: Dictionary) -> Vector3:
	var basis_to_road = params["basis_to_road"]
	var basis = params["basis"]
	var normal = basis_to_road.y
	var x = basis.x.dot(normal)
	var y = basis.y.dot(normal)
	var z = basis.z.dot(normal)
	return Vector3(x, y, z)


func wheel_slope_vector(params: Dictionary, vector: Vector3) -> Vector3:
	var slope = orientation_to_ground(params).y
	return vector * slope


func wheel_forces_to_linear_acceleration(params: Dictionary, forces: Array) -> Vector3:
	var sloped = forces.map(func(x): return wheel_slope_vector(params, x))
	var result = 0.5 * sloped.reduce(func(a, x): return a + x)
	return result


func wheel_forces_to_angular_acceleration(params: Dictionary, forces: Array) -> Vector3:
	var mass = params["mass"]
	var inertia_inv = params["inertia_inv"]
	var timestep = params["timestep"]
	var sloped = forces.map(func(x): return wheel_slope_vector(params, x))
	var ang_accel_y = (
		((sloped[0].x + sloped[1].x) - (sloped[2].x + sloped[3].x))
		* 0.5
		* 4
		* mass
		* inertia_inv.y
		* timestep
	)
	return Vector3(0, ang_accel_y, 0)


func weather_factor() -> float:
	const SUNNY = 1.0
	const RAIN = 0.9
	const SNOW = 0.8
	return SUNNY


func wheel_surface_grip_factor(params: Dictionary, wheel_data: Dictionary) -> float:
	const road_factors = [
		1.0,
		1.0,
		0.75,
		0.8,
		0.98,
		0.8,
		0.75,
		0.95,
		0.75,
		0.75,
		0.98,
		0.95,
		0.95,
		0.8,
		1.0,
		0.75,
		0.98,
		0.98,
		0.8,
		0.8,
		0.8,
		0.8,
		0.8,
		0.8
	]
	var road_surface = wheel_data["road_surface"]
	var slope = clamp(self.orientation_to_ground(params).y, 0.75, 1.0)
	var road_factor = road_factors[road_surface]
	var weather_factor = slope * road_factor * self.weather_factor() * 0.25
	return (weather_factor + slope) * road_factor


func wheel_base_road_grip(params: Dictionary, wheel: Dictionary, surface_grip: float) -> float:
	var basis = params["basis_to_road"]
	var performance = params["performance"]
	var gravity = basis.inverse() * params["gravity_vector"]
	var lateral_grip_mult = performance.lateral_grip_multiplier()
	return -gravity.y * lateral_grip_mult * surface_grip


func wheel_bias_grip(params: Dictionary, wheel: Dictionary, grip: float) -> float:
	var performance = params["performance"]
	var front_grip_bias = performance.front_grip_bias()
	var rear_grip_bias = 1 - front_grip_bias
	var result = 0
	match wheel["type"]:
		CarTypes.Wheel.FRONT_RIGHT, CarTypes.Wheel.FRONT_LEFT:
			result = grip * front_grip_bias
		CarTypes.Wheel.REAR_RIGHT, CarTypes.Wheel.REAR_LEFT:
			result = grip * rear_grip_bias
	return result


func wheel_downforce_grip(params: Dictionary, wheel: Dictionary, grip: float) -> float:
	var downforce = self.wheel_downforce_factor(params, wheel)
	return grip * downforce


func model_wheel_grip(params: Dictionary, wheel: Dictionary) -> float:
	var surface_grip = self.wheel_surface_grip_factor(params, wheel)
	var base_grip = self.wheel_base_road_grip(params, wheel, surface_grip)
	var biased_grip = self.wheel_bias_grip(params, wheel, base_grip)
	# Missing g transfer influence
	var downforce_grip = self.wheel_downforce_grip(params, wheel, biased_grip)
	return downforce_grip


func traction(params: Dictionary) -> float:
	var performance = params["performance"]
	var throttle = params["throttle_input"]
	var engine_redline_rpm = performance.engine_redline_rpm()
	var rpm = rpm_from_wheels(params)
	var force = self.traction_powertrain(params, rpm) * throttle
	if rpm >= engine_redline_rpm:
		return 0
	return force


func wheel_traction(params: Dictionary, wheel: Dictionary) -> float:
	var traction = self.traction(params) - self.drag(params)
	var performance = params["performance"]
	var front_drive_ratio = performance.front_drive_ratio()
	var rear_drive_ratio = 1 - front_drive_ratio
	match wheel["type"]:
		CarTypes.Wheel.FRONT_RIGHT, CarTypes.Wheel.FRONT_LEFT:
			traction *= front_drive_ratio
		CarTypes.Wheel.REAR_RIGHT, CarTypes.Wheel.REAR_LEFT:
			traction *= rear_drive_ratio
	var brake = self.brake_force(params, wheel)
	return traction - brake


func calculate_wheel_data(params: Dictionary, wheel: Dictionary) -> Dictionary:
	var grip = self.model_wheel_grip(params, wheel)
	var traction = self.wheel_traction(params, wheel)
	return {
		"type": wheel["type"],
		"grip": grip,
		"traction": traction,
	}


func road_factor(params: Dictionary) -> float:
	const road_factors = [
		1.0,
		1.0,
		0.75,
		0.8,
		0.98,
		0.8,
		0.75,
		0.95,
		0.75,
		0.75,
		0.98,
		0.95,
		0.95,
		0.8,
		1.0,
		0.75,
		0.98,
		0.98,
		0.8,
		0.8,
		0.8,
		0.8,
		0.8,
		0.8
	]
	const weather_factors = [1.0, 0.87, 0.75]
	var road_surface = params["road_surface"]
	var weather = params["weather"]
	return road_factors[road_surface] * weather_factors[weather]


func wheel_loss_of_grip(params: Dictionary, wheel_data: Dictionary, forces: Vector3) -> Vector3:
	var gear = params["gear"]
	var throttle = params["throttle_input"]
	var performance = params["performance"]
	var rpm = params["rpm"]
	var engine_redline_rpm = performance.engine_redline_rpm()
	var force_magnitude = forces.length()
	var lateral_grip = wheel_data["grip"]
	var tire_factor = self.tire_factor(params)
	var grip_loss = lateral_grip - lateral_grip * tire_factor
	var is_front = false
	var result = forces
	if grip_loss < force_magnitude:
		var diff = force_magnitude - grip_loss
		var val = min(diff, grip_loss) * tire_factor
		# Missing other weather conditions
		var factor = (grip_loss - val) / force_magnitude
		if force_magnitude <= (grip_loss - val):
			factor = 1.0
		match wheel_data["type"]:
			CarTypes.Wheel.FRONT_RIGHT, CarTypes.Wheel.FRONT_LEFT:
				is_front = true
		if (
			not is_front
			and gear == CarTypes.Gear.GEAR_1
			and 0.85 < throttle
			and engine_redline_rpm * 0.85 <= rpm
			and 0.95 <= road_factor(params)
		):  # Bug here, road factor effect only, no weather
			result.z = 0.5 * factor * forces.z
			result.x = factor * forces.x
	return result


func wheel_force(params: Dictionary, wheel_data: Dictionary) -> Vector3:
	var basis = params["basis_to_road"]
	var traction = wheel_data["traction"]
	var performance = params["performance"]
	var current_steering = params["current_steering"]
	var throttle = params["throttle_input"]
	var lateral_grip_mult = performance.lateral_grip_multiplier()
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var wheel_planar_vector = self.wheel_planar_vector(params, wheel_data)
	var is_front = false
	var steering
	match wheel_data["type"]:
		CarTypes.Wheel.FRONT_RIGHT, CarTypes.Wheel.FRONT_LEFT:
			steering = self.steering_angle(params)
			is_front = true
		CarTypes.Wheel.REAR_RIGHT, CarTypes.Wheel.REAR_LEFT:
			steering = 0
	wheel_planar_vector = vector_rotate_y(wheel_planar_vector, -steering)
	traction = self.longitudal_acceleration(params, wheel_data, wheel_planar_vector)
	# Missing handbrake
	var value = self.turned_steering_acceleration(params, wheel_data)
	var steering_accel = performance.minimum_steering_acceleration() * 2.0
	steering_accel = min(abs(value), steering_accel)
	if (
		abs(velocity_local.z) < 13.4
		&& ((throttle < 0.02 && 127 <= abs(current_steering)) or throttle < 0.015)
	):
		steering_accel *= 0.25
	var understeer_gradient = performance.understeer_gradient()
	var understeer = sign(wheel_planar_vector.x) * min(steering_accel, abs(wheel_planar_vector.x))
	match wheel_data["type"]:
		CarTypes.Wheel.FRONT_RIGHT, CarTypes.Wheel.FRONT_LEFT:
			# missing handbrake
			understeer = understeer * 0.8 * understeer_gradient
			pass
		CarTypes.Wheel.REAR_RIGHT, CarTypes.Wheel.REAR_LEFT:
			understeer = (understeer * 1.4) / understeer_gradient
			pass
	var f = Vector3(understeer, 0, traction)
	f = wheel_loss_of_grip(params, wheel_data, f)
	var forces = vector_rotate_y(f, -steering)
	return forces


func wheel_longitudal_acceleration(params: Dictionary, acceleration: Vector3) -> Vector3:
	var performance = params["performance"]
	acceleration.z /= performance.lateral_grip_multiplier()
	return acceleration


func process_wheels_cm(params: Dictionary) -> Dictionary:
	var wheels = params["wheels"]
	var basis = params["basis_to_road"]
	var wheel_data = wheels.map(func(x): return self.calculate_wheel_data(params, x))
	var linear_acceleration = Vector3.ZERO
	var angular_acceleration = Vector3.ZERO
	if wheel_data.any(func(x): return 0 < x["grip"]):
		var vectors = wheel_data.map(func(x): return wheel_force(params, x))
		var vectors_sloped = vectors.map(func(x): return wheel_slope_vector(params, x))
		linear_acceleration = wheel_forces_to_linear_acceleration(params, vectors)
		linear_acceleration = wheel_longitudal_acceleration(params, linear_acceleration)
		angular_acceleration = self.wheel_forces_to_angular_acceleration(params, vectors)
	return {
		"linear_acceleration": basis * linear_acceleration,
		"angular_acceleration": basis * angular_acceleration,
	}


func turning_circle_cm(params: Dictionary) -> Dictionary:
	var basis = params["basis_to_road"]
	var angular_velocity = basis.inverse() * params["angular_velocity"]
	var linear_velocity = basis.inverse() * params["linear_velocity"]
	var result = self.turning_circle(params, angular_velocity, linear_velocity)
	result.y = (result.y - angular_velocity.y) * 32
	result.z = 0
	result.x = 0
	return {"angular_acceleration": result}


func airborne_drag_cm(params: Dictionary) -> Dictionary:
	const COEFFICIENTS = Vector3(0.006, 0.004, 0.002)
	var basis = params["basis"]
	var basis_inv = basis.inverse()
	var basis_right = abs(basis_inv.x)
	var basis_forward = abs(basis_inv.z)
	var velocity = params["linear_velocity"]
	var c = Vector3(COEFFICIENTS.dot(basis_right), 0, COEFFICIENTS.dot(basis_forward))
	var downforce = -abs(velocity) * velocity * c
	return {
		"linear_acceleration": downforce,
	}


func neutral_gear_deceleration_cm(params: Dictionary) -> Dictionary:
	var basis = params["basis_to_road"]
	var steering = params["current_steering"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var factor = 0.998
	if abs(velocity_local.z) < 20.0 or 32.0 < abs(steering):
		factor = 0.99
	factor = (factor - 1)
	var linear_acceleration = factor * params["linear_velocity"] * 32
	var angular_acceleration = factor * params["angular_velocity"] * 32
	return {
		"linear_acceleration": linear_acceleration,
		"angular_acceleration": angular_acceleration,
	}


func damp_lateral_velocity_cm(params: Dictionary) -> Dictionary:
	const LOW_VELOCITY_DAMP = 0.9
	const LOW_VELOCITY_THRESHOLD = 1.0
	const MEDIUM_VELOCITY_DAMP = 0.99
	const HIGH_VELOCITY_THRESHOLD = 2.0
	const HIGH_VELOCITY_DAMP = 0.99
	var basis = params["basis_to_road"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var lateral_velocity = abs(velocity_local.x)
	var alpha = (lateral_velocity - 1) * 0.09 + 0.9
	var beta = clamp(alpha, LOW_VELOCITY_DAMP, MEDIUM_VELOCITY_DAMP)
	var d
	if lateral_velocity < LOW_VELOCITY_THRESHOLD:
		d = LOW_VELOCITY_DAMP
	elif lateral_velocity > HIGH_VELOCITY_THRESHOLD:
		d = MEDIUM_VELOCITY_DAMP
	else:
		d = beta
	var accel_x = (d - 1) * velocity_local.x * 32
	return {"linear_acceleration": basis * Vector3(accel_x, 0, 0)}


func process_inputs_cm(params: Dictionary) -> Dictionary:
	var steering = params["current_steering"]
	var performance = params["performance"]
	var turn_in_ramp = performance.turn_in_ramp()
	var turn_out_ramp = performance.turn_out_ramp()
	var turn_input = params["turn_input"]
	var steering_target = -128 * turn_input
	var steering_diff = steering_target - steering
	var delta
	if steering_diff < 0 and steering > 0:
		delta = turn_out_ramp
	elif steering_diff > 0 and steering < 0:
		delta = turn_out_ramp
	else:
		delta = turn_in_ramp
	var result = move_toward(steering, steering_target, delta * 32 * params["timestep"])
	return {"current_steering": result}


func gravity_cm(params: Dictionary) -> Dictionary:
	var gravity = params["gravity_vector"]
	return {"linear_acceleration": gravity}


func near_stop_deceleration(params: Dictionary) -> Dictionary:
	const VELOCITY_THRESHOLD_REVERSE = 4.0
	const VELOCITY_THRESHOLD_FORWARD = 5.0
	const DAMP_FACTOR = 0.8
	var gear = params["gear"]
	var basis = params["basis_to_road"]
	var linear_velocity = params["linear_velocity"]
	var angular_velocity = params["angular_velocity"]
	var linear_acceleration = Vector3.ZERO
	var angular_acceleration = Vector3.ZERO
	var threshold = VELOCITY_THRESHOLD_FORWARD
	if gear == CarTypes.Gear.REVERSE:
		threshold = VELOCITY_THRESHOLD_REVERSE
	var velocity_local = basis.inverse() * linear_velocity
	if abs(velocity_local.z) < threshold:
		var damp = DAMP_FACTOR - 1
		linear_acceleration = damp * linear_velocity * 32
		angular_acceleration = damp * angular_velocity * 32
	return {
		"linear_acceleration": linear_acceleration,
		"angular_acceleration": angular_acceleration,
	}


var should_come_to_stop = predicate_all(
	[
		throttle_in_range_uint8(0, 32),
		brake_in_range_uint8(0, 32),
		neg(is_gear_neutral),
	]
)

var near_stop_deceleration_cm = enable_if(
	should_come_to_stop, integrate(self.near_stop_deceleration)
)


func brake_force(params: Dictionary, wheel_data: Dictionary) -> float:
	var performance = params["performance"]
	var brake_input = params["brake_input"]
	var brake_deceleration = brake_input * performance.maximum_braking_deceleration()
	var wheel_type = wheel_data["type"]
	var front_brake_ratio = performance.front_brake_bias()
	var basis = params["basis_to_road"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var brake_maximum = abs(32 * velocity_local.z)
	var has_spoiler = performance.has_spoiler()
	var downforce_mult = performance.downforce_mult()
	brake_deceleration = min(brake_maximum, brake_deceleration)
	if 0.15 < brake_input and has_spoiler:
		brake_deceleration += abs(velocity_local.z) * downforce_mult
	if params["handbrake"]:
		front_brake_ratio += 0.05
	var rear_brake_ratio = 1 - front_brake_ratio
	match wheel_type:
		CarTypes.Wheel.FRONT_RIGHT, CarTypes.Wheel.FRONT_LEFT:
			brake_deceleration *= front_brake_ratio
		CarTypes.Wheel.REAR_RIGHT, CarTypes.Wheel.REAR_LEFT:
			brake_deceleration *= rear_brake_ratio
	return sign(velocity_local.z) * brake_deceleration


func limit_angular_velocity_cm(params: Dictionary) -> Dictionary:
	const ANGULAR_VELOCITY_LIMIT = 2.4 / TAU
	var limit = ANGULAR_VELOCITY_LIMIT * Vector3.ONE
	var angular_velocity = params["angular_velocity"].clamp(-limit, limit)
	return {"angular_velocity": angular_velocity}


func downforce_cm(params: Dictionary) -> Dictionary:
	var basis = params["basis"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var downforce_mult = params["performance"].downforce_mult()
	var downforce_accel = -downforce_mult * velocity_local.z * 32
	var result = Vector3(0, downforce_accel, 0)
	return {"linear_acceleration": basis * result}


func adjust_to_road_cm(params: Dictionary) -> Dictionary:
	#const LIMIT = 0.97222
	const LIMIT = 0.6
	var basis_current = params["basis_to_road"]
	var basis_next = params["basis_to_road_next"]
	var interpolated = basis_current.slerp(basis_next, 0.5)
	var basis_inv = params["basis"].inverse()
	var normal = interpolated.y
	var angular_velocity = params["angular_velocity"]
	var orientation = self.orientation_to_ground(params)
	var signs = normal.sign()
	var vec1 = signs * basis_inv.x - normal.x * Vector3.ONE
	var vec2 = normal.z * Vector3.ONE - signs * basis_inv.z
	var idx = 0
	var should_adjust = false
	var absv = abs(orientation)
	if LIMIT < absv.x or LIMIT < absv.y or LIMIT < absv.z:
		if LIMIT < abs(orientation.y):
			idx = 1
		elif LIMIT < abs(orientation.x):
			idx = 0
		elif LIMIT < abs(orientation.z):
			idx = 2
		if 0.02 < abs(vec1[idx]) or 0.02 < abs(vec2[idx]):
			should_adjust = true
		if should_adjust:
			var v1 = clamp(vec1[idx], -0.5, 0.5)
			var v2 = clamp(vec2[idx], -0.5, 0.5)
			angular_velocity.z = v1
			angular_velocity.x = v2
		else:
			angular_velocity.z = 0.0
			angular_velocity.x = 0.0
	return {
		"angular_velocity": angular_velocity,
	}


func prevent_sinking_cm(params: Dictionary) -> Dictionary:
	var basis_current = params["basis_to_road"]
	var basis_next = params["basis_to_road_next"]
	var interpolated = basis_current.slerp(basis_next, 0.5)
	var distance_above_ground = params["distance_above_ground"]
	var velocity_local = interpolated.inverse() * params["linear_velocity"]
	var normal = interpolated.y
	if distance_above_ground < 0.8:
		if velocity_local.y < 0.0:
			velocity_local.y = 0
	return {
		"linear_velocity": interpolated * velocity_local,
	}


func rpm_from_wheels(params: Dictionary) -> float:
	var performance = params["performance"]
	var gear = params["gear"]
	var throttle = params["throttle_input"]
	var basis = params["basis"]
	var velocity_local = basis.inverse() * params["linear_velocity"]
	var velocity_to_rpm = performance.gear_velocity_to_rpm(gear)
	var rpm = abs(velocity_local.z) * velocity_to_rpm
	var engine_redline_rpm = performance.engine_redline_rpm()
	var engine_min_rpm = performance.engine_min_rpm()
	rpm = clamp(rpm, engine_min_rpm, engine_redline_rpm)
	var engine_target_rpm = engine_redline_rpm * throttle
	rpm = clamp(engine_target_rpm, engine_min_rpm, rpm)
	return rpm


func rpmdummy(params: Dictionary) -> Dictionary:
	return {"rpm": rpm_from_wheels(params)}


# Predicates

func predicate_all(func_array: Array) -> Callable:
	return func(params: Dictionary) -> bool:
		return func_array.all(func(x): return x.call(params))


func predicate_any(func_array: Array) -> Callable:
	return func(params: Dictionary) -> bool:
		return func_array.any(func(x): return x.call(params))


func is_gear_neutral(params: Dictionary) -> bool:
	return params["gear"] == CarTypes.Gear.NEUTRAL


func is_gear_reverse(params: Dictionary) -> bool:
	return params["gear"] == CarTypes.Gear.REVERSE


func is_airborne(params: Dictionary) -> bool:
	return params["has_contact_with_ground"] == false


func throttle_in_range(lower: float, upper: float) -> Callable:
	return func(params: Dictionary) -> bool:
		var throttle = params["throttle_input"]
		return lower <= throttle and throttle <= upper


func brake_in_range(lower: float, upper: float) -> Callable:
	return func(params: Dictionary) -> bool:
		var throttle = params["brake_input"]
		return lower <= throttle and throttle <= upper


func throttle_in_range_uint8(lower: int, upper: int) -> Callable:
	return throttle_in_range(lower / 255, upper / 255)


func brake_in_range_uint8(lower: int, upper: int) -> Callable:
	return brake_in_range(lower / 255, upper / 255)


func process(params: Dictionary) -> Dictionary:
	var basis = Basis.from_euler(Vector3(0, PI, 0))
	params["basis"] = params["basis"] * basis
	params["basis_to_road"] = params["basis_to_road"] * basis
	params["slip_angle"] = self.vehicle_slip_angle_tg(params)
	params["speed_xz"] = self.calculate_speed_xz(params)
	var angular_velocity = params["angular_velocity"] / TAU
	params["angular_velocity"] = angular_velocity
	var traction_pipeline = make_model_pipeline(
		[
			rpmdummy,
			enable_if(should_come_to_stop, integrate(self.near_stop_deceleration_cm)),
			integrate(self.process_wheels_cm),
			integrate(turning_circle_cm),
			integrate(self.damp_lateral_velocity_cm),
			enable_if(is_gear_neutral, integrate(self.neutral_gear_deceleration_cm)),
		]
	)
	var airborne_processing = make_model_pipeline(
		[
			enable_if(is_airborne, integrate(airborne_drag_cm)),
			enable_if(neg(is_airborne), integrate(self.gravity_cm)),
			enable_if(neg(is_airborne), prevent_sinking_cm),
			enable_if(neg(is_airborne), adjust_to_road_cm),
		]
	)
	var model = make_model_pipeline(
		[
			process_inputs_cm,
			enable_if(neg(is_airborne), traction_pipeline),
			airborne_processing,
			integrate(self.downforce_cm),
			enable_if(is_airborne, limit_angular_velocity_cm),
			enable_if(is_airborne, integrate(self.gravity_cm)),
		]
	)
	var result = model.call(params)
	angular_velocity = result["angular_velocity"] * TAU
	result["angular_velocity"] = angular_velocity
	return result
