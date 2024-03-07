extends Control

@onready var lap_number = %LapNumber
@onready var ticket_count = %TicketCount

@export var config := PursuitRules.new():
	set(value):
		if not value:
			return
		config = value
		lap_number.value = config.num_laps
		ticket_count.value = config.num_tickets
	get:
		return config


func _on_lap_number_value_changed(value):
	config.num_laps = value


func _on_ticket_count_value_changed(value):
	config.num_tickets = value
