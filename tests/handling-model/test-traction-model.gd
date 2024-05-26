extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.001


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["rpm"] = self.rpm(data)
	result["gear"] = self.gear(data)
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["handbrake"] = self.handbrake(data)
	result["throttle_input"] = self.throttle(data)
	result["weather"] = self.weather(data)
	result["slip_angle"] = self.slip_angle(data)
	result["brake_input"] = self.brake_input(data)
	result["unknown_value"] = data["unknown_engine_value"] != "0"
	result["unknown_value2"] = data["unknown_engine_value2"] != "0"
	result["gear_shift_counter"] = int(data["some_gear_shift_value"])
	result["has_contact_with_ground"] = not self.is_airborne(data)
	result["handbrake_accumulator"] = self.handbrake_accumulator(data)
	result["speed_xz"] = self.speed_xz(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_rpm = int(data["result_rpm"])
	var expected_gear = int(data["result_gear"])
	var expected_has_grip = data["result_handbrake"] == "0"
	var expected_force = float(data["result_force"])
	if is_equal_approx(-4.1633582, expected_force):
		pass
	var result = self.model.traction_model(params)
	var msg = "rpm=" + str(params["rpm"]) \
			+ " gear=" + str(params["gear"]) \
			+ " thr=" + str(params["throttle_input"]) \
			+ " brk=" + str(params["brake_input"]) \
			+ " air=" + str(not params["has_contact_with_ground"]) \
			+ " v.z=" + str(params["linear_velocity"].z) \
			+ " unk=" + str(params["unknown_value"]) \
			+ " unk2=" + str(params["unknown_value2"])
	#assert_almost_eq(result["force"], expected_force, EPSILON, "force: " + msg)
	assert_eq(result["has_grip"], expected_has_grip, "has_grip: " + msg)
	# Rounding error somewhere
	assert_eq(result["rpm"], expected_rpm, "rpm: " + msg)

