class_name SingleRace
extends BaseRaceLogic

@export var rules: SingleRaceRules

@onready var spectator = $PlayerSpectator

signal racer_finished(racer: Player)

var players_spawned := 0


func get_spawn_position(_player: Player) -> Transform3D:
	const SPAWN_DISTANCE := 10.0
	const LATERAL_OFFSET := 2.0
	var distance := -self.players_spawned * SPAWN_DISTANCE
	var direction := 1.0 if self.players_spawned % 2 == 0 else -1.0
	var position := self.track.nav_path.advance_by_distance_smooth(0.0, self.track.nav_path.points[0], distance)
	var orientation := self.track.nav_path.orientations[0]
	var shifted := position + orientation * Vector3(direction * LATERAL_OFFSET, 0, 0)
	self.players_spawned += 1
	return Transform3D(orientation, shifted)


func player_spawned(player: Player):
	var racer = preload("res://core/gameplay/racer.tscn").instantiate()
	player.add_child(racer, true)
	racer.owner = player
	if player.is_local():
		player.add_to_group(&"SpectatedPlayer")


func start():
	var players: Array[Player]
	players.assign(get_tree().get_nodes_in_group(&"Players"))
	for player in players:
		player.disable_steering = false
	var racers: Array[Racer]
	racers.assign(get_tree().get_nodes_in_group(&"Racers"))
	for racer in racers:
		racer.start_timer()


func _ready():
	super()
	var waypoints = self.track.get_waypoints()
	self.spectator.set_waypoints(waypoints)
	self.spectator.race_laps = self.rules.num_laps
	if self.get_multiplayer_authority() != multiplayer.get_unique_id():
		self.set_physics_process(false)


func _check_end_conditions(racers):
	if racers.all(func(x): return x.laps > rules.num_laps):
		self.race_finished.emit()


func _physics_process(delta):
	super(delta)
	var racers: Array[Racer] = []
	racers.assign(get_tree().get_nodes_in_group(&"Racers"))
	for racer in racers:
		var progress = racer.player.position_along_track / self.track.nav_path.get_track_length()
		var prev_progress = racer.track_progress
		if prev_progress > 0.9 and progress < 0.1:
			racer.laps += 1
			if racer.laps > racer.max_laps:
				racer.capture_time()
			racer.max_laps = max(racer.laps, racer.max_laps)
		elif prev_progress < 0.1 and progress > 0.9:
			racer.laps -= 1
		racer.track_progress = progress
	self._check_end_conditions(racers)
