extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.001


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_rpm_from_wheels.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["gear"] = self.gear(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_rpm = float(data["result_rpm_from_wheels"])
	var result = self.model.rpm_from_wheels(params)
	var msg = "v.z=" + str(params["linear_velocity"].z) \
			+ " gear=" + str(params["gear"]) \
			+ " res=" + str(result)
	assert_eq(round(result), expected_rpm, msg)
