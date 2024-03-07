extends MultiplayerSynchronizer

@export var sync_on_ready: bool = false
@export var sequence_counter = 0

var prev_sequence_counter = 0

signal on_demand_synchronized


func on_demand_sync():
	sequence_counter += 1


func _ready():
	if self.sync_on_ready:
		self.on_demand_sync()


func _on_delta_synchronized():
	if sequence_counter != prev_sequence_counter:
		self.on_demand_synchronized.emit()
	prev_sequence_counter = sequence_counter
