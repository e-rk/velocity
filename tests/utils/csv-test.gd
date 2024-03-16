extends GutTest
class_name CsvTest

func get_csv() -> FileAccess:
	return null

func body(data: Dictionary):
	pass

func get_csv_line_dict(file, header):
	var line = file.get_csv_line()
	var result = Dictionary()
	if len(line) == 1:
		return null
	for i in line.size():
		result[header[i]] = line[i]
	return result

func test_csv():
	var csv = self.get_csv()
	var header = csv.get_csv_line()
	while not csv.eof_reached():
		var line = self.get_csv_line_dict(csv, header)
		if line == null:
			break
		self.body(line)

func rpm(data: Dictionary) -> float:
	return float(data["rpm"])

func torque(data: Dictionary) -> float:
	return float(data["torque"])

func gear(data: Dictionary) -> int:
	return int(data["gear"])

func local_linear_velocity(data: Dictionary) -> Vector3:
	var vx = float(data.get("local_linear_velocity_x", "0.0"))
	var vy = float(data.get("local_linear_velocity_y", "0.0"))
	var vz = float(data.get("local_linear_velocity_z", "0.0"))
	return Vector3(vx, vy, vz)

func global_linear_velocity(data: Dictionary) -> Vector3:
	var vx = float(data.get("global_linear_velocity_x", "0.0"))
	var vy = float(data.get("global_linear_velocity_y", "0.0"))
	var vz = float(data.get("global_linear_velocity_z", "0.0"))
	return Vector3(vx, vy, vz)

func global_angular_velocity(data: Dictionary) -> Vector3:
	var wx = float(data.get("global_angular_velocity_x", "0.0"))
	var wy = float(data.get("global_angular_velocity_y", "0.0"))
	var wz = float(data.get("global_angular_velocity_z", "0.0"))
	return Vector3(wx, wy, wz)

func local_angular_velocity(data: Dictionary) -> Vector3:
	var wx = float(data.get("local_angular_velocity_x", "0.0"))
	var wy = float(data.get("local_angular_velocity_y", "0.0"))
	var wz = float(data.get("local_angular_velocity_z", "0.0"))
	return Vector3(wx, wy, wz)

func inertia_inv(data: Dictionary) -> Vector3:
	var ix = float(data.get("inertia_inv_x", "0.0"))
	var iy = float(data.get("inertia_inv_y", "0.0"))
	var iz = float(data.get("inertia_inv_z", "0.0"))
	return Vector3(ix, iy, iz)

func mass(data: Dictionary) -> float:
	return float(data["mass"])

func is_airborne(data: Dictionary) -> bool:
	var airborne_counter = int(data["airborne_counter"])
	return airborne_counter != 0

func handbrake(data: Dictionary) -> bool:
	return data["handbrake"] != "0"

func steering(data: Dictionary) -> int:
	return int(data["turn_angle"])

func throttle(data: Dictionary) -> float:
	return float(data["throttle"])

func brake_input(data: Dictionary) -> float:
	return float(data["brake"])

func slip_angle(data: Dictionary) -> float:
	return float(data["slip_angle"])

func wheel_planar_vector(data: Dictionary) -> Vector3:
	var fx = float(data.get("wheel_planar_vector_lateral", "0.0"))
	var fz = float(data.get("wheel_planar_vector_longitudal", "0.0"))
	return Vector3(fx, 0, fz)

func wheel_type(data: Dictionary) -> int:
	return int(data["wheel_type"])

func wheel_is_front(data: Dictionary) -> float:
	return data["wheel_is_front"] != "0"

func wheel_downforce(data: Dictionary, wheel_idx: int) -> float:
	return float(data["wheel_" + str(wheel_idx) + "_downforce_factor"])

func wheel_lateral_grip(data: Dictionary) -> float:
	return float(data["lateral_grip"])

func wheel_force(data: Dictionary, prefix="") -> Vector3:
	var fx = float(data.get(prefix + "lateral_force", "0.0"))
	var fz = float(data.get(prefix + "longitudal_force", "0.0"))
	return Vector3(fx, 0, fz)

func wheel_traction(data: Dictionary) -> float:
	return float(data["wheel_traction"])

func road_basis_normal_y(data: Dictionary) -> Vector3:
	var nx = float(data.get("road_basis_normal_x", "0.0"))
	var ny = float(data.get("road_basis_normal_y", "0.0"))
	var nz = float(data.get("road_basis_normal_z", "0.0"))
	return Vector3(nx, ny, nz)

func local_linear_acceleration(data: Dictionary) -> Vector3:
	var ax = float(data.get("local_linear_acceleration_x", "0.0"))
	var ay = float(data.get("local_linear_acceleration_y", "0.0"))
	var az = float(data.get("local_linear_acceleration_z", "0.0"))
	return Vector3(ax, ay, az)

func road_surface(data: Dictionary) -> int:
	return int(data["road_surface"])

func weather(data: Dictionary) -> int:
	return int(data["weather"])

func basis_to_road(data: Dictionary) -> Basis:
	return Basis(
		Vector3(float(data["road_basis_right_x"]), float(data["road_basis_right_y"]), float(data["road_basis_right_z"])),
		Vector3(float(data["road_basis_normal_x"]), float(data["road_basis_normal_y"]), float(data["road_basis_normal_z"])),
		Vector3(float(data["road_basis_forward_x"]), float(data["road_basis_forward_y"]), float(data["road_basis_forward_z"])),
	)
