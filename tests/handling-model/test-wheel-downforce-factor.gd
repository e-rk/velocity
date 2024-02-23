extends CsvTest

var model: HandlingModelRE
@onready var performance: CarPerformance = preload("res://tests/handling-model/data/performance.tres")

const EPSILON = 0.0001

func before_all():
	self.model = HandlingModelRE.new()

func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/wheel_downforce_factor.csv", FileAccess.READ)

func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["linear_velocity"] = self.local_linear_velocity(data)
	return result

func body(data: Dictionary):
	var params = self.make_params(data)
	var wheels = [
		{ "type": CarTypes.Wheel.FRONT_LEFT },
		{ "type": CarTypes.Wheel.FRONT_RIGHT },
		{ "type": CarTypes.Wheel.REAR_LEFT },
		{ "type": CarTypes.Wheel.REAR_RIGHT },
	]
	for i in wheels.size():
		var expected = self.wheel_downforce(data, i)
		var result = self.model.wheel_downforce_factor(params, wheels[i])
		var msg = "v.z="+str(params["linear_velocity"].z)+" type="+str(wheels[i]["type"])
		assert_almost_eq(result, expected, EPSILON, msg)

