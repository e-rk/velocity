extends Window

@onready var debug: CheckButton = $VBoxContainer/PathDebug
@onready var path_select: OptionButton = $VBoxContainer/PathSelect

var players_in_list: Array[AIPlayer]

func csv_make_header(header: Array[String]) -> String:
	var ret = ""
	for s in header:
		ret += s + ","
	return ret


func _open_track_file() -> FileAccess:
	return FileAccess.open("/home/rafal/godot2/logs/track_data.csv", FileAccess.WRITE)


func _open_avoidance_file() -> FileAccess:
	return FileAccess.open("/home/rafal/godot2/logs/avoidance_data.csv", FileAccess.WRITE)


func snapshot_track():
	var track := get_tree().get_first_node_in_group(&"Track") as RaceTrack
	if track:
		var waypoints = track.nav_path
		var file = self._open_track_file()
		file.store_csv_line(
			PackedStringArray(
				[
					"Node",
					"X", "Y", "Z",
					"LeftWall", "RightWall",
					"NormalX", "NormalY", "NormalZ",
				]))
		for i in waypoints.points.size():
			var point = waypoints.points[i]
			var data = waypoints.point_data[i]
			var left_wall = waypoints.left_walls[i]
			var right_wall = waypoints.right_walls[i]
			file.store_csv_line(
				PackedStringArray(
					[
						str(i),
					 	str(point.x), str(point.y), str(point.z),
					 	str(left_wall), str(right_wall),
						str(data.normal.x), str(data.normal.y), str(data.normal.z),
					]))


func snapshot_avoidance():
	var players: Array[Player]
	players.assign(get_tree().get_nodes_in_group(&"Players"))
	var file = self._open_avoidance_file()
	file.store_csv_line(PackedStringArray(["X", "Y", "Z", "offset"]))
	for player in players:
		var point = player.car.global_position
		file.store_csv_line(PackedStringArray([str(point.x), str(point.y), str(point.z), str(player.current_node_idx)]))

func snapshot_all():
	self.snapshot_track()
	self.snapshot_avoidance()


func _on_snapshot_track_pressed() -> void:
	self.snapshot_track()


func _on_snapshot_avoidance_pressed() -> void:
	self.snapshot_avoidance()


func _physics_process(delta: float) -> void:
	if debug.button_pressed:
		var ai_player: Array[AIPlayer]
		ai_player.assign(get_tree().get_nodes_in_group(&"AiPlayers"))
		for player in ai_player:
			var algo = player.drive_algo
			if player.disable_steering or not algo.debug_draw:
				continue
			var translated = PackedVector3Array()
			var pts = algo.waypoints.points
			for i in algo.offsets.size():
				var idx = i % pts.size()
				algo.optimize_mtx.lock()
				var t = algo.waypoints.offset_vector_at_idx(idx, algo.offsets, pts[idx])
				translated.append(t)
				algo.optimize_mtx.unlock()
			DebugDraw3D.draw_arrow_path(translated, Color.PINK, 0.4, true, delta)


func _on_option_button_item_selected(index: int) -> void:
	var ai_player: Array[AIPlayer]
	ai_player.assign(get_tree().get_nodes_in_group(&"AiPlayers"))
	var id = self.path_select.get_item_id(index)
	for i in players_in_list.size():
		var player = players_in_list[i]
		if i == id:
			player.drive_algo.debug_draw = true
		else:
			player.drive_algo.debug_draw = false


func _on_timer_timeout() -> void:
	var ai_player: Array[AIPlayer]
	ai_player.assign(get_tree().get_nodes_in_group(&"AiPlayers"))
	if ai_player != players_in_list:
		self.path_select.clear()
		self.path_select.add_item("All")
		self.path_select.add_separator()
		for i in ai_player.size():
			var player = ai_player[i]
			self.path_select.add_item(player.name, i)
	players_in_list = ai_player


func _on_reload_shaders_pressed() -> void:
	OptimizerServer.reload_shaders()
