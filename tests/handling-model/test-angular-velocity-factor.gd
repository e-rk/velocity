extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.005


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/angular_velocity_factor.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["angular_velocity"] = self.global_angular_velocity(data)
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["mass"] = self.mass(data)
	result["inertia_inv"] = self.inertia_inv(data)
	result["gear"] = self.gear(data)
	result["has_contact_with_ground"] = !self.is_airborne(data)
	result["speed_xz"] = self.speed_xz(data)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = float(data["result"])
	var result = self.model.angular_velocity_factor(params)
	assert_almost_eq(result, expected, EPSILON, "gear=" + str(params["gear"]))
