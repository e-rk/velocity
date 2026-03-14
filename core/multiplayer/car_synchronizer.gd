class_name CarSynchronizer
extends MultiplayerSynchronizer

@export var sync_state: Dictionary = {
	"transform": Transform3D.IDENTITY,
	"linear_velocity": Vector3.ZERO,
	"angular_velocity": Vector3.ZERO,
}

@onready var target: Car = get_node(root_path)

var body_state: PhysicsDirectBodyState3D


func _enter_tree() -> void:
	self.set_multiplayer_authority(1)


func _ready():
	self.synchronized.connect(self._on_synchronized)


func _physics_process(_delta: float):
	if not body_state:
		body_state = PhysicsServer3D.body_get_direct_state(target.get_rid())
	if self.target and multiplayer.get_unique_id() == 1:
		sync_state = {
			"transform": body_state.transform,
			"linear_velocity": body_state.linear_velocity,
			"angular_velocity": body_state.angular_velocity,
		}


func _on_synchronized():
	if body_state:
		body_state.transform = sync_state["transform"]
		body_state.linear_velocity = sync_state["linear_velocity"]
		body_state.angular_velocity = sync_state["angular_velocity"]
