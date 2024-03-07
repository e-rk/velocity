extends Node

var builtin_modes = {
	SingleRaceRules.mode_uuid(): SingleRaceRules,
	PursuitRules.mode_uuid(): PursuitRules,
}

func get_mode_by_uuid(uuid: StringName) -> GDScript:
	return builtin_modes[uuid]

func get_all_modes() -> Array:
	return builtin_modes.values()
