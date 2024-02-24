extends HBoxContainer
class_name TrackPicker

signal track_selected
@export var selected_track: String = ""

@onready var track_selection = $TrackSelection

func _ready():
	TrackDB.database_updated.connect(self._on_track_database_updated)


func _on_track_database_updated():
	var idx = 0
	for track in TrackDB.tracks.values():
		track_selection.add_item(track.name)
		track_selection.set_item_metadata(idx, track.path)
		idx += 1
	track_selection.select(0)


func _on_track_selection_item_selected(index):
	selected_track = track_selection.get_item_metadata(index)
	self.track_selected.emit()
