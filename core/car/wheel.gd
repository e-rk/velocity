@tool
extends Node3D
class_name CarWheel

const wheel_circumference = 2 * PI * 0.2
var wheel_basis = Basis()
var turn := 0.0:
	set(value):
		turn = value
	get:
		return turn

@export var is_front = false

func step_rotation(linear_distance: float):
	var step = linear_distance / wheel_circumference
	wheel_basis = wheel_basis.rotated(Vector3.RIGHT, step)

func _process(delta):
	var basis = wheel_basis
	if self.is_front:
		basis = wheel_basis.rotated(Vector3.UP, turn)
	self.basis = basis
