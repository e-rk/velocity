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
