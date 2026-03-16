extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/b911/b911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.000001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/wheel_downforce_factor.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> HandlingModelRE.HandlingState:
	var result = HandlingModelRE.HandlingState.new()
	result.performance = self.performance
	result.basis_to_road = Basis()
	result.linear_velocity = self.local_linear_velocity(data)
	result.brake = self.brake(data)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var wheel_data := HandlingModelRE.WheelData.new()
	var wheels = [
		CarTypes.Wheel.FRONT_LEFT,
		CarTypes.Wheel.FRONT_RIGHT,
		CarTypes.Wheel.REAR_LEFT,
		CarTypes.Wheel.REAR_RIGHT,
	]
	for i in wheels.size():
		wheel_data.type = wheels[i]
		var expected = self.wheel_downforce(data, i)
		var result = self.model.wheel_downforce_factor(params, wheel_data)
		var msg = "v.z=" + str(params.linear_velocity.z) + " type=" + str(wheels[i])
		assert_almost_eq(result, expected, EPSILON, msg)
