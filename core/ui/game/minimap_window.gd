extends Control
class_name MinimapWindow

@onready var minimap: Minimap = %MinimapBare
@onready var laps: Label = %Laps


func set_minimap_rotation(rotation: float):
	minimap.rotation = rotation


func set_minimap_center(point: Vector3):
	minimap.set_minimap_center(point)


func set_players(players: Array):
	minimap.players = players


func set_waypoints(waypoints: Array):
	minimap.set_waypoints(waypoints)


func set_laps(racer_laps: int, overall_laps: int):
	laps.text = "%d/%d" % [racer_laps, overall_laps]
