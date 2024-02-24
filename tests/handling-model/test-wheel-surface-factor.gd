extends CsvTest

var model: HandlingModelRE
@onready var performance: CarPerformance = preload("res://tests/handling-model/data/performance.tres")

const EPSILON = 0.0001

func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/wheel_surface_factor.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis(
		Vector3(1, 0, 0),
		self.road_basis_normal_y(data),
		Vector3(1, 0, 0),
	) # Note: not orthonormal
	result["basis"] = Basis()
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = float(data["result"])
	var wheel_data = {
		"road_surface": self.road_surface(data),
	}
	var result = self.model.wheel_surface_grip_factor(params, wheel_data)
	var msg = "surf="+str(wheel_data["road_surface"])
	assert_almost_eq(result, expected, EPSILON, msg)

