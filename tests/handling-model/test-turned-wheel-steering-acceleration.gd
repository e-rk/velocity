extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/wheel_turned_steering_acceleration.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["gear"] = self.gear(data)
	result["inertia_inv"] = self.inertia_inv(data)
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["angular_velocity"] = self.local_angular_velocity(data)
	result["mass"] = self.mass(data)
	result["current_steering"] = self.steering(data)
	result["handbrake"] = self.handbrake(data)
	result["has_contact_with_ground"] = !self.is_airborne(data)
	result["weather"] = 0
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = float(data["result"])
	var wheel_data = Dictionary()
	wheel_data["grip"] = self.wheel_lateral_grip(data)
	if self.wheel_is_front(data):
		wheel_data["type"] = CarTypes.Wheel.FRONT_LEFT
	else:
		wheel_data["type"] = CarTypes.Wheel.REAR_LEFT
	var result = self.model.turned_steering_acceleration(params, wheel_data)
	var msg = "gear=" + str(params["gear"]) + " hb=" + str(params["handbrake"])
	assert_almost_eq(result, expected, EPSILON, msg)
