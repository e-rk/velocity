extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.01


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/wheel_base_grip.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = self.basis_to_road(data)
	result["gravity_vector"] = Vector3(0, -9.81, 0)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var wheel= {"type": CarTypes.Wheel.FRONT_LEFT}
	var surface_grip = float(data["surface_grip"])
	var expected = float(data["result_base_grip"])
	var result = self.model.wheel_base_road_grip(params, wheel, surface_grip)
	var msg = "surf=" + str(surface_grip)
	assert_almost_eq(result, expected, EPSILON, msg)
