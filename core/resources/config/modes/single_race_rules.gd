class_name SingleRaceRules
extends RaceRules

@export var num_laps: int = 2


static func mode_uuid() -> StringName:
	return &"9adcac35-c1c7-45d1-89f9-38d0eefe959f"


static func mode_display_name() -> StringName:
	return &"Single race"


static func get_namespace() -> String:
	return "single_race"


static func get_config_interface() -> Control:
	return preload("res://core/ui/config/modes/single_race_configurator.tscn").instantiate()


func get_race_logic() -> Node:
	var node = preload("res://core/gameplay/modes/single_race.tscn").instantiate()
	node.rules = self
	return node
