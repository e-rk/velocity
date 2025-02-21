extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.00001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/wheel_forces_sloped.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis(
		Vector3(1, 0, 0),
		self.road_basis_normal_y(data),
		Vector3(1, 0, 0),
	)  # Note: not orthonormal
	result["basis"] = Basis()
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = self.wheel_force(data, "result_wheel_")
	var wheel_forces = self.wheel_force(data, "wheel_")
	var result = self.model.wheel_slope_vector(params, wheel_forces)
	assert_almost_eq(result, expected, Vector3.ONE * EPSILON)
