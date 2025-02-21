extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.000001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open(
		"res://tests/handling-model/data/wheel_force_loss_of_grip.csv", FileAccess.READ
	)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis"] = Basis()
	result["gear"] = self.gear(data)
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["throttle"] = self.throttle(data)
	result["rpm"] = int(data["rpm"])
	result["road_surface"] = self.road_surface(data)
	result["weather"] = self.weather(data)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = self.wheel_force(data, "result_")
	var wheel_data = Dictionary()
	var force = self.wheel_force(data)
	wheel_data["grip"] = self.wheel_lateral_grip(data)
	if self.wheel_is_front(data):
		wheel_data["type"] = CarTypes.Wheel.FRONT_LEFT
	else:
		wheel_data["type"] = CarTypes.Wheel.REAR_LEFT
	var result = self.model.wheel_loss_of_grip(params, wheel_data, force)
	var msg = (
		"v="
		+ str(params["linear_velocity"])
		+ " sufr="
		+ str(params["weather"])
		+ " rpm="
		+ str(params["rpm"])
		+ " rsurf="
		+ str(params["road_surface"])
	)
	assert_almost_eq(result, expected, EPSILON * Vector3.ONE, msg)
