extends Control

signal host_mode_set(lobby_name: String, port: int)

@onready var host_mode: OptionButton = %HostMode
@onready var host_dialog: AcceptDialog = %HostGameDialog
@onready var lobby_name: LineEdit = %LobbyName
@onready var host_port: SpinBox = %HostPort


func _ready():
	self.host_dialog.add_cancel_button("Cancel")


func _on_pressed():
	self.host_dialog.show()


func _on_host_game_dialog_confirmed():
	self.host_mode_set.emit(lobby_name.text, host_port.value)
