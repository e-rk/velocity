extends State

signal start_requested

@onready var confirm_start = $ConfirmStart


func enter():
	context.start_race_button.disabled = false
	context.game_config.enable()
	context.lobby_window.show()
	super()


func leave():
	super()


func disconnected():
	context.set_state(context.lobby_state_disconnected)


func joined():
	assert(false, "Joined in invalid state")


func hosting():
	assert(false, "Started hosting in invalid state")


func join(address: String, port: int):
	pass


func disconnect_from_game():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	context.set_state(context.lobby_state_disconnected)


func peer_connected(id: int):
	context.player_container.register_player(id)


func peer_disconnected(id: int):
	context.player_container.unregister_player(id)


func start_game():
	if not context.player_container.check_all_players_ready():
		self.confirm_start.show()
	else:
		self.start_requested.emit()


func game_started():
	context.lobby_window.hide()


func game_ended():
	context.lobby_window.show()


func _on_confirm_start_confirmed():
	self.start_requested.emit()
