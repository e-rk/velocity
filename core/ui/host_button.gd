extends Button

@onready var host_dialog = $HostGameDialog


func _on_pressed():
	self.host_dialog.show()
