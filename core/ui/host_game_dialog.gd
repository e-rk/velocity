extends PopupPanel

signal host_mode_set

@onready var host_mode: OptionButton = %HostMode
@onready var lobby_name: LineEdit = %LobbyName

func _on_host_button_pressed():
	self.host_mode_set.emit(lobby_name.text)
	self.hide()


func _on_cancel_button_pressed():
	self.hide()
