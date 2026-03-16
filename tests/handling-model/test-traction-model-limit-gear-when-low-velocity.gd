extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/b911/b911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

var result := HandlingModelRE.TractionOutput.new()


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_limit_gear_when_low_velocity.csv", FileAccess.READ)

func make_params(data: Dictionary) -> HandlingModelRE.TractionState:
	var result = HandlingModelRE.TractionState.new()
	result.performance = self.performance
	result.linear_velocity = self.local_linear_velocity(data)
	result.gear = self.gear(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var result_gear = int(data.result_current_gear)
	self.model.traction_model_limit_gear_when_low_velocity(params, result)
	var msg = "v.z=" + str(params.linear_velocity)
	assert_eq(result.gear, result_gear, msg)
