class_name SingleRace
extends BaseRaceLogic

@export var rules: SingleRaceRules

@onready var spectator = $PlayerSpectator


func spawn_player(track: RaceTrack, data: PlayerConfig):
	var car_data = CarDB.get_car_by_uuid(data.car_uuid)
	var car = load(car_data.path).instantiate()
	var racer = Racer.new(car)
	racer.add_to_group(&"Racers")
	racer.add_to_group(&"SpectatedRacer")
	racer.add_to_group(&"ControlledRacer")
	car.global_transform = track.get_spawn_transform(0)
	return racer


func _ready():
	var waypoints = self.track.get_waypoints()
	self.spectator.set_waypoints(waypoints)
	self.spectator.race_laps = self.rules.num_laps


func _check_end_conditions(racers):
	if racers.all(func(x): return x.laps > rules.num_laps):
		self.race_finished.emit()


func _physics_process(delta):
	var racers = get_tree().get_nodes_in_group(&"Racers")
	for racer in racers:
		var progress = self.track.progress_along_track(racer.car.global_position)
		var prev_progress = racer.track_progress
		if prev_progress > 0.9 and progress < 0.1:
			racer.laps += 1
		elif prev_progress < 0.1 and progress > 0.9:
			racer.laps -= 1
		racer.track_progress = progress
	self._check_end_conditions(racers)
