extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.00001


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
	result["angular_velocity"] = self.global_angular_velocity(data)
	result["mass"] = self.mass(data)
	result["current_steering"] = self.steering(data)
	result["handbrake"] = self.handbrake(data)
	result["has_contact_with_ground"] = !self.is_airborne(data)
	result["weather"] = 0
	result["slip_angle"] = self.slip_angle(data)
	result["speed_xz"] = self.speed_xz(data)
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
	var steering
	match wheel_data["type"]:
		CarTypes.Wheel.FRONT_RIGHT, CarTypes.Wheel.FRONT_LEFT:
			steering = self.model.steering_angle(params)["steering"]
		CarTypes.Wheel.REAR_RIGHT, CarTypes.Wheel.REAR_LEFT:
			steering = 0.0
	var planar_vector = self.model.wheel_planar_vector(params, wheel_data)
	planar_vector = self.model.vector_rotate_y(planar_vector, -steering)
	var result = self.model.turned_steering_acceleration(params, wheel_data, planar_vector)
	var msg = "gear=" + str(params["gear"]) \
			+ " hb=" + str(params["handbrake"]) \
			+ " steer=" + str(params["current_steering"]) \
			+ " slip=" + str(params["slip_angle"]) \
			+ " xz=" + str(params["speed_xz"]) \
			+ " v=" + str(params["linear_velocity"]) \
			+ " w=" + str(params["angular_velocity"])
	assert_almost_eq(result, expected, EPSILON, msg)
