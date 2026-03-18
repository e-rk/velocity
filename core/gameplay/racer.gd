class_name Racer
extends Node

@export var laps: int = 0
@export var max_laps: int = 1
@export var best_lap_time: float = INF
@export var track_progress := 0.80
@export var lap_start_timestamp: int = 0

@onready var player: Player = $".."

var current_ticks := 0


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


func _physics_process(delta: float) -> void:
	self.current_ticks += 1
