class_name Car
extends RigidBody3D

@export var performance: CarPerformance

@export_range(-1.0, 1.0) var steering: float = 0.0:
	set(value):
		steering = clamp(value, -1.0, 1.0)
	get:
		return steering

@export_range(0.0, 1.0) var throttle: float = 0.0:
	set(value):
		throttle = clamp(value, 0.0, 1.0)
	get:
		return throttle

@export var handbrake: bool = false

@export_range(0.0, 1.0) var brake: float = 0.0:
	set(value):
		brake = clamp(value, 0.0, 1.0)
	get:
		return brake

@export var gear := CarTypes.Gear.NEUTRAL:
	set(value):
		gear = clamp(value, CarTypes.Gear.REVERSE, self.max_gear())
	get:
		return gear

@export var handling_model: HandlingModel

@export var lights_on : bool:
	set(value):
		lights_on = value
		self._enable_lights(self.head_lights, value)
		self._enable_lights(self.tail_lights, value)
		if self.interior_dashboard_lit:
			self.interior_dashboard_lit.visible = value
		if self.dashboard_lit:
			self.dashboard_lit.visible = value
	get:
		return lights_on

@export var siren_on : bool:
	set(value):
		siren_on = value
		self._enable_lights(self.siren_lights, value)
	get:
		return siren_on

@export var color : CarColorSet:
	set(value):
		color = value
		self._set_car_color(value)
	get:
		return color

@export var palette: Array[CarColorSet]

@export var car_textures: Array[CarTexture] = []


var current_rpm := 0.0
var current_steering := 0.0
var current_throttle := 0.0
var current_brake := 0.0
var current_gear := CarTypes.Gear.NEUTRAL
var linear_acceleration = Vector3.ZERO
var prev_linear_velocity = Vector3.ZERO
var prev_angular_velocity = Vector3.ZERO
var skip_counter = 0
var handbrake_accumulator = 0
var gear_shift_counter = 0
var shifted_down = false
var g_transfer := 0.0
var has_contact_with_ground := true
var head_lights: Array[Light3D] = []
var tail_lights: Array[Light3D] = []
var brake_lights: Array[Light3D] = []
var directional_lights: Array[Light3D] = []
var reverse_lights: Array[Light3D] = []
var siren_lights: Array[Light3D] = []
var tail_light_energy : float = 0.0
var brake_light_energy : float = 0.0

@onready var collider: CollisionShape3D = $Collider
@onready var interior_camera: Camera3D = $"Interior camera"
@onready var interior_wheel = $steering
@onready var rpm_meter: MeshInstance3D = $tachometer
@onready var mph_meter: MeshInstance3D = $speedometer
@onready var interior_dashboard_lit: MeshInstance3D = $interior_dashboard_lit
@onready var dashboard_lit: MeshInstance3D = $dashboard_lit
@onready var road_raycasts: Node3D = $RoadRaycasts
@onready var road_raycast_down: RayCast3D = $RoadRaycasts/Down
@onready var road_raycast_up: RayCast3D = $RoadRaycasts/Up
@onready var synchronizer: CarSynchronizer = $CarSynchronizer
@onready var wall_prober: RayCast3D = $WallProber


func _ready():
	if handling_model == null:
		handling_model = HandlingModelRE.new()
	var nodes = self.get_children().filter(func(x): return x is Light3D)
	self.head_lights.assign(nodes.filter(func(x): return x.name.begins_with("headlight")))
	self.tail_lights.assign(nodes.filter(func(x): return x.name.begins_with("taillight")))
	self.brake_lights.assign(nodes.filter(func(x): return x.name.begins_with("brakelight")))
	self.reverse_lights.assign(nodes.filter(func(x): return x.name.begins_with("reverse")))
	self.directional_lights.assign(nodes.filter(func(x): return x.name.begins_with("directional")))
	self.siren_lights.assign(nodes.filter(func(x): return x.name.begins_with("siren")))
	self._enable_lights(self.head_lights, self.lights_on)
	self._enable_lights(self.tail_lights, self.lights_on)
	self._enable_lights(self.brake_lights, false)
	self._enable_lights(self.reverse_lights, false)
	self._enable_lights(self.directional_lights, false)
	if self.tail_lights:
		self.tail_light_energy = self.tail_lights[0].light_energy
	if self.brake_lights:
		self.brake_light_energy = self.brake_lights[0].light_energy
	else:
		self.brake_light_energy = 2 * tail_light_energy
	if not self.interior_wheel:
		self.interior_wheel = self.find_child("*Steering*")

func _enable_lights(lights: Array, visible: bool):
	for light in lights:
		light.visible = visible


func _set_car_color(color: CarColorSet):
	for texture in self.car_textures:
		texture.color_set = color


func get_interior_camera() -> Camera3D:
	return self.interior_camera

func dimensions() -> Vector3:
	return collider.shape.size


func max_gear() -> CarTypes.Gear:
	return self.performance.max_gear()


func _do_road_raycasts(position: Vector3) -> Dictionary:
	self.road_raycasts.global_position = position
	self.road_raycasts.force_update_transform()
	self.road_raycast_down.force_raycast_update()
	self.road_raycast_up.force_raycast_update()
	var collision_position = Vector3(position.x, -INF, position.z)
	var normal = Vector3.UP
	if self.road_raycast_down.is_colliding():
		collision_position = self.road_raycast_down.get_collision_point()
		normal = self.road_raycast_down.get_collision_normal()
	elif self.road_raycast_up.is_colliding():
		collision_position = self.road_raycast_up.get_collision_point()
		normal = -self.road_raycast_up.get_collision_normal()
	var result = {
		"distance": (position.y - collision_position.y),
		"normal": normal,
	}
	return result


func basis_from_normal(normal: Vector3) -> Basis:
	var x = self.basis.z.cross(normal).normalized()
	var z = normal.cross(x)
	return Basis(-x, normal, z)


func get_positional_attributes(position: Vector3) -> Dictionary:
	var result = self._do_road_raycasts(position)
	return {
		"distance_above_ground": result["distance"],
		"basis_to_road": self.basis_from_normal(result["normal"]),
	}


func get_current_positional_attributes(state: PhysicsDirectBodyState3D) -> Dictionary:
	return self.get_positional_attributes(state.transform.origin)


func get_next_positional_attributes(state: PhysicsDirectBodyState3D, timestep: float) -> Dictionary:
	var next_position = state.transform.origin + timestep * state.linear_velocity
	return self.get_positional_attributes(next_position)


func check_contact_with_ground(positional_attributes: Dictionary) -> bool:
	return positional_attributes["distance_above_ground"] < 0.6


func keep_height_above_ground(state: PhysicsDirectBodyState3D, positional_attributes: Dictionary):
	if check_contact_with_ground(positional_attributes):
		var pos = state.transform.origin
		pos.y = pos.y - positional_attributes["distance_above_ground"] + 0.5  # 0.6
		state.transform.origin = pos


func enable_sync(enable: bool) -> void:
	self.synchronizer.public_visibility = enable


func is_police() -> bool:
	return not self.siren_lights.is_empty()


func is_siren_active() -> bool:
	if self.siren_lights:
		return self.siren_lights[0].visible
	return false


func _process(delta: float):
	var velocity_local = self.basis.inverse() * self.linear_velocity * delta
	var wheel_turn = (self.current_steering / 128.0) * (PI / 4)
	for child in self.get_children().filter(func(x): return x is CarWheel):
		child.step_rotation(velocity_local.z)
		child.turn = wheel_turn
	if self.interior_wheel:
		self.interior_wheel.rotation = remap(self.current_steering, -128.0, 128.0, deg_to_rad(90), deg_to_rad(-90)) * Vector3.MODEL_FRONT
	if self.rpm_meter:
		self.rpm_meter.value = remap(self.current_rpm, self.performance.engine_min_rpm(), self.performance.engine_redline_rpm, 0.0, 1.0)
	if self.mph_meter:
		self.mph_meter.value = remap(self.linear_velocity.length(), 0, self.performance.max_velocity(), 0.0, 1.0)
	#var box_pos = self.wall_collider.global_position
	#DebugDraw3D.draw_box(box_pos, wall_collider.quaternion, wall_collider.shape.size, Color(0.893, 0.0, 0.15, 1.0), true)
	#for i in self.wall_collider.get_collision_count():
		#var point = self.wall_collider.get_collision_point(i)
		#var normal = self.wall_collider.get_collision_normal(i)
		#DebugDraw3D.draw_arrow(point, point + normal * 3, Color(1, 1, 1), 1, 1, 2)


func _min_dot(collision_point: Vector3, normal: Vector3, point_a: Vector3, point_b: Vector3) -> bool:
	var dot_a = normal.dot(point_a - collision_point)
	var dot_b = normal.dot(point_b - collision_point)
	return dot_a < dot_b


func _collision(state: PhysicsDirectBodyState3D):
	var next_position = state.transform.origin + state.linear_velocity * state.step * 2
	var next_rotation = state.angular_velocity * state.step * 2
	var basis = Basis.from_euler(next_rotation)
	var rotated = basis * state.transform.basis
	var next_transform = Transform3D(rotated, next_position)
	#self.wall_prober.transform = next_transform

	var shape_size = self.collider.shape.size
	shape_size /= 2.0
	var points_to_check = [
		Vector3(shape_size.x, 0.0, shape_size.z),
		Vector3(-shape_size.x, 0.0, shape_size.z),
		Vector3(-shape_size.x, 0.0, -shape_size.z),
		Vector3(shape_size.x, 0.0, -shape_size.z),
		Vector3(shape_size.x, 0.0, 0.0),
		Vector3(-shape_size.x, 0.0, 0.0),
		Vector3(0.0, 0.0, shape_size.z),
		Vector3(0.0, 0.0, -shape_size.z),
	]
	var points_current = points_to_check.map(func(x): return state.transform * x)
	var points_next = points_to_check.map(func(x): return next_transform * x)

	var linear_velocity = state.linear_velocity
	var angular_velocity = state.angular_velocity
	var position = state.transform.origin

	for point in points_next:
		self.wall_prober.target_position = next_transform.inverse() * point
		self.wall_prober.force_raycast_update()

		if self.wall_prober.is_colliding():
			var collision_point = self.wall_prober.get_collision_point()
			var collision_normal = self.wall_prober.get_collision_normal()
			points_current.sort_custom(func(x, y): return _min_dot(collision_point, collision_normal, x, y))
			var min_point = points_current[0]
			var params = {
				"position": position,
				"angular_velocity": angular_velocity,
				"linear_velocity": linear_velocity,
				"friction": self.physics_material_override.friction,
				"mass": self.mass,
				"inertia_inv": state.inverse_inertia,
				"basis": state.transform.basis,
			}
			var collision_result = self.handling_model.process_collision(
				params,
				min_point,
				collision_point,
				collision_normal,
				1.0,
			)
			position = collision_result["position"]
			linear_velocity = collision_result["linear_velocity"]
			angular_velocity = collision_result["angular_velocity"]
	return {
		"position": position,
		"linear_velocity": linear_velocity,
		"angular_velocity": angular_velocity
	}


func _integrate_forces(state: PhysicsDirectBodyState3D):
	skip_counter = (skip_counter + 1) % 2
	if skip_counter == 0:
		return

	var wheels = [
		{"type": CarTypes.Wheel.FRONT_RIGHT, "road_surface": 1},
		{"type": CarTypes.Wheel.FRONT_LEFT, "road_surface": 1},
		{"type": CarTypes.Wheel.REAR_RIGHT, "road_surface": 1},
		{"type": CarTypes.Wheel.REAR_LEFT, "road_surface": 1},
	]
	var collision_result = self._collision(state)
	state.linear_velocity = collision_result["linear_velocity"]
	state.angular_velocity = collision_result["angular_velocity"]
	state.transform.origin = collision_result["position"]

	var positional_attributes = self.get_current_positional_attributes(state)
	var next_positional_attributes = self.get_next_positional_attributes(state, state.step * 2)
	var model_params = {
		"linear_velocity": state.linear_velocity,
		"angular_velocity": state.angular_velocity,
		"gravity_vector": state.total_gravity,
		"has_contact_with_ground": self.has_contact_with_ground,
		"timestep": state.step * 2,
		"performance": self.performance,
		"gear": self.current_gear,
		"next_gear": self.gear,
		"rpm": self.current_rpm,
		"mass": self.mass,
		"basis": state.transform.basis,
		"basis_to_road": positional_attributes["basis_to_road"],
		"current_steering": self.current_steering,
		"throttle_input": self.throttle,
		"throttle": self.current_throttle,
		"brake_input": self.brake,
		"brake": self.current_brake,
		"turn_input": self.steering,
		"handbrake": self.handbrake,
		"inertia_inv": state.inverse_inertia,
		"road_surface": 0,
		"weather": 0,
		"lost_grip": true,
		"basis_to_road_next": next_positional_attributes["basis_to_road"],
		"distance_above_ground": positional_attributes["distance_above_ground"],
		"wheels": wheels,
		"handbrake_accumulator": self.handbrake_accumulator,
		"force": 0.0,
		"gear_shift_counter": self.gear_shift_counter,
		"shifted_down": self.shifted_down,
		"g_transfer": self.g_transfer,
		"unknown_bool": false,
	}
	var result = handling_model.process(model_params)
	state.linear_velocity = result["linear_velocity"]
	state.angular_velocity = result["angular_velocity"]
	self.current_steering = result["current_steering"]
	self.current_throttle = result["throttle"]
	self.current_brake = result["brake"]
	self.current_rpm = result["rpm"]
	self.handbrake_accumulator = result["handbrake_accumulator"]
	self.gear_shift_counter = result["gear_shift_counter"]
	self.shifted_down = result["shifted_down"]
	self.current_gear = result["gear"]
	self.g_transfer = result["g_transfer"]
	self.has_contact_with_ground = result["has_contact_with_ground"]
	self.linear_acceleration = (state.linear_velocity - prev_linear_velocity) / (state.step * 2)
	prev_linear_velocity = state.linear_velocity
	prev_angular_velocity = state.angular_velocity
	self.keep_height_above_ground(state, positional_attributes)

	self._enable_lights(self.brake_lights, self.current_brake > 0)
	self._enable_lights(self.tail_lights, self.current_brake > 0 || self.lights_on)
	self._enable_lights(self.reverse_lights,self.current_gear == CarTypes.Gear.REVERSE)
	self.gear = self.current_gear
	var tail_light_energy = self.tail_light_energy
	if self.current_brake > 0:
		tail_light_energy = self.brake_light_energy
	for light in self.tail_lights:
		light.light_energy = tail_light_energy
