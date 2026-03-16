extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/b911/b911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

var result := HandlingModelRE.HandlingOutput.new()

const EPSILON = 0.000001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/damp_lateral_velocity.csv", FileAccess.READ)


func make_params(data: Dictionary) -> HandlingModelRE.HandlingState:
	var result = HandlingModelRE.HandlingState.new()
	result.performance = self.performance
	result.basis_to_road = Basis()
	result.linear_velocity = self.local_linear_velocity(data)
	result.angular_velocity = Vector3.ZERO
	result.timestep = 1.0 / 32.0
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = Vector3(float(data["result_local_linear_velocity_x"]), 0, 0)
	self.model.integrate(self.model.damp_lateral_velocity_cm).call(params, result)
	var msg = "v=" + str(params.linear_velocity)
	assert_almost_eq(result.linear_velocity, expected, EPSILON * Vector3.ONE, msg)
