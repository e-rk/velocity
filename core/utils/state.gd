class_name State
extends Node

const context_path: NodePath = ".."

signal entered

@onready var context: StateMachine = get_node(context_path)


func enter():
	self.entered.emit()


func leave():
	pass
