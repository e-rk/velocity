extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.0001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/damp_velocity_when_neutral.csv", FileAccess.READ)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = self.basis_to_road(data)
	result["linear_velocity"] = self.global_linear_velocity(data)
	result["angular_velocity"] = self.global_angular_velocity(data)
	result["timestep"] = 1.0 / 32.0
	result["gear"] = self.gear(data)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_linear = Vector3(float(data["result_global_linear_velocity_x"]), float(data["result_global_linear_velocity_y"]), float(data["result_global_linear_velocity_z"]))
	var expected_angular = Vector3(float(data["result_global_angular_velocity_x"]), float(data["result_global_angular_velocity_y"]), float(data["result_global_angular_velocity_z"]))
	var result = self.model.integrate(self.model.neutral_gear_deceleration_cm).call(params)
	var msg = "v=" + str(params["linear_velocity"])
	assert_almost_eq(result["linear_velocity"], expected_linear, EPSILON * Vector3.ONE, msg)
	assert_almost_eq(result["angular_velocity"], expected_angular, EPSILON * Vector3.ONE, msg)
