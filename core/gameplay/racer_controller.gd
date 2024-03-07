class_name RacerController
extends Node

@export var steering_enabled: bool = true

signal reposition_requested


func _get_target_car() -> Car:
	var racer = get_tree().get_first_node_in_group(&"ControlledRacer")
	if racer:
		return racer.car
	return null


func _input(event: InputEvent):
	var car = self._get_target_car()
	if not car:
		return
	if event.is_action_pressed("shift_up"):
		car.shift_up()
	if event.is_action_pressed("shift_down"):
		car.shift_down()
	if event.is_action_pressed("reset"):
		self._signal_reposition.call_deferred()


func _physics_process(delta: float):
	var car = self._get_target_car()
	if not car:
		return
	var throttle = Input.get_action_strength("accelerate")
	var brake = Input.get_action_strength("brake")
	if not steering_enabled:
		brake = 1.0
		throttle = 0.0
	car.throttle = throttle
	car.brake = brake
	car.steering = Input.get_axis("turn_left", "turn_right")
	car.handbrake = Input.is_action_pressed("handbrake")


func _signal_reposition():
	var car = self._get_target_car()
	if car:
		self.reposition_requested.emit(car)
