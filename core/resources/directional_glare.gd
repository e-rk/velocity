@tool
extends MeshInstance3D

@export var color: Color = Color.WHITE
@export var size: float = 1.0

func _ready() -> void:
	self.mesh.size *= size
	var material = self.mesh.surface_get_material(0) as ShaderMaterial
	material.set_shader_parameter(&"color", self.color)
