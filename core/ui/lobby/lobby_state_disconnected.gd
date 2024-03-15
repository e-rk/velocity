extends State

signal start_requested


func enter():
	context.disconnect_button.disabled = true
	context.join_dialog.disabled = false
	context.host_dialog.disabled = false
	context.start_race_button.disabled = false
	context.ready_button.disabled = true
	context.lobby_button.disabled = true
	context.game_config.enable()
	context.lobby_window.hide()
	context.player_container.clear()
	context.player_container.register_player(1)
	super()


func leave():
	context.disconnect_button.disabled = false
	context.join_dialog.disabled = true
	context.host_dialog.disabled = true
	context.ready_button.disabled = false
	context.lobby_button.disabled = false
	super()


func disconnected():
	assert(false, "Disconnected in invalid state")


func joined():
	context.set_state(context.lobby_state_joined)


func hosting():
	context.set_state(context.lobby_state_hosting)


func host(lobby_name: String, port: int):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port)
	if err == OK:
		print("Lobby %s created" % lobby_name)
		multiplayer.multiplayer_peer = peer
		context.set_state(context.lobby_state_hosting)
	else:
		print("Host error: " + str(err))


func join(address: String, port: int):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(address, port)
	if err == OK:
		print("Joining game %s..." % address)
		multiplayer.multiplayer_peer = peer
	if err != OK:
		print("Join error: " + str(err))


func disconnect_from_game():
	pass


func peer_connected(id: int):
	assert(false, "Peer connected in disconnected state")


func peer_disconnected(id: int):
	assert(false, "Peer disconnected in disconnected state")


func game_started():
	pass


func game_ended():
	pass


func start_game():
	self.start_requested.emit()
