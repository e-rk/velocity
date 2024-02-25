extends Control

@onready var kph_meter = %KphMeter


func mps_to_kph(meters_per_second: float) -> float:
	return meters_per_second * 3.6


func mps_to_kph_round(meters_per_second: float) -> int:
	return round(mps_to_kph(meters_per_second))


func set_speed(speed: float):
	kph_meter.text = str(mps_to_kph_round(speed))
