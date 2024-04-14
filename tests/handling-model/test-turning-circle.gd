extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/turning_circle.csv", FileAccess.READ)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["gear"] = self.gear(data)
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["throttle_input"] = self.throttle(data)
	result["current_steering"] = self.steering(data)
	result["brake_input"] = self.brake_input(data)
	result["slip_angle"] = self.slip_angle(data)
	result["angular_velocity"] = self.local_angular_velocity(data)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = float(data["result_local_angular_velocity_y"])
	var result = self.model.turning_circle(params, params["angular_velocity"], params["linear_velocity"])
	var msg = (
		"gear="
		+ str(params["gear"])
		+ " thr="
		+ str(params["throttle_input"])
		+ " steer="
		+ str(params["current_steering"])
		+ " brake="
		+ str(params["brake_input"])
		+ " slip="
		+ str(params["slip_angle"])
		+ " angvel="
		+ str(params["angular_velocity"])
		+ " vel="
		+ str(params["linear_velocity"])
	)
	assert_almost_eq(result.y, expected, EPSILON, msg)
