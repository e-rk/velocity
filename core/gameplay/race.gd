extends Node

@export var config: GameConfig:
	set(value):
		config = value
		self.rules_changed.emit()
	get:
		return config

@onready var spawner = $MultiplayerSpawner
@onready var controller = $RacerController

var race_logic: BaseRaceLogic = null
var track = null

signal rules_changed
signal race_finished


func _ready():
	spawner.spawn_function = self._spawn_player_internal


func _spawn_player_internal(data: Dictionary) -> Node:
	var player = PlayerConfig.deserialize(data)
	var ret = race_logic.spawn_player(self.track, player)
	controller = ret.car
	return ret


func spawn_player(player: PlayerConfig):
	var serialized = player.serialize()
	spawner.spawn(serialized)


func _set_track(config: TrackConfig):
	var track_data = TrackDB.get_track_by_uuid(config.track_uuid)
	self.track = load(track_data.path).instantiate()
	self.add_child(self.track, true)


func _on_rules_changed():
	var rules = self.config.rules
	self._set_track(self.config.track)
	race_logic = rules.get_race_logic()
	race_logic.track = self.track
	race_logic.name = "RaceLogic"
	race_logic.race_finished.connect(self._on_race_finished)
	self.add_child(race_logic, true)


func _on_racer_controller_reposition_requested(car: Car):
	if !race_logic.reposition_allowed():
		return
	car.transform = self.track.get_closest_transform(car.global_position)
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO


func _on_race_finished():
	self.race_finished.emit()
