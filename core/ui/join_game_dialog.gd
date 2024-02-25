extends PopupPanel

signal server_selected

@onready var server_address = %ServerAddress
@onready var server_list = %ServerList


func _ready():
	server_list.set_item_metadata(0, "localhost")


func _on_cancel_button_pressed():
	self.hide()


func _on_join_button_pressed():
	self.server_selected.emit(server_address.text)
	self.hide()


func _on_server_list_item_selected(index):
	var metadata = server_list.get_item_metadata(index)
	server_address.text = metadata
