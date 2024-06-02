extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.001


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_force.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["rpm"] = self.rpm(data)
	result["gear"] = self.gear(data)
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["lost_grip"] = self.handbrake(data)
	result["throttle"] = self.throttle(data)
	result["weather"] = self.weather(data)
	result["slip_angle"] = self.slip_angle(data)
	result["gear_shift_counter"] = int(data["some_gear_shift_value"])
	result["has_contact_with_ground"] = not self.is_airborne(data)
	result["handbrake_accumulator"] = self.handbrake_accumulator(data)
	result["speed_xz"] = self.speed_xz(data)
	result["target_rpm"] = int(data["target_rpm"])
	result["rpm_above_redline"] = data["rpm_above_redline"] != "0"
	result["drag"] = float(data["drag"])
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_rpm = int(data["result_rpm"])
	var expected_force = float(data["result_force"])
	var expected_handbrake_accumulator = int(data["result_handbrake_accumulator"])
	var expected_lost_grip = data["result_handbrake"] != "0"
	if expected_handbrake_accumulator == 70:
		pass
	var result = self.model.traction_model_force(params)
	var msg = "rpm=" + str(params["rpm"]) \
			+ " thr=" + str(params["throttle"])
	assert_eq(result["rpm"], expected_rpm, "rpm: " + msg)
	assert_almost_eq(result["force"], expected_force, EPSILON, "force: " + msg)
	assert_eq(result["handbrake_accumulator"], expected_handbrake_accumulator, "hbacc: " + msg)
	assert_eq(result["lost_grip"], expected_lost_grip, "lg: " + msg)
