class_name ControllablePlayer
extends Player

@onready var input = $Input

var authority := 1
var previous_gear: int = 0

func _enter_tree() -> void:
	assert(self.name.is_valid_int())
	self.authority = self.name.to_int()


func is_local() -> bool:
	return self.authority == multiplayer.get_unique_id()


func _physics_process(_delta):
	var input_gear = self.input.gear
	if not self.disable_steering:
		car.brake = input.brake
		car.steering = input.steering
		car.handbrake = input.handbrake
		if self.previous_gear != input_gear:
			# Gear change by difference to avoid duplicated states.
			car.gear += (input_gear - previous_gear)
	else:
		car.brake = 1.0
		car.handbrake = false
		car.gear = CarTypes.Gear.NEUTRAL
		car.steering = 0.0
	self.previous_gear = input_gear
	car.throttle = input.throttle
	car.lights_on = input.lights_on
	car.siren_on = input.siren_on
	self._update_dynamic_player_avoidance()


@rpc("any_peer", "call_local", "reliable")
func request_reposition():
	var id = multiplayer.get_remote_sender_id()
	if id == authority:
		self.reposition_requested.emit()
