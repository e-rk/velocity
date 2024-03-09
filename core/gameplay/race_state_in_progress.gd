extends RaceState

@onready var race_state_ending = $"../RaceStateEnding"


func enter():
	context.race_logic.race_finished.connect(self._on_race_finished)
	context.controller.reposition_requested.connect(self._on_racer_controller_reposition_requested)
	context.race_logic.process_mode = Node.PROCESS_MODE_INHERIT
	super()


func leave():
	context.race_logic.race_finished.disconnect(self._on_race_finished)
	context.controller.reposition_requested.disconnect(
		self._on_racer_controller_reposition_requested
	)


func _on_race_finished():
	context.set_state(race_state_ending)


func _on_racer_controller_reposition_requested(car: Car):
	if !context.race_logic.reposition_allowed():
		return
	car.transform = context.track.get_closest_transform(car.global_position)
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO


func end_race():
	context.set_state(race_state_ending)
