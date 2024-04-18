extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/wheel_forces_to_angular_acceleration.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["basis"] = Basis()
	result["inertia_inv"] = self.inertia_inv(data)
	result["mass"] = self.mass(data)
	result["timestep"] = 1.0 / 32
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = float(data["result"]) * Vector3.UP
	var wheel_forces: Array[Vector3] = [
		self.wheel_force(data, "wheel_0_"),
		self.wheel_force(data, "wheel_1_"),
		self.wheel_force(data, "wheel_2_"),
		self.wheel_force(data, "wheel_3_"),
	]
	var result = self.model.wheel_forces_to_angular_acceleration(params, wheel_forces)
	assert_almost_eq(result, expected, Vector3.ONE * EPSILON)
