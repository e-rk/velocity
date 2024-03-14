extends Button

@onready var dialog = $DisconnectDialog

signal disconnect_confirmed


func _on_pressed():
	dialog.show()


func _on_disconnect_dialog_confirmed():
	self.disconnect_confirmed.emit()
