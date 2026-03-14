class_name BaseRaceLogic
extends Node

@export var track: RaceTrack

signal race_finished


func get_spawn_position(player: Player) -> Transform3D:
	return Transform3D.IDENTITY


func player_spawned(player: Player):
	pass


func ai_player_spawned(player: AIPlayer):
	pass


func start():
	pass


func reposition_allowed() -> bool:
	return true


func _physics_process(delta: float) -> void:
	var players: Array[Player]
	players.assign(get_tree().get_nodes_in_group(&"Players"))
	for player in players:
		var node_idx = self.track.nav_path.get_closest_point(player.car.global_position, player.current_node_idx)
		var progress = self.track.nav_path.get_distance_along_track(node_idx)
		player.current_node_idx = node_idx
		player.position_along_track = progress
