extends Control
class_name MainLobby

@export var players: Dictionary:
	set(value):
		players = value
		self._update_player_list(players)
	get:
		return players

@onready var player_list = %PlayerList
@onready var player_name = %PlayerName
@onready var track_picker = %TrackPicker
@onready var car_picker = %CarPicker
@onready var disconnect_button = %Disconnect

var race_rules: RaceRules
var track_config: TrackConfig


func _ready():
	multiplayer.peer_connected.connect(self._on_peer_connected)
	multiplayer.peer_disconnected.connect(self._on_peer_disconnected)
	multiplayer.connected_to_server.connect(self._on_connected_to_server)
	multiplayer.connection_failed.connect(self._on_connection_failed)


func _update_player_list(players: Dictionary):
	player_list.clear()
	for id in players:
		var player = players[id]
		var content = player["name"] + " " + player["car"]
		player_list.add_item(content, null, false)


@rpc("any_peer", "call_local", "reliable")
func send_player_data(name: String, car: String):
	var id = multiplayer.get_remote_sender_id()
	if id == 0:
		id = 1
	var players = self.players
	players[id] = {
		"name": name,
		"car": car,
	}
	self.players = players


func remove_player_data(id: int):
	var players = self.players
	players.erase(id)
	self.players = players


@rpc("any_peer", "call_remote", "reliable")
func set_car(car: String):
	var id = multiplayer.get_remote_sender_id()
	self.players[id]["car"] = car


@rpc("authority", "call_local", "reliable")
func start_game():
	print("Starting game not implemented")


func send_current_player_data():
	self.send_player_data.rpc(player_name.text, car_picker.selected_car)


func _on_disconnect_dialog_confirmed():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func _on_join_game_dialog_server_selected(server_address: String):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(server_address, 9999)
	if err == OK:
		print("Joining game %s..." % server_address)
		multiplayer.multiplayer_peer = peer
	if err != OK:
		print("Join error: " + str(err))


func _on_host_game_dialog_host_mode_set(lobby_name: String):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(9999)
	if err == OK:
		print("Lobby %s created" % lobby_name)
		multiplayer.multiplayer_peer = peer
	if err != OK:
		print("Host error: " + str(err))
	self.send_current_player_data()


func _on_car_picker_car_selected():
	self.send_current_player_data()


func _on_track_picker_track_selected(config: TrackConfig):
	self.track_config = config


func _on_start_race_pressed():
	start_game.rpc()


func _on_player_name_text_changed(new_text):
	self.send_current_player_data()


func _on_peer_connected(id):
	print("Connected: %d" % id)
	disconnect_button.disabled = false


func _on_peer_disconnected(id):
	print("Disconnected: %d" % id)
	self.remove_player_data(id)


func _on_connected_to_server():
	print("Connected to server")
	disconnect_button.disabled = false
	self.send_current_player_data()


func _on_connection_failed():
	print("Connection failed")


func _on_rule_configurator_rules_changed(rules: RaceRules):
	race_rules = rules
