@tool
extends GLTFDocumentExtension

func create_waypoints(waypoints: Array):
	var node = Waypoints.new()
	node.name = "Waypoints"
	var curve = Curve3D.new()
	for waypoint in waypoints:
		var v = Vector3(waypoint[0], waypoint[1], -waypoint[2])
		curve.add_point(v)
	node.waypoints = curve
	return node

func scale_light_energy(node: Node):
	if node is Light3D:
		node.light_energy /= 6830
	if node is DirectionalLight3D:
		node.light_energy = 0.5
		node.shadow_reverse_cull_face = true
		node.shadow_enabled = true
		node.shadow_blur = true
	for child in node.get_children():
		scale_light_energy(child)
	return OK

func dict_to_color(value: Dictionary) -> Color:
	return Color(value["red"], value["green"], value["blue"])

func create_environment(environment: Dictionary):
	var worldenv = WorldEnvironment.new()
	var ambient = environment["ambient"]
	var horizon = environment["horizon"]
	var color = dict_to_color(ambient)
	worldenv.name = "WorldEnvironment"
	worldenv.environment = Environment.new()
	worldenv.environment.ssao_enabled = true
	worldenv.environment.ssao_intensity = 6
	worldenv.environment.ssao_detail = 5
	worldenv.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	worldenv.environment.ambient_light_color = Color.WHITE
	worldenv.environment.ambient_light_energy = 0.5
	worldenv.environment.background_mode = Environment.BG_SKY
	worldenv.environment.sky = Sky.new()
	worldenv.environment.sky.sky_material = ShaderMaterial.new()
	worldenv.environment.sky.sky_material.shader = load("res://core/resources/shader/sky.gdshader")
	worldenv.camera_attributes = load("res://core/resources/camera-attributes.tres")
	worldenv.environment.sky.sky_material.set_shader_parameter("sun_side_color", dict_to_color(horizon["sun"]))
	worldenv.environment.sky.sky_material.set_shader_parameter("top_side_color", dict_to_color(horizon["top"]))
	worldenv.environment.sky.sky_material.set_shader_parameter("opposite_side_color", dict_to_color(horizon["opposite"]))
	worldenv.environment.sky.sky_material.set_shader_parameter("CloudTexture", load("res://core/resources/clouds.tres"))
	return worldenv

func finalize_additive_materials(json: Dictionary, materials: Array[Material]):
	var json_materials = json["materials"]
	for i in len(materials):
		var json_material = json_materials[i]
		var material = materials[i]
		if !json_material.has("extras"):
			continue
		var extras = json_material["extras"]
		var is_additive = false
		if extras.has("SPT_additive"):
			is_additive = extras["SPT_additive"]
		if is_additive and material is BaseMaterial3D:
			material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	return OK

func finalize_static_bodies(state: GLTFState, node: Node):
	var nodes = state.json["nodes"]
	var i = 0
	while i < range(0, len(nodes)):
		var json_node = nodes[i]
		var checked_node = node.get_child(i, false)
		if !json_node.has("extras"):
			continue
		var extras = json_node["extras"]
		if not extras.has("SPT_surface_type"):
			prints("No surface type")
			continue
		var surface_type = extras["SPT_surface_type"]
		checked_node.set_meta("surface_type", surface_type)
	return OK

func remove_metallic_specular(materials: Array[Material]):
	for material in materials:
		if material is BaseMaterial3D:
			material.metallic_specular = 0.0
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return OK

func process_car_extras(root: Node, data: Dictionary):
	var synchronizer = CarSynchronizer.new()
	synchronizer.name = "CarSynchronizer"
	var config = SceneReplicationConfig.new()
	config.add_property("CarSynchronizer:sync_state")
	synchronizer.replication_config = config
	root.add_child(synchronizer)
	synchronizer.owner = root
	var dimensions = data["dimensions"]
	var collisionshape = CollisionShape3D.new()
	collisionshape.owner = root
	collisionshape.name = "Collider"
	collisionshape.shape = BoxShape3D.new()
	collisionshape.shape.size = Vector3(dimensions[0], dimensions[1], dimensions[2])
	root.add_child(collisionshape)
	collisionshape.owner = root
	root.set_meta("performance", data["performance"])
	root.set_meta("type", "car")

func process_track_extras(root: Node, data: Dictionary):
	var node = self.create_environment(data["environment"])
	root.add_child(node)
	node.owner = root
	node = self.create_waypoints(data["waypoints"])
	root.add_child(node, true)
	node.owner = root
	root.set_meta("type", "track")

func make_track_node(environment_data: Dictionary) -> RaceTrack:
	var track_node = RaceTrack.new()
	return track_node

func process_scene_extras(state: GLTFState, root: Node):
	var main_scene_idx = state.json["scene"]
	var scene = state.json["scenes"][main_scene_idx]
	if !scene.has("extras"):
		return null
	var extras = scene["extras"]
	if extras.has("SPT_car"):
		process_car_extras(root, extras["SPT_car"])
	if extras.has("SPT_track"):
		process_track_extras(root, extras["SPT_track"])

func _import_post(state: GLTFState, root: Node):
	var err
	err = scale_light_energy(root)
	if err != OK:
		return err
	err = finalize_additive_materials(state.json, state.materials)
	if err != OK:
		return err
	err = remove_metallic_specular(state.materials)
	if err != OK:
		return err
	#err = finalize_static_bodies(state, root)
	#if err != OK:
		#return err
	process_scene_extras(state, root)
	return OK
