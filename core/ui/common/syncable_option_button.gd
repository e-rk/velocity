class_name SyncableOptionButton
extends OptionButton

@export var selected_uuid: String:
	set(value):
		self._set_by_uuid(value)
		selected_uuid = value
		self.syncable_item_selected.emit(selected_uuid)
	get:
		return selected_uuid

var id = 0
var uuid_to_id_map = {}

signal syncable_item_selected


func _ready():
	self.item_selected.connect(self._on_item_selected)


func add_syncable_item(label: String, uuid: String):
	if self.uuid_to_id_map.has(uuid):
		printerr("Duplicate item unique name: ", uuid)
	self.add_item(label, self.id)
	self.set_item_metadata(-1, uuid)
	self.uuid_to_id_map[uuid] = id
	self.id += 1
	self.selected_uuid = self.get_selected_metadata()


func remove_syncable_item(uuid: String):
	var id = self.uuid_to_id_map[uuid]
	var idx = self.get_item_index(id)
	self.uuid_to_id_map.erase(uuid)


func _set_by_uuid(uuid: String):
	if not uuid_to_id_map.has(uuid):
		# TODO: emit signal maybe?
		return
	var id = self.uuid_to_id_map[uuid]
	var idx = self.get_item_index(id)
	self.select(idx)


func set_by_uuid(uuid: String):
	self.selected_uuid = uuid

func get_selected_uuid() -> String:
	return self.selected_uuid

func _on_item_selected(idx):
	var id = self.get_item_id(idx)
	self.selected_uuid = self.get_selected_metadata()
