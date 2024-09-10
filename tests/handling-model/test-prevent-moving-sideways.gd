extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.000000001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/prevent_moving_sideways.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = self.basis_to_road(data)
	result["linear_velocity"] = self.global_linear_velocity(data)
	result["current_steering"] = self.steering(data)
	result["throttle"] = self.throttle(data)
	result["brake"] = self.brake_input(data)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = Vector3(float(data["result_global_linear_velocity_x"]), float(data["result_global_linear_velocity_y"]), float(data["result_global_linear_velocity_z"]))
	var result = self.model.prevent_moving_sideways_cm(params)
	assert_almost_eq(result["linear_velocity"], expected, EPSILON * Vector3.ONE)
