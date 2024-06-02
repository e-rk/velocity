extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.001


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_target_rpm.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["throttle"] = self.throttle(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_target_rpm = roundi(float(data["result_target_rpm"]))
	var result = self.model.traction_model_target_rpm(params)
	var msg = "thr=" + str(params["throttle"])
	assert_eq(result["target_rpm"], expected_target_rpm, "rpm: " + msg)

