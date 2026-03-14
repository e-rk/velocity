extends Resource
class_name CarColorSet

@export var primary: Color
@export var secondary: Color
@export var driver: Color
@export var interior: Color

static func from_colors(primary_color: Color,
						secondary_color: Color,
						driver_color: Color,
						interior_color: Color) -> CarColorSet:
	var ret = CarColorSet.new()
	ret.primary = primary_color
	ret.secondary = secondary_color
	ret.driver = driver_color
	ret.interior = interior_color
	return ret
