extends StateMachine
class_name BehaviorAlgo

@export var steering_controller: SteeringAlgo
@export_range(0.0, 10.0, 0.1, "or_greater") var airborne_recovery_time: float = 5.0

@onready var state_racing: BehaviorAlgoRacing = $BehaviorAlgoRacing
@onready var state_recover: BehaviorAlgoRecover = $BehaviorAlgoRecover

var airborne_counter := 0.0


func reposition(player: Player):
	player.reposition_requested.emit()
	self.steering_controller.reset()
	self.airborne_counter = 0.0
	self.set_state(get_node(self.initial_state))


func decide(player: Player, delta: float):
	if not player.car.has_contact_with_ground:
		self.airborne_counter += delta
	else:
		self.airborne_counter = 0.0
	if self.airborne_counter >= airborne_recovery_time:
		self.reposition(player)
		return
	current_state.decide(player, delta)
