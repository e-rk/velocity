@tool
extends EditorPlugin

var spt_gltf_extras

func _enter_tree():
	spt_gltf_extras = preload("gltf-extras.gd").new()
	GLTFDocument.register_gltf_document_extension(spt_gltf_extras)

func _exit_tree():
	GLTFDocument.unregister_gltf_document_extension(spt_gltf_extras)


