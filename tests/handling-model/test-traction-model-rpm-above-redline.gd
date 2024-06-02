extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.001


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_rpm_above_redline.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["rpm"] = self.rpm(data)
	result["throttle"] = self.throttle(data)
	result["lost_grip"] = self.handbrake(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_rpm = int(data["result_rpm"])
	var expected_lost_grip = data["result_handbrake"] != "0"
	var expected_rpm_above_redline = data["result_rpm_above_redline"] != "0"
	var result = self.model.traction_model_rpm_above_redline(params)
	var msg = "rpm=" + str(params["rpm"]) \
			+ " thr=" + str(params["throttle"])
	assert_eq(result["lost_grip"], expected_lost_grip, "lost_grip: " + msg)
	assert_eq(result["rpm"], expected_rpm, "rpm: " + msg)
	assert_eq(result["rpm_above_redline"], expected_rpm_above_redline, "rar: " + msg)

