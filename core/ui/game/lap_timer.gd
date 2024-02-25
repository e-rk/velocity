extends Control

@onready var current_time: Label = %CurrentTime
@onready var last_time: Label = %LastTime


func float_to_time(value: float) -> Dictionary:
	var rounded = roundi(value * 100)
	var msec = rounded % 100
	var sec = (rounded / 100) % 60
	var mins = rounded / 6000
	return {
		"minutes": mins,
		"seconds": sec,
		"milliseconds": msec,
	}


func float_to_format(value: float) -> String:
	var time = float_to_time(value)
	return "%02d:%02d:%02d" % [time["minutes"], time["seconds"], time["milliseconds"]]


func set_current_time(value: float):
	current_time.text = float_to_format(value)


func set_last_time(value: float):
	last_time.text = float_to_format(value)
