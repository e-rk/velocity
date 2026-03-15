class_name Minimap
extends Control


@export var players: Array = []:
	set(value):
		players = value
		self.refresh()

@export var minimap_scale: float = 300.0

var track_offset := Vector2.ZERO
var center_point := Vector2.ZERO
var track_centroid := Vector2.ZERO
var normalization_factor := 1.0
var scaled_track_points := PackedVector2Array()


@onready var track_layer: Control = $TrackLayer
@onready var player_layer: Control = $PlayerLayer


func to_vec2(point: Vector3) -> Vector2:
	return Vector2(-point.x, -point.z)


func refresh():
	self.player_layer.queue_redraw()


func set_waypoints(points: Array):
	var pts: Array = points.map(to_vec2)

	var sum := Vector2.ZERO
	for p: Vector2 in pts:
		sum += p
	self.track_centroid = pts.reduce(func(acc: Vector2, x: Vector2): return acc + x) / pts.size()
	var centered = pts.map(func(p: Vector2) -> Vector2: return p - self.track_centroid)

	self.normalization_factor = centered.reduce(func(acc, p): return max(acc, p.length()), 0.0)

	self.scaled_track_points.clear()
	for p in centered:
		self.scaled_track_points.append(p / self.normalization_factor * self.minimap_scale)
	self.scaled_track_points.append(self.scaled_track_points[0])
	self.track_layer.queue_redraw()
	self.refresh()


func set_minimap_center(point: Vector3):
	self.center_point = to_vec2(point)
	self.track_offset = -((self.center_point - self.track_centroid) / self.normalization_factor * self.minimap_scale)
	self.track_layer.queue_redraw()   # offset is baked into the draw call now
	self.refresh()


func _on_track_layer_draw() -> void:
	self.track_layer.draw_set_transform(self.track_offset)
	self.track_layer.draw_polyline(self.scaled_track_points, Color.WHITE, -1.0)


func _on_player_layer_draw() -> void:
	for player in players:
		var world_2d := to_vec2(player["global_position"])
		var local_pos := (world_2d - self.center_point) / self.normalization_factor * self.minimap_scale
		var radius := 15.0 if player["emphasis"] else 10.0
		self.player_layer.draw_circle(local_pos, radius, player["color"])
