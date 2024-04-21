extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.00001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/handbrake_scaling_function.csv", FileAccess.READ)


func body(data: Dictionary):
	var input = float(data["input"])
	var expected = float(data["result"])
	var result = self.model.handbrake_scaling_function(input)
	var msg = "input=" + str(input)
	assert_almost_eq(result, expected, EPSILON, msg)
