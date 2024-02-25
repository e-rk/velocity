class_name Constants
extends Node

enum CollisionLayer {
	TRACK_ROAD = 0,
	TRACK_WALLS = 1,
	TRACK_CEILING = 2,
	RACERS = 3,
	TRAFFIC = 4,
	POLICE = 5,
}

static func collision_layer_to_mask(layers: Array[CollisionLayer]) -> int:
	var mask = 0
	for layer in layers:
		mask |= 1 << layer
	return mask
