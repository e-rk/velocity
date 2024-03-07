class_name BaseRaceLogic
extends Node

@export var track: RaceTrack

signal race_finished


func spawn_player(track: RaceTrack, data: PlayerConfig):
	pass


func player_spawned(track: RaceTrack, data: PlayerConfig):
	pass


func setup(track: RaceTrack):
	pass


func reposition_allowed() -> bool:
	return true
