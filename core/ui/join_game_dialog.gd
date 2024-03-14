extends Control

signal server_selected(address: String, port: int)

@onready var server_address = %ServerAddress
@onready var server_port = %ServerPort
@onready var server_list = %ServerList
@onready var join_dialog = %JoinGameDialog


func _ready():
	self.join_dialog.add_cancel_button("Cancel")
	self.server_list.set_item_metadata(0, "localhost")


func _on_server_list_item_selected(index):
	var metadata = server_list.get_item_metadata(index)
	server_address.text = metadata


func _on_join_game_dialog_confirmed():
	self.server_selected.emit(server_address.text, server_port.value)


func _on_pressed():
	self.join_dialog.show()
