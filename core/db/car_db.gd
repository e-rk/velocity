extends Node
class_name CarDatabase

signal database_updated

@onready var watcher = %DirectoryWatcher

var cars: Dictionary = {}


class CarData:
	var name: String
	var path: String
	var uuid: String


func get_car_by_uuid(uuid: String) -> CarData:
	return cars[uuid]


func _on_directory_watcher_content_changed():
	var cars = {}
	for file in watcher.files:
		var path = "%s/%s/%s.tscn" % [watcher.directory, file, file]
		var uuid = path
		var car = CarData.new()
		car.name = file
		car.path = path
		car.uuid = uuid
		cars[uuid] = car
	self.cars = cars
	self.database_updated.emit()
