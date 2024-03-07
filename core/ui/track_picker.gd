extends HBoxContainer
class_name TrackPicker

@export var config: TrackConfig = TrackConfig.new()

@onready var track_selection: SyncableOptionButton = $TrackSelection

signal track_selected
signal track_not_found


func _ready():
	TrackDB.database_updated.connect(self._on_track_database_updated)


func _on_track_database_updated():
	for track in TrackDB.tracks.values():
		track_selection.add_syncable_item(track.name, track.uuid)


func _on_track_selection_syncable_item_selected(uuid):
	self.config.track_uuid = uuid
	self.track_selected.emit(self.config.duplicate(true))
