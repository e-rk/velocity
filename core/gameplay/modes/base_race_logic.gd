class_name BaseRaceLogic
extends Node

@export var track: RaceTrack

signal race_finished

var track_set := false

func _ready() -> void:
	pass


func _exit_tree() -> void:
	OptimizerServer.clear_waypoints()


func get_spawn_position(_player: Player) -> Transform3D:
	return Transform3D.IDENTITY


func player_spawned(_player: Player):
	pass


func ai_player_spawned(_player: AIPlayer):
	pass


func start():
	pass


func reposition_allowed() -> bool:
	return true


func _physics_process(_delta: float) -> void:
	if not track_set:
		self.track.nav_path._measure_walls()
		OptimizerServer.set_waypoints(track.nav_path)
		track_set = true
	var players: Array[Player]
	players.assign(get_tree().get_nodes_in_group(&"Players"))
	for player in players:
		var node_idx = self.track.nav_path.get_closest_point(player.car.global_position, player.current_node_idx)
		var progress = self.track.nav_path.get_distance_along_track(node_idx)
		player.current_node_idx = node_idx
		player.position_along_track = progress
