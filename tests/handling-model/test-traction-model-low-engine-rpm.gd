extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.00000001


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_low_engine_rpm.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["rpm"] = int(data["rpm"])
	result["force"] = float(data["force"])
	result["gear"] = self.gear(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	#var expected_rpm = int(data["result_rpm"])
	var expected_force = float(data["result_force"])
	var result = self.model.traction_model_low_engine_rpm(params)
	var msg = "rpm=" + str(params["rpm"])
	#assert_eq(result["rpm"], expected_rpm, msg)
	assert_almost_eq(result["force"], expected_force, EPSILON, msg)
