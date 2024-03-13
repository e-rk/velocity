class_name RaceInterface
extends Node

@onready var race_state_context = $RaceStateContext

signal race_finished
signal race_waiting_for_players


func end_race():
	race_state_context.end_race()


func spawn_player(player_id, player_config: PlayerConfig):
	race_state_context.spawn_player(player_id, player_config)


func despawn_player(player_id: int):
	race_state_context.despawn_player(player_id)


func set_config(game_config: GameConfig):
	race_state_context.set_config(game_config)


func start_race():
	race_state_context.start_race()


func _on_race_state_ended_entered():
	self.race_finished.emit()


func _on_race_state_waiting_for_players_entered():
	self.race_waiting_for_players.emit()
