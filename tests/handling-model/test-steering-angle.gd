extends CsvTest

var model: HandlingModelRE

@onready var car: Car = preload("res://import/cars/B911/B911.glb").instantiate()
@onready var performance: CarPerformance = car.performance

const EPSILON = 0.0000001


func before_all():
	self.model = HandlingModelRE.new()


func get_csv() -> FileAccess:
	return FileAccess.open("res://tests/handling-model/data/steering_angle.csv", FileAccess.READ)


func make_params(data: Dictionary) -> Dictionary:
	var result = Dictionary()
	result["performance"] = self.performance
	result["basis_to_road"] = Basis()
	result["linear_velocity"] = self.local_linear_velocity(data)
	result["handbrake"] = self.handbrake(data)
	result["current_steering"] = self.steering(data)
	result["has_contact_with_ground"] = !self.is_airborne(data)
	result["slip_angle"] = self.slip_angle(data)
	return result


func body(data: Dictionary):
	var params = self.make_params(data)
	var expected = float(data["result"])
	var result = self.model.steering_angle(params)
	var msg = (
		"hb="
		+ str(params["handbrake"])
		+ " st="
		+ str(params["current_steering"])
		+ " v="
		+ str(params["linear_velocity"])
		+ " slip="
		+ str(params["slip_angle"])
		+ " cwg="
		+ str(params["has_contact_with_ground"])
	)
	assert_almost_eq(result["steering"], expected, EPSILON, msg)
