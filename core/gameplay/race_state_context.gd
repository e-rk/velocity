extends StateMachine

@onready var player_container = $PlayerContainer

var race_logic = null
var track = null


func end_race():
	self.current_state.end_race()


func spawn_player(player_id, player_config: PlayerConfig):
	self.current_state.spawn_player(player_id, player_config)


func despawn_player(player_id):
	var player = self.player_container.find_child(str(player_id), false, false)
	self.player_container.remove_child(player)
	player.queue_free()


func set_config(game_config: GameConfig):
	self.current_state.set_config(game_config)


func start_race():
	self.current_state.start_race()
