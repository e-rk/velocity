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
