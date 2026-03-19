class_name Racer
extends Node

@export var laps: int = 0
@export var max_laps: int = 1
@export var best_lap_time: float = INF
@export var track_progress := 0.80
@export var lap_start_timestamp: int = 0

@onready var player: Player = $".."

var current_ticks := 0
var average_speed := 1.0
var num_measurements := 0


func start_timer():
	self.lap_start_timestamp = self.current_ticks


func capture_time():
	var lap_time = self.current_lap_time()
	self.best_lap_time = min(self.best_lap_time, lap_time)
	self.lap_start_timestamp = self.current_ticks


func get_best_lap_time():
	if is_inf(self.best_lap_time):
		return 0.0
	return self.best_lap_time


func current_lap_time() -> float:
	if self.lap_start_timestamp == 0:
		return 0.0
	return float(self.current_ticks - self.lap_start_timestamp) / Engine.physics_ticks_per_second


func _update_average_speed() -> void:
	var speed := self.player.car.linear_velocity.length()
	self.average_speed = (1.0 / (self.num_measurements + 1)) * (speed + self.num_measurements * self.average_speed)
	self.average_speed = max(1.0, self.average_speed)
	self.num_measurements += 1


func _physics_process(delta: float) -> void:
	self.current_ticks += 1
	if not self.player.disable_steering:
		self._update_average_speed()
