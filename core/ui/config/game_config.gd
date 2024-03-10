extends Control

@export var config := GameConfig.new()

signal config_error
signal config_changed

@onready var track_picker = %TrackPicker
@onready var rule_configurator = %RuleConfigurator


func _on_rule_configurator_rules_changed(rules):
	config.rules = rules


func _on_track_picker_track_selected(track):
	config.track = track


func disable():
	track_picker.disable()
	rule_configurator.disable()


func enable():
	track_picker.enable()
	rule_configurator.enable()
