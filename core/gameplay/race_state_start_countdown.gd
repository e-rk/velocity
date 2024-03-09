extends RaceState

@onready var race_state_in_progress = $"../RaceStateInProgress"
@onready var timer = $Timer
@onready var starting_message: Label = %StartingMessage


func enter():
	timer.start()
	starting_message.show()
	super()


func leave():
	timer.stop()
	starting_message.hide()
	super()


func _process(_delta):
	var time_left = ceil(timer.time_left)
	starting_message.text = "Starting in %d" % time_left


func _on_timer_timeout():
	context.set_state(race_state_in_progress)
