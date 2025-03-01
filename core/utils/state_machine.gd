class_name StateMachine
extends Node

@export_node_path("State") var initial_state: NodePath

@onready var current_state = get_node(self.initial_state)

signal state_changed


func _ready():
	current_state.enter()


func set_state(next_state: State):
	assert(next_state != null)
	self.current_state.leave()
	self.current_state = next_state
	self.current_state.enter()
	self.state_changed.emit(self.current_state.name)


func is_state_active(expected_state) -> bool:
	return expected_state == self.current_state
