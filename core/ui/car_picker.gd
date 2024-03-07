extends HBoxContainer
class_name CarPicker

signal car_selected
@export var selected_car: String = ""

@onready var car_selection: OptionButton = $CarSelection


func _ready():
	CarDB.database_updated.connect(self._on_car_database_updated)


func _on_car_database_updated():
	car_selection.clear()
	var idx = 0
	for car in CarDB.cars.values():
		car_selection.add_item(car.name)
		car_selection.set_item_metadata(idx, car.path)
		idx += 1
	car_selection.select(0)
	self.selected_car = car_selection.get_selected_metadata()


func _on_car_selection_item_selected(index):
	selected_car = car_selection.get_item_metadata(index)
	self.car_selected.emit()
