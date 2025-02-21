extends CsvTest

var model: HandlingModelRE

const EPSILON = 0.00001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/vector_rotate_y.csv", FileAccess.READ
	)

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
