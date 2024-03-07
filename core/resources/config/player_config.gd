class_name PlayerConfig
extends Resource

@export var player_name: String
@export var car_uuid: String


func serialize() -> Dictionary:
	return {
		"player_name": self.player_name,
		"car_uuid": self.car_uuid,
	}


static func deserialize(data: Dictionary) -> PlayerConfig:
	var result = PlayerConfig.new()
	result.player_name = data["player_name"]
	result.car_uuid = data["car_uuid"]
	return result
