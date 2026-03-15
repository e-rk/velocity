class_name AIPlayer
extends Player

@export var waypoints: NavPath

@onready var drive_algo: SteeringAlgo = $SteeringAlgo
@onready var behavior: BehaviorAlgo = $BehaviorAlgo


func _ready():
	super()
	drive_algo.waypoints = self.waypoints


func _physics_process(delta):
	if not self.is_multiplayer_authority():
		return
	if not self.disable_steering:
		behavior.decide(self, delta)
		drive_algo.process(self, delta)
	else:
		self.car.throttle = 0.0
		self.car.brake = 1.0
		self.car.steering = 0.0
	self._update_dynamic_player_avoidance()


func is_local() -> bool:
	return false


func is_ai() -> bool:
	return true
