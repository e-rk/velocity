extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.0000001


func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/traction_model_postprocess.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["has_contact_with_ground"] = not self.is_airborne(data)
	result["drag"] = float(data["drag"])
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["force"] = float(data["force"])
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_force = float(data["result_force"])
	var result = self.model.traction_model_postprocess(params)
	var msg = "force=" + str(params["force"]) \
			+ " drag=" + str(params["drag"]) \
			+ " v.z=" + str(params["linear_velocity"].z)
	assert_almost_eq(result["force"], expected_force, EPSILON, msg)
