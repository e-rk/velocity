extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/b911/b911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

var result := HandlingModelRE.TractionOutput.new()

func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_airborne_target_rpm.csv", FileAccess.READ)

func make_params(data: Dictionary) -> HandlingModelRE.TractionState:
	var result = HandlingModelRE.TractionState.new()
	result.performance = self.performance
	result.has_contact_with_ground = not self.is_airborne(data)
	result.target_rpm = int(data.target_rpm)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_target_rpm = int(data.result_target_rpm)
	self.model.traction_model_airborne_target_rpm(params, result)
	var msg = "rpm=" + str(params.target_rpm)
	assert_eq(result.target_rpm, expected_target_rpm, msg)
