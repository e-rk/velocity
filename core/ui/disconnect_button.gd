extends Button

@onready var dialog = $DisconnectDialog

func _on_pressed():
	dialog.show()
