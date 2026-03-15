extends Resource
class_name CarColorList

@export var colors: Array[CarColorSet]

static func from_list(list: Array[CarColorSet]):
	var ret := CarColorList.new()
	ret.colors = list
	return ret
