extends RaceState

@onready var race_state_start_countdown = $"../RaceStateStartCountdown"
@onready var spawner = $MultiplayerSpawner


func _ready():
	spawner.spawn_function = self._spawn_player_internal


func spawn_player(player_config: PlayerConfig):
	var serialized = player_config.serialize()
	spawner.spawn(serialized)


func start_race():
	context.set_state(race_state_start_countdown)


func _spawn_player_internal(data: Dictionary) -> Node:
	var player = PlayerConfig.deserialize(data)
	var ret = context.race_logic.spawn_player(context.track, player)
	return ret
