extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_limit_gear_when_low_velocity.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["gear"] = self.gear(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var result_gear = int(data["result_current_gear"])
	var result = self.model.traction_model_limit_gear_when_low_velocity(params)
	var msg = "v.z=" + str(params["linear_velocity"])
	assert_eq(result["gear"], result_gear, msg)
