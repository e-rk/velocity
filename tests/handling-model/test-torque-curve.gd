extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.0001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/handling_model_torque_curve.csv", FileAccess.READ
	)


func make_params() -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	return result


func body(data: Dictionary):
	var params = self.make_params()
	var rpm = self.rpm(data)
	var expected = self.torque(data)
	var torque = self.model.torque_for_rpm(params, rpm)
	assert_almost_eq(torque, expected, EPSILON, "rpm=" + str(rpm))
