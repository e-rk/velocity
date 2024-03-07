extends Control

@onready var lap_number = %LapNumber

@export var config := SingleRaceRules.new():
	set(value):
		config = value
		lap_number.value = config.num_laps
	get:
		return config


func _on_lap_number_value_changed(value):
	config.num_laps = value
