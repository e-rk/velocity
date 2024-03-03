@tool
extends EditorScenePostImport

func _post_import(scene):
	if scene.get_meta("type") == "track":
		var new_scene = RaceTrack.new()
		new_scene.name = scene.name
		scene.replace_by(new_scene)
		return new_scene
	elif scene.get_meta("type") == "car":
		var new_scene = Car.new()
		new_scene.name = scene.name
		scene.replace_by(new_scene)
		var performance = CarPerformance.new()
		performance.data = scene.get_meta("performance")
		new_scene.performance = performance
		new_scene.collision_layer = Constants.collision_layer_to_mask([Constants.CollisionLayer.RACERS])
		new_scene.collision_mask = Constants.collision_layer_to_mask([Constants.CollisionLayer.RACERS])
		new_scene.continuous_cd = true
		scene = new_scene
	return scene
