extends Node3D

@export var racer: Racer = null:
	set(value):
		racer = value
	get:
		return racer

@export_exp_easing("attenuation") var easing

@onready var ui: PlayerUI = $PlayerUI
@onready var camera_arm: SpringArm3D = %CameraArm
@onready var reflection: ReflectionProbe = $ReflectionProbe


func set_waypoints(waypoints: Array):
	ui.set_minimap_waypoints(waypoints)


var weight_accumulated = 0.0
var current_camera_rotation := 0.0
var camera_direction := Vector3.FORWARD


func player_to_minimap_data(node: Node) -> Dictionary:
	var racer = node as Racer
	return {
		"global_position": racer.car.global_position,
		"emphasis": false,
		"color": Color.BLUE,
	}


func _physics_process(delta):
	var racer = get_tree().get_first_node_in_group(&"SpectatedRacer")
	var player_data = get_tree().get_nodes_in_group(&"Racers").map(player_to_minimap_data)
	self.global_transform = racer.car.global_transform
	ui.set_speed(racer.car.linear_velocity.length())
	ui.set_rpm(racer.car.current_rpm)
	ui.set_gear(racer.car.current_gear)
	ui.set_minimap_center(racer.car.global_position)
	ui.set_minimap_rotation(racer.car.global_rotation.y)
	ui.set_minimap_players(player_data)
	ui.set_laps(racer.laps, 2)
	ui.set_current_lap_time(racer.current_lap_time)
	ui.set_last_lap_time(racer.last_lap_time)
