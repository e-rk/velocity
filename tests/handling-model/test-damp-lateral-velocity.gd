extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.0001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/damp_lateral_velocity.csv", FileAccess.READ)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["angular_velocity"] = Vector3.ZERO
	result["timestep"] = 1.0 / 32.0
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = Vector3(float(data["result_local_linear_velocity_x"]), 0, 0)
	var result = self.model.integrate(self.model.damp_lateral_velocity_cm).call(params)
	var msg = "v=" + str(params["linear_velocity"])
	assert_almost_eq(result["linear_velocity"], expected, EPSILON * Vector3.ONE, msg)
