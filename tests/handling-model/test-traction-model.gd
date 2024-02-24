extends CsvTest

var model: HandlingModelRE
@onready var performance: CarPerformance = preload("res://tests/handling-model/data/performance.tres")

const EPSILON = 0.001

func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis"] = Basis()
	result["rpm"] = self.rpm(data)
	result["gear"] = self.gear(data)
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["handbrake"] = self.handbrake(data)
	result["throttle_input"] = self.throttle(data)
	result["weather"] = self.weather(data)
	result["slip_angle"] = self.slip_angle(data)
	result["brake_input"] = self.brake_input(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_rpm = float(data["result_rpm"])
	var expected_gear = int(data["result_gear"])
	var expected_handbrake = data["result_handbrake"] != "0"
	var expected_force = float(data["result_force"])

	var result = self.model.traction_model(params)
	var msg = "rpm=" + str(params["rpm"]) \
			+ " gear=" + str(params["gear"]) \
			+ " throttle=" + str(params["throttle_input"])
	assert_almost_eq(result["force"], expected_force, EPSILON, msg)

