extends Button

@onready var join_dialog = %JoinGameDialog


func _on_pressed():
	join_dialog.show()
