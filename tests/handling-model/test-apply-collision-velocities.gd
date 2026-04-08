extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/b911/b911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.00001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/apply_collision_velocities.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> HandlingModelRE.CollisionParams:
	var result = HandlingModelRE.CollisionParams.new()
	result.basis = self.basis(data)
	result.angular_velocity = self.global_angular_velocity(data)
	result.linear_velocity = self.global_linear_velocity(data)
	result.mass = self.mass(data)
	result.inertia_inv = self.inertia_inv(data)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var momentum = self.vector3("momentum", data)
	var radius = self.vector3("radius", data)
	var ratio = float(data["ratio"])
	var friction = float(data["maybe_friction"])
	var expected_linear_velocity = self.result_global_linear_velocity(data)
	var expected_angular_velocity = self.result_global_angular_velocity(data)
	var expected_result = float(data["result"])
	var result := HandlingModelRE.CollisionOutput.new()
	self.model.apply_collision_velocities(params, momentum, radius, ratio, friction, result)
	assert_almost_eq(result.linear_velocity, expected_linear_velocity, EPSILON * Vector3.ONE)
	assert_almost_eq(result.angular_velocity, expected_angular_velocity, EPSILON * Vector3.ONE)
