extends PanelContainer
class_name RaceLeaderboard

@onready var container: GridContainer = %PlayerContainer
@onready var player_position: Label = %PlayerPosition

class RowData:
	var name: String
	var label: Label
	var distance: Label

class PlayerPosition:
	var name: String
	var color: Color
	var distance: float

var player_rows: Array[RowData]


func _ready() -> void:
	self._clear_all()


func float_to_time(value: float) -> Dictionary:
	var rounded = roundi(value * 100)
	var msec = rounded % 100
	var sec = (rounded / 100) % 60
	var mins = rounded / 6000
	return {
		"minutes": mins,
		"seconds": sec,
		"milliseconds": msec,
	}


func float_to_format(value: float) -> String:
	var time = float_to_time(value)
	return "%02d:%02d:%02d" % [time["minutes"], time["seconds"], time["milliseconds"]]


func update(data: Array[PlayerPosition], position: int) -> void:
	var cnt := data.size()
	if player_rows.size() != cnt:
		self._reconstruct(cnt)
	for i in cnt:
		var d := data[i]
		var row := player_rows[i]
		var color := d.color
		# Limits for visual clarity
		color.v = max(0.35, color.v)
		color.s = min(0.75, color.s)
		row.label.text = d.name
		row.label.add_theme_color_override(&"font_color", color)
		row.distance.text = float_to_format(abs(d.distance))
		if d.distance < 0.0:
			row.distance.add_theme_color_override(&"font_color", Color.GREEN_YELLOW)
		elif d.distance > 0.0:
			row.distance.add_theme_color_override(&"font_color", Color.RED)
		elif is_zero_approx(d.distance):
			row.distance.text = "-------------"
			row.distance.add_theme_color_override(&"font_color", Color.GRAY)
	self.player_position.text = "%d/%d" % [position, data.size()]


func _reconstruct(cnt: int) -> void:
	self._clear_all()
	for i in cnt:
		var row := RowData.new()
		row.label = Label.new()
		row.distance = Label.new()
		self.player_rows.append(row)
		self.container.add_child(row.label)
		self.container.add_child(row.distance)


func _clear_all() -> void:
	for child in container.get_children():
		child.queue_free()
	self.player_rows.clear()
