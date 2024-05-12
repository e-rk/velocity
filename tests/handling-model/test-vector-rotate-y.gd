extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

# https://randomascii.wordpress.com/2014/10/09/intel-underestimates-error-bounds-by-1-3-quintillion/
# fsin accuracy is terrible for small values. fcos accuracy if terrible for values around pi/2.
# Both are used by the original. Unfortunate.
const EPSILON = 0.002


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/vector_rotate_y.csv", FileAccess.READ
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

func result_wheel_planar_vector(data: Dictionary) -> Vector3:
	var fx = float(data.get("result_wheel_planar_vector_lateral", "0.0"))
	var fz = float(data.get("result_wheel_planar_vector_longitudal", "0.0"))
	return Vector3(fx, 0, fz)

func body(data: Dictionary):
	var input = self.wheel_planar_vector(data)
	var steering = float(data["wheel_steering"])
	var expected = result_wheel_planar_vector(data)
	var result = self.model.vector_rotate_y(input, -steering)
	var msg = "steer=" + str(steering) + " input=" + str(input)
	assert_almost_eq(result, expected, Vector3.ONE * EPSILON, msg)
