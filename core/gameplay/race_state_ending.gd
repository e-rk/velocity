extends RaceState

@onready var race_state_ended = $"../RaceStateEnded"
@onready var timer = $Timer
@onready var ending_message: Label = %EndingMessage


func enter():
	timer.start()
	context.controller.steering_enabled = false
	ending_message.show()
	super()


func leave():
	timer.stop()
	ending_message.hide()
	super()


func _process(_delta):
	var time_left = ceil(timer.time_left)
	ending_message.text = "Ending in %d" % time_left


func _on_timer_timeout():
	context.set_state(race_state_ended)
