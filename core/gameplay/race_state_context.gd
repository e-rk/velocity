extends StateMachine

@onready var controller: RacerController = $RacerController

var race_logic = null
var track = null


func end_race():
	self.current_state.end_race()


func spawn_player(player_config: PlayerConfig):
	self.current_state.spawn_player(player_config)


func set_config(game_config: GameConfig):
	self.current_state.set_config(game_config)


func start_race():
	self.current_state.start_race()
