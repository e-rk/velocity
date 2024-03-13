class_name Racer
extends Node

var laps: int = 0:
	set(value):
		if value > max_laps:
			_on_lap_finished(value)
		laps = value
		max_laps = max(max_laps, laps)
	get:
		return laps

var max_laps := 0
var current_lap_time := 0.0
var last_lap_time := 0.0
var track_progress := 0.80
var car: Car


func _process(delta: float):
	current_lap_time += delta


func _on_lap_finished(laps: int):
	if laps > 1:
		last_lap_time = current_lap_time
		current_lap_time = 0.0
