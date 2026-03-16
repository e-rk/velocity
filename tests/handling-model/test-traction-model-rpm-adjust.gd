extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/b911/b911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

var result := HandlingModelRE.TractionOutput.new()


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_rpm_adjust.csv", FileAccess.READ)

func make_params(data: Dictionary) -> HandlingModelRE.TractionState:
	var result = HandlingModelRE.TractionState.new()
	result.performance = self.performance
	result.rpm = self.rpm(data)
	result.linear_velocity = self.local_linear_velocity(data)
	result.throttle = self.throttle(data)
	result.brake = self.brake(data)
	result.shifted_down = data.unknown_engine_value != "0"
	result.gear_shift_counter = (int(data.unknown_engine_value2) >> 0x10)
	result.target_rpm = int(data.target_rpm)
	result.rpm_above_redline = data.rpm_above_redline != "0"
	result.force = float(data.force)
	result.gear = self.gear(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_rpm = int(data.result_rpm)
	self.model.traction_model_rpm_adjust(params, result)
	var msg = "rpm=" + str(params.rpm) \
			+ " thr=" + str(params.throttle) \
			+ " brk=" + str(params.brake) \
			+ " sd=" + str(params.shifted_down) \
			+ " sc=" + str(params.gear_shift_counter)
	assert_eq(result.rpm, expected_rpm, msg)
