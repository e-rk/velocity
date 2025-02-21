extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/wheel_steering_acceleration.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["gear"] = self.gear(data)
	result["weather"] = 0
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = float(data["result"])
	var wheel_data = Dictionary()
	var wheel_planar_vector = self.wheel_planar_vector(data)
	wheel_data["grip"] = self.wheel_lateral_grip(data)
	if self.wheel_is_front(data):
		wheel_data["type"] = CarTypes.Wheel.FRONT_LEFT
	else:
		wheel_data["type"] = CarTypes.Wheel.REAR_LEFT
	var result = self.model.steering_acceleration(params, wheel_data, wheel_planar_vector)
	var msg = "gear=" + str(params["gear"])
	assert_almost_eq(
		result,
		expected,
		EPSILON,
	)
