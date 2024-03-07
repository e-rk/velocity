class_name RaceRules
extends Resource


static func mode_uuid() -> StringName:
	return &""


static func mode_display_name() -> StringName:
	return &"Unknown mode"


static func get_namespace() -> String:
	return "unknown_mode"


static func get_config_interface() -> Control:
	return null


func get_race_logic() -> Node:
	return null
