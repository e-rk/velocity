extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.1


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/wheel_planar_vector.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["basis_to_road"] = Basis()
	result["angular_velocity"] = self.global_angular_velocity(data)
	result["inertia_inv"] = self.inertia_inv(data)
	result["mass"] = self.mass(data)
	result["gear"] = self.gear(data)
	result["has_contact_with_ground"] = !self.is_airborne(data)
	result["speed_xz"] = self.speed_xz(data)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = self.wheel_planar_vector(data)
	var wheel_data = Dictionary()
	match self.wheel_type(data):
		0:
			wheel_data["type"] = CarTypes.Wheel.FRONT_LEFT
		1:
			wheel_data["type"] = CarTypes.Wheel.FRONT_RIGHT
		2:
			wheel_data["type"] = CarTypes.Wheel.REAR_LEFT
		3:
			wheel_data["type"] = CarTypes.Wheel.REAR_RIGHT
		_:
			assert(false)
	var result = self.model.wheel_planar_vector(params, wheel_data)
	var msg = "v=" + str(params["linear_velocity"]) + " gear=" + str(params["gear"]) + " type=" + str(wheel_data["type"])
	assert_almost_eq(result, expected, Vector3.ONE * EPSILON, msg)
