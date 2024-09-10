extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.0001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/turning_circle.csv", FileAccess.READ)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = self.basis_to_road(data)
	result["gear"] = self.gear(data)
	result["linear_velocity"] = self.global_linear_velocity(data)
	result["throttle"] = self.throttle(data)
	result["current_steering"] = self.steering(data)
	result["brake"] = self.brake(data)
	result["slip_angle"] = self.slip_angle(data)
	result["angular_velocity"] = self.global_angular_velocity(data)
	result["timestep"] = 1.0 / 32.0
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected_angular = float(data["result_global_angular_velocity_y"])
	var expected_linear = Vector3(float(data["result_global_linear_velocity_x"]), float(data["result_global_linear_velocity_y"]), float(data["result_global_linear_velocity_z"]))
	var result = self.model.integrate(self.model.turning_circle_cm).call(params)
	var msg = (
		"gear="
		+ str(params["gear"])
		+ " thr="
		+ str(params["throttle"])
		+ " steer="
		+ str(params["current_steering"])
		+ " brake="
		+ str(params["brake"])
		+ " slip="
		+ str(params["slip_angle"])
		+ " angvel="
		+ str(params["angular_velocity"])
		+ " vel="
		+ str(params["linear_velocity"])
	)
	assert_almost_eq(result["angular_velocity"].y, expected_angular, EPSILON, msg)
	assert_almost_eq(result["linear_velocity"], expected_linear, EPSILON * Vector3.ONE, msg)
