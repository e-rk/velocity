extends Node

@export_range(-1.0, 1.0) var steering := 0.0:
	set(value): steering = clamp(value, -1.0, 1.0)
@export_range(0.0, 1.0) var throttle := 0.0:
	set(value): throttle = clamp(value, 0.0, 1.0)
@export_range(0.0, 1.0) var brake := 0.0:
	set(value): brake = clamp(value, 0.0, 1.0)
@export var gear: int = 0
@export var handbrake := false
@export var lights_on := false
@export var siren_on := false


@onready var player: ControllablePlayer = $".."


func _enter_tree() -> void:
	self.set_multiplayer_authority($"..".name.to_int())


func _input(event: InputEvent) -> void:
	if self.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	if event.is_action_pressed("shift_up"):
		self.gear += 1
	if event.is_action_pressed("shift_down"):
		self.gear -= 1
	if event.is_action_pressed("lights"):
		self.lights_on = not self.lights_on
	if event.is_action_pressed("siren"):
		self.siren_on = not self.siren_on
	if event.is_action_pressed("reset"):
		self.player.request_reposition.rpc_id(1)


func _physics_process(_delta: float) -> void:
	if self.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	self.steering  = Input.get_axis("turn_right", "turn_left")
	self.handbrake = Input.is_action_pressed("handbrake")
	self.throttle  = Input.get_action_strength("accelerate")
	self.brake     = Input.get_action_strength("brake")
