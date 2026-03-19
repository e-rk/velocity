extends "res://core/gameplay/player_spectator.gd"

@export var race_laps: int = 2

@onready var lap_timer: Control = $PlayerUI/HSplitContainer/LapTimer
@onready var race_leaderboard: RaceLeaderboard = $PlayerUI/RaceLeaderboard

var player_positions: Array[RaceLeaderboard.PlayerPosition]


func _racer_distance(racer: Racer) -> float:
	var track = get_tree().get_first_node_in_group(&"Track")
	return racer.laps * track.nav_path.get_track_length() + racer.player.position_along_track


func _update_player_positions(current_racer: Racer) -> int:
	var racers: Array[Racer]
	racers.assign(get_tree().get_nodes_in_group(&"Racers"))
	if player_positions.size() != racers.size():
		player_positions.clear()
		for _p in racers:
			player_positions.append(RaceLeaderboard.PlayerPosition.new())
	racers.sort_custom(func (a: Racer, b: Racer) -> bool: return _racer_distance(a) > _racer_distance(b))
	for i in racers.size():
		var racer := racers[i]
		var data := player_positions[i]
		var distance := _racer_distance(racer) - _racer_distance(current_racer)
		data.name = racer.player.player_name
		data.distance = distance / current_racer.average_speed
		data.color = racer.player.car.color.primary
	return racers.find(current_racer) + 1


func _update_ui(player: Player) -> void:
	var racer := player.get_node_or_null("Racer") as Racer
	ui.set_laps(min(racer.laps, self.race_laps), self.race_laps)
	lap_timer.set_current_time(racer.current_lap_time())
	lap_timer.set_last_time(racer.get_best_lap_time())


func _on_position_update_timer_timeout() -> void:
	var racer := spectated_player.get_node_or_null("Racer") as Racer
	var current_position := self._update_player_positions(racer)
	race_leaderboard.update(player_positions, current_position)
