extends Resource
class_name CarPerformance

@export var data: Dictionary


func mass() -> float:
	return data["mass"]


func torque_curve() -> Array:
	return data["torque_curve"]


func gear_efficiency(gear) -> float:
	return data["manual_gear_efficiency"][gear]


func gear_velocity_to_rpm(gear) -> float:
	return data["manual_velocity_to_rpm_ratio"][gear]


func max_gear() -> CarTypes.Gear:
	return data["manual_number_of_gears"] - 1


func front_drive_ratio() -> float:
	return data["front_drive_ratio"]


func engine_redline_rpm() -> int:
	return data["engine_redline_rpm"]


func engine_min_rpm() -> int:
	return data["engine_minimum_rpm"]


func downforce_mult() -> float:
	return data["aerodynamic_downforce_multiplier"]


func max_velocity() -> float:
	return data["maximum_velocity"]


func has_spoiler() -> bool:
	return data["spoiler_function_type"]


func turn_in_ramp() -> float:
	return data["turn_in_ramp"]


func turn_out_ramp() -> float:
	return data["turn_out_ramp"]


func minimum_steering_acceleration() -> float:
	return data["minimum_steering_acceleration"]


func maximum_braking_deceleration() -> float:
	return data["maximum_braking_deceleration"]


func front_brake_bias() -> float:
	return data["front_bias_brake_ratio"]


func lateral_grip_multiplier() -> float:
	return data["lateral_acceleration_grip_multiplier"]


func front_grip_bias() -> float:
	return data["front_grip_bias"]


func has_abs() -> bool:
	return data["has_abs"]


func understeer_gradient() -> float:
	return data["understeer_gradient"]


func turning_circle_radius() -> float:
	return data["turning_circle_radius"]


func gas_off_factor() -> float:
	return data["gas_off_factor"]


func shift_blip_in_rpm(gear: CarTypes.Gear) -> int:
	return data["shift_blip_in_rpm"][gear]


func brake_blip_in_rpm(gear: CarTypes.Gear) -> int:
	return data["brake_blip_in_rpm"][gear]


func gear_shift_delay() -> int:
	return data["gear_shift_delay"]


func g_transfer_factor() -> float:
	return data["g_transfer_factor"]


func brake_decreasing_curve(idx: int) -> int:
	return data["brake_decreasing_curve"][idx]


func brake_increasing_curve(idx: int) -> int:
	return data["brake_increasing_curve"][idx]
