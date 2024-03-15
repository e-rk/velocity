class_name PlayerDataContainer
extends Node

signal player_config_changed(node: PlayerData)
signal player_data_removed(node: PlayerData)
signal local_player_data_created(node: PlayerData)
signal remote_player_data_created(node: PlayerData)
signal all_players_ready
signal all_players_standby
signal all_players_in_game

const data_scene = preload("res://core/multiplayer/player_data.tscn")

@onready var players = $Players


func _find_player(id: int) -> PlayerData:
	return players.find_child(str(id), false, false)


func register_player(id: int):
	var node = data_scene.instantiate()
	node.name = str(id)
	players.add_child(node, true)
	if id == multiplayer.get_unique_id():
		self.local_player_data_created.emit(node)
	else:
		self.remote_player_data_created.emit(node)
	node.player_data_changed.connect(self._on_config_changed.bind(node))


func unregister_player(id: int):
	var node = self._find_player(id)
	if node:
		self.players.remove_child(node)
		self.player_data_removed.emit(node)
		node.queue_free()


func clear():
	for node in players.get_children():
		self.unregister_player(node.get_player_id())


func get_local_player_data() -> PlayerData:
	return self._find_player(multiplayer.get_unique_id())


func _on_multiplayer_spawner_spawned(node):
	if not node.name.is_valid_int():
		return
	var id = node.name.to_int()
	if id == multiplayer.get_unique_id():
		self.local_player_data_created.emit(node)
	else:
		self.remote_player_data_created.emit(node)
	node.player_data_changed.connect(self._on_config_changed.bind(node))


func _on_multiplayer_spawner_despawned(node):
	self.player_data_removed.emit(node)


func _on_config_changed(node: PlayerData):
	self.player_config_changed.emit(node)
	self._do_status_checks()


func _do_status_checks():
	var status_sig_map = {
		Constants.PlayerStatus.IN_LOBBY_READY: self.all_players_ready,
		Constants.PlayerStatus.IN_GAME_STANDBY: self.all_players_standby,
		Constants.PlayerStatus.IN_GAME_PLAYING: self.all_players_in_game,
	}
	for status in status_sig_map.keys():
		if self.players.get_children().all(func(x): return x.player_status == status):
			status_sig_map[status].emit()


func check_all_players_ready():
	return self.players.get_children().all(
		func(x): return x.player_status == Constants.PlayerStatus.IN_LOBBY_READY
	)


func get_players() -> Array:
	return self.players.get_children()
