@tool # Needed so it runs in editor.
extends EditorScenePostImport

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	var new_root = scene
	var node = scene.get_child(0, true)
	if node is RaceTrack:
		new_root = node
		var name = scene.name
		var packed = PackedScene.new()
		packed.pack(new_root)
		ResourceSaver.save(packed, "res://import/tracks/%s/%s.tscn" % [name, name])
	if node is Car:
		new_root = node
		var name = scene.name
		var packed = PackedScene.new()
		packed.pack(new_root)
		ResourceSaver.save(packed, "res://import/cars/%s/%s.tscn" % [name, name])
	return new_root # Remember to return the imported scene
