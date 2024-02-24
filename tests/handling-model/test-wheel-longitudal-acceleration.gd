extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.0001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/wheel_longitudal_acceleration.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["gear"] = self.gear(data)
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["handbrake"] = self.handbrake(data)
	result["throttle_input"] = self.throttle(data)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = self.wheel_force(data).z
	var planar_vector = self.wheel_planar_vector(data)
	var wheel_data = Dictionary()
	wheel_data["traction"] = self.wheel_traction(data)
	wheel_data["effective_grip"] = self.wheel_lateral_grip(data)
	if self.wheel_is_front(data):
		wheel_data["type"] = CarTypes.Wheel.FRONT_LEFT
	else:
		wheel_data["type"] = CarTypes.Wheel.REAR_LEFT
	var result = self.model.longitudal_acceleration(params, wheel_data, planar_vector)
	var msg = (
		"gear="
		+ str(params["gear"])
		+ " hb="
		+ str(params["handbrake"])
		+ " v.z="
		+ str(params["linear_velocity"].z)
		+ " sv.z="
		+ str(planar_vector.z)
	)
	assert_almost_eq(result, expected, EPSILON, msg)
