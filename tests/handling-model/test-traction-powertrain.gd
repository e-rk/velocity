extends CsvTest

var model: HandlingModelRE
@onready var performance: CarPerformance = preload("res://tests/handling-model/data/performance.tres")

const EPSILON = 0.0001

func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_powertrain.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["gear"] = self.gear(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var rpm = self.rpm(data)
	var expected = float(data["result"])
	var result = self.model.traction_powertrain(params, rpm)
	assert_almost_eq(result, expected, EPSILON, "gear="+str(params["gear"]))
