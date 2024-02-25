extends HBoxContainer
class_name TrackPicker

signal track_selected
@export var selected_track: String = "":
	set(value):
		selected_track = value
		self._on_selection_externally_changed()
	get:
		return selected_track

@export var disabled: bool = false:
	set(value):
		disabled = value
		self._on_disable_state_changed()
	get:
		return disabled

@onready var track_selection: OptionButton = $TrackSelection


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


func _on_disable_state_changed():
	for i in track_selection.item_count:
		track_selection.set_item_disabled(i, self.disabled)


func _on_selection_externally_changed():
	for i in track_selection.item_count:
		var track = track_selection.get_item_metadata(i)
		if track == self.selected_track:
			track_selection.selected = i
			break
