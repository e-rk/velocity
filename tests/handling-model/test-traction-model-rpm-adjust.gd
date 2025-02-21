extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_rpm_adjust.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["rpm"] = self.rpm(data)
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["throttle"] = self.throttle(data)
	result["brake"] = self.brake(data)
	result["shifted_down"] = data["unknown_engine_value"] != "0"
	result["gear_shift_counter"] = (int(data["unknown_engine_value2"]) >> 0x10)
	result["target_rpm"] = int(data["target_rpm"])
	result["rpm_above_redline"] = data["rpm_above_redline"] != "0"
	result["force"] = float(data["force"])
	result["gear"] = self.gear(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_rpm = int(data["result_rpm"])
	print(int(data["unknown_engine_value"]))
	var result = self.model.traction_model_rpm_adjust(params)
	var msg = "rpm=" + str(params["rpm"]) \
			+ " thr=" + str(params["throttle"]) \
			+ " brk=" + str(params["brake"]) \
			+ " sd=" + str(params["shifted_down"]) \
			+ " sc=" + str(params["gear_shift_counter"])
	assert_eq(result["rpm"], expected_rpm, msg)
